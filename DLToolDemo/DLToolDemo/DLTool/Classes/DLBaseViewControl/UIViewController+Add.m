#import "UIViewController+Add.h"
#import "DLToolMacro.h"

//static char const viewController_Key;

@implementation UIViewController (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        Safe_ExchangeMethod([self class], @selector(viewWillAppear:), @selector(safe_viewWillAppear:));
//        Safe_ExchangeMethod([self class], @selector(viewWillDisappear:), @selector(safe_viewWillDisappear:));
//        Safe_ExchangeMethod([self class], @selector(dismissViewControllerAnimated:completion:), @selector(safe_dismissViewControllerAnimated:completion:));
    });
}

//-(void)safe_viewWillAppear:(BOOL)ani{
//    [self safe_viewWillAppear:ani];
//    objc_setAssociatedObject(self, &viewController_Key, @(NO), OBJC_ASSOCIATION_ASSIGN);
//}
//
//-(void)safe_viewWillDisappear:(BOOL)ani{
//    [self safe_viewWillDisappear:ani];
//    if ([objc_getAssociatedObject(self, &viewController_Key) boolValue]) {
//        [self willDealloc];
//    }
//}
//
//- (void)safe_dismissViewControllerAnimated:(BOOL)ani completion:(void (^ __nullable)(void))comp{
//    [self safe_dismissViewControllerAnimated:ani completion:comp];
//    [self willDealloc];
//}
//         
//- (void)willDealloc{
//    __weak typeof(self) weakSelf = self;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        __strong typeof(self) strongSelf = weakSelf;
//        [strongSelf isNotDealloc];
//    });
//}
//
//- (void)isNotDealloc{
//    NSLog(@"warning  ==  %@ is not dealloc",self);
//}


@end
