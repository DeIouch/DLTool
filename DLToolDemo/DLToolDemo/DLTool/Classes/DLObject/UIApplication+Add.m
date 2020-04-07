#import "UIApplication+Add.h"
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <objc/runtime.h>
#import "DLToolMacro.h"
#import <objc/message.h>

#define kNetworkIndicatorDelay (1/30.0)
@interface _DLUIApplicationNetworkIndicatorInfo : NSObject
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation _DLUIApplicationNetworkIndicatorInfo
@end

@implementation UIView (DLSign)

//-(void)dl_touchAction:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//
//}

@end

@implementation UIApplication (Add)

//+(void)load{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Safe_ExchangeMethod([self class], @selector(sendEvent:), @selector(safe_sendEvent:));
//    });
//}

//- (void)safe_sendEvent:(UIEvent *)event{
//    NSSet *set= event.allTouches;
//    NSArray *array=[set allObjects];
//    UITouch *touchEvent= [array lastObject];
//    UIView *view=[touchEvent view];
//    
//    NSLog(@"event  ==  %ld", (long)event.type);
//    
//    if ([NSStringFromClass([view.superview class]) containsString:@"UISwitch"]) {
//        if (!(view.superview.superview.userInteractionEnabled == NO || view.superview.superview.hidden == YES || view.superview.superview.alpha <= 0.01)){
//            void(*action)(id,SEL,id,id) = (void(*)(id,SEL,id,id))objc_msgSend;
//            action(view.superview.superview,@selector(dl_touchAction: withEvent:),set,event);
//        }
//    }
//    if (touchEvent.phase==UITouchPhaseEnded) {
//        CGPoint point = [touchEvent locationInView:view];
//        UIView *tempView = [self hitTest:point withEvent:event withView:view];
//        if(tempView){
//            void(*action)(id,SEL,id,id) = (void(*)(id,SEL,id,id))objc_msgSend;
//            if ([NSStringFromClass([tempView class]) isEqualToString:@"_UITableViewHeaderFooterContentView"]) {
//                action(tempView.superview,@selector(dl_touchAction: withEvent:),set,event);
//            }else{
//                action(tempView,@selector(dl_touchAction: withEvent:),set,event);
//            }
//        }
//    }
//}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    return YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event withView:(UIView *)view{
    if (view.userInteractionEnabled == NO || view.hidden == YES || view.alpha <= 0.01) return nil;
    if ([view pointInside:point withEvent:event] == NO) return nil;
    if ([view isKindOfClass:[UIStepper class]]) {
        return view;
    }
    NSInteger count = view.subviews.count;
    for (NSInteger i = count - 1; i >= 0; i--) {
        UIView *childView = view.subviews[i];
        CGPoint childP = [view convertPoint:point toView:childView];
        UIView *tempView = [childView hitTest:childP withEvent:event];
        if (tempView && !(tempView.userInteractionEnabled == NO || tempView.hidden == YES || tempView.alpha <= 0.01)) {
            return tempView;
        }
    }
    return view;
}

- (NSURL *)dl_documentsURL {
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSDocumentDirectory
             inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)dl_documentsPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

- (NSURL *)dl_cachesURL {
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSCachesDirectory
             inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)dl_cachesPath {
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

- (NSURL *)dl_libraryURL {
    return [[[NSFileManager defaultManager]
             URLsForDirectory:NSLibraryDirectory
             inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)dl_libraryPath {
    return [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
}

- (BOOL)dl_isPirated {
//    if ([[UIDevice currentDevice] isSimulator]) return YES; // Simulator is not from appstore
    
    if (getgid() <= 10) return YES; // process ID shouldn't be root
    
    if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"SignerIdentity"]) {
        return YES;
    }
    
    if (![self _yy_fileExistInMainBundle:@"_CodeSignature"]) {
        return YES;
    }
    
    if (![self _yy_fileExistInMainBundle:@"SC_Info"]) {
        return YES;
    }
    
    //if someone really want to crack your app, this method is useless..
    //you may change this method's name, encrypt the code and do more check..
    return NO;
}

- (BOOL)_yy_fileExistInMainBundle:(NSString *)name {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *path = [NSString stringWithFormat:@"%@/%@", bundlePath, name];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (NSString *)dl_appBundleName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSString *)dl_appBundleID {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)dl_appVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)dl_appBuildVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (BOOL)dl_isBeingDebugged {
    size_t size = sizeof(struct kinfo_proc);
    struct kinfo_proc info;
    int ret = 0, name[4];
    memset(&info, 0, sizeof(struct kinfo_proc));
    
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID; name[3] = getpid();
    
    if (ret == (sysctl(name, 4, &info, &size, NULL, 0))) {
        return ret != 0;
    }
    return (info.kp_proc.p_flag & P_TRACED) ? YES : NO;
}

- (int64_t)dl_memoryUsage {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kern = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    if (kern != KERN_SUCCESS) return -1;
    return info.resident_size;
}

- (float)dl_cpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    thread_info_data_t thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_basic_info_t basic_info_th;
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    return tot_cpu;
}

DLSYNTH_DYNAMIC_PROPERTY_OBJECT(networkActivityInfo, setNetworkActivityInfo, RETAIN_NONATOMIC, _DLUIApplicationNetworkIndicatorInfo *);

- (void)_delaySetActivity:(NSTimer *)timer {
    NSNumber *visiable = timer.userInfo;
    if (self.networkActivityIndicatorVisible != visiable.boolValue) {
        [self setNetworkActivityIndicatorVisible:visiable.boolValue];
    }
    [timer invalidate];
}

- (void)_changeNetworkActivityCount:(NSInteger)delta {
    @synchronized(self){
        dispatch_async_on_main_queue(^{
            _DLUIApplicationNetworkIndicatorInfo *info = [self networkActivityInfo];
            if (!info) {
                info = [_DLUIApplicationNetworkIndicatorInfo new];
                [self setNetworkActivityInfo:info];
            }
            NSInteger count = info.count;
            count += delta;
            info.count = count;
            [info.timer invalidate];
            info.timer = [NSTimer timerWithTimeInterval:kNetworkIndicatorDelay target:self selector:@selector(_delaySetActivity:) userInfo:@(info.count > 0) repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:info.timer forMode:NSRunLoopCommonModes];
        });
    }
}

- (void)dl_incrementNetworkActivityCount {
    [self _changeNetworkActivityCount:1];
}

- (void)dl_decrementNetworkActivityCount {
    [self _changeNetworkActivityCount:-1];
}

+ (BOOL)dl_isAppExtension {
    static BOOL isAppExtension = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"UIApplication");
        if(!cls || ![cls respondsToSelector:@selector(sharedApplication)]) isAppExtension = YES;
        if ([[[NSBundle mainBundle] bundlePath] hasSuffix:@".appex"]) isAppExtension = YES;
    });
    return isAppExtension;
}

+ (UIApplication *)sharedExtensionApplication {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    return [self dl_isAppExtension] ? nil : [UIApplication performSelector:@selector(sharedApplication)];
#pragma clang diagnostic pop
}

@end
