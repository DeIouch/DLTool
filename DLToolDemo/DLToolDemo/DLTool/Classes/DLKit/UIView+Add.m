#import "UIView+Add.h"
#import "NSObject+Add.h"
#import <objc/runtime.h>
#import "DLColor.h"
#import "DLAutoLayout.h"
#import "DLAlert.h"
#import "NSString+Add.h"
#import "DLSafeProtector.h"
#import "DLDownloadOperationManager.h"

@interface UIView()

@property (nonatomic, strong) NSString *touchIdentifierStr;

@property (nonatomic, strong) DLConstraintMaker *make;

/// 按钮点击间隔（防重复点击）
@property (nonatomic, assign) NSTimeInterval qi_eventInterval;

/// 当前的显示图片的地址
@property (nonatomic, copy)NSString *currentURLString;

@end

static char const autolayout_StrKey;

static char const identifierStrKey;

static char const touchIdentifierStrKey;

static char const qi_eventIntervalKey;

static char const kActionHandlerTapBlockKey;
static char const kActionHandlerTapGestureKey;
static char const kActionHandlerLongPressBlockKey;
static char const kActionHandlerLongPressGestureKey;

static char topNameKey;
static char rightNameKey;
static char bottomNameKey;
static char leftNameKey;


@implementation UIView (Add)

-(void)setMake:(DLConstraintMaker *)make{
    objc_setAssociatedObject(self, &autolayout_StrKey, make, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(DLConstraintMaker *)make{
    return objc_getAssociatedObject(self, &autolayout_StrKey);
}

+(instancetype)dl_view:(void (^) (UIView *view))block{
    UIView *view;
    @try {
        view = [[UIView alloc]init];
        view.userInteractionEnabled = YES;
        view.layer.drawsAsynchronously = true;
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

-(void)dl_AutoLayout:(void (^)(DLConstraintMaker *make))block{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if (!self.make) {
        self.make = [[DLConstraintMaker alloc]initWithView:self];
    }
    block(self.make);
    [self.make install];
}

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

-(instancetype)getCommonSuperView:(UIView *)view{
    UIView *commonSuperview = nil;
    UIView *secondViewSuperview = view;
    while (!commonSuperview && secondViewSuperview) {
        UIView *firstViewSuperview = self;
        while (!commonSuperview && firstViewSuperview) {
            if (secondViewSuperview == firstViewSuperview) {
                commonSuperview = secondViewSuperview;
            }
            firstViewSuperview = firstViewSuperview.superview;
        }
        secondViewSuperview = secondViewSuperview.superview;
    }
    return commonSuperview;
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

- (CGFloat)left_dl {
    return self.frame.origin.x;
}

- (void)setLeft_dl:(CGFloat)left_dl {
    CGRect frame = self.frame;
    frame.origin.x = left_dl;
    self.frame = frame;
}

- (CGFloat)top_dl {
    return self.frame.origin.y;
}

- (void)setTop_dl:(CGFloat)top_dl {
    CGRect frame = self.frame;
    frame.origin.y = top_dl;
    self.frame = frame;
}

- (CGFloat)right_dl {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight_dl:(CGFloat)right_dl {
    CGRect frame = self.frame;
    frame.origin.x = right_dl - frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom_dl {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom_dl:(CGFloat)bottom_dl {
    CGRect frame = self.frame;
    frame.origin.y = bottom_dl - frame.size.height;
    self.frame = frame;
}

#pragma mark -x
-(void)setX_dl:(CGFloat)x_dl{
    CGRect frame = self.frame;
    frame.origin.x = x_dl;
    self.frame = frame;
}
-(CGFloat)x_dl{
    return self.frame.origin.x;
}

#pragma mark -y
-(void)setY_dl:(CGFloat)y_dl{
    CGRect frame = self.frame;
    frame.origin.y = y_dl;
    self.frame = frame;
}
-(CGFloat)y_dl{
    return self.frame.origin.y;
}
#pragma mark -size
-(void)setSize_dl:(CGSize)size_dl{
    CGRect frame = self.frame;
    frame.size = size_dl;
    self.frame = frame;
}
-(CGSize)size_dl{
    return self.frame.size;
}
#pragma mark -origin
-(void)setOrigin_dl:(CGPoint)origin_dl{
    CGRect frame = self.frame;
    frame.origin = origin_dl;
    self.frame = frame;
}
-(CGPoint)origin_dl{
    return self.frame.origin;
}

#pragma mark -minX
-(CGFloat)minX_dl{
    
    return CGRectGetMinX(self.frame);
}
#pragma mark -minY

-(CGFloat)minY_dl{
    return CGRectGetMinY(self.frame);
}

#pragma mark-maxX
-(CGFloat)maxX_dl{
    return CGRectGetMaxX(self.frame);
}

#pragma mark-maxY
-(CGFloat)maxY_dl{
    return CGRectGetMaxY(self.frame);
}

#pragma mark -midX
-(CGFloat)midX_dl{
    return CGRectGetMidX(self.frame);
}
#pragma mark -midY
-(CGFloat)midY_dl{
    return CGRectGetMidY(self.frame);
}
#pragma mark -centerX
-(void)setCenterX_dl:(CGFloat)centerX_dl{
    CGPoint center = self.center;
    center.x = centerX_dl;
    self.center = center;
}
-(CGFloat)centerX_dl{
    return self.center.x;
}
#pragma mark -centerY
-(void)setCenterY_dl:(CGFloat)centerY_dl{
    CGPoint center = self.center;
    center.y = centerY_dl;
    self.center = center;
}
-(CGFloat)centerY_dl{
    return self.center.y;
}

#pragma maek - width
-(void)setWidth_dl:(CGFloat)width_dl{
    CGRect frame = self.frame;
    frame.size.width = width_dl;
    self.frame = frame;
}
-(CGFloat)width_dl{
    return CGRectGetWidth(self.frame);
}

#pragma maek - height
-(void)setHeight_dl:(CGFloat)height_dl{
    CGRect frame = self.frame;
    frame.size.height = height_dl;
    self.frame = frame;
}
-(CGFloat)height_dl{
    return CGRectGetHeight(self.frame);
}


#pragma mark UIKit
-(UIView *(^) (id color))dl_backColor{
    return ^(id color) {
        if ([color isNSArray]) {
            NSArray *colorArray = (NSArray *)color;
//            if (@available(iOS 13.0, *)) {
//                self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                        return [DLColor DLColorWithAHEXColor:(colorArray.count == 1) ? colorArray[0] : colorArray[1]];
//                    }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }
//                    return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                }];
//            }else{
                self.backgroundColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
//            };
        }else if ([color isNSString]) {
            NSString *colorStr = (NSString *)color;
//            if (@available(iOS 13.0, *)) {
//                self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }
//                    return [DLColor DLColorWithAHEXColor:colorStr];
//                }];
//            }else{
                self.backgroundColor = [DLColor DLColorWithAHEXColor:colorStr];
//            };
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

-(UIView *(^) (CGFloat radius))dl_topLeftCorner{
    return ^(CGFloat radius) {
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:(CGSize){radius}];
//        CAShapeLayer *shapeLayer = self.layer.mask ?  : [CAShapeLayer layer];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))dl_bottomLeftCorner{
    return ^(CGFloat radius) {
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomLeft cornerRadii:(CGSize){radius}];
//        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))dl_topRightCorner{
    return ^(CGFloat radius) {
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopRight cornerRadii:(CGSize){radius}];
//        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))dl_bottomRightCorner{
    return ^(CGFloat radius) {
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomRight cornerRadii:(CGSize){radius}];
//        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        return self;
    };
}

-(UIView *(^) (CGFloat radius))dl_allCorner{
    return ^(CGFloat radius) {
        [self layoutIfNeeded];
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerBottomRight | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:(CGSize){radius}];
//        CAShapeLayer *shapeLayer = self.layer.mask ?: [CAShapeLayer layer];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        shapeLayer.frame = self.bounds;
        self.layer.mask = shapeLayer;
        return self;
    };
}


-(UIView *)dl_viewShow{
    [self dl_cancelFadeOut];
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.hidden = NO;
    } completion:^(BOOL finished) {

    }];
    return self;
}

-(void)dl_viewHidden:(float)delay{
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

- (void)dl_cancelFadeOut
{
    [self setFadeSeeds:@(arc4random_uniform(1000))];
}

-(UIView *(^) (NSString *imageString))dl_urlReduceImageString{
    return ^(NSString *imageString){
        if ([NSStringFromClass([self class]) isEqualToString:@"UIImageView"]) {
            UIImageView *imageView = (UIImageView *)self;
            if (imageString.length > 0) {
                if (![imageString isEqualToString:self.currentURLString]) {
                    [[DLDownloadOperationManager sharedManager]cancelOperation:imageString];
                }
                self.currentURLString = imageString;
                [[DLDownloadOperationManager sharedManager]downloadWithUrlString:imageString imageView:imageView finishedBlock:^(UIImage *image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = image;
                    });
                }];
            }
        }
        return self;
    };
}

-(UIView *(^) (NSString *imageString))dl_urlImageString{
    return ^(NSString *imageString){
        if ([NSStringFromClass([self class]) isEqualToString:@"UIImageView"]) {
            UIImageView *imageView = (UIImageView *)self;
            if (imageString.length > 0) {
                if (![imageString isEqualToString:self.currentURLString] && self.currentURLString.length > 0) {
                    [[DLDownloadOperationManager sharedManager]cancelOperation:imageString];
                }
                self.currentURLString = imageString;
                [[DLDownloadOperationManager sharedManager]downloadWithUrlString:imageString imageView:nil finishedBlock:^(UIImage *image) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = image;
                    });
                }];
            }
        }
        return self;
    };
}

-(UIView *(^) (NSString *imageString))dl_imageString{
    return ^(NSString *imageString){
        if ([NSStringFromClass([self class]) isEqualToString:@"UIImageView"]) {
            UIImageView *imageView = (UIImageView *)self;
            if (!imageView.image) {
                imageView.image = [UIImage imageNamed:imageString];
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
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }] forState:UIControlStateNormal];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateNormal];
//                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }] forState:UIControlStateNormal];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateNormal];
//                };
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
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }] forState:UIControlStateSelected];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateSelected];
//                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }] forState:UIControlStateSelected];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateSelected];
//                };
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
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }] forState:UIControlStateHighlighted];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorArray[0]] forState:UIControlStateHighlighted];
//                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
//                if (@available(iOS 13.0, *)) {
//                    [button setTitleColor:[UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }] forState:UIControlStateHighlighted];
//                }else{
                    [button setTitleColor:[DLColor DLColorWithAHEXColor:colorStr] forState:UIControlStateHighlighted];
//                };
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
//                if (@available(iOS 13.0, *)) {
//                    label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }];
//                }else{
                    label.textColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
//                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
//                if (@available(iOS 13.0, *)) {
//                    label.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }];
//                }else{
                    label.textColor = [DLColor DLColorWithAHEXColor:colorStr];
//                };
            }
        }else if ([NSStringFromClass([self class]) isEqualToString:@"UITextView"]) {
            UITextView *textView = (UITextView *)self;
            if ([color isNSArray]) {
                NSArray *colorArray = (NSArray *)color;
//                if (@available(iOS 13.0, *)) {
//                    textView.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorArray.count > 1 ? colorArray[1] : colorArray[0]];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorArray[0]];
//                    }];
//                }else{
                    textView.textColor = [DLColor DLColorWithAHEXColor:colorArray[0]];
//                };
            }else if ([color isNSString]) {
                NSString *colorStr = (NSString *)color;
//                if (@available(iOS 13.0, *)) {
//                    textView.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                            return [DLColor DLColorWithAHEXColor:colorStr];
//                        }
//                        return [DLColor DLColorWithAHEXColor:colorStr];
//                    }];
//                }else{
                    textView.textColor = [DLColor DLColorWithAHEXColor:colorStr];
//                };
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

-(void)addClickAction:(void (^)(UIView *view))block{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kActionHandlerTapGestureKey);
    if (!gesture){
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleActionForTapGesture:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &kActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
    }
    objc_setAssociatedObject(self, &kActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

- (void)handleActionForTapGesture:(UITapGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateRecognized){
        void(^action)(UIView *view) = objc_getAssociatedObject(self, &kActionHandlerTapBlockKey);
        if (action){
            action(self);
            if (self.qi_eventInterval > 0) {
                self.userInteractionEnabled = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.qi_eventInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   self.userInteractionEnabled = YES;
               });
            }
        }
    }
}

- (void)handleActionForLongPressGesture:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan){
        void(^action)(UIView *view) = objc_getAssociatedObject(self, &kActionHandlerLongPressBlockKey);
        if (action){
            if (self.qi_eventInterval > 0) {
                self.userInteractionEnabled = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.qi_eventInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                   self.userInteractionEnabled = YES;
               });
            }
            action(self);
        }
    }
}

-(void)addLongClickAction:(void (^)(UIView *view))block{
    self.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *gesture = objc_getAssociatedObject(self, &kActionHandlerLongPressGestureKey);
    if (!gesture){
        gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleActionForLongPressGesture:)];
        [self addGestureRecognizer:gesture];
        objc_setAssociatedObject(self, &kActionHandlerLongPressGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
    }
    objc_setAssociatedObject(self, &kActionHandlerLongPressBlockKey, block, OBJC_ASSOCIATION_COPY);
}

-(UIView *(^)(NSTimeInterval time))dl_clickTime{
    return ^(NSTimeInterval time) {
        self.qi_eventInterval = time;
        return self;
    };
}

-(UIView *(^)(CGFloat size))dl_clickEdge{
    return ^(CGFloat size) {
        objc_setAssociatedObject(self, &topNameKey, [NSNumber numberWithFloat:size], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &rightNameKey, [NSNumber numberWithFloat:size], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &bottomNameKey, [NSNumber numberWithFloat:size], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &leftNameKey, [NSNumber numberWithFloat:size], OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

-(UIView *(^)(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left))dl_clickFrame{
    return ^(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left) {
        objc_setAssociatedObject(self, &topNameKey, [NSNumber numberWithFloat:top], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &rightNameKey, [NSNumber numberWithFloat:right], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &bottomNameKey, [NSNumber numberWithFloat:bottom], OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &leftNameKey, [NSNumber numberWithFloat:left], OBJC_ASSOCIATION_COPY_NONATOMIC);
        return self;
    };
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event{
    CGRect myBounds = self.bounds;
    NSNumber* topEdge = objc_getAssociatedObject(self, &topNameKey);
    NSNumber* rightEdge = objc_getAssociatedObject(self, &rightNameKey);
    NSNumber* bottomEdge = objc_getAssociatedObject(self, &bottomNameKey);
    NSNumber* leftEdge = objc_getAssociatedObject(self, &leftNameKey);
    myBounds.origin.x = myBounds.origin.x - leftEdge.floatValue;
    myBounds.origin.y = myBounds.origin.y - topEdge.floatValue;
    myBounds.size.width = myBounds.size.width + leftEdge.floatValue + rightEdge.floatValue;
    myBounds.size.height = myBounds.size.height + topEdge.floatValue + bottomEdge.floatValue;
    return CGRectContainsPoint(myBounds, point);
}

-(UIImage *)dl_snapshotImage{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

-(UIImage *)dl_snapshotImageAfterScreenUpdates:(BOOL)afterUpdates{
    if (![self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        return [self dl_snapshotImage];
    }
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:afterUpdates];
    UIImage *snap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snap;
}

-(NSData *)dl_snapshotPDF{
    CGRect bounds = self.bounds;
    NSMutableData* data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
    CGContextRef context = CGPDFContextCreate(consumer, &bounds, NULL);
    CGDataConsumerRelease(consumer);
    if (!context) return nil;
    CGPDFContextBeginPage(context, NULL);
    CGContextTranslateCTM(context, 0, bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    [self.layer renderInContext:context];
    CGPDFContextEndPage(context);
    CGPDFContextClose(context);
    CGContextRelease(context);
    return data;
}

-(CGPoint)dl_convertPoint:(CGPoint)point toViewOrWindow:(UIView *)view{
    if (!view) {
        if ([self isKindOfClass:[UIWindow class]]) {
            return [((UIWindow *)self) convertPoint:point toWindow:nil];
        } else {
            return [self convertPoint:point toView:nil];
        }
    }
    
    UIWindow *from = [self isKindOfClass:[UIWindow class]] ? (id)self : self.window;
    UIWindow *to = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    if ((!from || !to) || (from == to)) return [self convertPoint:point toView:view];
    point = [self convertPoint:point toView:from];
    point = [to convertPoint:point fromWindow:from];
    point = [view convertPoint:point fromView:to];
    return point;
}

-(CGPoint)dl_convertPoint:(CGPoint)point fromViewOrWindow:(UIView *)view{
    if (!view) {
        if ([self isKindOfClass:[UIWindow class]]) {
            return [((UIWindow *)self) convertPoint:point fromWindow:nil];
        } else {
            return [self convertPoint:point fromView:nil];
        }
    }
    
    UIWindow *from = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    UIWindow *to = [self isKindOfClass:[UIWindow class]] ? (id)self : self.window;
    if ((!from || !to) || (from == to)) return [self convertPoint:point fromView:view];
    point = [from convertPoint:point fromView:view];
    point = [to convertPoint:point fromWindow:from];
    point = [self convertPoint:point fromView:to];
    return point;
}

-(CGRect)dl_convertRect:(CGRect)rect toViewOrWindow:(UIView *)view{
    if (!view) {
        if ([self isKindOfClass:[UIWindow class]]) {
            return [((UIWindow *)self) convertRect:rect toWindow:nil];
        } else {
            return [self convertRect:rect toView:nil];
        }
    }
    
    UIWindow *from = [self isKindOfClass:[UIWindow class]] ? (id)self : self.window;
    UIWindow *to = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    if (!from || !to) return [self convertRect:rect toView:view];
    if (from == to) return [self convertRect:rect toView:view];
    rect = [self convertRect:rect toView:from];
    rect = [to convertRect:rect fromWindow:from];
    rect = [view convertRect:rect fromView:to];
    return rect;
}

-(CGRect)dl_convertRect:(CGRect)rect fromViewOrWindow:(UIView *)view{
    if (!view) {
        if ([self isKindOfClass:[UIWindow class]]) {
            return [((UIWindow *)self) convertRect:rect fromWindow:nil];
        } else {
            return [self convertRect:rect fromView:nil];
        }
    }
    
    UIWindow *from = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    UIWindow *to = [self isKindOfClass:[UIWindow class]] ? (id)self : self.window;
    if ((!from || !to) || (from == to)) return [self convertRect:rect fromView:view];
    rect = [from convertRect:rect fromView:view];
    rect = [to convertRect:rect fromWindow:from];
    rect = [self convertRect:rect fromView:to];
    return rect;
}

#pragma mark runtime set and get

-(void)setTouchIdentifierStr:(NSString *)touchIdentifierStr{
    objc_setAssociatedObject(self, &touchIdentifierStrKey, touchIdentifierStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)touchIdentifierStr{
    return objc_getAssociatedObject(self, &touchIdentifierStrKey);
}

-(void)setIdentifierStr:(NSString *)identifierStr{
    objc_setAssociatedObject(self, &identifierStrKey, identifierStr, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)identifierStr{
    return objc_getAssociatedObject(self, &identifierStrKey);
}

- (NSTimeInterval)qi_eventInterval {
    return [objc_getAssociatedObject(self, &qi_eventIntervalKey) doubleValue];
}

- (void)setQi_eventInterval:(NSTimeInterval)qi_eventInterval {
    objc_setAssociatedObject(self, &qi_eventIntervalKey, @(qi_eventInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCurrentURLString:(NSString *)currentURLString{
    objc_setAssociatedObject(self, @"currentURLString", currentURLString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)currentURLString{
    return  objc_getAssociatedObject(self, @"currentURLString");
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
        button = [[UIButton alloc]init];
        button.userInteractionEnabled = YES;
        button.layer.drawsAsynchronously = true;
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
        textField.layer.drawsAsynchronously = true;
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
        imageView.layer.drawsAsynchronously = true;
        imageView.contentMode = UIViewContentModeScaleAspectFit;
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
        label.layer.drawsAsynchronously = true;
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
        textView.layer.drawsAsynchronously = true;
        block(textView);
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewAsyncThread);
    } @finally {
        
    }
    return textView;
}

@end
