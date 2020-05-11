#import "DLCache.h"
#import <sqlite3.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DLCacheType) {
    DLCacheMemoryType        =   0,
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
    DLCacheType _type;
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
    if (map->_totalCount > DLMemoryCacheNumber) {
        removeNode(map,node);
        sqlite3_exec(map->db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", node->_key] UTF8String], NULL, NULL, nil);
        NSFileManager *fileManage = [NSFileManager defaultManager];
        if (node->_type == DLCacheDiskType) {
            [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", node->_value, node->_key] error:nil];
        }
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

void SetNode(DLCacheMapNode *node, NSString *key, id value, Class class, DLCacheType type, NSString *valueHash){
    node->_key = key;
    node->_value = value;
    node->_class = class;
    node->_type = type;
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
        self->_cacheFile = fileName;
        sqlite3_open([[fileName stringByAppendingPathComponent:@"dl_cache.sqlite"] UTF8String], &db);
        sqlite3_exec(db, [@"CREATE TABLE IF NOT EXISTS dl_cache (cache_key varchar PRIMARY KEY, cache_class varchar, cache_obj blob, cache_filename varchar, cache_time integer, cache_type integer, cache_hash varchar); " UTF8String], NULL, NULL, nil);
        [self selectAllCacheNode];
    }
    return self;
}

-(void)selectAllCacheNode{
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(db, [@"SELECT * FROM dl_cache;" UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        NSTimeInterval nowTime = CFAbsoluteTimeGetCurrent();
        NSFileManager *fileManage = [NSFileManager defaultManager];
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            NSTimeInterval oldTime = (NSTimeInterval)sqlite3_column_int(stmt, 4);
            DLCacheMapNode *node = [[DLCacheMapNode alloc]init];
            id value;
            switch (node->_type) {
                case DLCacheDiskType:
                    {
                        value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 3)];
                    }
                    break;
                    
                case DLCacheSQLType:
                    {
                        value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 2)];
                    }
                    break;
                    
                default:
                    break;
            }
            SetNode(node, [NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 0)], value, NSClassFromString([NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 1)]), sqlite3_column_int(stmt, 5),[NSString stringWithUTF8String:(const char *)sqlite3_column_text(stmt, 6)] );
            if (nowTime - oldTime > DLDiskCacheSaveTime) {
                //  超时了，删除文件
                sqlite3_exec(db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", node->_key] UTF8String], NULL, NULL, nil);
                if (node->_type == DLCacheDiskType) {
                    [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", node->_value, node->_key] error:nil];
                }
            }else{
                //  没有超时，将数据保存到缓存map中
                insertNodeAtHead(self, node);
            }
        }
    }
}

@end

@interface DLCache ()

@end

@implementation DLCache{
    DLCacheMap *_diskCacheMap;
    NSCache *_memoryCache;
    dispatch_queue_t _queue;
    dispatch_semaphore_t _dl_memory_cache_semaphore;
    
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
        self->_diskCacheMap = [[DLCacheMap alloc]initWithFileName:[NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject], fileName]];        
        self->_queue = dispatch_get_global_queue(0, 0);
        self->_dl_memory_cache_semaphore = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldObject) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteOldObject) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}

-(void)deleteOldObject{
    [self->_memoryCache removeAllObjects];
}

-(void)setObject:(NSObject *)obj forKey:(NSString *)key{
    if (!key || !obj) {
        return;
    }
    
//    [self printfAllObjects];
    
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_sync(self->_queue, ^{
    DLCacheMapNode *node;
        node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
        //  在缓存中不存在
        if (!node) {
            NSData *data;
            if (@available(iOS 11.0, *)) {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:NULL];
            } else {
                data = [NSKeyedArchiver archivedDataWithRootObject:obj];
            }
            if (data.length <= 20480) {
                //  数据库存储
                DLCacheMapNode *node = [[DLCacheMapNode alloc]init];
                SetNode(node, key, data, [obj class], DLCacheSQLType, [NSString stringWithFormat:@"%lu", (unsigned long)obj.hash]);
                insertNodeAtHead(self->_diskCacheMap, node);
                sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_class, cache_obj, cache_filename, cache_time, cache_type, cache_hash) VALUES('%@', '%@', '%@', '%@', %f, '%ld', '%@');", key, NSStringFromClass([obj class]), data, @"", CFAbsoluteTimeGetCurrent(), (long)node->_type, node->_valueHash] UTF8String], NULL, NULL, nil);
            }else{
                //  磁盘存储
                NSString *fileName = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
                BOOL writeToFileSuccess = [data writeToFile:fileName atomically:NO];
                if (writeToFileSuccess) {
                    node = [[DLCacheMapNode alloc]init];
                    SetNode(node, key, fileName, [obj class], DLCacheDiskType, [NSString stringWithFormat:@"%lu", (unsigned long)obj.hash]);
                    insertNodeAtHead(self->_diskCacheMap, node);
                    sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"INSERT INTO dl_cache (cache_key, cache_class, cache_obj, cache_filename, cache_time, cache_type, cache_hash) VALUES('%@', '%@', '%@', '%@', %f, '%ld', '%@');", key, NSStringFromClass([obj class]), @"", fileName, CFAbsoluteTimeGetCurrent(), (long)DLCacheDiskType, node->_valueHash] UTF8String], NULL, NULL, nil);
                }
            }
            dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
        }else{
            if ([node->_valueHash isEqualToString:[NSString stringWithFormat:@"%ld", obj.hash]]) {
                //  缓存中存在的值和要缓存的值一样，不需要更新缓存数据，只需要更新时间戳
                sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_time = %f WHERE cache_key = %@;", CFAbsoluteTimeGetCurrent(), key] UTF8String], NULL, NULL, nil);
                bringNodeToHead(self->_diskCacheMap, node);
            }else{
                //  缓存中的值和要缓存的值不一样，更新缓存数据，更新时间戳
                NSData *data;
                if (@available(iOS 11.0, *)) {
                    data = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:NULL];
                } else {
                    data = [NSKeyedArchiver archivedDataWithRootObject:obj];
                }
                NSString *valueHash = [NSString stringWithFormat:@"%ld", obj.hash];
                id value;
                switch (node->_type) {
                    case DLCacheSQLType:
                        {
                            value = data;
                            sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class = '%@', cache_filename = '%@', cache_time = %f, cache_type = '%ld', cache_hash= '%@' WHERE cache_key = %@;", value, NSStringFromClass([obj class]), @"", CFAbsoluteTimeGetCurrent(), (long)node->_type, valueHash, key] UTF8String], NULL, NULL, nil);
                        }
                        break;

                    case DLCacheDiskType:
                        {
                            value = [NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, key];
                            sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"UPDATE dl_cache SET cache_obj='%@', cache_class = '%@', cache_filename = '%@', cache_time = %f, cache_type = '%ld', cache_hash= '%@' WHERE cache_key = %@;", @"", NSStringFromClass([obj class]), value, CFAbsoluteTimeGetCurrent(), (long)node->_type, valueHash, key] UTF8String], NULL, NULL, nil);
                        }
                        break;

                    default:
                        break;
                }
                SetNode(node, key, value, [obj class], node->_type, [NSString stringWithFormat:@"%ld", obj.hash]);
                bringNodeToHead(self->_diskCacheMap, node);
            }
            dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
        }
    });
}

-(instancetype)objectForKey:(NSString *)key{
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
        id obj;
        DLCacheMapNode *node = [self->_memoryCache objectForKey:key];
        if (node) {
            obj = node->_value;
            bringNodeToHead(self->_diskCacheMap, node);
        }else{
            node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
            if (node) {
                NSData *data;
                switch (node->_type) {
                    case DLCacheDiskType:
                        {
                            data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, node->_key]];
                        }
                        break;
                        
                    case DLCacheSQLType:
                        {
                            data = node->_value;
                        }
                        break;
                        
                    default:
                        break;
                }
                if (@available(iOS 11.0, *)) {
                    obj = [NSKeyedUnarchiver unarchivedObjectOfClass:node->_class fromData:data error:NULL];
                } else {
                    obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
                bringNodeToHead(self->_diskCacheMap, node);
            }
        }
        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
        return obj ? obj : nil;
}

-(void)removeObjectForKey:(NSString *)key{
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self->_queue, ^{
        [self->_memoryCache removeObjectForKey:key];
        DLCacheMapNode *node = CFDictionaryGetValue(self->_diskCacheMap->_dic, (__bridge const void *)(key));
        if (node) {
            removeNode(self->_diskCacheMap,node);
            sqlite3_exec(self->_diskCacheMap->db, [[NSString stringWithFormat:@"DELETE FROM dl_cache WHERE cache_key = '%@'", key] UTF8String], NULL, NULL, nil);
            NSFileManager *fileManage = [NSFileManager defaultManager];
            if (node->_type == DLCacheDiskType) {
                [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@", node->_value, key] error:nil];
            }
        }
        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
    });
}

-(void)removeAllObjects{
    dispatch_semaphore_wait(self->_dl_memory_cache_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(self->_queue, ^{
        [self->_memoryCache removeAllObjects];
        removeAllNode(self->_diskCacheMap);
        sqlite3_exec(self->_diskCacheMap->db, [@"DELETE FROM dl_cache;" UTF8String], NULL, NULL, nil);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:self->_diskCacheMap->_cacheFile error:nil];
        dispatch_semaphore_signal(self->_dl_memory_cache_semaphore);
    });
}

-(void)printfAllObjects{
    NSDictionary *tempDic = (__bridge NSDictionary *)self->_diskCacheMap->_dic;
    NSArray *array = [tempDic allValues];
    for (DLCacheMapNode *node in array) {
        switch (node->_type) {
            case DLCacheDiskType:
                {
                    id obj;
                    NSData *data = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", self->_diskCacheMap->_cacheFile, node->_key]];
                    if (@available(iOS 11.0, *)) {
                        obj = [NSKeyedUnarchiver unarchivedObjectOfClass:node->_class fromData:data error:NULL];
                    } else {
                        obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    }
                    NSLog(@"Diskcache_obj  ==  %@", obj);
                }
                break;
                
            case DLCacheSQLType:
                {
                    NSLog(@"SQLcache_obj  ==  %@", node->_value);
                }
                break;
                
            default:
                break;
        }
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

+(void)printfAllObjects{
    [[DLCache shareInstance] printfAllObjects];
}

+(NSString *)fileName{
    return [[DLCache shareInstance] fileName];
}

@end
