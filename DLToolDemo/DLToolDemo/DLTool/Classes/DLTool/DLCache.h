#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//#define DLDiskCacheSaveTime 60 * 60 * 24 * 14

#define DLDiskCacheSaveTime 0

#define DLMemoryCacheNumber 9999

@interface DLCache : NSObject

+(DLCache *)shareInstance;

-(instancetype)initWithFileName:(NSString *)fileName;

-(void)setMemoryCache:(id)obj withKey:(NSString *)key;

-(void)setDiskCache:(id)obj withKey:(NSString *)key;

-(instancetype)cacheForKey:(NSString *)key;

-(void)removeCacheForKey:(NSString *)key;

-(void)removeAllCache;

-(void)setCache:(id)obj withKey:(NSString *)key;

-(void)printfAllCache;

-(NSString *)fileName;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
