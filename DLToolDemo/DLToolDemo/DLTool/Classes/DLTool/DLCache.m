#import "DLCache.h"
#import <time.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import <CoreFoundation/CoreFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>

static inline dispatch_queue_t DLMemoryCacheGetReleaseQueue(){
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

static const NSUInteger kMaxErrorRetryCount = 8;
static const NSTimeInterval kMinRetryTimeInterval = 2.0;
static const int kPathLengthMax = PATH_MAX -64;
static NSString *const kDBFileName = @"dl_cache.sqlite";
static NSString *const kDBShmFileName = @"dl_cache.sqlite-shm";
static NSString *const kDBWalFileName = @"dl_cache.sqlite-wal";
static NSString *const kDataDirectoryName = @"data";
static NSString *const kTrashDirectoryName = @"trash";

@interface DLKVStorageItem : NSObject
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSData *value;
@property (nullable, nonatomic, strong) NSString *filename;
@property (nonatomic) int size;
@property (nonatomic) int modTime;
@property (nonatomic) int accessTime;
@property (nullable, nonatomic, strong) NSData *extendedData;
@end

typedef NS_ENUM(NSUInteger, DLKVStorageType){
    DLKVStorageTypeFile = 0,
    DLKVStorageTypeSQLite = 1,
    DLKVStorageTypeMixed = 2,
};

@interface DLKVStorage : NSObject

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) DLKVStorageType type;
@property (nonatomic) BOOL errorLogsEnabled;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

-(instancetype)initWithPath:(NSString *)path type:(DLKVStorageType)type NS_DESIGNATED_INITIALIZER;

-(BOOL)saveItem:(DLKVStorageItem *)item;

-(BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;

-(BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(NSString *)filename
           extendedData:(NSData *)extendedData;

-(BOOL)removeItemForKey:(NSString *)key;

-(BOOL)removeItemForKeys:(NSArray<NSString *> *)keys;

-(BOOL)removeItemsLargerThanSize:(int)size;

-(BOOL)removeItemsEarlierThanTime:(int)time;

-(BOOL)removeItemsToFitSize:(int)maxSize;

-(BOOL)removeItemsToFitCount:(int)maxCount;

-(BOOL)removeAllItems;

-(void)removeAllItemsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                               endBlock:(void(^)(BOOL error))end;

-(DLKVStorageItem *)getItemForKey:(NSString *)key;

-(DLKVStorageItem *)getItemInfoForKey:(NSString *)key;

-(NSData *)getItemValueForKey:(NSString *)key;

-(NSArray<DLKVStorageItem *> *)getItemForKeys:(NSArray<NSString *> *)keys;

-(NSArray<DLKVStorageItem *> *)getItemInfoForKeys:(NSArray<NSString *> *)keys;

-(NSDictionary<NSString *, NSData *> *)getItemValueForKeys:(NSArray<NSString *> *)keys;

-(BOOL)itemExistsForKey:(NSString *)key;

-(int)getItemsCount;

-(int)getItemsSize;

@end


static UIApplication *_DLSharedApplication(){
    static BOOL isAppExtension = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"UIApplication");
        if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) isAppExtension = YES;
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) isAppExtension = YES;
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    return isAppExtension ? nil : [UIApplication performSelector:@selector(sharedApplication)];
#pragma clang diagnostic pop
}


@implementation DLKVStorageItem
@end

@implementation DLKVStorage{
    dispatch_queue_t _trashQueue;
    
    NSString *_path;
    NSString *_dbPath;
    NSString *_dataPath;
    NSString *_trashPath;
    
    sqlite3 *_db;
    CFMutableDictionaryRef _dbStmtCache;
    NSTimeInterval _dbLastOpenErrorTime;
    NSUInteger _dbOpenErrorCount;
}


#pragma mark -db

-(BOOL)_dbOpen{
    if (_db) return YES;
    
    int result = sqlite3_open(_dbPath.UTF8String, &_db);
    if (result == SQLITE_OK){
        CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
        CFDictionaryValueCallBacks valueCallbacks ={0};
        _dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
        _dbLastOpenErrorTime = 0;
        _dbOpenErrorCount = 0;
        return YES;
    } else{
        _db = NULL;
        if (_dbStmtCache) CFRelease(_dbStmtCache);
        _dbStmtCache = NULL;
        _dbLastOpenErrorTime = CACurrentMediaTime();
        _dbOpenErrorCount++;
        
        if (_errorLogsEnabled){
            NSLog(@"%s line:%d sqlite open failed (%d).", __FUNCTION__, __LINE__, result);
        }
        return NO;
    }
}

-(BOOL)_dbClose{
    if (!_db) return YES;
    int  result = 0;
    BOOL retry = NO;
    BOOL stmtFinalized = NO;
    if (_dbStmtCache) CFRelease(_dbStmtCache);
    _dbStmtCache = NULL;
    do{
        retry = NO;
        result = sqlite3_close(_db);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED){
            if (!stmtFinalized){
                stmtFinalized = YES;
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(_db, nil)) != 0){
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
            }
        } else if (result != SQLITE_OK){
            if (_errorLogsEnabled){
                NSLog(@"%s line:%d sqlite close failed (%d).", __FUNCTION__, __LINE__, result);
            }
        }
    } while (retry);
    _db = NULL;
    return YES;
}

-(BOOL)_dbCheck{
    if (!_db){
        if (_dbOpenErrorCount < kMaxErrorRetryCount &&
            CACurrentMediaTime() -_dbLastOpenErrorTime > kMinRetryTimeInterval){
            return [self _dbOpen] && [self _dbInitialize];
        } else{
            return NO;
        }
    }
    return YES;
}

-(BOOL)_dbInitialize{
    NSString *sql = @"pragma journal_mode = wal; pragma synchronous = normal; create table if not exists dl_cache (key text, filename text, size integer, inline_data blob, modification_time integer, last_access_time integer, extended_data blob, primary key(key)); create index if not exists last_access_time_idx on dl_cache(last_access_time);";
    return [self _dbExecute:sql];
}

-(void)_dbCheckpoint{
    if (![self _dbCheck]) return;
    sqlite3_wal_checkpoint(_db, NULL);
}

-(BOOL)_dbExecute:(NSString *)sql{
    if (sql.length == 0) return NO;
    if (![self _dbCheck]) return NO;
    
    char *error = NULL;
    int result = sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &error);
    if (error){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite exec error (%d): %s", __FUNCTION__, __LINE__, result, error);
        sqlite3_free(error);
    }
    
    return result == SQLITE_OK;
}

-(sqlite3_stmt *)_dbPrepareStmt:(NSString *)sql{
    if (![self _dbCheck] || sql.length == 0 || !_dbStmtCache) return NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_dbStmtCache, (__bridge const void *)(sql));
    if (!stmt){
        int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK){
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            return NULL;
        }
        CFDictionarySetValue(_dbStmtCache, (__bridge const void *)(sql), stmt);
    } else{
        sqlite3_reset(stmt);
    }
    return stmt;
}

-(NSString *)_dbJoinedKeys:(NSArray *)keys{
    NSMutableString *string = [NSMutableString new];
    for (NSUInteger i = 0,max = keys.count; i < max; i++){
        [string appendString:@"?"];
        if (i +1 != max){
            [string appendString:@","];
        }
    }
    return string;
}

-(void)_dbBindJoinedKeys:(NSArray *)keys stmt:(sqlite3_stmt *)stmt fromIndex:(int)index{
    for (int i = 0, max = (int)keys.count; i < max; i++){
        NSString *key = keys[i];
        sqlite3_bind_text(stmt, index +i, key.UTF8String, -1, NULL);
    }
}

-(BOOL)_dbSaveWithKey:(NSString *)key value:(NSData *)value fileName:(NSString *)fileName extendedData:(NSData *)extendedData{
    NSString *sql = @"insert or replace into dl_cache (key, filename, size, inline_data, modification_time, last_access_time, extended_data) values (?1, ?2, ?3, ?4, ?5, ?6, ?7);";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return NO;
    
    int timestamp = (int)time(NULL);
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    sqlite3_bind_text(stmt, 2, fileName.UTF8String, -1, NULL);
    sqlite3_bind_int(stmt, 3, (int)value.length);
    if (fileName.length == 0){
        sqlite3_bind_blob(stmt, 4, value.bytes, (int)value.length, 0);
    } else{
        sqlite3_bind_blob(stmt, 4, NULL, 0, 0);
    }
    sqlite3_bind_int(stmt, 5, timestamp);
    sqlite3_bind_int(stmt, 6, timestamp);
    sqlite3_bind_blob(stmt, 7, extendedData.bytes, (int)extendedData.length, 0);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite insert error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbUpdateAccessTimeWithKey:(NSString *)key{
    NSString *sql = @"update dl_cache set last_access_time = ?1 where key = ?2;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return NO;
    sqlite3_bind_int(stmt, 1, (int)time(NULL));
    sqlite3_bind_text(stmt, 2, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite update error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbUpdateAccessTimeWithKeys:(NSArray *)keys{
    if (![self _dbCheck]) return NO;
    int t = (int)time(NULL);
    NSString *sql = [NSString stringWithFormat:@"update dl_cache set last_access_time = %d where key in (%@);", t, [self _dbJoinedKeys:keys]];
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK){
        if (_errorLogsEnabled)  NSLog(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    
    [self _dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite update error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbDeleteItemWithKey:(NSString *)key{
    NSString *sql = @"delete from dl_cache where key = ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return NO;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled) NSLog(@"%s line:%d db delete error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbDeleteItemWithKeys:(NSArray *)keys{
    if (![self _dbCheck]) return NO;
    NSString *sql =  [NSString stringWithFormat:@"delete from dl_cache where key in (%@);", [self _dbJoinedKeys:keys]];
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    
    [self _dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (result == SQLITE_ERROR){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite delete error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbDeleteItemsWithSizeLargerThan:(int)size{
    NSString *sql = @"delete from dl_cache where size > ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return NO;
    sqlite3_bind_int(stmt, 1, size);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite delete error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(BOOL)_dbDeleteItemsWithTimeEarlierThan:(int)time{
    NSString *sql = @"delete from dl_cache where last_access_time < ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return NO;
    sqlite3_bind_int(stmt, 1, time);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE){
        if (_errorLogsEnabled)  NSLog(@"%s line:%d sqlite delete error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return NO;
    }
    return YES;
}

-(DLKVStorageItem *)_dbGetItemFromStmt:(sqlite3_stmt *)stmt excludeInlineData:(BOOL)excludeInlineData{
    int i = 0;
    char *key = (char *)sqlite3_column_text(stmt, i++);
    char *filename = (char *)sqlite3_column_text(stmt, i++);
    int size = sqlite3_column_int(stmt, i++);
    const void *inline_data = excludeInlineData ? NULL : sqlite3_column_blob(stmt, i);
    int inline_data_bytes = excludeInlineData ? 0 : sqlite3_column_bytes(stmt, i++);
    int modification_time = sqlite3_column_int(stmt, i++);
    int last_access_time = sqlite3_column_int(stmt, i++);
    const void *extended_data = sqlite3_column_blob(stmt, i);
    int extended_data_bytes = sqlite3_column_bytes(stmt, i++);
    
    DLKVStorageItem *item = [DLKVStorageItem new];
    if (key) item.key = [NSString stringWithUTF8String:key];
    if (filename && *filename != 0) item.filename = [NSString stringWithUTF8String:filename];
    item.size = size;
    if (inline_data_bytes > 0 && inline_data) item.value = [NSData dataWithBytes:inline_data length:inline_data_bytes];
    item.modTime = modification_time;
    item.accessTime = last_access_time;
    if (extended_data_bytes > 0 && extended_data) item.extendedData = [NSData dataWithBytes:extended_data length:extended_data_bytes];
    return item;
}

-(DLKVStorageItem *)_dbGetItemWithKey:(NSString *)key excludeInlineData:(BOOL)excludeInlineData{
    NSString *sql = excludeInlineData ? @"select key, filename, size, modification_time, last_access_time, extended_data from dl_cache where key = ?1;" : @"select key, filename, size, inline_data, modification_time, last_access_time, extended_data from dl_cache where key = ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    DLKVStorageItem *item = nil;
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW){
        item = [self _dbGetItemFromStmt:stmt excludeInlineData:excludeInlineData];
    } else{
        if (result != SQLITE_DONE){
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        }
    }
    return item;
}

-(NSMutableArray *)_dbGetItemWithKeys:(NSArray *)keys excludeInlineData:(BOOL)excludeInlineData{
    if (![self _dbCheck]) return nil;
    NSString *sql;
    if (excludeInlineData){
        sql = [NSString stringWithFormat:@"select key, filename, size, modification_time, last_access_time, extended_data from dl_cache where key in (%@);", [self _dbJoinedKeys:keys]];
    } else{
        sql = [NSString stringWithFormat:@"select key, filename, size, inline_data, modification_time, last_access_time, extended_data from dl_cache where key in (%@)", [self _dbJoinedKeys:keys]];
    }
    
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return nil;
    }
    
    [self _dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    NSMutableArray *items = [NSMutableArray new];
    do{
        result = sqlite3_step(stmt);
        if (result == SQLITE_ROW){
            DLKVStorageItem *item = [self _dbGetItemFromStmt:stmt excludeInlineData:excludeInlineData];
            if (item) [items addObject:item];
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            items = nil;
            break;
        }
    } while (1);
    sqlite3_finalize(stmt);
    return items;
}

-(NSData *)_dbGetValueWithKey:(NSString *)key{
    NSString *sql = @"select inline_data from dl_cache where key = ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW){
        const void *inline_data = sqlite3_column_blob(stmt, 0);
        int inline_data_bytes = sqlite3_column_bytes(stmt, 0);
        if (!inline_data || inline_data_bytes <= 0) return nil;
        return [NSData dataWithBytes:inline_data length:inline_data_bytes];
    } else{
        if (result != SQLITE_DONE){
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        }
        return nil;
    }
}

-(NSString *)_dbGetFilenameWithKey:(NSString *)key{
    NSString *sql = @"select filename from dl_cache where key = ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW){
        char *filename = (char *)sqlite3_column_text(stmt, 0);
        if (filename && *filename != 0){
            return [NSString stringWithUTF8String:filename];
        }
    } else{
        if (result != SQLITE_DONE){
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        }
    }
    return nil;
}

-(NSMutableArray *)_dbGetFilenameWithKeys:(NSArray *)keys{
    if (![self _dbCheck]) return nil;
    NSString *sql = [NSString stringWithFormat:@"select filename from dl_cache where key in (%@);", [self _dbJoinedKeys:keys]];
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite stmt prepare error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return nil;
    }
    
    [self _dbBindJoinedKeys:keys stmt:stmt fromIndex:1];
    NSMutableArray *filenames = [NSMutableArray new];
    do{
        result = sqlite3_step(stmt);
        if (result == SQLITE_ROW){
            char *filename = (char *)sqlite3_column_text(stmt, 0);
            if (filename && *filename != 0){
                NSString *name = [NSString stringWithUTF8String:filename];
                if (name) [filenames addObject:name];
            }
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            filenames = nil;
            break;
        }
    } while (1);
    sqlite3_finalize(stmt);
    return filenames;
}

-(NSMutableArray *)_dbGetFilenamesWithSizeLargerThan:(int)size{
    NSString *sql = @"select filename from dl_cache where size > ?1 and filename is not null;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_int(stmt, 1, size);
    
    NSMutableArray *filenames = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW){
            char *filename = (char *)sqlite3_column_text(stmt, 0);
            if (filename && *filename != 0){
                NSString *name = [NSString stringWithUTF8String:filename];
                if (name) [filenames addObject:name];
            }
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            filenames = nil;
            break;
        }
    } while (1);
    return filenames;
}

-(NSMutableArray *)_dbGetFilenamesWithTimeEarlierThan:(int)time{
    NSString *sql = @"select filename from dl_cache where last_access_time < ?1 and filename is not null;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_int(stmt, 1, time);
    
    NSMutableArray *filenames = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW){
            char *filename = (char *)sqlite3_column_text(stmt, 0);
            if (filename && *filename != 0){
                NSString *name = [NSString stringWithUTF8String:filename];
                if (name) [filenames addObject:name];
            }
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            filenames = nil;
            break;
        }
    } while (1);
    return filenames;
}

-(NSMutableArray *)_dbGetItemSizeInfoOrderByTimeAscWithLimit:(int)count{
    NSString *sql = @"select key, filename, size from dl_cache order by last_access_time asc limit ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return nil;
    sqlite3_bind_int(stmt, 1, count);
    
    NSMutableArray *items = [NSMutableArray new];
    do{
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW){
            char *key = (char *)sqlite3_column_text(stmt, 0);
            char *filename = (char *)sqlite3_column_text(stmt, 1);
            int size = sqlite3_column_int(stmt, 2);
            NSString *keyStr = key ? [NSString stringWithUTF8String:key] : nil;
            if (keyStr){
                DLKVStorageItem *item = [DLKVStorageItem new];
                item.key = key ? [NSString stringWithUTF8String:key] : nil;
                item.filename = filename ? [NSString stringWithUTF8String:filename] : nil;
                item.size = size;
                [items addObject:item];
            }
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
            items = nil;
            break;
        }
    } while (1);
    return items;
}

-(int)_dbGetItemCountWithKey:(NSString *)key{
    NSString *sql = @"select count(key) from dl_cache where key = ?1;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return -1;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

-(int)_dbGetTotalItemSize{
    NSString *sql = @"select sum(size) from dl_cache;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return -1;
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

-(int)_dbGetTotalItemCount{
    NSString *sql = @"select count(*) from lelouch;";
    sqlite3_stmt *stmt = [self _dbPrepareStmt:sql];
    if (!stmt) return -1;
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW){
        if (_errorLogsEnabled) NSLog(@"%s line:%d sqlite query error (%d): %s", __FUNCTION__, __LINE__, result, sqlite3_errmsg(_db));
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}


#pragma mark -file

-(BOOL)_fileWriteWithName:(NSString *)filename data:(NSData *)data{
    NSString *path = [_dataPath stringByAppendingPathComponent:filename];
    return [data writeToFile:path atomically:NO];
}

-(NSData *)_fileReadWithName:(NSString *)filename{
    NSString *path = [_dataPath stringByAppendingPathComponent:filename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

-(BOOL)_fileDeleteWithName:(NSString *)filename{
    NSString *path = [_dataPath stringByAppendingPathComponent:filename];
    return [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

-(BOOL)_fileMoveAllToTrash{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuid = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *tmpPath = [_trashPath stringByAppendingPathComponent:(__bridge NSString *)(uuid)];
    BOOL suc = [[NSFileManager defaultManager] moveItemAtPath:_dataPath toPath:tmpPath error:nil];
    if (suc){
        suc = [[NSFileManager defaultManager] createDirectoryAtPath:_dataPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    CFRelease(uuid);
    return suc;
}

-(void)_fileEmptyTrashInBackground{
    NSString *trashPath = _trashPath;
    dispatch_queue_t queue = _trashQueue;
    dispatch_async(queue, ^{
        NSFileManager *manager = [NSFileManager new];
        NSArray *directoryContents = [manager contentsOfDirectoryAtPath:trashPath error:NULL];
        for (NSString *path in directoryContents){
            NSString *fullPath = [trashPath stringByAppendingPathComponent:path];
            [manager removeItemAtPath:fullPath error:NULL];
        }
    });
}


#pragma mark -private

/**
 Delete all files and empty in background.
 Make sure the db is closed.
 */
-(void)_reset{
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:kDBFileName] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:kDBShmFileName] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:kDBWalFileName] error:nil];
    [self _fileMoveAllToTrash];
    [self _fileEmptyTrashInBackground];
}

#pragma mark -public

-(instancetype)init{
    @throw [NSException exceptionWithName:@"DLKVStorage init error" reason:@"Please use the designated initializer and pass the 'path' and 'type'." userInfo:nil];
    return [self initWithPath:@"" type:DLKVStorageTypeFile];
}

-(instancetype)initWithPath:(NSString *)path type:(DLKVStorageType)type{
    if (path.length == 0 || path.length > kPathLengthMax){
        NSLog(@"DLKVStorage init error: invalid path: [%@].", path);
        return nil;
    }
    if (type > DLKVStorageTypeMixed){
        NSLog(@"DLKVStorage init error: invalid type: %lu.", (unsigned long)type);
        return nil;
    }
    
    self = [super init];
    _path = path.copy;
    _type = type;
    _dataPath = [path stringByAppendingPathComponent:kDataDirectoryName];
    _trashPath = [path stringByAppendingPathComponent:kTrashDirectoryName];
    _trashQueue = dispatch_queue_create("com.dl.cache.disk.trash", DISPATCH_QUEUE_SERIAL);
    _dbPath = [path stringByAppendingPathComponent:kDBFileName];
    _errorLogsEnabled = YES;
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error] ||
        ![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:kDataDirectoryName]
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error] ||
        ![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:kTrashDirectoryName]
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error]){
            NSLog(@"DLKVStorage init error:%@", error);
            return nil;
        }
    
    if (![self _dbOpen] || ![self _dbInitialize]){
        [self _dbClose];
        [self _reset];
        if (![self _dbOpen] || ![self _dbInitialize]){
            [self _dbClose];
            NSLog(@"DLKVStorage init error: fail to open sqlite db.");
            return nil;
        }
    }
    [self _fileEmptyTrashInBackground];
    return self;
}

-(void)dealloc{
    UIBackgroundTaskIdentifier taskID = [_DLSharedApplication() beginBackgroundTaskWithExpirationHandler:^{}];
    [self _dbClose];
    if (taskID != UIBackgroundTaskInvalid){
        [_DLSharedApplication() endBackgroundTask:taskID];
    }
}

-(BOOL)saveItem:(DLKVStorageItem *)item{
    return [self saveItemWithKey:item.key value:item.value filename:item.filename extendedData:item.extendedData];
}

-(BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value{
    return [self saveItemWithKey:key value:value filename:nil extendedData:nil];
}

-(BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename extendedData:(NSData *)extendedData{
    if (key.length == 0 || value.length == 0) return NO;
    if (_type == DLKVStorageTypeFile && filename.length == 0){
        return NO;
    }
    
    if (filename.length){
        if (![self _fileWriteWithName:filename data:value]){
            return NO;
        }
        if (![self _dbSaveWithKey:key value:value fileName:filename extendedData:extendedData]){
            [self _fileDeleteWithName:filename];
            return NO;
        }
        return YES;
    } else{
        if (_type != DLKVStorageTypeSQLite){
            NSString *filename = [self _dbGetFilenameWithKey:key];
            if (filename){
                [self _fileDeleteWithName:filename];
            }
        }
        return [self _dbSaveWithKey:key value:value fileName:nil extendedData:extendedData];
    }
}

-(BOOL)removeItemForKey:(NSString *)key{
    if (key.length == 0) return NO;
    switch (_type){
        case DLKVStorageTypeSQLite:{
            return [self _dbDeleteItemWithKey:key];
        } break;
        case DLKVStorageTypeFile:
        case DLKVStorageTypeMixed:{
            NSString *filename = [self _dbGetFilenameWithKey:key];
            if (filename){
                [self _fileDeleteWithName:filename];
            }
            return [self _dbDeleteItemWithKey:key];
        } break;
        default: return NO;
    }
}

-(BOOL)removeItemForKeys:(NSArray *)keys{
    if (keys.count == 0) return NO;
    switch (_type){
        case DLKVStorageTypeSQLite:{
            return [self _dbDeleteItemWithKeys:keys];
        } break;
        case DLKVStorageTypeFile:
        case DLKVStorageTypeMixed:{
            NSArray *filenames = [self _dbGetFilenameWithKeys:keys];
            for (NSString *filename in filenames){
                [self _fileDeleteWithName:filename];
            }
            return [self _dbDeleteItemWithKeys:keys];
        } break;
        default: return NO;
    }
}

-(BOOL)removeItemsLargerThanSize:(int)size{
    if (size == INT_MAX) return YES;
    if (size <= 0) return [self removeAllItems];
    
    switch (_type){
        case DLKVStorageTypeSQLite:{
            if ([self _dbDeleteItemsWithSizeLargerThan:size]){
                [self _dbCheckpoint];
                return YES;
            }
        } break;
        case DLKVStorageTypeFile:
        case DLKVStorageTypeMixed:{
            NSArray *filenames = [self _dbGetFilenamesWithSizeLargerThan:size];
            for (NSString *name in filenames){
                [self _fileDeleteWithName:name];
            }
            if ([self _dbDeleteItemsWithSizeLargerThan:size]){
                [self _dbCheckpoint];
                return YES;
            }
        } break;
    }
    return NO;
}

-(BOOL)removeItemsEarlierThanTime:(int)time{
    if (time <= 0) return YES;
    if (time == INT_MAX) return [self removeAllItems];
    
    switch (_type){
        case DLKVStorageTypeSQLite:{
            if ([self _dbDeleteItemsWithTimeEarlierThan:time]){
                [self _dbCheckpoint];
                return YES;
            }
        } break;
        case DLKVStorageTypeFile:
        case DLKVStorageTypeMixed:{
            NSArray *filenames = [self _dbGetFilenamesWithTimeEarlierThan:time];
            for (NSString *name in filenames){
                [self _fileDeleteWithName:name];
            }
            if ([self _dbDeleteItemsWithTimeEarlierThan:time]){
                [self _dbCheckpoint];
                return YES;
            }
        } break;
    }
    return NO;
}

-(BOOL)removeItemsToFitSize:(int)maxSize{
    if (maxSize == INT_MAX) return YES;
    if (maxSize <= 0) return [self removeAllItems];
    
    int total = [self _dbGetTotalItemSize];
    if (total < 0) return NO;
    if (total <= maxSize) return YES;
    
    NSArray *items = nil;
    BOOL suc = NO;
    do{
        int perCount = 16;
        items = [self _dbGetItemSizeInfoOrderByTimeAscWithLimit:perCount];
        for (DLKVStorageItem *item in items){
            if (total > maxSize){
                if (item.filename){
                    [self _fileDeleteWithName:item.filename];
                }
                suc = [self _dbDeleteItemWithKey:item.key];
                total -= item.size;
            } else{
                break;
            }
            if (!suc) break;
        }
    } while (total > maxSize && items.count > 0 && suc);
    if (suc) [self _dbCheckpoint];
    return suc;
}

-(BOOL)removeItemsToFitCount:(int)maxCount{
    if (maxCount == INT_MAX) return YES;
    if (maxCount <= 0) return [self removeAllItems];
    
    int total = [self _dbGetTotalItemCount];
    if (total < 0) return NO;
    if (total <= maxCount) return YES;
    
    NSArray *items = nil;
    BOOL suc = NO;
    do{
        int perCount = 16;
        items = [self _dbGetItemSizeInfoOrderByTimeAscWithLimit:perCount];
        for (DLKVStorageItem *item in items){
            if (total > maxCount){
                if (item.filename){
                    [self _fileDeleteWithName:item.filename];
                }
                suc = [self _dbDeleteItemWithKey:item.key];
                total--;
            } else{
                break;
            }
            if (!suc) break;
        }
    } while (total > maxCount && items.count > 0 && suc);
    if (suc) [self _dbCheckpoint];
    return suc;
}

-(BOOL)removeAllItems{
    if (![self _dbClose]) return NO;
    [self _reset];
    if (![self _dbOpen]) return NO;
    if (![self _dbInitialize]) return NO;
    return YES;
}

-(void)removeAllItemsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                               endBlock:(void(^)(BOOL error))end{
    
    int total = [self _dbGetTotalItemCount];
    if (total <= 0){
        if (end) end(total < 0);
    } else{
        int left = total;
        int perCount = 32;
        NSArray *items = nil;
        BOOL suc = NO;
        do{
            items = [self _dbGetItemSizeInfoOrderByTimeAscWithLimit:perCount];
            for (DLKVStorageItem *item in items){
                if (left > 0){
                    if (item.filename){
                        [self _fileDeleteWithName:item.filename];
                    }
                    suc = [self _dbDeleteItemWithKey:item.key];
                    left--;
                } else{
                    break;
                }
                if (!suc) break;
            }
            if (progress) progress(total -left, total);
        } while (left > 0 && items.count > 0 && suc);
        if (suc) [self _dbCheckpoint];
        if (end) end(!suc);
    }
}

-(DLKVStorageItem *)getItemForKey:(NSString *)key{
    if (key.length == 0) return nil;
    DLKVStorageItem *item = [self _dbGetItemWithKey:key excludeInlineData:NO];
    if (item){
        [self _dbUpdateAccessTimeWithKey:key];
        if (item.filename){
            item.value = [self _fileReadWithName:item.filename];
            if (!item.value){
                [self _dbDeleteItemWithKey:key];
                item = nil;
            }
        }
    }
    return item;
}

-(DLKVStorageItem *)getItemInfoForKey:(NSString *)key{
    if (key.length == 0) return nil;
    DLKVStorageItem *item = [self _dbGetItemWithKey:key excludeInlineData:YES];
    return item;
}

-(NSData *)getItemValueForKey:(NSString *)key{
    if (key.length == 0) return nil;
    NSData *value = nil;
    switch (_type){
        case DLKVStorageTypeFile:{
            NSString *filename = [self _dbGetFilenameWithKey:key];
            if (filename){
                value = [self _fileReadWithName:filename];
                if (!value){
                    [self _dbDeleteItemWithKey:key];
                    value = nil;
                }
            }
        } break;
        case DLKVStorageTypeSQLite:{
            value = [self _dbGetValueWithKey:key];
        } break;
        case DLKVStorageTypeMixed:{
            NSString *filename = [self _dbGetFilenameWithKey:key];
            if (filename){
                value = [self _fileReadWithName:filename];
                if (!value){
                    [self _dbDeleteItemWithKey:key];
                    value = nil;
                }
            } else{
                value = [self _dbGetValueWithKey:key];
            }
        } break;
    }
    if (value){
        [self _dbUpdateAccessTimeWithKey:key];
    }
    return value;
}

-(NSArray *)getItemForKeys:(NSArray *)keys{
    if (keys.count == 0) return nil;
    NSMutableArray *items = [self _dbGetItemWithKeys:keys excludeInlineData:NO];
    if (_type != DLKVStorageTypeSQLite){
        for (NSInteger i = 0, max = items.count; i < max; i++){
            DLKVStorageItem *item = items[i];
            if (item.filename){
                item.value = [self _fileReadWithName:item.filename];
                if (!item.value){
                    if (item.key) [self _dbDeleteItemWithKey:item.key];
                    [items removeObjectAtIndex:i];
                    i--;
                    max--;
                }
            }
        }
    }
    if (items.count > 0){
        [self _dbUpdateAccessTimeWithKeys:keys];
    }
    return items.count ? items : nil;
}

-(NSArray *)getItemInfoForKeys:(NSArray *)keys{
    if (keys.count == 0) return nil;
    return [self _dbGetItemWithKeys:keys excludeInlineData:YES];
}

-(NSDictionary *)getItemValueForKeys:(NSArray *)keys{
    NSMutableArray *items = (NSMutableArray *)[self getItemForKeys:keys];
    NSMutableDictionary *kv = [NSMutableDictionary new];
    for (DLKVStorageItem *item in items){
        if (item.key && item.value){
            [kv setObject:item.value forKey:item.key];
        }
    }
    return kv.count ? kv : nil;
}

-(BOOL)itemExistsForKey:(NSString *)key{
    if (key.length == 0) return NO;
    return [self _dbGetItemCountWithKey:key] > 0;
}

-(int)getItemsCount{
    return [self _dbGetTotalItemCount];
}

-(int)getItemsSize{
    return [self _dbGetTotalItemSize];
}

@end


@interface DLDiskCache : NSObject

@property (nullable, copy) NSString *name;

@property (readonly) NSString *path;

@property (readonly) NSUInteger inlineThreshold;

@property (nullable, copy) NSData *(^customArchiveBlock)(id object);

@property (nullable, copy) id (^customUnarchiveBlock)(NSData *data);

@property (nullable, copy) NSString *(^customFileNameBlock)(NSString *key);

@property NSUInteger countLimit;

@property NSUInteger costLimit;

@property NSTimeInterval ageLimit;

@property NSUInteger freeDiskSpaceLimit;

@property NSTimeInterval autoTrimInterval;

@property BOOL errorLogsEnabled;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

-(nullable instancetype)initWithPath:(NSString *)path;

-(nullable instancetype)initWithPath:(NSString *)path
                      inlineThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;

-(BOOL)containsObjectForKey:(NSString *)key;

-(void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

-(nullable id<NSCoding>)objectForKey:(NSString *)key;

-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

-(void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

-(void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

-(void)removeObjectForKey:(NSString *)key;

-(void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;

-(void)removeAllObjects;

-(void)removeAllObjectsWithBlock:(void(^)(void))block;

-(void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;

-(NSInteger)totalCount;

-(void)totalCountWithBlock:(void(^)(NSInteger totalCount))block;

-(NSInteger)totalCost;

-(void)totalCostWithBlock:(void(^)(NSInteger totalCost))block;

-(void)trimToCount:(NSUInteger)count;

-(void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block;

-(void)trimToCost:(NSUInteger)cost;

-(void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block;

-(void)trimToAge:(NSTimeInterval)age;

-(void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block;

+(nullable NSData *)getExtendedDataFromObject:(id)object;

+(void)setExtendedData:(nullable NSData *)extendedData toObject:(id)object;

@end

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

static const int extended_data_key;

/// Free disk space in bytes.
static int64_t _DLDiskSpaceFree(){
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}

static NSString *_DLNSStringMD5(NSString *string){
    if (!string) return nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

static NSMapTable *_globalInstances;
static dispatch_semaphore_t _globalInstancesLock;

static void _DLDiskCacheInitGlobal(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _globalInstancesLock = dispatch_semaphore_create(1);
        _globalInstances = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    });
}

static DLDiskCache *_DLDiskCacheGetGlobal(NSString *path){
    if (path.length == 0) return nil;
    _DLDiskCacheInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    id cache = [_globalInstances objectForKey:path];
    dispatch_semaphore_signal(_globalInstancesLock);
    return cache;
}

static void _DLDiskCacheSetGlobal(DLDiskCache *cache){
    if (cache.path.length == 0) return;
    _DLDiskCacheInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    [_globalInstances setObject:cache forKey:cache.path];
    dispatch_semaphore_signal(_globalInstancesLock);
}



@implementation DLDiskCache{
    DLKVStorage *_kv;
    dispatch_semaphore_t _lock;
    dispatch_queue_t _queue;
}

-(void)_trimRecursively{
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self _trimInBackground];
        [self _trimRecursively];
    });
}

-(void)_trimInBackground{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        Lock();
        [self _trimToCost:self.costLimit];
        [self _trimToCount:self.countLimit];
        [self _trimToAge:self.ageLimit];
        [self _trimToFreeDiskSpace:self.freeDiskSpaceLimit];
        Unlock();
    });
}

-(void)_trimToCost:(NSUInteger)costLimit{
    if (costLimit >= INT_MAX) return;
    [_kv removeItemsToFitSize:(int)costLimit];
    
}

-(void)_trimToCount:(NSUInteger)countLimit{
    if (countLimit >= INT_MAX) return;
    [_kv removeItemsToFitCount:(int)countLimit];
}

-(void)_trimToAge:(NSTimeInterval)ageLimit{
    if (ageLimit <= 0){
        [_kv removeAllItems];
        return;
    }
    long timestamp = time(NULL);
    if (timestamp <= ageLimit) return;
    long age = timestamp -ageLimit;
    if (age >= INT_MAX) return;
    [_kv removeItemsEarlierThanTime:(int)age];
}

-(void)_trimToFreeDiskSpace:(NSUInteger)targetFreeDiskSpace{
    if (targetFreeDiskSpace == 0) return;
    int64_t totalBytes = [_kv getItemsSize];
    if (totalBytes <= 0) return;
    int64_t diskFreeBytes = _DLDiskSpaceFree();
    if (diskFreeBytes < 0) return;
    int64_t needTrimBytes = targetFreeDiskSpace -diskFreeBytes;
    if (needTrimBytes <= 0) return;
    int64_t costLimit = totalBytes -needTrimBytes;
    if (costLimit < 0) costLimit = 0;
    [self _trimToCost:(int)costLimit];
}

-(NSString *)_filenameForKey:(NSString *)key{
    NSString *filename = nil;
    if (_customFileNameBlock) filename = _customFileNameBlock(key);
    if (!filename) filename = _DLNSStringMD5(key);
    return filename;
}

-(void)_appWillBeTerminated{
    Lock();
    _kv = nil;
    Unlock();
}

#pragma mark -public

//-(void)dealloc{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
//}

-(instancetype)init{
    @throw [NSException exceptionWithName:@"DLDiskCache init error" reason:@"DLDiskCache must be initialized with a path. Use 'initWithPath:' or 'initWithPath:inlineThreshold:' instead." userInfo:nil];
    return [self initWithPath:@"" inlineThreshold:0];
}

-(instancetype)initWithPath:(NSString *)path{
    return [self initWithPath:path inlineThreshold:1024 * 20]; // 20KB
}

-(instancetype)initWithPath:(NSString *)path
             inlineThreshold:(NSUInteger)threshold{
    self = [super init];
    if (!self) return nil;
    
    DLDiskCache *globalCache = _DLDiskCacheGetGlobal(path);
    if (globalCache) return globalCache;
    
    DLKVStorageType type;
    if (threshold == 0){
        type = DLKVStorageTypeFile;
    } else if (threshold == NSUIntegerMax){
        type = DLKVStorageTypeSQLite;
    } else{
        type = DLKVStorageTypeMixed;
    }
    
    DLKVStorage *kv = [[DLKVStorage alloc] initWithPath:path type:type];
    if (!kv) return nil;
    
    _kv = kv;
    _path = path;
    _lock = dispatch_semaphore_create(1);
    _queue = dispatch_queue_create("com.dl.cache.disk", DISPATCH_QUEUE_CONCURRENT);
    _inlineThreshold = threshold;
    _countLimit = NSUIntegerMax;
    _costLimit = NSUIntegerMax;
    _ageLimit = DBL_MAX;
    _freeDiskSpaceLimit = 0;
    _autoTrimInterval = 60;
    
//    [self _trimRecursively];
    _DLDiskCacheSetGlobal(self);
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillBeTerminated) name:UIApplicationWillTerminateNotification object:nil];
    return self;
}

-(BOOL)containsObjectForKey:(NSString *)key{
    if (!key) return NO;
    Lock();
    BOOL contains = [_kv itemExistsForKey:key];
    Unlock();
    return contains;
}

-(void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block{
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        BOOL contains = [self containsObjectForKey:key];
        block(key, contains);
    });
}

-(id<NSCoding>)objectForKey:(NSString *)key{
    if (!key) return nil;
    Lock();
    DLKVStorageItem *item = [_kv getItemForKey:key];
    Unlock();
    if (!item.value) return nil;
    
    id object = nil;
    if (_customUnarchiveBlock){
        object = _customUnarchiveBlock(item.value);
    } else{
        @try{
            object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        }
        @catch (NSException *exception){
            // nothing to do...
        }
    }
    if (object && item.extendedData){
        [DLDiskCache setExtendedData:item.extendedData toObject:object];
    }
    return object;
}

-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> object))block{
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        id<NSCoding> object = [self objectForKey:key];
        block(key, object);
    });
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    if (!key) return;
    if (!object){
        [self removeObjectForKey:key];
        return;
    }
    
    NSData *extendedData = [DLDiskCache getExtendedDataFromObject:object];
    NSData *value = nil;
    if (_customArchiveBlock){
        value = _customArchiveBlock(object);
    } else{
        @try{
            value = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
        @catch (NSException *exception){
            // nothing to do...
        }
    }
    if (!value) return;
    NSString *filename = nil;
    if (_kv.type != DLKVStorageTypeSQLite){
        if (value.length > _inlineThreshold){
            filename = [self _filenameForKey:key];
        }
    }
    
    Lock();
    [_kv saveItemWithKey:key value:value filename:filename extendedData:extendedData];
    Unlock();
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self setObject:object forKey:key];
        if (block) block();
    });
}

-(void)removeObjectForKey:(NSString *)key{
    if (!key) return;
    Lock();
    [_kv removeItemForKey:key];
    Unlock();
}

-(void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self removeObjectForKey:key];
        if (block) block(key);
    });
}

-(void)removeAllObjects{
    Lock();
    [_kv removeAllItems];
    Unlock();
}

-(void)removeAllObjectsWithBlock:(void(^)(void))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self removeAllObjects];
        if (block) block();
    });
}

-(void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                                 endBlock:(void(^)(BOOL error))end{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        if (!self){
            if (end) end(YES);
            return;
        }
        Lock();
        [_kv removeAllItemsWithProgressBlock:progress endBlock:end];
        Unlock();
    });
}

-(NSInteger)totalCount{
    Lock();
    int count = [_kv getItemsCount];
    Unlock();
    return count;
}

-(void)totalCountWithBlock:(void(^)(NSInteger totalCount))block{
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        NSInteger totalCount = [self totalCount];
        block(totalCount);
    });
}

-(NSInteger)totalCost{
    Lock();
    int count = [_kv getItemsSize];
    Unlock();
    return count;
}

-(void)totalCostWithBlock:(void(^)(NSInteger totalCost))block{
    if (!block) return;
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        NSInteger totalCost = [self totalCost];
        block(totalCost);
    });
}

-(void)trimToCount:(NSUInteger)count{
    Lock();
    [self _trimToCount:count];
    Unlock();
}

-(void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCount:count];
        if (block) block();
    });
}

-(void)trimToCost:(NSUInteger)cost{
    Lock();
    [self _trimToCost:cost];
    Unlock();
}

-(void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCost:cost];
        if (block) block();
    });
}

-(void)trimToAge:(NSTimeInterval)age{
    Lock();
    [self _trimToAge:age];
    Unlock();
}

-(void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block{
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToAge:age];
        if (block) block();
    });
}

+(NSData *)getExtendedDataFromObject:(id)object{
    if (!object) return nil;
    return (NSData *)objc_getAssociatedObject(object, &extended_data_key);
}

+(void)setExtendedData:(NSData *)extendedData toObject:(id)object{
    if (!object) return;
    objc_setAssociatedObject(object, &extended_data_key, extendedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString *)description{
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@:%@)", self.class, self, _name, _path];
    else return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _path];
}

-(BOOL)errorLogsEnabled{
    Lock();
    BOOL enabled = _kv.errorLogsEnabled;
    Unlock();
    return enabled;
}

-(void)setErrorLogsEnabled:(BOOL)errorLogsEnabled{
    Lock();
    _kv.errorLogsEnabled = errorLogsEnabled;
    Unlock();
}

@end

@interface DLMemoryCache : NSObject

@property (nullable, copy) NSString *name;

@property (readonly) NSUInteger totalCount;

@property (readonly) NSUInteger totalCost;

@property NSUInteger countLimit;

@property NSUInteger costLimit;

@property NSTimeInterval ageLimit;

@property NSTimeInterval autoTrimInterval;

@property BOOL shouldRemoveAllObjectsOnMemoryWarning;

@property BOOL shouldRemoveAllObjectsWhenEnteringBackground;

@property (nullable, copy) void(^didReceiveMemoryWarningBlock)(DLMemoryCache *cache);

@property (nullable, copy) void(^didEnterBackgroundBlock)(DLMemoryCache *cache);

@property BOOL releaseOnMainThread;

@property BOOL releaseAsynchronously;

-(BOOL)containsObjectForKey:(id)key;

-(nullable id)objectForKey:(id)key;

-(void)setObject:(nullable id)object forKey:(id)key;

-(void)setObject:(nullable id)object forKey:(id)key withCost:(NSUInteger)cost;

-(void)removeObjectForKey:(id)key;

-(void)removeAllObjects;

-(void)trimToCount:(NSUInteger)count;

-(void)trimToCost:(NSUInteger)cost;

-(void)trimToAge:(NSTimeInterval)age;

@end

@interface _DLLinkedMapNode : NSObject{
    @package
    __unsafe_unretained _DLLinkedMapNode *_prev; // retained by dic
    __unsafe_unretained _DLLinkedMapNode *_next; // retained by dic
    id _key;
    id _value;
    NSUInteger _cost;
    NSTimeInterval _time;
}
@end

@implementation _DLLinkedMapNode
@end


/**
 A linked map used by DLMemoryCache.
 It's not thread-safe and does not validate the parameters.
 
 Typically, you should not use this class directly.
 */
@interface _DLLinkedMap : NSObject{
    @package
    CFMutableDictionaryRef _dic; // do not set object directly
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    _DLLinkedMapNode *_head; // MRU, do not change it directly
    _DLLinkedMapNode *_tail; // LRU, do not change it directly
    BOOL _releaseOnMainThread;
    BOOL _releaseAsynchronously;
}

/// Insert a node at head and update the total cost.
/// Node and node.key should not be nil.
-(void)insertNodeAtHead:(_DLLinkedMapNode *)node;

/// Bring a inner node to header.
/// Node should already inside the dic.
-(void)bringNodeToHead:(_DLLinkedMapNode *)node;

/// Remove a inner node and update the total cost.
/// Node should already inside the dic.
-(void)removeNode:(_DLLinkedMapNode *)node;

/// Remove tail node if exist.
-(_DLLinkedMapNode *)removeTailNode;

/// Remove all node in background queue.
-(void)removeAll;

@end

@implementation _DLLinkedMap

-(instancetype)init{
    self = [super init];
    _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    _releaseOnMainThread = NO;
    _releaseAsynchronously = YES;
    return self;
}

-(void)dealloc{
    CFRelease(_dic);
}

-(void)insertNodeAtHead:(_DLLinkedMapNode *)node{
    CFDictionarySetValue(_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    _totalCost += node->_cost;
    _totalCount++;
    if (_head){
        node->_next = _head;
        _head->_prev = node;
        _head = node;
    } else{
        _head = _tail = node;
    }
}

-(void)bringNodeToHead:(_DLLinkedMapNode *)node{
    if (_head == node) return;
    
    if (_tail == node){
        _tail = node->_prev;
        _tail->_next = nil;
    } else{
        node->_next->_prev = node->_prev;
        node->_prev->_next = node->_next;
    }
    node->_next = _head;
    node->_prev = nil;
    _head->_prev = node;
    _head = node;
}

-(void)removeNode:(_DLLinkedMapNode *)node{
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node->_key));
    _totalCost -= node->_cost;
    _totalCount--;
    if (node->_next) node->_next->_prev = node->_prev;
    if (node->_prev) node->_prev->_next = node->_next;
    if (_head == node) _head = node->_next;
    if (_tail == node) _tail = node->_prev;
}

-(_DLLinkedMapNode *)removeTailNode{
    if (!_tail) return nil;
    _DLLinkedMapNode *tail = _tail;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_tail->_key));
    _totalCost -= _tail->_cost;
    _totalCount--;
    if (_head == _tail){
        _head = _tail = nil;
    } else{
        _tail = _tail->_prev;
        _tail->_next = nil;
    }
    return tail;
}

-(void)removeAll{
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    if (CFDictionaryGetCount(_dic) > 0){
        CFMutableDictionaryRef holder = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        if (_releaseAsynchronously){
            dispatch_queue_t queue = _releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                CFRelease(holder); // hold and release in specified queue
            });
        } else if (_releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder); // hold and release in specified queue
            });
        } else{
            CFRelease(holder);
        }
    }
}

@end



@implementation DLMemoryCache{
    pthread_mutex_t _lock;
    _DLLinkedMap *_lru;
    dispatch_queue_t _queue;
}

-(void)_trimRecursively{
    __weak typeof(self) _self = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(_self) self = _self;
        if (!self) return;
        [self _trimInBackground];
        [self _trimRecursively];
    });
}

-(void)_trimInBackground{
    dispatch_async(_queue, ^{
        [self _trimToCost:self->_costLimit];
        [self _trimToCount:self->_countLimit];
        [self _trimToAge:self->_ageLimit];
    });
}

-(void)_trimToCost:(NSUInteger)costLimit{
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if (costLimit == 0){
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCost <= costLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish){
        if (pthread_mutex_trylock(&_lock) == 0){
            if (_lru->_totalCost > costLimit){
                _DLLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else{
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count){
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

-(void)_trimToCount:(NSUInteger)countLimit{
    BOOL finish = NO;
    pthread_mutex_lock(&_lock);
    if (countLimit == 0){
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCount <= countLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish){
        if (pthread_mutex_trylock(&_lock) == 0){
            if (_lru->_totalCount > countLimit){
                _DLLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else{
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count){
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

-(void)_trimToAge:(NSTimeInterval)ageLimit{
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    pthread_mutex_lock(&_lock);
    if (ageLimit <= 0){
        [_lru removeAll];
        finish = YES;
    } else if (!_lru->_tail || (now -_lru->_tail->_time) <= ageLimit){
        finish = YES;
    }
    pthread_mutex_unlock(&_lock);
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray new];
    while (!finish){
        if (pthread_mutex_trylock(&_lock) == 0){
            if (_lru->_tail && (now -_lru->_tail->_time) > ageLimit){
                _DLLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else{
                finish = YES;
            }
            pthread_mutex_unlock(&_lock);
        } else{
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count){
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

-(void)_appDidReceiveMemoryWarningNotification{
    if (self.didReceiveMemoryWarningBlock){
        self.didReceiveMemoryWarningBlock(self);
    }
    if (self.shouldRemoveAllObjectsOnMemoryWarning){
        [self removeAllObjects];
    }
}

-(void)_appDidEnterBackgroundNotification{
    if (self.didEnterBackgroundBlock){
        self.didEnterBackgroundBlock(self);
    }
    if (self.shouldRemoveAllObjectsWhenEnteringBackground){
        [self removeAllObjects];
    }
}

#pragma mark -public

-(instancetype)init{
    self = super.init;
    pthread_mutex_init(&_lock, NULL);
    _lru = [_DLLinkedMap new];
    _queue = dispatch_queue_create("com.dl.cache.memory", DISPATCH_QUEUE_SERIAL);
    
    _countLimit = NSUIntegerMax;
    _costLimit = NSUIntegerMax;
    _ageLimit = DBL_MAX;
    _autoTrimInterval = 5.0;
    _shouldRemoveAllObjectsOnMemoryWarning = YES;
    _shouldRemoveAllObjectsWhenEnteringBackground = YES;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
//    [self _trimRecursively];
    return self;
}

-(void)dealloc{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [_lru removeAll];
    pthread_mutex_destroy(&_lock);
}

-(NSUInteger)totalCount{
    pthread_mutex_lock(&_lock);
    NSUInteger count = _lru->_totalCount;
    pthread_mutex_unlock(&_lock);
    return count;
}

-(NSUInteger)totalCost{
    pthread_mutex_lock(&_lock);
    NSUInteger totalCost = _lru->_totalCost;
    pthread_mutex_unlock(&_lock);
    return totalCost;
}

-(BOOL)releaseOnMainThread{
    pthread_mutex_lock(&_lock);
    BOOL releaseOnMainThread = _lru->_releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
    return releaseOnMainThread;
}

-(void)setReleaseOnMainThread:(BOOL)releaseOnMainThread{
    pthread_mutex_lock(&_lock);
    _lru->_releaseOnMainThread = releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
}

-(BOOL)releaseAsynchronously{
    pthread_mutex_lock(&_lock);
    BOOL releaseAsynchronously = _lru->_releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
    return releaseAsynchronously;
}

-(void)setReleaseAsynchronously:(BOOL)releaseAsynchronously{
    pthread_mutex_lock(&_lock);
    _lru->_releaseAsynchronously = releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
}

-(BOOL)containsObjectForKey:(id)key{
    if (!key) return NO;
    pthread_mutex_lock(&_lock);
    BOOL contains = CFDictionaryContainsKey(_lru->_dic, (__bridge const void *)(key));
    pthread_mutex_unlock(&_lock);
    return contains;
}

-(id)objectForKey:(id)key{
    if (!key) return nil;
    pthread_mutex_lock(&_lock);
    _DLLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node){
        node->_time = CACurrentMediaTime();
        [_lru bringNodeToHead:node];
    }
    pthread_mutex_unlock(&_lock);
    return node ? node->_value : nil;
}

-(void)setObject:(id)object forKey:(id)key{
    [self setObject:object forKey:key withCost:0];
}

-(void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost{
    if (!key) return;
    if (!object){
        [self removeObjectForKey:key];
        return;
    }
    pthread_mutex_lock(&_lock);
    _DLLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    NSTimeInterval now = CACurrentMediaTime();
    if (node){
        _lru->_totalCost -= node->_cost;
        _lru->_totalCost += cost;
        node->_cost = cost;
        node->_time = now;
        node->_value = object;
        [_lru bringNodeToHead:node];
    } else{
        node = [_DLLinkedMapNode new];
        node->_cost = cost;
        node->_time = now;
        node->_key = key;
        node->_value = object;
        [_lru insertNodeAtHead:node];
    }
    if (_lru->_totalCost > _costLimit){
        dispatch_async(_queue, ^{
            [self trimToCost:_costLimit];
        });
    }
    if (_lru->_totalCount > _countLimit){
        _DLLinkedMapNode *node = [_lru removeTailNode];
        if (_lru->_releaseAsynchronously){
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                [node class]; //hold and release in queue
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class]; //hold and release in queue
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}

-(void)removeObjectForKey:(id)key{
    if (!key) return;
    pthread_mutex_lock(&_lock);
    _DLLinkedMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node){
        [_lru removeNode:node];
        if (_lru->_releaseAsynchronously){
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : DLMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                [node class]; //hold and release in queue
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class]; //hold and release in queue
            });
        }
    }
    pthread_mutex_unlock(&_lock);
}

-(void)removeAllObjects{
    pthread_mutex_lock(&_lock);
    [_lru removeAll];
    pthread_mutex_unlock(&_lock);
}

-(void)trimToCount:(NSUInteger)count{
    if (count == 0){
        [self removeAllObjects];
        return;
    }
    [self _trimToCount:count];
}

-(void)trimToCost:(NSUInteger)cost{
    [self _trimToCost:cost];
}

-(void)trimToAge:(NSTimeInterval)age{
    [self _trimToAge:age];
}

-(NSString *)description{
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

@end

@interface DLCache()

@property (strong, readonly) DLMemoryCache *memoryCache;

@property (strong, readonly) DLDiskCache *diskCache;

@end

@implementation DLCache

-(instancetype) init{
    NSLog(@"Use \"initWithName\" or \"initWithPath\" to create YYCache instance.");
    return [self initWithPath:@""];
}

-(instancetype)initWithName:(NSString *)name{
    if (name.length == 0) return nil;
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

-(instancetype)initWithPath:(NSString *)path{
    if (path.length == 0) return nil;
    DLDiskCache *diskCache = [[DLDiskCache alloc] initWithPath:path];
    if (!diskCache) return nil;
    NSString *name = [path lastPathComponent];
    DLMemoryCache *memoryCache = [[DLMemoryCache alloc]init];
    memoryCache.name = name;
    self = [super init];
    _name = name;
    _diskCache = diskCache;
    _memoryCache = memoryCache;
    return self;
}

+(instancetype)cacheWithName:(NSString *)name{
    return [[self alloc] initWithName:name];
}

+(instancetype)cacheWithPath:(NSString *)path{
    return [[self alloc] initWithPath:path];
}

-(BOOL)containsObjectForKey:(NSString *)key{
    return [_memoryCache containsObjectForKey:key] || [_diskCache containsObjectForKey:key];
}

-(void)containsObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key, BOOL contains))block{
    if (!block) return;
    
    if ([_memoryCache containsObjectForKey:key]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, YES);
        });
    } else{
        [_diskCache containsObjectForKey:key withBlock:block];
    }
}

-(id<NSCoding>)objectForKey:(NSString *)key{
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (!object){
        object = [_diskCache objectForKey:key];
        if (object){
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}

-(void)objectForKey:(NSString *)key withBlock:(void (^)(NSString *key, id<NSCoding> object))block{
    if (!block) return;
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, object);
        });
    } else{
        [_diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding> object){
            if (object && ![_memoryCache objectForKey:key]){
                [_memoryCache setObject:object forKey:key];
            }
            block(key, object);
        }];
    }
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void (^)(void))block{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key withBlock:block];
}

-(void)removeObjectForKey:(NSString *)key{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

-(void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key))block{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key withBlock:block];
}

-(void)removeAllObjects{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

-(void)removeAllObjectsWithBlock:(void(^)(void))block{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithBlock:block];
}

-(void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                                 endBlock:(void(^)(BOOL error))end{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithProgressBlock:progress endBlock:end];
    
}

-(NSString *)description{
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}



static DLDiskCache *diskCache = nil;
+(DLDiskCache *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        diskCache = [[DLDiskCache alloc]initWithPath:[NSString stringWithFormat:@"%@/imageCache", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject]]];
    });
    return diskCache;
}


+(void)saveImageCache:(UIImage *)image key:(NSString *)key{
    DLDiskCache *cache = [DLCache shareInstance];
    [cache setObject:image forKey:key withBlock:nil];
}

+(UIImage *)getCacheImage:(NSString *)key{
    DLDiskCache *cache = [DLCache shareInstance];
    return (UIImage *)[cache objectForKey:key];
}

@end
