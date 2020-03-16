#import "DLReachability.h"
#import "Reachability.h"
#import "NSObject+Add.h"
#import "NSNotificationCenter+Add.h"

@interface DLReachability ()

@property (nonatomic, copy) void (^notifyBlock)(DLReachabilityStatus status);

@property (nonatomic, strong) Reachability *interNetReachability;

@property (nonatomic, assign) DLReachabilityStatus status;

@end


@implementation DLReachability

static DLReachability *reachability = nil;
+(DLReachability *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reachability = [[DLReachability alloc]_init];
    });
    return reachability;
}

-(instancetype)_init{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.interNetReachability = [Reachability reachabilityForInternetConnection];
    [self.interNetReachability startNotifier];
    self.status = (DLReachabilityStatus)[self.interNetReachability currentReachabilityStatus];
    return self;
}

- (void) reachabilityChanged:(NSNotification *)note {
    Reachability *reachability = [note object];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    self.status = (DLReachabilityStatus)netStatus;
}

//-(void)setStatus:(DLReachabilityStatus)status{
//    _status = status;
//    @autoreleasepool {
//        void (^block)(DLReachabilityStatus status);
//        for (int i = 0; i < self.blockArray.count; i++) {
//            block = self.blockArray[i];
//            block(status);
//        }
//    }
//}

//+(void)openReachabilityMonitor:(void(^)(DLReachabilityStatus status))notifyBlock{
//    DLReachability *reachability = [DLReachability shareInstance];
//    [reachability.blockArray addObject:notifyBlock];
//}

+(DLReachabilityStatus)getReachabilityStatus{
    DLReachability *reachability = [DLReachability shareInstance];
    return reachability.status;
}

@end
