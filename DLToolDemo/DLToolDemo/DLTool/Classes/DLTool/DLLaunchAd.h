#import <Foundation/Foundation.h>

@interface DLLaunchAd : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(void)addLaunchAd:(NSString *)imageUrl secondTime:(NSInteger)second clickBlock:(void (^)(void))clickBlock timeArrierBlock:(void (^)(void))timeArrierBlock;

@end
