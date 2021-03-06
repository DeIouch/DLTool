#import "DLCache.h"
#import <sqlite3.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonCrypto.h>

//typedef NS_ENUM(NSUInteger, DLCacheType) {
////    DLCacheMemoryType        =   0,
//    DLCacheSQLType              =   1,
//    DLCacheDiskType              =   2,
//};

@interface DLCacheMapNode : NSObject{
    @package
    __unsafe_unretained DLCacheMapNode *_prev;
    __unsafe_unretained DLCacheMapNode *_next;
    NSString *_key;
    id _value;
    Class _class;
//    DLCacheType _type;
    NSString *_valueHash;
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
    NSUInteger _totalCount;
    sqlite3 *db;
    dispatch_queue_t _queue;
    dispatch_semaphore_t _dl_memory_cache_semaphore;
}

@end

void removeTailNode(DLCacheMap *map){
    if (!map->_tail) {
        return;
    }
    DLCacheMapNode *node = (__bridge DLCacheMapNode *)((__bridge struct DLCacheMapNode *)(map->_tail));
    CFDictionaryRemoveValue(map->_dic, (__bridge const void *)(node->_key));
    map->_totalCount--;
    if (map->_head == node) {
        map->_head = map->_tail = NULL;
    }else{
        map->_tail = map->_tail->_prev;
        map->_tail->_next = NULL;
    }
}

void removeAllNode(DLCacheMap *map){
    map->_totalCount = 0;
    map->_head = NULL;
    map->_tail = NULL;
    if (CFDictionaryGetCount(map->_dic) > 0) {
        CFMutableDictionaryRef holder = map->_dic;
        map->_dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFRelease(holder);
    }
}

void removeNode(DLCacheMap *map, DLCacheMapNode *node){
    CFDictionaryRemoveValue(map->_dic, (__bridge const void *)(node->_key));
    map->_totalCount --;
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

void insertNodeAtHead (DLCacheMap *map, DLCacheMapNode *node){
    CFDictionarySetValue(map->_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    map->_totalCount++;
    if (map->_head) {
        node->_next = map->_head;
        map->_head->_prev = node;
        map->_head = node;
    }else{
        map->_head = map->_tail = node;
    }
    if (map->_totalCount > DLDiskCacheNumber) {
        DLCacheMapNode *tailNode = map->_tail;
        removeTailNode(map);
        dispatch_async(map->_queue, ^{
            sqlite3_exec(map->db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", tailNode->_key] UTF8String], NULL, NULL, nil);
        });
        NSFileManager *fileManage = [NSFileManager defaultManager];
        [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@", tailNode->_value] error:nil];
    }
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

void SaveNode(DLCacheMap *map, NSObject *obj, NSString *key, Class class) {
    DLCacheMapNode *node = [[DLCacheMapNode alloc]init];
    node->_value = obj;
    node->_key = key;
    node->_class = class;
    insertNodeAtHead(map, node);
}

void SetNode(DLCacheMapNode *node, NSString *key, id value, Class class, NSString *valueHash){
    node->_key = key;
    node->_value = value;
    node->_class = class;
    node->_valueHash = valueHash;
}

@implementation DLCacheMap

-(instancetype)initWithFileName:(NSString *)fileName{
    if ([super init]) {
        self->_head = NULL;
        self->_tail = NULL;
        self->_dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        self->_totalCount = 0;
        BOOL isDic;
        if(![[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:&isDic]||(!isDic)){
            [[NSFileManager defaultManager] createDirectoryAtPath:fileName withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self->_queue = dispatch_queue_create("com.dl.cache.queue", DISPATCH_QUEUE_CONCURRENT);
        self->_dl_memory_cache_semaphore = dispatch_semaphore_create(1);
        self->_cacheFile = fileName;
        sqlite3_open([[fileName stringByAppendingPathComponent:@"dl_cache.sqlite"] UTF8String], &db);
        sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS dl_cache (cache_key varchar PRIMARY KEY, cache_class varchar, cache_obj blob, cache_filename varchar, cache_time integer, cache_type integer, cache_hash varchar); " UTF8String], NULL, NULL, nil);
        [self selectAllCacheNode];
    }
    return self;
}

-(void)selectAllCacheNode{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self->_queue, ^{
        sqlite3_stmt *stmt = NULL;
        if (sqlite3_prepare_v2(self->db, [@"SELECT * FROM dl_cache ORDER BY cache_time ASC;" UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
            NSTimeInterval nowTime = CFAbsoluteTimeGetCurrent();
            NSFileManager *fileManage = [NSFileManager defaultManager];
            while (sqlite3_step(stmt)==SQLITE_ROW) {
                NSTimeInterval oldTime = (NSTimeInterval)sqlite3_column_int(stmt, 4);
                DLCacheMapNode *node = [[DLCacheMapNode alloc]init];
                id value;
                value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 3)];
                SetNode(node, [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)], value, NSClassFromString([NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)]), [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 6)] );
                if (nowTime - oldTime > DLDiskCacheSaveTime) {
                    //  超时了，删除文件
                    dispatch_async(dispatch_get_main_queue(), ^{
                        sqlite3_exec(self->db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", node->_key] UTF8String], NULL, NULL, nil);
                    });
                    [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", node->_value, node->_key] error:nil];
                }else{
                    //  没有超时，将数据保存到缓存map中
                    insertNodeAtHead(self, node);
                }
            }
        }
        dispatch_semaphore_signal(semaphore);
    });
}

@end

@interface DLCache ()

@end

@implementation DLCache{
    DLCacheMap *_diskCacheMap;
    NSCache *_memoryCache;
}

static DLCache *dlMemoryCache = nil;

+(DLCache *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dlMemoryCache = [[DLCache alloc]initWithFileName:@"dl_cache"];
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
        self->_diskCacheMap = [[DLCacheMap alloc]initWithFileName:[NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject], fileName]];
        
        NSLog(@"_diskCacheMap  ==  %@", self->_diskCacheMap->_cacheFile);
        
//        self->_queue = dispatch_queue_create("com.dl.cache.queue", DISPATCH_QUEUE_CONCURRENT);
//        self->_dl_memory_cache_semaphore = dispatch_semaphore_create(1);
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldObject) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldObject) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

//-(void)deleteOldObject{
//    [self->_memoryCache removeAllObjects];
//}

static NSString *DLNSStringMD5(NSString *string) {
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
    return string;
}

-(void)setObject:(NSObject *)obj forKey:(NSString *)key{
    if (!key || !obj) {
        return;
    }
    key = DLNSStringMD5(key);
    @autoreleasepool {
        dispatch_semaphore_wait(self->_diskCacheMap->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(self->_diskCacheMap->_queue, ^{
            DLCacheMapNode *node;
            node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
            //  在缓存中不存在
            if (!node) {
                NSData *data;
                data = [NSKeyedArchiver archivedDataWithRootObject:[obj mutableCopy]];
                //  磁盘存储
                NSString *fileName = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
                BOOL writeToFileSuccess = [data writeToFile:fileName atomically:NO];
                if (writeToFileSuccess) {
                    node = [[DLCacheMapNode alloc]init];
                    SetNode(node, key, fileName, [obj class], [NSString stringWithFormat:@"%lu", (unsigned long)obj.hash]);
                    insertNodeAtHead(self->_diskCacheMap, node);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_class, cache_obj, cache_filename, cache_time, cache_hash) VALUES('%@', '%@', '%@', '%@', %f, '%@');", key, NSStringFromClass([obj class]), @"", fileName, CFAbsoluteTimeGetCurrent(), node->_valueHash] UTF8String], NULL, NULL, nil);
                    });
                }else{
                    NSLog(@"存储失败");
                }
                dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
            }else{
                if ([node->_valueHash isEqualToString:[NSString stringWithFormat:@"%zd", obj.hash]]) {
                    //  缓存中存在的值和要缓存的值一样，不需要更新缓存数据，只需要更新时间戳
                    dispatch_async(dispatch_get_main_queue(), ^{
                        sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_time = %f WHERE cache_key = '%@';", CFAbsoluteTimeGetCurrent(), key] UTF8String], NULL, NULL, nil);
                    });
                    bringNodeToHead(self->_diskCacheMap, node);
                }else{
                    //  缓存中的值和要缓存的值不一样，更新缓存数据，更新时间戳
                    NSData *data;
                    if (@available(iOS 11.0, *)) {
                        data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:YES error:NULL];
                    } else {
                        data = [NSKeyedArchiver archivedDataWithRootObject:obj];
                    }
                    NSString *valueHash = [NSString stringWithFormat:@"%zd", obj.hash];
                    id value;
                    value = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
                    sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class = '%@', cache_filename = '%@', cache_time = %f, cache_hash= '%@' WHERE cache_key = '%@';", @"", NSStringFromClass([obj class]), value, CFAbsoluteTimeGetCurrent(), valueHash, key] UTF8String], NULL, NULL, nil);
                    SetNode(node, key, value, [obj class], [NSString stringWithFormat:@"%zd", obj.hash]);
                    bringNodeToHead(self->_diskCacheMap, node);
                }
                dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
            }
        });
    }
}

-(instancetype)objectForKey:(NSString *)key{
    if (!key || key.length == 0) {
        return nil;
    }
    @autoreleasepool {
        key = DLNSStringMD5(key);
        dispatch_semaphore_wait(self->_diskCacheMap->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
        id obj;
        DLCacheMapNode *node = [self->_memoryCache objectForKey:key];
        if (node) {
            obj = node->_value;
            bringNodeToHead(self->_diskCacheMap, node);
            dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
            return obj;
        }else{
            node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
            if (node) {
                NSData *data;
                data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, node->_key]];
                obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                bringNodeToHead(self->_diskCacheMap, node);
                if (obj && key) {
                    [self->_memoryCache setObject:obj forKey:key];
                }
                dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
                return obj;
            }else{
                return obj;
            }
        }
    }
}

-(void)removeObjectForKey:(NSString *)key{
    if (!key || key.length == 0) {
        return;
    }
    key = DLNSStringMD5(key);
    @autoreleasepool {
        dispatch_semaphore_wait(self->_diskCacheMap->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(self->_diskCacheMap->_queue, ^{
            [self->_memoryCache removeObjectForKey:key];
            DLCacheMapNode *node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
            if (node) {
                removeNode(self->_diskCacheMap,node);
                sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", key] UTF8String], NULL, NULL, nil);
                NSFileManager *fileManage = [NSFileManager defaultManager];
                [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", node->_value, key] error:nil];
            }
            dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
        });
    }
}

-(void)removeAllObjects{
    @autoreleasepool {
        dispatch_semaphore_wait(self->_diskCacheMap->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(self->_diskCacheMap->_queue, ^{
            [self->_memoryCache removeAllObjects];
            removeAllNode(self->_diskCacheMap);
            sqlite3_exec(self->_diskCacheMap->db, [@"DELETE FROM dl_cache;" UTF8String], NULL, NULL, nil);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:self->_diskCacheMap->_cacheFile error:nil];
            dispatch_semaphore_signal(self->_diskCacheMap->_dl_memory_cache_semaphore);
        });
    }
}

-(NSDictionary *)getAllObjects{
    @autoreleasepool {
        NSDictionary *tempDic = (__bridge NSDictionary *)self->_diskCacheMap->_dic;
        NSMutableDictionary *objDic = [[NSMutableDictionary alloc]init];
        NSArray *array = [tempDic allValues];
        for (DLCacheMapNode *node in array) {
            id obj;
            NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, node->_key]];
            if (@available(iOS 11.0, *)) {
                obj = [NSKeyedUnarchiver unarchivedObjectOfClass:node->_class fromData:data error:NULL];
            } else {
                obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
            [objDic setObject:obj forKey:node->_key];
        }
        return objDic;
    }
}

+(instancetype)objectForKey:(NSString *)key{
    return [[DLCache shareInstance] objectForKey:key];
}

+(void)removeObjectForKey:(NSString *)key{
    [[DLCache shareInstance] removeObjectForKey:key];
}

+(void)removeAllObjects{
    [[DLCache shareInstance] removeAllObjects];
}

+(void)setObject:(id)obj forKey:(NSString *)key{
    [[DLCache shareInstance]setObject:obj forKey:key];
}

+(NSDictionary *)getAllObjects{
    return [[DLCache shareInstance] getAllObjects];
}

+(NSString *)fileName{
    return [[DLCache shareInstance] fileName];
}

+(void)removeAllCache{
    NSString *cachPath = [NSSearchPathForDirectoriesInDomains (NSCachesDirectory ,NSUserDomainMask ,YES)firstObject];
    NSArray *files = [[NSFileManager defaultManager] subpathsAtPath:cachPath];
    for (NSString *p in files) {
        NSError *error = nil ;
        NSString *path = [cachPath stringByAppendingPathComponent :p];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        }
    }
}

+(float)cacheSize{
    NSString * cachPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory ,NSUserDomainMask ,YES) firstObject];
    NSFileManager * manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:cachPath]) return 0 ;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:cachPath]objectEnumerator];
    NSString * fileName;
    long long folderSize = 0 ;
    while((fileName = [childFilesEnumerator nextObject]) != nil){
        long long fileSize = 0;
        if ([manager fileExistsAtPath:[cachPath stringByAppendingPathComponent :fileName]]) {
            fileSize = [[manager attributesOfItemAtPath:[cachPath stringByAppendingPathComponent :fileName] error:nil] fileSize];
        }
        folderSize += fileSize;
    }
    return folderSize/(1024.0 * 1024.0);
}

@end
