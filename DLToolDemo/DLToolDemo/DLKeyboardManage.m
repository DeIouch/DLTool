#import "DLKeyboardManage.h"
#import <UIKit/UIKit.h>
#import "NSObject+Add.h"
#import "UIView+Add.h"
#import <objc/runtime.h>
#import "UIView+Layout.h"
#import "DLAutoLayout.h"

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

@property (nonatomic, weak) UIView *view;

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, assign) CGFloat bottomConstraint;

@property (nonatomic, strong) NSMutableArray *constraintArray;

@property (nonatomic, strong) NSLayoutConstraint *constraint;

@property (nonatomic, assign) BOOL resetBOOL;

@end

@implementation DLKeyboardManage

static DLKeyboardManage *keyboard = nil;

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(statusBarOrientationChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification  object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:[DLKeyboardManage shareInstance] selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    });
}

+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyboard = [[DLKeyboardManage alloc]_init];
        keyboard.resetBOOL = YES;
        keyboard.constraintArray = [[NSMutableArray alloc]init];
    });
    return keyboard;
}

//-(void)statusBarOrientationChanged:(NSNotification *)noti{
//    NSLog(@"11111");
//
//    [keyboard.fatherView dl_printConstraintsForSelf];
//
//    if (keyboard.fatherView) {
////        [keyboard.view resignFirstResponder];
////        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////            [keyboard.view becomeFirstResponder];
////        });
////        [keyboard.view setNeedsUpdateConstraints];
////        [keyboard.view updateConstraintsIfNeeded];
//
////        NSArray *array = keyboard.fatherView.constraints;
////        NSLog(@"%@", array);
//
////        [keyboard.fatherView.constraints enumerateObjectsUsingBlock:^(NSLayoutConstraint *obj, NSUInteger idx, BOOL * _Nonnull stop) {
////            NSLog(@"%@", obj);
////        }];
//
////        [keyboard.fatherView dl_printConstraintsForSelf];
//
////        [keyboard.f];
//
//    }
//}

-(void)keyboardWillShow:(NSNotification *)noti{
    CGSize keyboardSize = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    UIView *view = [UIResponder dl_currentFirstResponder];
    keyboard.view = view;
    if (view.singleMeView) {
        
    }else{
        if (keyboard.resetBOOL) {
            UIView *tempView;
            while (!tempView) {
                if ([NSStringFromClass([view.superview.superview class])isEqualToString:@"UIViewControllerWrapperView"]) {
                    tempView = view;
                }else{
                    view = view.superview;
                }
            }
            keyboard.fatherView = tempView;
        }
        keyboard.resetBOOL = NO;
        [keyboard.constraintArray removeAllObjects];
        [self dl_getConstraints];
        CGFloat tempHeight = [UIScreen mainScreen].bounds.size.height - view.y_dl - view.height_dl;
        if (tempHeight < keyboardSize.height) {
            
            NSLog(@"fatherView  ==  %@", keyboard.fatherView);
            
            [keyboard.fatherView dl_printConstraintsForSelf];
            
            keyboard.fatherView.dl_layout.bottom.offset(keyboardSize.height).install();
        }
    }
}

- (void)dl_getConstraints{
    NSArray<__kindof NSLayoutConstraint *> *constrain = keyboard.fatherView.constraints;
    NSArray<__kindof NSLayoutConstraint *> *superConstrain = keyboard.fatherView.superview.constraints;
    NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
    [array addObjectsFromArray:constrain];
    [array addObjectsFromArray:superConstrain];
    [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.firstItem == keyboard.fatherView) {
            [keyboard.constraintArray addObject:obj];
            if (obj.firstAttribute == NSLayoutAttributeBottom) {
                keyboard.constraint = obj;
            }
        }
    }];
}

-(void)keyboardWillHide:(NSNotification *)noti{
    UIView *view = [UIResponder dl_currentFirstResponder];
    if ([view isEqual:keyboard.view]) {
        keyboard.fatherView.dl_layout.bottom.remove();
        if (keyboard.constraintArray.count > 0) {
            [keyboard.constraint.secondItem addConstraint:keyboard.constraint];
        }
        [keyboard.constraintArray removeAllObjects];
        keyboard.resetBOOL = YES;
        keyboard.fatherView = nil;
        keyboard.view = nil;
    }
}

//-(void)keyboardDidHide:(NSNotification *)noti{
//    UIView *view = [UIResponder dl_currentFirstResponder];
//    view.frame = CGRectMake(50, 50, 100, 100);
//    NSLog(@"keyboardDidHide  ==  %@", [UIResponder dl_currentFirstResponder]);
//}

//-(void)keyboardDidShow:(NSNotification *)noti{
//    UIView *view = [UIResponder dl_currentFirstResponder];
//    view.frame = CGRectMake(50, 50, 100, 100);
//    NSLog(@"keyboardDidShow  ==  %@", [UIResponder dl_currentFirstResponder]);
//}

-(instancetype)_init{
    self = [super init];
    return self;
}

@end
