#import <Foundation/Foundation.h>

//  存储比YYCache快5%左右，读取比YYCache快20多倍
//  优化存储，有文件hash值对比功能，相同的文件不会重复存储

//  磁盘文件保存时间
#define DLDiskCacheSaveTime 60 * 60 * 24 * 30

//  本地文件最大存储个数（只能够约束单个cache对象）
#define DLMemoryCacheNumber 1000

//  数据库允许存储的单个文件最大界限
#define DLSQLLimit 20480

@interface DLCache : NSObject

/// 从默认缓存对象中取出对应key的值
/// @param key 要取出的对象的key值
+(instancetype)objectForKey:(NSString *)key;

/// 删除默认缓存对象的缓存
/// @param key 要删除对象的key值
+(void)removeObjectForKey:(NSString *)key;

/// 删除默认缓存对象的所有缓存
+(void)removeAllObjects;

/// 删除所有缓存
+(void)removeAllCache;

/// 返回缓存的大小
+(float)cacheSize;

/// 保存缓存到默认的缓存对象
/// @param obj 要保存的对象
/// @param key 对应的key值
+(void)setObject:(id)obj forKey:(NSString *)key;

/// 打印默认缓存对象的所有值
+(void)printfAllObjects;

/// 获取默认缓存对象的文件路径
+(NSString *)fileName;


/// 初始化缓存对象
/// @param fileName 文件名
-(instancetype)initWithFileName:(NSString *)fileName;

/// 从缓存对象中取出对应key的值
/// @param key 要取出的对象的key值
-(instancetype)objectForKey:(NSString *)key;

/// 删除缓存对象的缓存
/// @param key 要删除对象的key值
-(void)removeObjectForKey:(NSString *)key;

/// 删除缓存对象的所有缓存
-(void)removeAllObjects;

/// 保存缓存到缓存对象
/// @param obj 要保存的对象
/// @param key 对应的key值
-(void)setObject:(id)obj forKey:(NSString *)key;

/// 打印缓存对象的所有值
-(void)printfAllObjects;

/// 获取缓存对象的文件路径
-(NSString *)fileName;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
