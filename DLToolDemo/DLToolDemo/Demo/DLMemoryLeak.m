#import "DLMemoryLeak.h"
#import <UIKit/UIKit.h>
#import "DLToolMacro.h"

@interface DLMemoryLeak()

@property (nonatomic, strong) NSString *leakStr;

@property (nonatomic, strong) NSString *vcStr;

@property (nonatomic, retain) NSMutableDictionary *vcDic;

@property (nonatomic, retain) NSMutableDictionary *viewDic;

+(DLMemoryLeak *)shareInstance;

@end

@interface UIView(Leak)



@end

@implementation UIView(Leak)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(init), @selector(safe_init));
        Safe_ExchangeMethod([self class], NSSelectorFromString(@"dealloc"), @selector(safe_dealloc));
    });
}

-(instancetype)safe_init{
    if ([self isCustomClass]) {
        UIViewController *currentShowViewController = [self getCurrentShowViewController];
        NSString *str = NSStringFromClass([currentShowViewController class]);
        if (str.length > 0 && currentShowViewController.view != self) {
            NSMutableArray *array = [[NSMutableArray alloc]init];
            [array addObjectsFromArray:[DLMemoryLeak shareInstance].viewDic[str]];
            id obj = self;
            [array addObject:obj];
            [[DLMemoryLeak shareInstance].viewDic setObject:array forKey:str];
        }
    }
    return [self safe_init];
}

-(void)safe_dealloc{
    NSString *str = NSStringFromClass([[self getCurrentShowViewController] class]);
     if (str.length > 0) {
           NSMutableArray *array = [DLMemoryLeak shareInstance].viewDic[str];
           [array removeObject:self];
   }
    [self safe_dealloc];
}

-(BOOL)isCustomClass{
    NSBundle *mainB = [NSBundle bundleForClass:[self class]];
    if (mainB == [NSBundle mainBundle] || [self isKindOfClass:[UIResponder class]]) {
        return YES;
    }else{
        return NO;
    }
}

-(UIViewController *)getCurrentShowViewController{
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowVC = [self recursiveFindCurrentShowViewControllerFromViewController:rootVC];
    return currentShowVC;
}

-(UIViewController *)recursiveFindCurrentShowViewControllerFromViewController:(UIViewController *)fromVC{
    if ([fromVC isKindOfClass:[UINavigationController class]]) {
        return [self recursiveFindCurrentShowViewControllerFromViewController:[((UINavigationController *)fromVC) visibleViewController]];
    } else if ([fromVC isKindOfClass:[UITabBarController class]]) {
        return [self recursiveFindCurrentShowViewControllerFromViewController:[((UITabBarController *)fromVC) selectedViewController]];
    } else {
        if (fromVC.presentedViewController) {
            return [self recursiveFindCurrentShowViewControllerFromViewController:fromVC.presentedViewController];
        } else {
            return fromVC;
        }
    }
}

@end

@interface UIViewController (Leak)



@end

@implementation UIViewController(Leak)

//+(void)load{
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Safe_ExchangeMethod([self class], @selector(viewDidLoad), @selector(safe_viewDidLoad));
//        Safe_ExchangeMethod([self class], @selector(dismissViewControllerAnimated:completion:), @selector(safe_dismissViewControllerAnimated:completion:));
//        Safe_ExchangeMethod([self class], NSSelectorFromString(@"dealloc"), @selector(safe_dealloc));
//    });
//}

-(void)safe_dealloc{
    if (self.parentViewController) {
//        NSLog(@"shareInstance  ==  %@", [DLMemoryLeak shareInstance].leakStr);
        [[DLMemoryLeak shareInstance].vcDic removeObjectForKey:NSStringFromClass([self class])];
        [[DLMemoryLeak shareInstance].viewDic removeObjectForKey:NSStringFromClass([self class])];
    }
    [self safe_dealloc];
}

-(void)safe_viewDidLoad{
    [[DLMemoryLeak shareInstance].vcDic setObject:NSStringFromClass([self class]) forKey:NSStringFromClass([self class])];
    [self safe_viewDidLoad];
}

-(void)safe_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion{
    [DLMemoryLeak shareInstance].leakStr = NSStringFromClass([self class]);
    [self safe_dismissViewControllerAnimated:flag completion:completion];
}

@end

@interface UINavigationController (Leak)

@end

@implementation UINavigationController (Leak)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(popViewControllerAnimated:), @selector(safe_popViewControllerAnimated:));
//        Safe_ExchangeMethod([self class], @selector(pushViewController:animated:), @selector(safe_pushViewController:animated:));
    });
}

-(void)safe_pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [[DLMemoryLeak shareInstance].vcDic setObject:NSStringFromClass([viewController class]) forKey:NSStringFromClass([viewController class])];
    [self safe_pushViewController:viewController animated:animated];
}

- (nullable UIViewController *)safe_popViewControllerAnimated:(BOOL)animated{
    [DLMemoryLeak shareInstance].leakStr = NSStringFromClass([self.topViewController class]);
    return [self safe_popViewControllerAnimated:YES];
}

@end

@implementation DLMemoryLeak

static DLMemoryLeak *leak = nil;
+(DLMemoryLeak *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leak = [[DLMemoryLeak alloc]_init];
    });
    return leak;
}

-(instancetype)_init{
    self.vcDic = [[NSMutableDictionary alloc]init];
    self.viewDic = [[NSMutableDictionary alloc]init];
    return [self init];
}

-(void)setLeakStr:(NSString *)leakStr{
    _leakStr = leakStr;
    if (self.vcDic.allKeys) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *str = self.vcDic[leakStr];
            if (str) {
                NSLog(@"%@ 未释放", str);
            }
            NSArray *array = self.viewDic[leakStr];
            if (array.count > 0) {
                NSLog(@"%@ 未释放", array);
            }
        });
    }
}

@end
