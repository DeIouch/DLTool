#import "DLKeyboardManage.h"
#import <UIKit/UIKit.h>
#import "UIView+Add.h"
#import <objc/runtime.h>

static char const singleMeViewKey;
@implementation UIView (KeyBoard)

-(void)setSingleMeView:(UIView *)singleMeView{
    objc_setAssociatedObject(self, &singleMeViewKey, singleMeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIView *)singleMeView{
    return objc_getAssociatedObject(self, &singleMeViewKey);
}

@end

@interface UIResponder (KeyBoard)

+(id)dl_currentFirstResponder;

@end

static __weak id dl_currentFirstResponder;

@implementation UIResponder (KeyBoard)

+(id)dl_currentFirstResponder {
    dl_currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(dl_findFirstResponder:)
                                               to:nil
                                             from:nil
                                         forEvent:nil];
    return dl_currentFirstResponder;
}
- (void)dl_findFirstResponder:(id)sender {
    dl_currentFirstResponder = self;
}

@end

@interface DLKeyboardManage ()

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, weak) UIView *singleView;

@property (nonatomic, assign) CGFloat singleOldY;

@property (nonatomic, assign) CGFloat oldY;

/**
 是否已经变动
 */
@property (nonatomic, assign) BOOL isChange;


@end

@implementation DLKeyboardManage

static DLKeyboardManage *keyboard = nil;

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
    });
    return keyboard;
}

-(void)keyboardWillShow:(NSNotification *)noti{
    CGSize keyboardSize = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIView *view = [UIResponder dl_currentFirstResponder];
    if (view.singleMeView) {
        if ([NSStringFromClass([view.singleMeView.superview class])isEqualToString:@"UIViewControllerWrapperView"]) {
            keyboard.fatherView = view.singleMeView;
            CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - view.y_dl - view.height_dl;
            if (keyboard.isChange) {
                keyboard.oldY = keyboard.fatherView.y_dl;
                if (tempHeight > keyboardSize.height) {
                    keyboard.fatherView.y_dl = 0;
                }else{
                    keyboard.fatherView.y_dl = tempHeight - keyboardSize.height;
                }
            }else{
                if (tempHeight < keyboardSize.height) {
                    keyboard.oldY = keyboard.fatherView.y_dl;
                    keyboard.fatherView.y_dl = tempHeight - keyboardSize.height;
                }
            }
        }else{
            keyboard.singleView = view.singleMeView;
            [view.singleMeView layoutIfNeeded];
            CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - view.singleMeView.y_dl - view.singleMeView.frame.size.height;
            if (keyboard.isChange) {
                keyboard.singleOldY = keyboard.singleView.y_dl;
                keyboard.singleView.y_dl = [UIScreen mainScreen].bounds.size.height - (keyboardSize.height + keyboard.singleView.height_dl);
            }else{
                if (tempHeight < keyboardSize.height) {
                    keyboard.singleOldY = keyboard.singleView.y_dl;
                    keyboard.singleView.y_dl = [UIScreen mainScreen].bounds.size.height - (keyboardSize.height + keyboard.singleView.height_dl);
                }
            }
        }
    }else{
        UIView *tempView;
        while (!tempView) {
            if ([NSStringFromClass([view.superview.superview class])isEqualToString:@"UIViewControllerWrapperView"]) {
                tempView = view.superview;
            }else{
                view = view.superview;
            }
        }
        keyboard.fatherView = tempView;
        CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - view.y_dl - view.height_dl;
        if (keyboard.isChange) {
            keyboard.oldY = keyboard.fatherView.y_dl;
            if (tempHeight > keyboardSize.height) {
                keyboard.fatherView.y_dl = 0;
            }else{
                keyboard.fatherView.y_dl = tempHeight - keyboardSize.height;
            }
        }else{
            if (tempHeight < keyboardSize.height) {
                keyboard.oldY = keyboard.fatherView.y_dl;
                keyboard.fatherView.y_dl = tempHeight - keyboardSize.height;
            }
        }
    }
    
    keyboard.isChange = YES;
}

-(void)keyboardWillHide:(NSNotification *)noti{
    if (keyboard.fatherView) {
        keyboard.fatherView.y_dl = 0;
    }
    if (keyboard.singleView) {
        keyboard.singleView.y_dl = keyboard.singleOldY;
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
