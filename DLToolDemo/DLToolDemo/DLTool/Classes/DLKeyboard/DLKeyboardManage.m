#import "DLKeyboardManage.h"
#import <UIKit/UIKit.h>
#import "UIView+Add.h"
#import "NSObject+Add.h"
#import <objc/runtime.h>

static DLKeyboardManage *keyboard = nil;

static char const singleMeViewKey;

static char const notManageBOOLKey;

@interface DLKeyboardManage ()

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, weak) UIView *singleView;

@property (nonatomic, weak) UIView *firstResponderView;

@property (nonatomic, assign) CGFloat singleOldY;

@property (nonatomic, assign) CGFloat oldY;

@property (nonatomic, assign) CGSize keyBoardSize;

@property (nonatomic, weak) UIViewController *keyBoardManageVC;

@property (nonatomic, strong) NSMutableArray *viewArray;

/**
 是否已经变动
 */
@property (nonatomic, assign) BOOL isChange;


@end

@interface UIResponder (KeyBoardManage)

+(id)dl_currentFirstResponder;

@end

static __weak id dl_currentFirstResponder;

@implementation UIResponder (KeyBoardManage)

+(id)dl_currentFirstResponder {
    dl_currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(dl_findFirstResponder:) to:nil from:nil forEvent:nil];
    return dl_currentFirstResponder;
}

-(void)dl_findFirstResponder:(id)sender {
    dl_currentFirstResponder = self;
}

@end

@implementation UIView (KeyBoardManage)

-(void)setSingleMeView:(UIView *)singleMeView{
    objc_setAssociatedObject(self, &singleMeViewKey, singleMeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIView *)singleMeView{
    return objc_getAssociatedObject(self, &singleMeViewKey);
}

-(BOOL)notManageBOOL{
    return objc_getAssociatedObject(self, &notManageBOOLKey);
}

-(void)setNotManageBOOL:(BOOL)notManageBOOL{
    objc_setAssociatedObject(self, &notManageBOOLKey, @(notManageBOOL), OBJC_ASSOCIATION_ASSIGN);
}

@end

@interface UIViewController (KeyBoardManage)

@end

@implementation UIViewController (KeyBoardManage)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(viewWillDisappear:) newSel:@selector(safe_viewWillDisappear:)];
    });
}

-(void)safe_viewWillDisappear:(BOOL)animated{
    if (self == keyboard.keyBoardManageVC && [UIResponder dl_currentFirstResponder]) {
        UIView *view = [UIResponder dl_currentFirstResponder];
        [view resignFirstResponder];
        keyboard.keyBoardManageVC = nil;
    }
    [self safe_viewWillDisappear:animated];
}

@end

@implementation DLKeyboardManage

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    });
}

+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyboard = [[DLKeyboardManage alloc]_init];
        keyboard.isChange = NO;
        keyboard.viewArray = [[NSMutableArray alloc]init];
        [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"_UIConstraintBasedLayoutLogUnsatisfiable"];
    });
    return keyboard;
}

-(CGFloat)convertYView:(UIView *)view toView:(UIView *)toView{
    return [view.superview convertRect:view.frame toView:toView].origin.y;
}

-(void)keyboardWillShow:(NSNotification *)noti{
    keyboard.keyBoardSize = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    keyboard.firstResponderView = [UIResponder dl_currentFirstResponder];
    if (!keyboard.keyBoardManageVC) {
        keyboard.keyBoardManageVC = keyboard.firstResponderView.fatherViewController;
    }
    if (keyboard.firstResponderView.notManageBOOL) {
        return;
    }
    if (keyboard.firstResponderView.singleMeView) {
        if ([NSStringFromClass([keyboard.firstResponderView.singleMeView.superview class])isEqualToString:@"UIViewControllerWrapperView"] || [NSStringFromClass([keyboard.firstResponderView.singleMeView.superview class])isEqualToString:@"UIWindow"]) {
            keyboard.fatherView = keyboard.firstResponderView.singleMeView;
            CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - keyboard.firstResponderView.y_dl - keyboard.firstResponderView.height_dl;
            if (keyboard.isChange) {
                keyboard.oldY = keyboard.fatherView.y_dl;
                if (tempHeight > keyboard.keyBoardSize.height) {
                    [UIView animateWithDuration:0.3 animations:^{
                        keyboard.fatherView.y_dl = 0;
                    }];
                }else{
                    [UIView animateWithDuration:0.3 animations:^{
                        keyboard.fatherView.y_dl = (tempHeight - keyboard.keyBoardSize.height) > -keyboard.keyBoardSize.height ? (tempHeight - keyboard.keyBoardSize.height) :  -keyboard.keyBoardSize.height;
                    }];
                }
            }else{
                if (tempHeight < keyboard.keyBoardSize.height) {
                    keyboard.oldY = keyboard.fatherView.y_dl;
                    [UIView animateWithDuration:0.3 animations:^{
                        keyboard.fatherView.y_dl = (tempHeight - keyboard.keyBoardSize.height) > -keyboard.keyBoardSize.height ? (tempHeight - keyboard.keyBoardSize.height) :  -keyboard.keyBoardSize.height;
                    }];
                }
            }
        }else{
            keyboard.singleView = keyboard.firstResponderView.singleMeView;
            [keyboard.firstResponderView.singleMeView layoutIfNeeded];
            CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - keyboard.firstResponderView.singleMeView.y_dl - keyboard.firstResponderView.singleMeView.frame.size.height;
            if (keyboard.isChange) {
                keyboard.singleOldY = keyboard.singleView.y_dl;
                [UIView animateWithDuration:0.3 animations:^{
                    keyboard.singleView.y_dl = [UIScreen mainScreen].bounds.size.height - (keyboard.keyBoardSize.height + keyboard.singleView.height_dl);
                }];
            }else{
                if (tempHeight < keyboard.keyBoardSize.height) {
                    keyboard.singleOldY = keyboard.singleView.y_dl;
                    [UIView animateWithDuration:0.3 animations:^{
                        keyboard.singleView.y_dl = [UIScreen mainScreen].bounds.size.height - (keyboard.keyBoardSize.height + keyboard.singleView.height_dl) ;
                    }];
                }
            }
        }
    }else{
        UIView *tempView;
        UIView *tempView2 = keyboard.firstResponderView;
        while (!tempView) {
            if ([NSStringFromClass([tempView2.superview class])isEqualToString:@"UIViewControllerWrapperView"] || [NSStringFromClass([tempView2.superview class])isEqualToString:@"UIWindow"]) {
                tempView = tempView2;
            }else{
                tempView2 = tempView2.superview;
            }
        }
        keyboard.fatherView = tempView;
        CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - [self convertYView:keyboard.firstResponderView toView:keyboard.fatherView] - keyboard.firstResponderView.height_dl;
        if (keyboard.isChange) {
            keyboard.oldY = keyboard.fatherView.y_dl;
            if (tempHeight > keyboard.keyBoardSize.height) {
                [UIView animateWithDuration:0.3 animations:^{
                    keyboard.fatherView.y_dl = 0;
                }];
            }else{
                [UIView animateWithDuration:0.3 animations:^{
                    keyboard.fatherView.y_dl = (tempHeight - keyboard.keyBoardSize.height) > -keyboard.keyBoardSize.height ? (tempHeight - keyboard.keyBoardSize.height) :  -keyboard.keyBoardSize.height;
                }];
            }
        }else{
            if (tempHeight < keyboard.keyBoardSize.height) {
                keyboard.oldY = keyboard.fatherView.y_dl;
                [UIView animateWithDuration:0.3 animations:^{
                    keyboard.fatherView.y_dl = (tempHeight - keyboard.keyBoardSize.height) > -keyboard.keyBoardSize.height ? (tempHeight - keyboard.keyBoardSize.height) :  -keyboard.keyBoardSize.height;
                }];
            }
        }
    }
//    [self getAllView:keyboard.keyBoardManageVC.view];
    keyboard.isChange = YES;
}

-(void)getAllView:(UIView *)view{
    
    
}

-(void)keyboardWillHide:(NSNotification *)noti{
    keyboard.isChange = NO;
    if (keyboard.fatherView) {
        keyboard.fatherView.y_dl = 0;
    }
    if (keyboard.singleView) {
        keyboard.singleView.y_dl = keyboard.singleOldY;
    }
    if (keyboard.firstResponderView) {
        keyboard.firstResponderView = nil;
    }
    keyboard.fatherView = nil;
    keyboard.singleView = nil;
    keyboard.isChange = NO;
}

-(instancetype)_init{
    self = [super init];
    return self;
}

@end
