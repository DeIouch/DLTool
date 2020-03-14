#import <Foundation/Foundation.h>

@interface DLLaunchAdModel : NSObject

@property (nonatomic, strong) NSString *adUrl;

@property (nonatomic, strong) NSString *pushUrl;

@property (nonatomic, assign) NSInteger adCount;

@property (nonatomic, assign) BOOL countdownShow;

@end

@interface DLLaunchAd : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(void)addLaunchAd:(DLLaunchAdModel *)model clickBlock:(void (^)(void))clickBlock timeArrierBlock:(void (^)(void))timeArrierBlock;

@end
