#import <UIKit/UIKit.h>

@interface UINavigationController (Add)

/**
 是否隐藏导航栏，YES表示隐藏
 */
@property (nonatomic, assign) BOOL dl_viewControllerBasedNavigationBarAppearanceEnabled;

@end

@interface UIViewController (HandlerNavigationBar)

@property (nonatomic, assign) BOOL dl_prefersNavigationBarHidden;

@end
