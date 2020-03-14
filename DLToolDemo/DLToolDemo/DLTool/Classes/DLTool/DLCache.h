#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLCache : NSObject

@property (copy, readonly) NSString *cachePathName;

/// 根据名称初始化
/// @param name 名称
-(instancetype)initWithName:(NSString *)name;

/// 根据路径初始化
/// @param path 路径
-(instancetype)initWithPath:(NSString *)path;

/// 缓存中是否包含key对应的数据
/// @param key key
-(BOOL)containsObjectForKey:(NSString *)key;

/// 根据key查找并返回缓存中对应的数据
/// @param key key
-(id<NSCoding>)objectForKey:(NSString *)key;

/// 向缓存中存入数据
/// @param object 数据
/// @param key keu
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

/// 删除key对应的缓存数据
/// @param key key
-(void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;

/// 删除所有数据
-(void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress endBlock:(void(^)(BOOL error))end;


+(void)saveImageCache:(UIImage *)image imageUrl:(NSString *)url;

+(UIImage *)getImageCache:(NSString *)url;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
