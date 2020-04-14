#import "UINavigationController+Add.h"
#import "DLToolMacro.h"
static char const navigationController_Key;

typedef void(^_DLViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (HandlerNavigationBarPrivate)

@property(nonatomic, copy) _DLViewControllerWillAppearInjectBlock dl_willAppearInjectBlock;

@end

// MARK: - 替换UIViewController的viewWillAppear方法，在此方法中，执行设置导航栏隐藏和显示的代码块。
@implementation UIViewController (HandlerNavigationBarPrivate)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(viewWillAppear:), @selector(dl_viewWillAppear:));
    });
}

-(void)dl_viewWillAppear:(BOOL)animated{
    [self dl_viewWillAppear:animated];
    if (self.dl_willAppearInjectBlock) {
        self.dl_willAppearInjectBlock(self, animated);
    }
}

-(_DLViewControllerWillAppearInjectBlock)dl_willAppearInjectBlock{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDl_willAppearInjectBlock:(_DLViewControllerWillAppearInjectBlock)dl_willAppearInjectBlock{
    objc_setAssociatedObject(self, @selector(dl_willAppearInjectBlock), dl_willAppearInjectBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

// MARK: - 给UIViewController添加dl_prefersNavigationBarHidden属性
@implementation UIViewController (HandlerNavigationBar)

- (BOOL)dl_prefersNavigationBarHidden{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)setDl_prefersNavigationBarHidden:(BOOL)dl_prefersNavigationBarHidden
{
    objc_setAssociatedObject(self, @selector(dl_prefersNavigationBarHidden), @(dl_prefersNavigationBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

// MARK: - 替换UINavigationController的pushViewController:animated:方法，在此方法中去设置导航栏的隐藏和显示
@implementation UINavigationController (Add)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(pushViewController:animated:), @selector(dl_pushViewController:animated:));
        Safe_ExchangeMethod([self class], @selector(popViewControllerAnimated:), @selector(dl_popViewControllerAnimated:));
        Safe_ExchangeMethod([self class], @selector(setViewControllers:animated:), @selector(dl_setViewControllers:animated:));
    });
}

- (UIViewController *)dl_popViewControllerAnimated:(BOOL)animated{
    UIViewController * popVC = [self dl_popViewControllerAnimated:animated];
    objc_setAssociatedObject(popVC, &navigationController_Key, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return popVC;
}

- (void)dl_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // Handle perferred navigation bar appearance.
    [self dl_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    
    // Forward to primary implementation.
    [self dl_pushViewController:viewController animated:animated];
}

- (void)dl_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
    // Handle perferred navigation bar appearance.
    for (UIViewController *viewController in viewControllers) {
        [self dl_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    }
    
    // Forward to primary implementation.
    [self dl_setViewControllers:viewControllers animated:animated];
}

- (void)dl_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController
{
    if (!self.dl_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    // 即将被调用的代码块
    __weak typeof(self) weakSelf = self;
    
    _DLViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated){
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.dl_prefersNavigationBarHidden animated:animated];
        }
    };
    
    // 给即将显示的控制器，注入代码块
    appearingViewController.dl_willAppearInjectBlock = block;
    
    // 因为不是所有的都是通过push的方式，把控制器压入stack中，也可能是"-setViewControllers:"的方式，所以需要对栈顶控制器做下判断并赋值。
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.dl_willAppearInjectBlock) {
        disappearingViewController.dl_willAppearInjectBlock = block;
    }
}

- (BOOL)dl_viewControllerBasedNavigationBarAppearanceEnabled
{
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.dl_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setDl_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)dl_viewControllerBasedNavigationBarAppearanceEnabled
{
    SEL key = @selector(dl_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(dl_viewControllerBasedNavigationBarAppearanceEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
