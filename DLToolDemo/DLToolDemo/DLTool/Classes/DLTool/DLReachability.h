#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DLReachabilityStatus) {
    DLReachabilityStatusNone  = 0,
    DLReachabilityWWANStatusWWAN,
    DLReachabilityStatusWiFi,
};

@interface DLReachability : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

//+(void)openReachabilityMonitor:(void(^)(DLReachabilityStatus status))notifyBlock;

+(DLReachabilityStatus)getReachabilityStatus;

@end
