#import "DLCache.h"
#import "DLToolMacro.h"
#import <sqlite3.h>

typedef NS_ENUM(NSInteger, DLCacheType) {
    DLCacheSQLType              =   1,
    DLCacheDiskType              =   2,
};

@interface DLCacheMapNode : NSObject{
    @package
    DLCacheMapNode *_prev;
    DLCacheMapNode *_next;
    NSString *_key;
    id _value;
    Class _class;
    DLCacheType *_type;
}

@end

@implementation DLCacheMapNode

-(instancetype)init{
    if ([super init]) {
        self->_prev = NULL;
        self->_next = NULL;
    }
    return self;
}

@end

@interface DLCacheMap : NSObject{
    @package
    DLCacheMapNode *_head;
    DLCacheMapNode *_tail;
    CFMutableDictionaryRef _dic;
    NSString *_cacheFile;
}

@end

void removeTailNode(DLCacheMap *map){
    if (!map->_tail) {
        return;
    }
    DLCacheMapNode *node = (__bridge DLCacheMapNode *)((__bridge struct DLCacheMapNode *)(map->_tail));
    CFDictionaryRemoveValue(map->_dic, (__bridge const void *)(node->_key));
//    map->_totalCount--;
    if (map->_head == node) {
        map->_head = map->_tail = NULL;
    }else{
        map->_tail = map->_tail->_prev;
        map->_tail->_next = NULL;
    }
}

void removeAllNode(DLCacheMap *map){
//    map->_totalCount = 0;
    map->_head = NULL;
    map->_tail = NULL;
    if (CFDictionaryGetCount(map->_dic) > 0) {
        CFMutableDictionaryRef holder = map->_dic;
        map->_dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFRelease(holder);
    }
}

void insertNodeAtHead (DLCacheMap *map, DLCacheMapNode *node){
    CFDictionarySetValue(map->_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
//    map->_totalCount++;
    if (map->_head) {
        node->_next = map->_head;
        map->_head->_prev = node;
        map->_head = node;
    }else{
        map->_head = map->_tail = node;
    }
//    if (map->_totalCount > DLMemoryCacheNumber) {
//        removeTailNode(map);
//        [NSThread sleepForTimeInterval:0.00001];
//    }
}

void bringNodeToHead(DLCacheMap *map, DLCacheMapNode *node) {
    if (map->_head == node) {
        return;
    }
    if (map->_tail ==node) {
        map->_tail = node->_prev;
        map->_tail->_next = NULL;
    }
    node->_prev = NULL;
    node->_next = map->_head;
    map->_head->_prev = node;
    map->_head = node;
}

void removeNode(DLCacheMap *map, DLCacheMapNode *node){
    CFDictionaryRemoveValue(map->_dic, (__bridge const void *)(node->_key));
//    map->_totalCount --;
    if (node->_next) {
        node->_next->_prev = node->_prev;
    }
    if (node->_prev) {
        node->_prev->_next = node->_next;
    }
    if (map->_head == node) {
        map->_head = node->_next;
    }
    if (map->_tail == node) {
        map->_tail = node->_prev;
    }
}

void SaveNode(DLCacheMap *map, NSObject *obj, NSString *key, Class class) {
    DLCacheMapNode *node = [[DLCacheMapNode alloc]init];
    node->_value = obj;
    node->_key = key;
    node->_class = class;
    insertNodeAtHead(map, node);
}

@implementation DLCacheMap

-(instancetype)init{
    if ([super init]) {
        self->_head = NULL;
        self->_tail = NULL;
        self->_dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//        self->_totalCount = 0;
    }
    return self;
}

@end

@interface DLCache ()

@end

@implementation DLCache{
    DLCacheMap *_diskCacheMap;
    NSCache *_memoryCache;
    dispatch_queue_t _queue;
    dispatch_semaphore_t _dl_memory_cache_semaphore;
    sqlite3 *db;
}

static DLCache *dlMemoryCache = nil;

+(DLCache *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dlMemoryCache = [[DLCache alloc]initWithFileName:@"DLCache"];
    });
    return dlMemoryCache;
}

-(NSString *)fileName{
    return self->_diskCacheMap->_cacheFile;
}

-(instancetype)initWithFileName:(NSString *)fileName{
    if ([super init]) {
        self->_memoryCache = [[NSCache alloc]init];
        self->_memoryCache.countLimit = DLMemoryCacheNumber;
        self->_diskCacheMap = [[DLCacheMap alloc]init];
        NSString *fileDirectory = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject], fileName];
        BOOL isDic;
        if(![[NSFileManager defaultManager] fileExistsAtPath:fileDirectory isDirectory:&isDic]||(!isDic)){
            [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self->_diskCacheMap->_cacheFile = fileDirectory;
        self->_queue = dispatch_get_global_queue(0, 0);
        self->_dl_memory_cache_semaphore = dispatch_semaphore_create(1);
        sqlite3_open([[fileDirectory stringByAppendingPathComponent:@"cache.sqlite"] UTF8String], &db);
        sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS dl_cache (cache_key varchar PRIMARY KEY, cache_class varchar, cache_obj blob, cache_filename varchar, cache_time integer, cache_type integer); " UTF8String], NULL, NULL, nil);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldCache) name:UIApplicationWillTerminateNotification object:nil];
//        [self selectAllCacheNode];
    }
    return self;
}

-(void)deleteOldCache{
//    removeAllNode(self->_memoryCacheMap);
}
-(void)setMemoryCache:(id)obj withKey:(NSString *)key{
    if (!key || !obj) {
        return;
    }
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self->_queue, ^{
//    SaveNode(self->_memoryCacheMap,(NSObject *)obj, key, [obj class]);
    dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
    });
}

-(void)setCache:(id)obj withKey:(NSString *)key{
    if (!key || !obj) {
        return;
    }
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_sync(self->_queue, ^{
        if ([obj conformsToProtocol:@protocol(NSCoding)]) {
            NSData *data;
            if (@available(iOS 11.0, *)) {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:NULL];
            } else {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj];
            }
            DLCacheMapNode *node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
            if (data.length / 1024 > 12) {
                //  保存的东西不存到内存当中，在map中查找
                NSString *dataHash = [NSString stringWithFormat:@"%@%lu", key,(unsigned long)data.hash];
                NSString *fileName = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
                //  map中存在并且值和已经保存的值一样，不做保存处理，只更新数据库信息和lru
                if (node && [node->_value isEqualToString:dataHash]) {
                    bringNodeToHead(self->_diskCacheMap, node);
                    //  已存在，更新信息
                    sqlite3_exec(db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_time = %ld WHERE cache_key = %@;", (long)[[NSDate date] timeIntervalSince1970], key] UTF8String], NULL, NULL, nil);
                }else{
                    BOOL writeToFileSuccess = [data writeToFile:fileName atomically:NO];
                    if (writeToFileSuccess) {
                        SaveNode(self->_diskCacheMap, dataHash, key, [obj class]);
                        if (node) {
                            //  已存在，但是需要更新
                            sqlite3_exec(db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class = '%@', cache_filename = '%@', cache_time = %ld, cache_type = '1' WHERE cache_key = %@;", dataHash, NSStringFromClass([obj class]), fileName, (long)[[NSDate date] timeIntervalSince1970], key] UTF8String], NULL, NULL, nil);
                        }else{
                            //  不存在，需要保存
                            sqlite3_exec(db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_class, cache_obj, cache_filename, cache_time, cache_type) VALUES('%@', '%@', '%@', '%@', %ld, '1');", key, NSStringFromClass([obj class]), dataHash, fileName, (long)[[NSDate date] timeIntervalSince1970]] UTF8String], NULL, NULL, nil);
                        }
                    }else{
                        NSLog(@"%@保存失败", key);
                    }
                }
            }else{
                //  数据库存储
                if (node) {
                    //  已存在，但是需要更新
                    sqlite3_exec(db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class = '%@', cache_filename = '%@', cache_time = %ld, cache_type = '0' WHERE cache_key = %@;", data, NSStringFromClass([obj class]), @"", (long)[[NSDate date] timeIntervalSince1970], key] UTF8String], NULL, NULL, nil);
                }else{
                    //  不存在，需要保存
                    sqlite3_exec(db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_class, cache_obj, cache_filename, cache_time, cache_type) VALUES('%@', '%@', '%@', '%@', %ld, '0');", key, NSStringFromClass([obj class]), data, @"", (long)[[NSDate date] timeIntervalSince1970]] UTF8String], NULL, NULL, nil);
                }
            }
            dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
        }else{
            dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
            NSLog(@"%@没有遵循NSCoding协议", key);
        }
    });
}

-(void)setDiskCache:(id)obj withKey:(NSString *)key{
    if (!key || !obj) {
        return;
    }
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self->_queue, ^{
        NSData *data;
        @try {
            if (@available(iOS 11.0, *)) {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:NULL];
            } else {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj];
            }
        } @catch (NSException *exception) {
            NSLog(@"hhhhhhhh");
        } @finally {
            
        }
        
        DLCacheMapNode *node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
        NSString *dataHash = [NSString stringWithFormat:@"%@%lu", key,(unsigned long)data.hash];
        if (node && [node->_value isEqualToString:dataHash]) {
            bringNodeToHead(self->_diskCacheMap, node);
        }else{
            NSString *fileName = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
            BOOL writeToFileSuccess = [data writeToFile:fileName atomically:NO];
            if (writeToFileSuccess) {
                SaveNode(self->_diskCacheMap, dataHash, key, [obj class]);
                if (node) {
                    //  已存在，但是需要更新
                    sqlite3_exec(db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class='%@', cache_time=%ld WHERE cache_key = '%@'", dataHash, NSStringFromClass([obj class]), (long)[[NSDate date] timeIntervalSince1970], key] UTF8String], NULL, NULL, nil);
                }else{
                    //  不存在，需要保存
                    sqlite3_exec(db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_obj, cache_class, cache_time) VALUES('%@', '%@', '%@', %ld);", key, dataHash, NSStringFromClass([obj class]), (long)[[NSDate date] timeIntervalSince1970]] UTF8String], NULL, NULL, nil);
                }
            }else{
                NSLog(@"%@保存失败", key);
            }
        }
        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
    });
}

//-(instancetype)cacheForKey:(NSString *)key{
//    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
//    DLCacheMapNode *node = CFDictionaryGetValue(self->_memoryCacheMap->_dic, (__bridge const void *)(key));
//    id obj;
//    if (node) {
//        bringNodeToHead(self->_memoryCacheMap,node);
//        obj = node->_value;
//    }else{
//        node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
//        if (node) {
//            bringNodeToHead(self->_diskCacheMap,node);
//            if (@available(iOS 11.0, *)) {
//                obj = [NSKeyedUnarchiver unarchivedObjectOfClass:node->_class fromData:node->_value error:NULL];
//            } else {
//                obj = [NSKeyedUnarchiver unarchiveObjectWithData:node->_value];
//            }
//        }
//    }
//    dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
//    return obj ? obj : nil;
//}

-(void)selectAllCacheNode{
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(db, [@"SELECT * FROM dl_cache;" UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
        NSFileManager *fileManage = [NSFileManager defaultManager];
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            NSString *key =  [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)];
            NSTimeInterval oldTime = (NSTimeInterval)sqlite3_column_int(stmt, 3);
            if (nowTime - oldTime > DLDiskCacheSaveTime) {
                //  超时了，删除文件
                sqlite3_exec(db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", key] UTF8String], NULL, NULL, nil);
                [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key] error:nil];
            }else{
                //  没有超时，将数据保存到缓存map中
                SaveNode(self->_diskCacheMap, [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)], key, NSClassFromString([NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 2)]));
            }
        }
    }
}

-(void)removeCacheForKey:(NSString *)key{
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
//    dispatch_async(self->_queue, ^{
//        DLCacheMapNode *node = CFDictionaryGetValue(self->_memoryCacheMap->_dic, (__bridge const void *)(key));
//        if (node) {
//            removeNode(self->_memoryCacheMap,node);
//        }else{
//            node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
//            if (node) {
//                removeNode(self->_diskCacheMap,node);
//                sqlite3_exec(db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", key] UTF8String], NULL, NULL, nil);
//            }
//        }
//        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
//    });
}

-(void)removeAllCache{
//    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
//    dispatch_async(self->_queue, ^{
//        removeAllNode(self->_memoryCacheMap);
//        removeAllNode(self->_diskCacheMap);
//        sqlite3_exec(db, [@"DELETE FROM dl_cache;" UTF8String], NULL, NULL, nil);
//        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
//    });
}

-(void)printfAllCache{
//    NSDictionary *tempDic = (__bridge NSDictionary *)self->_memoryCacheMap->_dic;
//    NSArray *array = [tempDic allValues];
//    for (DLCacheMapNode *node in array) {
//        NSLog(@"class  ==  %@", [node->_value class]);
//    }
}

@end
