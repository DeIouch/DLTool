#import <Foundation/Foundation.h>

//  存储比YYCache快5%左右，读取比YYCache快20多倍
//  优化存储，有文件hash值对比功能，相同的文件不会重复存储

#define DLDiskCacheSaveTime 60 * 60 * 24 * 30

#define DLMemoryCacheNumber 1000

@interface DLCache : NSObject

+(instancetype)objectForKey:(NSString *)key;

+(void)removeObjectForKey:(NSString *)key;

+(void)removeAllObjects;

+(void)setObject:(id)obj forKey:(NSString *)key;

+(void)printfAllObjects;

+(NSString *)fileName;



-(instancetype)initWithFileName:(NSString *)fileName;

-(instancetype)objectForKey:(NSString *)key;

-(void)removeObjectForKey:(NSString *)key;

-(void)removeAllObjects;

-(void)setObject:(id)obj forKey:(NSString *)key;

-(void)printfAllObjects;

-(NSString *)fileName;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
