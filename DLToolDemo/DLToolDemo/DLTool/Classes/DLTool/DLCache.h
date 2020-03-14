#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLCache : NSObject

@property (copy, readonly) NSString *name;

-(instancetype)initWithName:(NSString *)name;

-(instancetype)initWithPath:(NSString *)path;

-(void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

-(void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> object))block;

-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

-(void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;

-(void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                                 endBlock:(void(^)(BOOL error))end;

+(void)saveImageCache:(UIImage *)image key:(NSString *)key;

+(UIImage *)getCacheImage:(NSString *)key;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
