#import "UIView+Add.h"
#import "NSObject+Add.h"
#import <objc/runtime.h>
#import "DLColor.h"
#import "DLAutoLayout.h"
#import "DLAlert.h"
#import "NSString+Add.h"
#import "DLSafeProtector.h"

//static NSString *target_key = @"target_key";

static const int target_key;

@interface DLViewCategoryTarget : NSObject

@property (nonatomic, copy) void (^tapBlock)(void);

@property (nonatomic, strong) UIView *view;

-(instancetype)initWithBlock:(void (^)(void))block;

-(void)tapAction;

@end

@implementation DLViewCategoryTarget

-(instancetype)initWithBlock:(void (^)(void))block{
    if (self = [super init]) {
        _tapBlock = [block copy];
    }
    return self;
}

- (void)tapAction{
    if (self.tapBlock) {
        self.tapBlock();
    }
}

@end

@interface UIView()

@property (nonatomic, assign) NSTimeInterval touchInterval;

@property (nonatomic, assign) CGFloat topClick;

@property (nonatomic, assign) CGFloat rightClick;

@property (nonatomic, assign) CGFloat bottomClick;

@property (nonatomic, assign) CGFloat leftClick;

@property (nonatomic, strong) NSString *touchIdentifierStr;

@end

static NSString *identifierStrKey = @"identifierStrKey";

static NSString *touchIntervalKey = @"touchIntervalKey";

static NSString *kActionHandlerTapBlockKey = @"kActionHandlerTapBlockKey";

static NSString *kActionHandlerTapGestureKey = @"kActionHandlerTapGestureKey";

static NSString *classStrKey = @"classStrKey";

static NSString *topClickKey = @"topClickKey";

static NSString *rightClickKey = @"rightClickKey";

static NSString *bottomClickKey = @"bottomClickKey";

static NSString *leftClickKey = @"leftClickKey";

static NSString *touchIdentifierStrKey = @"touchIdentifierStrKey";

@implementation UIView (Add)

-(void)setClickAction:(void (^)(void))tapBlock{
    DLViewCategoryTarget *target = [[DLViewCategoryTarget alloc]initWithBlock:tapBlock];
//    target.tapBlock = [tapBlock copy];
    objc_setAssociatedObject(self, &target_key, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UITapGestureRecognizer *tap;
    for (UIGestureRecognizer *gestss in self.gestureRecognizers) {
        if ([NSStringFromClass([gestss class]) isEqualToString:@"UITapGestureRecognizer"]) {
            tap = (UITapGestureRecognizer *)gestss;
        }
    }
    if (!tap) {
        tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(tapAction)];
        [self addGestureRecognizer:tap];
    }
}

-(void (^)(void))clickAction{
    DLViewCategoryTarget *target = objc_getAssociatedObject(self, &target_key);
    return target.tapBlock;
}

+(instancetype)dl_view:(void (^) (UIView *view))block{
    UIView *view;
    @try {
        view = [[UIView alloc]init];
        view.userInteractionEnabled = YES;
        view.classStr = @"UIView";
        block(view);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return view;
}

-(BOOL)isEmptySuperView{
    BOOL isEmpty = NO;
    NSString *superViewStr = NSStringFromClass([self.superview class]);
    if (superViewStr.length == 0) {
//        [[DLAlert shareInstance]alertMessage:[NSString stringWithFormat:@"%@没有父视图", [NSString stringWithUTF8String:object_getClassName(self)]] cancelTitle:@"取消" sureTitle:@"确定" sureBlock:nil];
//        NSLog(@"%@", [NSString stringWithFormat:@"%@没有父视图", [NSString stringWithUTF8String:object_getClassName(self)]]);
        isEmpty = YES;
        NSAssert(self.superview, @"请先添加superview %@", self);
    }
    return isEmpty;
}

#pragma mark autoLayout

-(UIView *(^) (UIView *view,CGFloat constant))dl_left_to_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeLeft]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_leftEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_leftEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_right_to_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeRight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_rightEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_rightEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_top_to_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeTop]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_topEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_topEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_bottom_to_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeBottom]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_bottomEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_bottomEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_left_by_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeLeft]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_leftByView(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_leftByView(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_right_by_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeRight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_rightByView(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_rightByView(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_top_by_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeTop]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_topByView(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_topByView(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_bottom_by_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeBottom]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_bottomByView(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_bottomByView(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_width_equal_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeWidth]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_widthEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_widthEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_height_equal_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeHeight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_heightEqualTo(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_heightEqualTo(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_width_multiplier_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeWidth]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_widthEqualTo(view).multiplier(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_widthEqualTo(view).multiplier(constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_height_multiplier_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeHeight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_heightEqualTo(view).multiplier(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_heightEqualTo(view).multiplier(constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (CGFloat constant))dl_width_layout{
    return ^(CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeWidth]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_width(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_width(constant);
            }];
        }
        return self;
    };
}

-(void)dl_remove_allLayout{
    NSArray<__kindof NSLayoutConstraint *> *constrain = self.constraints;
    NSArray<__kindof NSLayoutConstraint *> *superConstrain = self.superview.constraints;
    NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
    [array addObjectsFromArray:constrain];
    [array addObjectsFromArray:superConstrain];
    [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.firstItem == self) {
            [self.superview removeConstraint:obj];
        }
    }];
    [self removeConstraints:constrain];
    [self dl_printConstraintsForSelf];
}

//-(UIView *(^) (void))dl_remove_allLayout{
//    return ^(void){
//        if ([self isEmptySuperView]) {
//            return self;
//        }
//
//        NSArray<__kindof NSLayoutConstraint *> *constrain = self.constraints;
//        NSArray<__kindof NSLayoutConstraint *> *superConstrain = self.superview.constraints;
//        NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
//        [array addObjectsFromArray:constrain];
//        [array addObjectsFromArray:superConstrain];
//        [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            if (obj.firstItem == self) {
//                [self.superview removeConstraint:obj];
//            }
//        }];
//        [self removeConstraints:constrain];
//        [self dl_printConstraintsForSelf];
//
//        return self;
//    };
//}

-(UIView *(^) (CGFloat constant))dl_height_layout{
    return ^(CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeHeight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_height(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_height(constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (CGFloat constant))dl_width_GreaterThanOrEqual_layout{
    return ^(CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeWidth]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_widthGreaterThanOrEqual(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_widthGreaterThanOrEqual(constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (CGFloat constant))dl_height_GreaterThanOrEqual_layout{
    return ^(CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeHeight]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_heightGreaterThanOrEqual(constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_heightGreaterThanOrEqual(constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_centerX_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeCenterX]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_centerX(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_centerX(view, constant);
            }];
        }
        return self;
    };
}

-(UIView *(^) (UIView *view,CGFloat constant))dl_centerY_layout{
    return ^(UIView *view,CGFloat constant){
        if ([self isEmptySuperView]) {
            return self;
        }
        if ([self dl_autoLayoutsForSelf:NSLayoutAttributeCenterY]) {
            [self dl_updateAutoLayouts:^{
                dl_layout_centerY(view, constant);
            }];
        }else{
            [self dl_addAutoLayouts:^{
                dl_layout_centerY(view, constant);
            }];
        }
        return self;
    };
}

-(CGFloat)dl_fittingHeight:(UIView *)view{
    return [self dl_fittingHeightWithSubview:view];
}

-(CGFloat)dl_fittingWidth:(UIView *)view{
    return [self dl_fittingWidth:view];
}


#pragma mark UIKit
-(UIView *(^) (id color))dl_backColor{
    return ^(id color) {
        if ([color isNSArray]) {
            NSArray *colorArray = (NSArray *)color;
            if (@available(iOS 13.0, *)) {
                self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                        return [DLColor DLColorWithAHEXColor:(colorArray.count == 1) ? colorArray[0] : colorArray[1]];
                    }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }
                    return [DLColor DLColorWithAHEXColor:colorArray[0]];
                }];
            }else{
                self.backgroundColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
            };
        }else if ([color isNSString]) {
            NSString *colorStr = (NSString *)color;
            if (@available(iOS 13.0, *)) {
                self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }
                    return [DLColor DLColorWithAHEXColor:colorStr];
                }];
            }else{
                self.backgroundColor = [DLColor DLColorWithAHEXColor:colorStr];
            };
        }
        return self;
    };
}

-(UIView *(^) (UIView *view))dl_backView{
    return ^(UIView *view) {
        [view addSubview:self];
        return self;
    };
}

-(UIView *(^) (CGFloat radius))topLeftCorner{
    return ^(CGFloat radius) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:(CGSize){radius}];
        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))bottomLeftCorner{
    return ^(CGFloat radius) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomLeft cornerRadii:(CGSize){radius}];
        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))topRightCorner{
    return ^(CGFloat radius) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopRight cornerRadii:(CGSize){radius}];
        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))bottomRightCorner{
    return ^(CGFloat radius) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomRight cornerRadii:(CGSize){radius}];
        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))allCorner{
    return ^(CGFloat radius) {
//        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomRight | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:(CGSize){radius}];
        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        shapeLayer.frame = self.bounds;
        self.layer.mask = shapeLayer;
        return self;
    };
}

//-(void)setClickAction:(void (^)(UIView *))clickAction{
//    UITapGestureRecognizer *tap;
//    for (UIGestureRecognizer *gestss in self.gestureRecognizers) {
//        if ([NSStringFromClass([gestss class]) isEqualToString:@"UITapGestureRecognizer"]) {
//            tap = (UITapGestureRecognizer *)gestss;
//        }
//    }
//    if (!tap) {
//        tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGest)];
//        [self addGestureRecognizer:tap];
//    }
//    objc_setAssociatedObject(self, &kActionHandlerTapBlockKey, clickAction, OBJC_ASSOCIATION_COPY_NONATOMIC);
//}
//
//-(void (^)(UIView *))clickAction{
//    return objc_getAssociatedObject(self, &kActionHandlerTapBlockKey);
//}
//
//-(void)tapGest{
//    if (self.clickAction) {
//        self.clickAction(self);
//    }
//}

//- (void)addTapGestureActionWithBlock:(void (^)(UITapGestureRecognizer *))block{
//    UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kActionHandlerTapGestureKey);
//    if (!gesture){
//        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleActionForTapGesture)];
//        [self addGestureRecognizer:gesture];
//        objc_setAssociatedObject(self, &kActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
//    }
//    objc_setAssociatedObject(self, &kActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

//- (void)handleActionForTapGesture{
////    void(^action)(UIView *view) = self.clickAction;
////    if (action){
////        action(self);
////        self.userInteractionEnabled = NO;
////        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.touchInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////            self.userInteractionEnabled = YES;
////        });
////    }
//}

//- (void)addLongPressGestureActionWithBlock:(void (^)(UILongPressGestureRecognizer *))block{
//    self.userInteractionEnabled = YES;
//    UILongPressGestureRecognizer *gesture = objc_getAssociatedObject(self, &kActionHandlerLongPressGestureKey);
//    if (!gesture){
//        gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleActionForLongPressGesture:)];
//        [self addGestureRecognizer:gesture];
//        objc_setAssociatedObject(self, &kActionHandlerLongPressGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
//    }
//    objc_setAssociatedObject(self, &kActionHandlerLongPressBlockKey, block, OBJC_ASSOCIATION_COPY);
//}
//
//- (void)handleActionForLongPressGesture:(UILongPressGestureRecognizer *)gesture{
//    if (gesture.state == UIGestureRecognizerStateBegan){
//        void(^action)(UILongPressGestureRecognizer *longPressAction) = objc_getAssociatedObject(self, &kActionHandlerLongPressBlockKey);
//        if (action){
//            action(gesture);
//        }
//    }
//}

-(UIView *)viewShow{
    [self cancelFadeOut];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hidden = NO;
    } completion:^(BOOL finished) {

    }];
    return self;
}

-(void)viewHidden:(NSInteger)delay{
    int seeds = [self.fadeSeeds intValue];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (seeds == [self.fadeSeeds intValue]) {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.hidden = YES;
            } completion:^(BOOL finished) {
                
            }];
        }
    });
}

- (NSNumber *)fadeSeeds{
    return objc_getAssociatedObject(self, @selector(fadeSeeds));
}

- (void)setFadeSeeds:(NSNumber *)seeds{
    objc_setAssociatedObject(self, @selector(fadeSeeds), seeds, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cancelFadeOut
{
    [self setFadeSeeds:@(arc4random_uniform(1000))];
}



-(UIView *(^) (NSString *imageString))dl_imageString{
    return ^(NSString *imageString){
        if ([NSStringFromClass([self class]) isEqualToString:@"UIImageView"]) {
            UIImageView *imageView = (UIImageView *)self;
            if (imageString.length > 0) {
                if ([imageString containsString:@"http"]) {
                    
                } else{
                    imageView.image = [UIImage imageNamed:imageString];
                }
            }
        }
        return self;
    };
}

-(UIView *(^)(NSString *title))dl_normalTitle{
    return ^(NSString *title) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setTitle:title forState:UIControlStateNormal];
        }
        return self;
    };
}

-(UIView *(^)(NSString *title))dl_selectTitle{
    return ^(NSString *title) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setTitle:title forState:UIControlStateSelected];
        }
        return self;
    };
}

-(UIView *(^)(NSString *title))dl_highlightTitle{
    return ^(NSString *title) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setTitle:title forState:UIControlStateHighlighted];
        }
        return self;
    };
}

-(UIView *(^)(CGFloat fontSize))dl_fontSize{
    return ^(CGFloat fontSize) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        } else if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            label.font = [UIFont systemFontOfSize:fontSize];
        } else if ([NSStringFromClass([self class]) isEqualToString:@"UITextView"]) {
            UITextView *textView = (UITextView *)self;
            textView.font = [UIFont systemFontOfSize:fontSize];
        }
        return self;
    };
}

-(UIView *(^)(NSString *image))dl_normalImage{
    return ^(NSString *image) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        }
        return self;
    };
}

-(UIView *(^)(NSString *image))dl_selectImage{
    return ^(NSString *image) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setImage:[UIImage imageNamed:image] forState:UIControlStateSelected];
        }
        return self;
    };
}

-(UIView *(^)(NSString *image))dl_highlightImage{
    return ^(NSString *image) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            [button setImage:[UIImage imageNamed:image] forState:UIControlStateHighlighted];
        }
        return self;
    };
}

-(UIView *(^)(id color))dl_normalTitleColor{
    return ^(id color) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
                        }
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }] forState:UIControlStateNormal];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateNormal];
                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }] forState:UIControlStateNormal];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateNormal];
                };
            }
        }
        return self;
    };
}

-(UIView *(^)(id color))dl_selectTitleColor{
    return ^(id color) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
                        }
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }] forState:UIControlStateSelected];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateSelected];
                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }] forState:UIControlStateSelected];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateSelected];
                };
            }
        }
        return self;
    };
}

-(UIView *(^)(id color))dl_highlightTitleColor{
    return ^(id color) {
        if ([NSStringFromClass([self class]) isEqualToString:@"UIButton"]) {
            UIButton *button = (UIButton *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
                        }
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }] forState:UIControlStateHighlighted];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateHighlighted];
                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
                if (@available(iOS 13.0, *)) {
                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }] forState:UIControlStateHighlighted];
                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateHighlighted];
                };
            }
        }
        return self;
    };
}

-(UIView *(^) (NSString *title))dl_text{
    return ^(NSString *title){
        if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            label.text = title;
        }else if ([NSStringFromClass([self class]) isEqualToString:@"UITextView"]) {
            UITextView *textView = (UITextView *)self;
            textView.text = title;
        }
        return self;
    };
}

-(UIView *(^) (id color))dl_textColor{
    return ^(id color){
        if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
                if (@available(iOS 13.0, *)) {
                    label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
                        }
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }];
                }else{
                    label.textColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
                if (@available(iOS 13.0, *)) {
                    label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }];
                }else{
                    label.textColor = [DLColor DLColorWithAHEXColor:colorStr];
                };
            }
        }else if ([NSStringFromClass([self class]) isEqualToString:@"UITextView"]) {
            UITextView *textView = (UITextView *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
                if (@available(iOS 13.0, *)) {
                    textView.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
                        }
                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
                    }];
                }else{
                    textView.textColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
                if (@available(iOS 13.0, *)) {
                    textView.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
                            return [DLColor DLColorWithAHEXColor:colorStr];
                        }
                        return [DLColor DLColorWithAHEXColor:colorStr];
                    }];
                }else{
                    textView.textColor = [DLColor DLColorWithAHEXColor:colorStr];
                };
            }
        }
        return self;
    };
}

-(UIView *(^) (NSTextAlignment alignment))dl_alignment{
    return ^(NSTextAlignment alignment){
        if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            label.textAlignment = alignment;
        }else if ([NSStringFromClass([self class]) isEqualToString:@"UITextView"]) {
            UITextView *textView = (UITextView *)self;
            textView.textAlignment = alignment;
        }
        return self;
    };
}

-(UIView *(^) (NSInteger lines))dl_lines{
    return ^(NSInteger lines){
        if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            label.numberOfLines = lines;
        }
        return self;
    };
}

-(UIView *(^) (CGFloat speed))dl_animationSpeed{
    return ^(CGFloat speed){
        if ([NSStringFromClass([self class]) isEqualToString:@"UILabel"]) {
            UILabel *label = (UILabel *)self;
            UIView *superView = [label superview];
            [superView layoutIfNeeded];
            [label layoutIfNeeded];
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.path = [UIBezierPath bezierPathWithRect:superView.bounds].CGPath;
            superView.layer.mask = maskLayer;
            CGFloat labelWidth = [label.text sizeWithAttributes:@{NSFontAttributeName:label.font}].width;
            if (labelWidth > superView.frame.size.width) {
                [label dl_remove_allLayout];
                label.translatesAutoresizingMaskIntoConstraints = YES;
                label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, labelWidth, label.frame.size.height > 0 ? label.frame.size.height : superView.frame.size.height);
                label.lineBreakMode = NSLineBreakByWordWrapping;
                [label.layer removeAllAnimations];
                CGFloat space = labelWidth - superView.frame.size.width;
                CAKeyframeAnimation *keyFrameAnimation = [CAKeyframeAnimation animation];
                keyFrameAnimation.keyPath = @"transform.translation.x";
                keyFrameAnimation.values = @[@(0), @(-space)];
                keyFrameAnimation.repeatCount = MAXFLOAT;
                keyFrameAnimation.duration = speed * label.text.length;
                keyFrameAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithControlPoints:0 :0 :0.5 :0.5]];
                [label.layer addAnimation:keyFrameAnimation forKey:nil];
            }
        }
        return self;
    };
}

-(UIView *(^)(NSTimeInterval time))dl_clickTime{
    return ^(NSTimeInterval time) {
        
        
        
        self.touchInterval = time;
        return self;
    };
}

-(UIView *(^)(CGFloat size))dl_clickEdge{
    return ^(CGFloat size) {
        self.leftClick = size;
        self.rightClick = size;
        self.topClick = size;
        self.bottomClick = size;
        return self;
    };
}

-(UIView *(^)(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left))dl_clickFrame{
    return ^(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left) {
        self.leftClick = left;
        self.rightClick = right;
        self.topClick = top;
        self.bottomClick = bottom;
        return self;
    };
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event{
    CGRect myBounds = self.bounds;
    myBounds.origin.x = myBounds.origin.x - self.leftClick;
    myBounds.origin.y = myBounds.origin.y - self.topClick;
    myBounds.size.width = myBounds.size.width + self.leftClick + self.rightClick;
    myBounds.size.height = myBounds.size.height + self.topClick + self.bottomClick;
    return CGRectContainsPoint(myBounds, point);
}

#pragma mark runtime set and get

-(void)setTouchIdentifierStr:(NSString *)touchIdentifierStr{
    objc_setAssociatedObject(self, &touchIdentifierStrKey, touchIdentifierStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)touchIdentifierStr{
    return objc_getAssociatedObject(self, &touchIdentifierStrKey);
}

-(void)setLeftClick:(CGFloat)leftClick{
    objc_setAssociatedObject(self, &leftClickKey, @(leftClick), OBJC_ASSOCIATION_ASSIGN);
}

-(CGFloat)leftClick{
    return [objc_getAssociatedObject(self, &leftClickKey) floatValue];
}

-(void)setRightClick:(CGFloat)rightClick{
    objc_setAssociatedObject(self, &rightClickKey, @(rightClick), OBJC_ASSOCIATION_ASSIGN);
}

-(CGFloat)rightClick{
    return [objc_getAssociatedObject(self, &rightClickKey) floatValue];
}

-(void)setTopClick:(CGFloat)topClick{
    objc_setAssociatedObject(self, &topClickKey, @(topClick), OBJC_ASSOCIATION_ASSIGN);
}

-(CGFloat)topClick{
    return [objc_getAssociatedObject(self, &topClickKey) floatValue];
}

-(void)setBottomClick:(CGFloat)bottomClick{
    objc_setAssociatedObject(self, &bottomClickKey, @(bottomClick), OBJC_ASSOCIATION_ASSIGN);
}

-(CGFloat)bottomClick{
    return [objc_getAssociatedObject(self, &bottomClickKey) floatValue];
}

-(void)setTouchInterval:(NSTimeInterval)touchInterval{
    objc_setAssociatedObject(self, &touchIntervalKey, @(touchInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSTimeInterval)touchInterval{
    return [objc_getAssociatedObject(self, &touchIntervalKey) doubleValue];
}

-(void)setClassStr:(NSString *)classStr{
    objc_setAssociatedObject(self, &classStrKey, classStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)classStr{
    return objc_getAssociatedObject(self, &classStrKey);
}

-(void)setIdentifierStr:(NSString *)identifierStr{
    objc_setAssociatedObject(self, &identifierStrKey, identifierStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)identifierStr{
    return objc_getAssociatedObject(self, &identifierStrKey);
}

@end


@implementation DefaulterImage : UIImage

+(UIImage *)createDefaulterImage:(UIImageView *)imageView{
    imageView.image = [UIImage imageNamed:@"defaulteImage"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIGraphicsBeginImageContext(imageView.bounds.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [imageView.layer renderInContext:ctx];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end


@implementation UIButton (Add)

+(instancetype)dl_view:(void (^) (UIButton *button))block{
    UIButton *button;
    @try {
        UIButton *button = [[UIButton alloc]init];
        button.userInteractionEnabled = YES;
        button.classStr = @"UIButton";
        block(button);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return button;
}

@end

@implementation UITextField (Add)

+(instancetype)dl_view:(void (^) (UITextField *textField))block{
    UITextField *textField;
    @try {
        textField = [[UITextField alloc]init];
        textField.userInteractionEnabled = YES;
        textField.classStr = @"UITextField";
        block(textField);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return textField;
}

@end

@implementation UIImageView (Add)

+(instancetype)dl_view:(void (^) (UIImageView *imageView))block{
    UIImageView *imageView;
    @try {
        imageView = [[UIImageView alloc]init];
        imageView.userInteractionEnabled = YES;
        imageView.classStr = @"UIImageView";
        block(imageView);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return imageView;
}

@end

@implementation UILabel (Add)

+(instancetype)dl_view:(void (^) (UILabel *label))block{
    UILabel *label;
    @try {
        label = [[UILabel alloc]init];
        label.userInteractionEnabled = YES;
        label.classStr = @"UILabel";
        block(label);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return label;
}

@end

@implementation UITextView (Add)

+(instancetype)dl_view:(void (^) (UITextView *textView))block{
    UITextView *textView;
    @try {
        textView = [[UITextView alloc]init];
        textView.userInteractionEnabled = YES;
        textView.classStr = @"UITextView";
        block(textView);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return textView;
}

@end
