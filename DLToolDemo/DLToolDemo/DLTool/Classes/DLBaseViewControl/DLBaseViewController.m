#import "DLBaseViewController.h"
#import "UINavigationController+Add.h"
#include <objc/runtime.h>

@interface DLBaseViewController ()

@end

@implementation DLBaseViewController



- (void)viewDidLoad {
    [super viewDidLoad];
}

///获取当前活动的控制器
+ (UIViewController *)getCurrentActivityViewController {
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow * tmpWin in windows) {
            if (tmpWin.windowLevel == UIWindowLevelNormal) {
                window = tmpWin;
                break;
            }
        }
    }
    
    //从根控制器开始查找
    UIViewController *rootVC = window.rootViewController;
    UIViewController *activityVC = nil;
    
    while (true) {
        if ([rootVC isKindOfClass:[UINavigationController class]]) {
            activityVC = [(UINavigationController *)rootVC visibleViewController];
        } else if ([rootVC isKindOfClass:[UITabBarController class]]) {
            activityVC = [(UITabBarController *)rootVC selectedViewController];
        } else if (rootVC.presentedViewController) {
            activityVC = rootVC.presentedViewController;
        }else {
            break;
        }
        
        rootVC = activityVC;
    }
    return activityVC;
}

@end


@implementation DLNaviHeadView : UIView

@end
