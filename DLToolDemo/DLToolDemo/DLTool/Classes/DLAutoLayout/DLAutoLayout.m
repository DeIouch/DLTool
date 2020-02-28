#import "DLAutoLayout.h"
#import "DLSafeProtector.h"
#import <objc/runtime.h>

#pragma mark - NSLayoutAttribute convert string

NSString* p_dl_layoutAttributeString(NSLayoutAttribute attribute) {
    NSString *attributeString;
#define enumToString(value) case value : attributeString = @#value; break;
    switch (attribute) {
            enumToString(NSLayoutAttributeLeft)
            enumToString(NSLayoutAttributeRight)
            enumToString(NSLayoutAttributeTop)
            enumToString(NSLayoutAttributeBottom)
            enumToString(NSLayoutAttributeLeading)
            enumToString(NSLayoutAttributeTrailing)
            enumToString(NSLayoutAttributeWidth)
            enumToString(NSLayoutAttributeHeight)
            enumToString(NSLayoutAttributeCenterX)
            enumToString(NSLayoutAttributeCenterY)
        default:
            enumToString(NSLayoutAttributeNotAnAttribute)
    }
#undef enumToString
    return attributeString;
}

#pragma mark - end NSLayoutAttribute convert string

static NSString * const kDLAutoLayoutMakerAdd       = @"DLAutoLayoutMakerAdd-dl";
static NSString * const kDLAutoLayoutMakerUpdate    = @"DLAutoLayoutMakerUpdate-dl";
static NSString * const kDLAttributeKey             = @"DLAttributeKey-dl";

static NSString * const kDLAutoLayoutForArrayObject = @"kDLAutoLayoutForArrayObject-dl";
static void * kDLAutoLayoutForArrayKey              = &kDLAutoLayoutForArrayKey;

static NSString * const kDLAutoLayoutForArrayForLockObject = @"kDLAutoLayoutForArrayForLockObject-dl";
static void * kDLAutoLayoutForArrayForLockKey              = &kDLAutoLayoutForArrayForLockKey;

#pragma mark - private category of array

@interface NSArray (DLPrivateOfAutoLayout)

- (NSArray *)distinctUnionOfObjects;

@end

@implementation NSArray (DLPrivateOfAutoLayout)

- (NSArray *)distinctUnionOfObjects {
    return [self valueForKeyPath:@"@distinctUnionOfObjects.self"];
}

@end

#pragma mark - DLStackView class

@implementation DLStackView

- (void)layoutWithType:(DLStackViewType)type {
    NSInteger subviewCount = self.subviews.count;
    
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj dl_addConstraints:^(DLAutoLayoutMaker *layout) {
            if (type == DLStackViewTypeHorizontal) { //水平
                if (!idx) {
                    layout.leftSpace(self.padding.left);
                }
                else {
                    layout.leftSpaceByView(self.subviews[idx - 1],self.space);
                }
                if (subviewCount - 1 == idx) {
                    layout.rightSpace(self.padding.right);
                }
                else {
                    layout.widthEqualTo(self.subviews[idx + 1],0);
                }
                layout.topSpace(self.padding.top);
                layout.bottomSpace(self.padding.bottom);
            }
            else if (type == DLStackViewTypeVertical) { //垂直
                if (!idx) {
                    layout.topSpace(self.padding.top);
                }
                else {
                    layout.topSpaceByView(self.subviews[idx - 1],self.space);
                }
                
                if (subviewCount - 1 == idx) {
                    layout.bottomSpace(self.padding.bottom);
                }
                else {
                    layout.heightEqualTo(self.subviews[idx + 1],0);
                }
                layout.leftSpace(self.padding.left);
                layout.rightSpace(self.padding.right);
            }
        }];
    }];
    
}

@end

#pragma mark - DLAutoLayoutFactory class

@interface DLAutoLayoutFactory ()

@property (nonatomic, assign) CGFloat            layoutConstant;
@property (nonatomic, assign) UILayoutPriority   layoutPriority;
@property (nonatomic, assign) NSLayoutAttribute  layoutFirstAttribute;
@property (nonatomic, assign) NSLayoutAttribute  layoutSecondAttribute;
@property (nonatomic, assign) CGFloat            layoutMultiplierValue;
@property (nonatomic, assign) BOOL               layoutAutoHeight;
@property (nonatomic, assign) BOOL               layoutAutoWidth;
@property (nonatomic,strong ) UIView             *layoutSecondView;
@property (nonatomic,copy   ) NSArray<DLAutoLayoutFactory *> *layoutCenters;
@property (nonatomic,copy   ) NSArray<DLAutoLayoutFactory *> *layoutInsets;
@property (nonatomic,strong) DLAutoLayoutMaker *marker;

@property (nonatomic, assign) BOOL               widthEqualToHeight;
@property (nonatomic, assign) BOOL               heightEqualToWidth;

+ (void)p_layoutMakerLockWithBlock:(void(^)(void))block;

@end

#pragma mark - DLAutoLayoutMaker class

@interface DLAutoLayoutMaker ()

@property (nonatomic,strong) NSMutableArray *constraintAttributes;

@property (nonatomic,strong) NSMutableArray<NSLayoutConstraint *> *tempRelatedConstraints;

@property (nonatomic,strong) UIView *view;
@property (nonatomic,strong) NSLayoutConstraint *lastConstraint;
@property (nonatomic,copy) NSString *layoutType;

@end

@implementation DLAutoLayoutMaker

+ (void)load {
    
    //-------- 已废弃, 保留1.0之前的api实现 --------
    NSMutableArray<NSString *> *layoutAttributeStringList = [NSMutableArray array];
    NSMutableArray<NSNumber *> *layoutAttributeValueList = [NSMutableArray array];
#define enumToString(value) [layoutAttributeStringList addObject:@#value]; \
[layoutAttributeValueList addObject:@(value)];
    enumToString(NSLayoutAttributeLeft)
    enumToString(NSLayoutAttributeRight)
    enumToString(NSLayoutAttributeTop)
    enumToString(NSLayoutAttributeBottom)
    enumToString(NSLayoutAttributeLeading)
    enumToString(NSLayoutAttributeTrailing)
    enumToString(NSLayoutAttributeWidth)
    enumToString(NSLayoutAttributeHeight)
    enumToString(NSLayoutAttributeCenterX)
    enumToString(NSLayoutAttributeCenterY)
#undef enumToString
    
    objc_setAssociatedObject([self class], @selector(swizzleMethodForAttribute),
                             @{@"keys":layoutAttributeStringList,
                               @"values":layoutAttributeValueList},
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    NSArray<NSString *> *methods = @[NSStringFromSelector(@selector(top)),
                                     NSStringFromSelector(@selector(left)),
                                     NSStringFromSelector(@selector(bottom)),
                                     NSStringFromSelector(@selector(right)),
                                     NSStringFromSelector(@selector(width)),
                                     NSStringFromSelector(@selector(height)),
                                     NSStringFromSelector(@selector(centerX)),
                                     NSStringFromSelector(@selector(centerY)),
                                     NSStringFromSelector(@selector(center))];
    
    [methods enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL aSel = NSSelectorFromString(obj);
        method_setImplementation(
                                 class_getInstanceMethod(DLAutoLayoutMaker.class,aSel),
                                 class_getMethodImplementation(DLAutoLayoutMaker.class, @selector(swizzleMethodForAttribute)));
    }];
    //---------- 以上是已废弃的代码, 保留1.0之前的api实现 --------------
}

#pragma mark - swizzle
/**
 *  @author coffee
 *
 *  @brief 已废弃,保留1.0之前的api接口实现
 *
 *  @return self
 */
- (id)swizzleMethodForAttribute  __deprecated_msg("过期") {
    
    NSString *methodName = NSStringFromSelector(_cmd);
    if ([methodName isEqualToString:@"center"]) {
        return self.centerByView(self.view.superview,0);
    }
    
    //remove tempRelatedConstraints
    [self.tempRelatedConstraints removeAllObjects];
    
    //get data for attributes
    NSDictionary *attributeData = objc_getAssociatedObject([self class], @selector(swizzleMethodForAttribute));
    NSMutableArray<NSString *> *layoutAttributeStringList = attributeData[@"keys"];
    NSMutableArray<NSNumber *> *layoutAttributeValueList = attributeData[@"values"];
    
    //get attribute for this
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self endswith[c] %@",methodName];
    NSString *layoutAttributeString = [layoutAttributeStringList filteredArrayUsingPredicate:predicate].firstObject;
    NSUInteger index = [layoutAttributeStringList indexOfObject:layoutAttributeString];
    
    //add constraints attribute
    [self.constraintAttributes addObject:layoutAttributeValueList[index]];
    
    return self;
}

#pragma mark - public

- (instancetype)initWithView:(UIView *)view type:(id)type {
    
    if (self = [super init]) {
        
        self.constraintAttributes = [NSMutableArray array];
        self.tempRelatedConstraints = [NSMutableArray array];
        
        self.view = view;
        self.layoutType = type;
        self.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    return self;
}

#pragma mark 设置在superview里的距离

- (DLAutoLayoutMaker *(^)(CGFloat))topSpace {
    return ^(CGFloat value) {
        return [self p_addOrUpdateSpaceInSuperview:NSLayoutAttributeTop constant:value];
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))leftSpace {
    return ^(CGFloat value) {
        return [self p_addOrUpdateSpaceInSuperview:NSLayoutAttributeLeft constant:value];
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))bottomSpace {
    return ^(CGFloat value) {
        return [self p_addOrUpdateSpaceInSuperview:NSLayoutAttributeBottom constant:value];
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))rightSpace {
    return ^(CGFloat value) {
        return [self p_addOrUpdateSpaceInSuperview:NSLayoutAttributeRight constant:value];
    };
}

- (DLAutoLayoutMaker *(^)(UIEdgeInsets))edgeInsets {
    return ^(UIEdgeInsets edge) {
        return self.topSpace(edge.top).leftSpace(edge.left).bottomSpace(edge.bottom).rightSpace(edge.right);
    };
}

- (DLAutoLayoutMaker *(^)(UIView *))edgeEqualTo {
    return ^(UIView *view) {
        return self.topSpaceEqualTo(view,0).leftSpaceEqualTo(view,0).bottomSpaceEqualTo(view,0).rightSpaceEqualTo(view,0);
    };
}

#pragma mark 居中

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))xCenterByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeCenterX multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))yCenterByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeCenterY multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))centerByView {
    return ^(UIView *view,CGFloat value) {
        return self.xCenterByView(view,value).yCenterByView(view,value);
    };
}

#pragma mark 设置距离其它view的间距
/*
 @param view  其它view
 @param value 距离多少间距
 */

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))topSpaceByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeBottom multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))leftSpaceByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeRight multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))bottomSpaceByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeTop multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))rightSpaceByView {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeLeft multiplier:1 constant:value];
        return self;
    };
}

#pragma mark 设置距离与其他view相等

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))topSpaceEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeTop multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))leftSpaceEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeLeft multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))bottomSpaceEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeBottom multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *, CGFloat))rightSpaceEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeRight multiplier:1 constant:value];
        return self;
    };
}

#pragma mark 设置宽高

- (DLAutoLayoutMaker *(^)(CGFloat))widthValue {
    return ^(CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual secondView:nil secondAttribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))heightValue {
    return ^(CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual secondView:nil secondAttribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))widthEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeWidth multiplier:1 constant:value];
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(UIView *,CGFloat))heightEqualTo {
    return ^(UIView *view,CGFloat value) {
        [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual secondView:view secondAttribute:NSLayoutAttributeHeight multiplier:1 constant:value];
        return self;
    };
}

#pragma mark 自适应宽高

- (DLAutoLayoutMaker *(^)(CGFloat value))autoHeight {
    return ^(CGFloat value) {
        return self.autoHeightByMin(0);
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))autoHeightByMin {
    return ^(CGFloat value) {
        if ([self.view isKindOfClass:[UILabel class]]) {
            [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual secondView:nil secondAttribute:NSLayoutAttributeHeight multiplier:1 constant:value];
        }
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat value))autoWidth {
    return ^(CGFloat value) {
        return self.autoWidthByMin(0);
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))autoWidthByMin {
    return ^(CGFloat value) {
        if ([self.view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *) self.view;
            NSInteger line = label.numberOfLines;
            label.numberOfLines = line > 0 ? line : 1;
            [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual secondView:nil secondAttribute:NSLayoutAttributeWidth multiplier:1 constant:value];
        }
        return self;
    };
}

#pragma mark - deprecated public
//--------以下方法都过期不推荐使用-------------

- (DLAutoLayoutMaker *)with {
    [self.tempRelatedConstraints removeAllObjects];
    return self;
}

- (DLAutoLayoutMaker *)edges {
    return self.top.left.bottom.right;
}

- (DLAutoLayoutMaker *(^)(CGFloat))offset {
    return ^(CGFloat offset) {
        return [self setupConstraint:offset relatedBy:NSLayoutRelationEqual multiplierBy:1.0];
    };
}

- (DLAutoLayoutMaker *(^)(id))greaterThanOrEqual {
    return ^(id value) {
        return self.greaterThanOrEqualWithMultiplier(value,1.0);
    };
}

- (DLAutoLayoutMaker *(^)(id))lessThanOrEqual {
    return ^(id value) {
        return self.lessThanOrEqualWithMultiplier(value,1.0);
    };
}

- (DLAutoLayoutMaker *(^)(id ))equalTo {
    return ^(id value) {
        return self.equalToWithMultiplier(value,1.0);
    };
}

- (DLAutoLayoutMaker *(^)(CGSize))sizeOffset {
    return ^(CGSize size) {
        self.width.offset(size.width);
        self.height.offset(size.height);
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(CGPoint))originOffset {
    return ^(CGPoint origin) {
        self.top.offset(origin.y);
        self.left.offset(origin.x);
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(CGRect))frameOffset {
    return ^(CGRect frame) {
        return self.top.offset(CGRectGetMinY(frame)).left.offset(CGRectGetMinX(frame)).width.offset(CGRectGetWidth(frame)).height.offset(CGRectGetHeight(frame));
    };
}

- (DLAutoLayoutMaker *(^)(UIEdgeInsets))insets {
    return ^(UIEdgeInsets insets) {
        return self.top.offset(insets.top).left.offset(insets.left).bottom.offset(insets.bottom).right.offset(insets.right);
    };
}

- (DLAutoLayoutMaker *(^)(UILayoutPriority))priority {
    return ^(UILayoutPriority priority) {
        self.lastConstraint.priority = priority;
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(CGFloat))multiplier {
    return ^(CGFloat multiplier) {
        if (self.lastConstraint) {
            [self.view.superview removeConstraint:self.lastConstraint];
            NSLayoutConstraint *obj = self.lastConstraint;
            [self.view.superview addConstraint:[NSLayoutConstraint constraintWithItem:obj.firstItem attribute:obj.firstAttribute relatedBy:obj.relation toItem:obj.secondItem attribute:obj.secondAttribute multiplier:multiplier constant:obj.constant]];
        }
        return self;
    };
}

- (DLAutoLayoutMaker *(^)(id, CGFloat))equalToWithMultiplier {
    return ^(id value,CGFloat multiplier) {
        return [self reAddConstraint:value relatedBy:NSLayoutRelationEqual multiplier:multiplier];
    };
}

- (DLAutoLayoutMaker *(^)(id, CGFloat))greaterThanOrEqualWithMultiplier {
    return ^(id value,CGFloat multiplier){
        return [self reAddConstraint:value relatedBy:NSLayoutRelationGreaterThanOrEqual multiplier:multiplier];
    };
}

- (DLAutoLayoutMaker *(^)(id, CGFloat))lessThanOrEqualWithMultiplier {
    return ^(id value,CGFloat multiplier) {
        return [self reAddConstraint:value relatedBy:NSLayoutRelationLessThanOrEqual multiplier:multiplier];
    };
}

#pragma mark - private methods

- (id)p_addOrUpdateSpaceInSuperview:(NSLayoutAttribute) attribute constant:(CGFloat)constant {
    [self p_addOrUpdateConstraintWithFristView:self.view firstAttribute:attribute relatedBy:NSLayoutRelationEqual secondView:nil secondAttribute:attribute multiplier:1 constant:constant];
    return self;
}

/**
 *  @author coffee
 *
 *  @brief 添加or更新 约束
 *
 *  @param firstView       第一个view
 *  @param firstAttribute  第一个view的属性
 *  @param relation        关系(等于,大于等于,小于等于)
 *  @param secondView      第二个view
 *  @param secondAttribute 第二个view的属性
 *  @param multiplier      比例 ( 0 -- 1 )
 *  @param constant        约束的值
 */
- (void)p_addOrUpdateConstraintWithFristView:(UIView *)firstView firstAttribute:(NSLayoutAttribute)firstAttribute relatedBy:(NSLayoutRelation)relation secondView:(UIView *)secondView secondAttribute:(NSLayoutAttribute)secondAttribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    
    if (self.layoutType == kDLAutoLayoutMakerAdd) {
        @try {
            [self p_addConstraintWithFristView:firstView firstAttribute:firstAttribute relatedBy:relation secondView:secondView secondAttribute:secondAttribute multiplier:multiplier constant:constant];
        } @catch (NSException *exception) {
            DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewLayout);
        } @finally {
            
        }
    }
    else { //update
        
        if (secondView) {
            [self.view.superview.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                if (obj.firstItem == self.view && obj.firstAttribute == firstAttribute) {
                    [self.view.superview removeConstraint:obj]; //remove
                }
                
            }];
            [self p_addConstraintWithFristView:firstView firstAttribute:firstAttribute relatedBy:relation secondView:secondView secondAttribute:secondAttribute multiplier:multiplier constant:constant];
        }
        else {
            [self p_updateConstraintWithFirstView:self.view firstAttribute:firstAttribute constant:constant];
        }
    }
    
}

- (void)p_addConstraintWithFristView:(UIView *)firstView firstAttribute:(NSLayoutAttribute)firstAttribute relatedBy:(NSLayoutRelation)relation secondView:(UIView *)secondView secondAttribute:(NSLayoutAttribute)secondAttribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    id view = nil;
    id toItem = nil;
    CGFloat value = firstAttribute == NSLayoutAttributeBottom || firstAttribute == NSLayoutAttributeRight ? 0.0 - constant : constant;
    
    if (firstAttribute == NSLayoutAttributeWidth || firstAttribute == NSLayoutAttributeHeight) {
        if (secondView) {
            view = firstView.superview;
            toItem = secondView?:firstView.superview;
        }
        else {
            view = firstView;
        }
    }
    else {
        view = firstView.superview;
        toItem = secondView?:firstView.superview;
    }
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:firstView
                                                                  attribute:firstAttribute
                                                                  relatedBy:relation
                                                                     toItem:toItem
                                                                  attribute:secondAttribute
                                                                 multiplier:multiplier
                                                                   constant:value];
    self.lastConstraint = constraint;
    [view addConstraint:constraint];
}

- (void)p_updateConstraintWithFirstView:(UIView *)view firstAttribute:(NSLayoutAttribute)attribute constant:(CGFloat)constant {
    
    NSArray<__kindof NSLayoutConstraint *> *constraints = attribute == NSLayoutAttributeWidth || attribute == NSLayoutAttributeHeight ? view.constraints : view.superview.constraints;
    [constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (attribute == NSLayoutAttributeLeft) {
            if (obj.firstItem == self.view && (obj.firstAttribute == attribute || obj.firstAttribute == NSLayoutAttributeLeading)) {
                obj.constant = constant;
            }
        }
        else if (attribute == NSLayoutAttributeRight) {
            *stop = [self p_updateRightOrBottomWithConstraint:obj firstAttr:NSLayoutAttributeTrailing secondAttr:attribute constant:constant];
        }
        else if (attribute == NSLayoutAttributeBottom) {
            *stop = [self p_updateRightOrBottomWithConstraint:obj firstAttr:NSLayoutAttributeBottom secondAttr:attribute constant:constant];
        }
        else {
            if (obj.firstItem == view && obj.firstAttribute == attribute) {
                obj.constant = constant;
            }
        }
    }];
    
    [self.view layoutIfNeeded];
    
}

- (BOOL)p_updateRightOrBottomWithConstraint:(NSLayoutConstraint *)obj firstAttr:(NSLayoutAttribute)firstAttr secondAttr:(NSLayoutAttribute)secondAttr constant:(CGFloat)constant {
    
    //更新ib里添加的约束, 右边距和下边距要特殊处理
    BOOL ibConstant = (obj.firstItem == self.view.superview && obj.firstAttribute == firstAttr ) && (obj.secondItem == self.view && obj.secondAttribute == firstAttr);
    if ( ibConstant ) { //ib添加的约束
        obj.constant = constant;
        return YES;
    }
    else if ( obj.firstItem == self.view && obj.firstAttribute == secondAttr ) { // DLAutoLayout添加的约束
        obj.constant = 0.0 - constant;
        return YES;
    }
    return NO;
}

#pragma mark - deprecated private methods , 保留1.0之前的api所使用的私有方法.

- (id)reAddConstraint:(id)value relatedBy:(NSLayoutRelation)relateBy multiplier:(CGFloat)multiplier {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [self setupConstraint:[value floatValue] relatedBy:relateBy multiplierBy:multiplier];
    }
    else if ([value isKindOfClass:[UIView class]]) {
        return [self reAddConstraintOfAttributesWithToItem:value relatedBy:relateBy multiplierBy:multiplier];
    }
    NSAssert(NO, @"%@ : Does not supper type",self.view);
    return self;
}

- (DLAutoLayoutMaker *)setupConstraint:(CGFloat)offset relatedBy:(NSLayoutRelation)related multiplierBy:(CGFloat)multiplier {
//    NSAssert(self.view.superview, @"%@ , not superview",self.view.class);
    @try {
        if (self.tempRelatedConstraints.count) {
            
            for (NSLayoutConstraint *constraint in self.tempRelatedConstraints) { //update constant in tempRelatedConstraints
                constraint.constant = offset;
            }
            
            //clear
            [self.tempRelatedConstraints removeAllObjects];
            [self.constraintAttributes removeAllObjects];
            
            return self;
        }
        
        NSArray *array = [self.constraintAttributes distinctUnionOfObjects];
        for (id attribute in array) {
            
            NSLayoutAttribute firstAttribute = [attribute integerValue];
            
            if ( self.layoutType == kDLAutoLayoutMakerAdd ) {
                
                id view = nil;
                id toItem = nil;
                NSLayoutAttribute secondAttribute = NSLayoutAttributeNotAnAttribute;
                
                if (firstAttribute == NSLayoutAttributeWidth || firstAttribute == NSLayoutAttributeHeight) {
                    view = self.view;
                }
                else {
                    view = self.view.superview;
                    toItem = self.view.superview;
                    secondAttribute = firstAttribute;
                }
                
                [view addConstraint:[NSLayoutConstraint constraintWithItem:self.view
                                                                 attribute:firstAttribute
                                                                 relatedBy:related
                                                                    toItem:toItem
                                                                 attribute:secondAttribute
                                                                multiplier:multiplier
                                                                  constant:offset]];
                
            }
            else { //update
                [self p_updateConstraintWithFirstView:self.view firstAttribute:firstAttribute constant:offset];
            }
            
        } //end for
        
        //clear attributes in array
        [self.constraintAttributes removeAllObjects];
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewLayout);
    } @finally {
        
    }
    return self;
}

- (DLAutoLayoutMaker *)reAddConstraintOfAttributesWithToItem:(UIView *)secondView relatedBy:(NSLayoutRelation)related multiplierBy:(CGFloat)multiplier {
//    NSAssert(self.view.superview, @"%@ , please add superview",self.view.class);
    
    @try {
        NSArray *distinctUnionAttributes = [self.constraintAttributes distinctUnionOfObjects];
        NSLayoutAttribute secondAttribute = [objc_getAssociatedObject(secondView, &kDLAttributeKey) integerValue];
        
        if (self.layoutType == kDLAutoLayoutMakerUpdate) { //如果是更新约束,就先删掉view对应的相对约束
            [self.view.superview.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                for (id attribute in distinctUnionAttributes) {
                    if (obj.firstItem == self.view && obj.firstAttribute == [attribute integerValue]) {
                        [self.view.superview removeConstraint:obj]; //remove
                    }
                }
                
            }];
        }
        
        for (id attribute in distinctUnionAttributes) {
            NSLayoutAttribute firstAttribute = [attribute integerValue];
            NSLayoutAttribute toAttribute = secondAttribute != NSLayoutAttributeNotAnAttribute ? secondAttribute : firstAttribute;
            
            //add constraint
            [self addConstraintInSuperviewWithFirstAttribute:firstAttribute toItem:secondView toAttribute:toAttribute relatedBy:related multiplierBy:multiplier];
            [self resetAttributeWithView:secondView];
        }
        
        //clear attributes in array
        [self.constraintAttributes removeAllObjects];
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeViewLayout);
    } @finally {
        
    }
    
    return self;
}

- (void)addConstraintInSuperviewWithFirstAttribute:(NSLayoutAttribute)firstAttribute toItem:(UIView *)view toAttribute:(NSLayoutAttribute)relatedAttribute relatedBy:(NSLayoutRelation)related multiplierBy:(CGFloat)multiplier {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                  attribute:firstAttribute
                                                                  relatedBy:related
                                                                     toItem:view
                                                                  attribute:relatedAttribute
                                                                 multiplier:multiplier
                                                                   constant:0];
    [self.view.superview addConstraint:constraint];//add constraint in superview
    self.lastConstraint = constraint;
    [self.tempRelatedConstraints addObject:constraint]; //add constraint object in the array
}

- (void)resetAttributeWithView:(UIView *)view {
    NSLayoutAttribute secondAttribute = [objc_getAssociatedObject(view, &kDLAttributeKey) integerValue];
    if ( secondAttribute != NSLayoutAttributeNotAnAttribute ) {
        objc_setAssociatedObject(view, &kDLAttributeKey, @(NSLayoutAttributeNotAnAttribute), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end

@implementation UIView (DLAdditions)

- (id)dl_top {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeTop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_left {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeLeft), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_bottom {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeBottom), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_right {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeRight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_leading {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeLeading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_trailing {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeTrailing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_width {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_height {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeHeight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_centerX {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeCenterX), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (id)dl_centerY {
    objc_setAssociatedObject(self, &kDLAttributeKey, @(NSLayoutAttributeCenterY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return self;
}

- (void)dl_addConstraints:(void(^)(DLAutoLayoutMaker *layout))layout {
    layout([[DLAutoLayoutMaker alloc] initWithView:self type:kDLAutoLayoutMakerAdd]);
}

- (void)dl_updateConstraints:(void(^)(DLAutoLayoutMaker *layout))layout {
    layout([[DLAutoLayoutMaker alloc] initWithView:self type:kDLAutoLayoutMakerUpdate]);
}

- (void)dl_printConstraintsForSelf {
    NSArray<__kindof NSLayoutConstraint *> *constrain = self.constraints;
    NSArray<__kindof NSLayoutConstraint *> *superConstrain = self.superview.constraints;
    NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
    [array addObjectsFromArray:constrain];
    [array addObjectsFromArray:superConstrain];
    [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.firstItem == self) {
            NSLog(@"p_dl_layoutAttributeString  ==  %@ -> %@ : %f",[self class],p_dl_layoutAttributeString(obj.firstAttribute),obj.constant);
        }
    }];
}

- (BOOL)dl_autoLayoutsForSelf:(NSLayoutAttribute)layoutAttribute{
    __block BOOL isHave = NO;
    NSArray<__kindof NSLayoutConstraint *> *constrain = self.constraints;
    NSArray<__kindof NSLayoutConstraint *> *superConstrain = self.superview.constraints;
    NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
    [array addObjectsFromArray:constrain];
    [array addObjectsFromArray:superConstrain];
    [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.firstItem == self) {
            if (obj.firstAttribute == layoutAttribute) {
                isHave = YES;
            }
        }
    }];
    return isHave;
}

#pragma mark 2.0+ 全新API

- (void)dl_addAutoLayouts:(void(^)(void))block {
    [DLAutoLayoutFactory p_layoutMakerLockWithBlock:block];
    [self p_dl_autoLayoutsWithType:kDLAutoLayoutMakerAdd];
}

- (void)dl_updateAutoLayouts:(void (^)(void))block {
    [DLAutoLayoutFactory p_layoutMakerLockWithBlock:block];
    [self p_dl_autoLayoutsWithType:kDLAutoLayoutMakerUpdate];
}

- (void)dl_printAutoLayoutsForSelf{
    
}

- (CGFloat)dl_fittingWidthWithSubview:(UIView *)view {
    return [self p_dl_fittingSizeWithSubview:view].width;
}

- (CGFloat)dl_fittingHeightWithSubview:(UIView *)view {
    return [self p_dl_fittingSizeWithSubview:view].height;
}

#pragma mark 2.0+ private

- (CGSize)p_dl_fittingSizeWithSubview:(UIView *)view {
    if ((![view isDescendantOfView:self]) || view == self) {
        return CGSizeZero;
    }
    [self layoutIfNeeded];
    return CGSizeMake(CGRectGetMaxX(view.frame), CGRectGetMaxY(view.frame));
}

- (void)p_dl_addAutoLayoutsWithArray:(NSArray<DLAutoLayoutFactory *> *)layouts {
    [self p_dl_autolayoutWithType:kDLAutoLayoutMakerAdd makers:layouts];
}

- (void)p_dl_updateAutoLayoutsWithArray:(NSArray<DLAutoLayoutFactory *> *)layouts {
    [self p_dl_autolayoutWithType:kDLAutoLayoutMakerUpdate makers:layouts];
}

- (void)p_dl_autoLayoutsWithType:(NSString *)type {
    NSArray<DLAutoLayoutFactory *> *factories = objc_getAssociatedObject(kDLAutoLayoutForArrayObject, kDLAutoLayoutForArrayKey);
    
    if (type == kDLAutoLayoutMakerAdd) {
        [self p_dl_addAutoLayoutsWithArray:factories];
    }
    else {
        [self p_dl_updateAutoLayoutsWithArray:factories];
    }
    
    objc_setAssociatedObject(kDLAutoLayoutForArrayObject, kDLAutoLayoutForArrayKey, nil, OBJC_ASSOCIATION_ASSIGN);
    factories = nil;
}

- (void)p_dl_autolayoutWithType:(NSString *)type makers:(NSArray<DLAutoLayoutFactory *> *)makers {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    [makers enumerateObjectsUsingBlock:^(DLAutoLayoutFactory * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool {
            DLAutoLayoutMaker *maker = [[DLAutoLayoutMaker alloc] initWithView:self type:type];
            if (obj.widthEqualToHeight) {
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
                maker.width.equalTo(obj.layoutSecondView.dl_height).offset(obj.layoutConstant);
            }
            else if (obj.heightEqualToWidth) {
                maker.height.equalTo(obj.layoutSecondView.dl_width).offset(obj.layoutConstant);
#pragma clang diagnostic pop
            }
            else if (obj.layoutAutoHeight) {
                maker.autoHeight(obj.layoutConstant);
            }
            else if (obj.layoutAutoWidth) {
                maker.autoWidth(obj.layoutConstant);
            }
            else if (obj.layoutSecondView) {
                
                SEL aSel = nil;
                
                if (obj.layoutSecondAttribute == NSLayoutAttributeNotAnAttribute) {
                    aSel = NSSelectorFromString(p_dl_layout_equalTo_method()[@(obj.layoutFirstAttribute)]);
                }
                else {
                    aSel = NSSelectorFromString(p_dl_layout_spaceByView_method()[@(obj.layoutFirstAttribute)]);
                }
                
                void(^block)(UIView *view, CGFloat value)        = [self p_dl_makerLayoutGetterBlock_:maker sel:aSel];
                if (block) {
                    block(obj.layoutSecondView,obj.layoutConstant);
                }
                
                if (obj.layoutMultiplierValue) {
                    maker.multiplier(obj.layoutMultiplierValue);
                }
            }
            else if (obj.layoutCenters) {
                if (type == kDLAutoLayoutMakerAdd) {
                    [self p_dl_addAutoLayoutsWithArray:obj.layoutCenters];
                }
                else {
                    [self p_dl_updateAutoLayoutsWithArray:obj.layoutCenters];
                }
            }
            else if (obj.layoutInsets) {
                if (type == kDLAutoLayoutMakerAdd) {
                    [self p_dl_addAutoLayoutsWithArray:obj.layoutInsets];
                }
                else {
                    [self p_dl_updateAutoLayoutsWithArray:obj.layoutInsets];
                }
            }
            else {
                
                SEL aSel       = NSSelectorFromString(p_dl_layout_space_method()[@(obj.layoutFirstAttribute)]);
                void(^block)(CGFloat value) = [self p_dl_makerLayoutGetterBlock_two:maker sel:aSel];
                if (block) {
                    block(obj.layoutConstant);
                }
            }
            
            if (obj.layoutPriority) {
                maker.priority(obj.layoutPriority);
            }
        }
    }];
}

- (void(^)(CGFloat value))p_dl_makerLayoutGetterBlock_two:(NSObject *)obj sel:(SEL)aSel {
    if (aSel && class_respondsToSelector([obj class],aSel)) {
        IMP aImp              = [obj methodForSelector:aSel];
        id (*execIMP)(id,SEL) = (void *)aImp;
        return ((void(^)(CGFloat value))execIMP(obj,aSel));
    }
    return nil;
}

- (void(^)(UIView *view, CGFloat value))p_dl_makerLayoutGetterBlock_:(NSObject *)obj sel:(SEL)aSel {
    if (aSel && class_respondsToSelector([obj class],aSel)) {
        IMP aImp              = [obj methodForSelector:aSel];
        id (*execIMP)(id,SEL) = (void *)aImp;
        return ((void(^)(UIView *view, CGFloat value))execIMP(obj,aSel));
    }
    return nil;
}

NSDictionary<NSNumber *,NSString *> *p_dl_layout_space_method() {
    return @{
             @(NSLayoutAttributeTop):@"topSpace",
             @(NSLayoutAttributeLeft):@"leftSpace",
             @(NSLayoutAttributeRight):@"rightSpace",
             @(NSLayoutAttributeBottom):@"bottomSpace",
             @(NSLayoutAttributeWidth):@"widthValue",
             @(NSLayoutAttributeHeight):@"heightValue",
             };
}

NSDictionary<NSNumber *,NSString *> *p_dl_layout_equalTo_method() {
    return @{
             @(NSLayoutAttributeTop):@"topSpaceEqualTo",
             @(NSLayoutAttributeLeft):@"leftSpaceEqualTo",
             @(NSLayoutAttributeRight):@"rightSpaceEqualTo",
             @(NSLayoutAttributeBottom):@"bottomSpaceEqualTo",
             @(NSLayoutAttributeWidth):@"widthEqualTo",
             @(NSLayoutAttributeHeight):@"heightEqualTo"
             };
}

NSDictionary<NSNumber *,NSString *> *p_dl_layout_spaceByView_method() {
    return @{
             @(NSLayoutAttributeTop):@"topSpaceByView",
             @(NSLayoutAttributeLeft):@"leftSpaceByView",
             @(NSLayoutAttributeRight):@"rightSpaceByView",
             @(NSLayoutAttributeBottom):@"bottomSpaceByView",
             @(NSLayoutAttributeCenterX):@"xCenterByView",
             @(NSLayoutAttributeCenterY):@"yCenterByView",
             };
}

@end

#pragma mark - category UITableView + DLCellAutoHeight

static NSString * const kDLTableViewCellHeightDictionary = @"kDLTableViewCellHeightDictionary_dl";

NSString *p_dl_heightDictionaryKey(NSIndexPath *indexPath);
void p_dl_swizzleMethodOfSelf(Class aClass,SEL sel1,SEL sel2);

@implementation UITableView (DLCellAutoHeight)

//+ (void)load {
//
//    p_dl_swizzleMethodOfSelf([self class], @selector(reloadData), @selector(p_dl_swizzleReloadData));
//    p_dl_swizzleMethodOfSelf([self class],@selector(reloadRowsAtIndexPaths:withRowAnimation:),@selector(p_dl_swizzleReloadRowsAtIndexPaths:withRowAnimation:));
//    p_dl_swizzleMethodOfSelf([self class],@selector(reloadSections:withRowAnimation:),@selector(p_dl_swizzleReloadSections:withRowAnimation:));
//    p_dl_swizzleMethodOfSelf([self class],@selector(deleteSections:withRowAnimation:),@selector(p_dl_swizzleDeleteSections:withRowAnimation:));
//    p_dl_swizzleMethodOfSelf([self class],@selector(deleteRowsAtIndexPaths:withRowAnimation:),@selector(p_dl_swizzleDeleteRowsAtIndexPaths:withRowAnimation:));
//}

#pragma mark - category UITableView + DLCellAutoHeight -> public apis

- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath {
    return [self p_dl_heightWithIndexPath:indexPath handle:^CGFloat(UITableViewCell *cell, NSIndexPath *indexPath) {
        NSMutableArray *maxYArray = [NSMutableArray array];
        [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.hidden) {
                [maxYArray addObject:@(CGRectGetMaxY(obj.frame))];
            }
        }];
        
        NSArray *compareMaxYArray = [maxYArray sortedArrayUsingSelector:@selector(compare:)];
        return [compareMaxYArray.lastObject floatValue];
    }];
}

- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath space:(CGFloat)space {
    return [self dl_cellHeightWithindexPath:indexPath] + space;
}

- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath bottomView:(UIView *(^)(__kindof UITableViewCell *cell))block {
    return [self p_dl_heightWithIndexPath:indexPath handle:^CGFloat(UITableViewCell *cell, NSIndexPath *indexPath) {
        if (!block) {
            return [self dl_cellHeightWithindexPath:indexPath];
        }
        
        UIView *bottomView = block(cell);
        return CGRectGetMaxY(bottomView.frame);
    }];
}

- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath bottomView:(UIView *(^)(__kindof UITableViewCell *cell))block space:(CGFloat)space {
    return [self dl_cellHeightWithindexPath:indexPath bottomView:block] + space;
}

#pragma mark - private

- (CGFloat)p_dl_heightWithIndexPath:(NSIndexPath *)indexPath handle:(CGFloat(^)(UITableViewCell *cell,NSIndexPath *indexPath))block {
    
    NSMutableDictionary *heightDictionary = [self p_dl_heightDictionary];
    NSString *dictionaryKey = p_dl_heightDictionaryKey(indexPath);
    CGFloat cacheHeight = [heightDictionary[dictionaryKey] floatValue];
    
    if (!cacheHeight) {
        UITableViewCell *cell = [self p_dl_cellWithIndexPath:indexPath];
        
        CGFloat height = block(cell,indexPath);
        
        cacheHeight = !height ? CGFLOAT_MIN : height;
        [heightDictionary setObject:@(cacheHeight) forKey:dictionaryKey];
        
    }
    
    return cacheHeight;
}

- (NSMutableDictionary *)p_dl_heightDictionary {
    NSMutableDictionary *heightDictionary = objc_getAssociatedObject(self, &kDLTableViewCellHeightDictionary);
    if (!heightDictionary) {
        heightDictionary = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &kDLTableViewCellHeightDictionary, heightDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return heightDictionary;
}

- (UITableViewCell *)p_dl_cellWithIndexPath:(NSIndexPath *)indexPath {
    id dataSourceObj = self.dataSource;
    
    NSAssert([dataSourceObj respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)], @"请实现 tableView:cellForRowAtIndexPath: 方法");
    
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    [window layoutIfNeeded];
    
    UITableViewCell *cell = [dataSourceObj tableView:self cellForRowAtIndexPath:indexPath];
    
    CGRect cellFrame = cell.frame;
    cellFrame.size.width = CGRectGetWidth(self.frame);
    cell.frame = cellFrame;
    
    [cell layoutIfNeeded];
    
    return cell;
}

#pragma mark swizzle method

- (void)p_dl_swizzleReloadData {
    if ([self p_dl_heightDictionary].count) {
        [[self p_dl_heightDictionary] removeAllObjects];
    }
    [self p_dl_swizzleReloadData];
}

- (void)p_dl_swizzleReloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    
    if ([self p_dl_heightDictionary].count) {
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [[self p_dl_heightDictionary] removeObjectForKey:p_dl_heightDictionaryKey(obj)];
        }];
    }
    
    [self p_dl_swizzleReloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
    
}

- (void)p_dl_swizzleReloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    
    if ([self p_dl_heightDictionary].count) {
        NSMutableArray *tempArray = [NSMutableArray array];
        
        [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger section = idx;
            [[[self p_dl_heightDictionary] allKeys] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *sectionString = [obj componentsSeparatedByString:@"-"].firstObject;
                
                if (section == [sectionString longLongValue]) {
                    [tempArray addObject:obj];
                }
                
            }];
        }];
        
        [[self p_dl_heightDictionary] removeObjectsForKeys:tempArray];
    }
    
    [self p_dl_swizzleReloadSections:sections withRowAnimation:animation];
    
}

- (void)p_dl_swizzleDeleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if ([self p_dl_heightDictionary].count) {
        [[self p_dl_heightDictionary] removeAllObjects];
    }
    [self p_dl_swizzleDeleteSections:sections withRowAnimation:animation];
}

- (void)p_dl_swizzleDeleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if ([self p_dl_heightDictionary].count) {
        [[self p_dl_heightDictionary] removeAllObjects];
    }
    [self p_dl_swizzleDeleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

#pragma mark - private -> c

NSString *p_dl_heightDictionaryKey(NSIndexPath *indexPath) {
    return [NSString stringWithFormat:@"%zi-%zi",indexPath.section,indexPath.row];
}

void p_dl_swizzleMethodOfSelf(Class aClass,SEL sel1,SEL sel2) {
    method_exchangeImplementations(class_getInstanceMethod(aClass, sel1), class_getInstanceMethod(aClass, sel2));
}

@end

//-----------------------------------------------------

@implementation DLAutoLayoutFactory

- (DLAutoLayoutFactory *(^)(UILayoutPriority))priority {
    return ^(UILayoutPriority priority) {
        self.layoutPriority          = priority;
        return self;
    };
}

- (DLAutoLayoutFactory *(^)(CGFloat))multiplier {
    return ^(CGFloat multiplier) {
        self.layoutMultiplierValue = multiplier;
        return self;
    };
}

- (CGFloat)layoutMultiplierValue {
    return _layoutMultiplierValue == 0 ? 1 : _layoutMultiplierValue;
}

+ (void)p_layoutMakerLockWithBlock:(void (^)(void))block {
    objc_setAssociatedObject(kDLAutoLayoutForArrayForLockObject, kDLAutoLayoutForArrayForLockKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (block) {
        block();
    }
    objc_setAssociatedObject(kDLAutoLayoutForArrayForLockObject, kDLAutoLayoutForArrayForLockKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end

#pragma mark - 生产 dl_layout 的C函数

#pragma mark 私有
__attribute__((__overloadable__)) DLAutoLayoutFactory * p_dl_layout_maker(UIView *secondView,CGFloat constant,NSLayoutAttribute firstAttribute,NSLayoutAttribute secondAttribute) {
    id lockLayout = objc_getAssociatedObject(kDLAutoLayoutForArrayForLockObject, kDLAutoLayoutForArrayForLockKey);
    if (!lockLayout) {
        return nil;
    }
    DLAutoLayoutMaker *layout = [[DLAutoLayoutMaker alloc] initWithView:nil type:kDLAutoLayoutMakerAdd];
    DLAutoLayoutFactory *factory = [DLAutoLayoutFactory new];
    factory.layoutConstant = constant;
    factory.layoutFirstAttribute = firstAttribute;
    factory.layoutSecondView = secondView;
    factory.layoutSecondAttribute = secondAttribute;
    factory.marker = layout;
    
    NSMutableArray<DLAutoLayoutFactory *> *array = objc_getAssociatedObject(kDLAutoLayoutForArrayObject, kDLAutoLayoutForArrayKey);
    if (array == nil) {
        array = [NSMutableArray array];
        objc_setAssociatedObject(kDLAutoLayoutForArrayObject, &kDLAutoLayoutForArrayKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [array addObject:factory];
    return factory;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * p_dl_layout_maker(UIView *secondView,CGFloat constant,NSLayoutAttribute attribute) {
    return p_dl_layout_maker(secondView, constant, attribute,NSLayoutAttributeNotAnAttribute);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * p_dl_layout_maker(CGFloat constant,NSLayoutAttribute attribute) {
    return p_dl_layout_maker(nil, constant, attribute);
}

#pragma mark 公开

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_top(CGFloat constant) {
    return p_dl_layout_maker(constant,NSLayoutAttributeTop);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_left(CGFloat constant) {
    return p_dl_layout_maker(constant,NSLayoutAttributeLeft);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_right(CGFloat constant) {
    return p_dl_layout_maker(constant,NSLayoutAttributeRight);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottom(CGFloat constant) {
    return p_dl_layout_maker(constant,NSLayoutAttributeBottom);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_width(CGFloat constant) {
    return p_dl_layout_maker(constant, NSLayoutAttributeWidth);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_height(CGFloat constant) {
    return p_dl_layout_maker(constant, NSLayoutAttributeHeight);
}

DLAutoLayoutFactory * dl_layout_edge(UIEdgeInsets insets) {
    DLAutoLayoutFactory *layout = p_dl_layout_maker(0, NSLayoutAttributeNotAnAttribute);
    layout.layoutInsets = @[
                            dl_layout_top(insets.top),
                            dl_layout_left(insets.left),
                            dl_layout_right(insets.right),
                            dl_layout_bottom(insets.bottom)
                            ];
    return layout;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_top(void) {
    return dl_layout_top(0.f);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_left(void) {
    return dl_layout_left(0.f);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_right(void) {
    return dl_layout_right(0.f);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottom(void) {
    return dl_layout_bottom(0.f);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_width(void) {
    return dl_layout_width(0.f);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_height(void) {
    return dl_layout_height(0.f);
}

DLAutoLayoutFactory * dl_layout_widthGreaterThanOrEqual(CGFloat constant) {
    DLAutoLayoutFactory *layout = p_dl_layout_maker(constant, NSLayoutAttributeNotAnAttribute);
    layout.layoutAutoWidth = YES;
    return layout;
}

DLAutoLayoutFactory * dl_layout_heightGreaterThanOrEqual(CGFloat constant) {
    DLAutoLayoutFactory *layout = p_dl_layout_maker(constant, NSLayoutAttributeNotAnAttribute);
    layout.layoutAutoHeight = YES;
    return layout;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_center(UIView *secondView,CGFloat constant) {
    DLAutoLayoutFactory *factory = [DLAutoLayoutFactory new];
    factory.layoutCenters = @[
                              dl_layout_centerX(secondView, constant),
                              dl_layout_centerY(secondView, constant)
                              ];
    return factory;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_center(UIView *secondView) {
    return dl_layout_center(secondView,0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_centerX(UIView *secondView,CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeCenterX, NSLayoutAttributeCenterX);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_centerX(UIView *secondView) {
    return dl_layout_centerX(secondView,0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_centerY(UIView *secondView,CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeCenterY, NSLayoutAttributeCenterY);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_centerY(UIView *secondView) {
    return dl_layout_centerY(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_topEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeTop);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_topEqualTo(UIView *secondView) {
    return dl_layout_topEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_leftEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeLeft);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_leftEqualTo(UIView *secondView) {
    return dl_layout_leftEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottomEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeBottom);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottomEqualTo(UIView *secondView) {
    return dl_layout_bottomEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_rightEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeRight);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_rightEqualTo(UIView *secondView) {
    return dl_layout_rightEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_widthEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeWidth);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_widthEqualTo(UIView *secondView) {
    return dl_layout_widthEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_heightEqualTo(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeHeight);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_heightEqualTo(UIView *secondView) {
    return dl_layout_heightEqualTo(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_widthEqualToHeight(UIView *secondView, CGFloat constant) {
    DLAutoLayoutFactory *factory = p_dl_layout_maker(secondView, constant, NSLayoutAttributeNotAnAttribute);
    factory.widthEqualToHeight = YES;
    return factory;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_widthEqualToHeight(UIView *secondView) {
    return dl_layout_widthEqualToHeight(secondView,0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_heightEqualToWidth(UIView *secondView, CGFloat constant) {
    DLAutoLayoutFactory *factory = p_dl_layout_maker(secondView, constant, NSLayoutAttributeNotAnAttribute);
    factory.heightEqualToWidth = YES;
    return factory;
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_heightEqualToWidth(UIView *secondView) {
    return dl_layout_heightEqualToWidth(secondView,0);
}

#pragma mark 某一边距参照某一个view来设置

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_topByView(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeTop,NSLayoutAttributeBottom);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_topByView(UIView *secondView) {
    return dl_layout_topByView(secondView,0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_leftByView(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeLeft, NSLayoutAttributeRight);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_leftByView(UIView *secondView) {
    return dl_layout_leftByView(secondView, 0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottomByView(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeBottom, NSLayoutAttributeTop);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_bottomByView(UIView *secondView) {
    return dl_layout_bottomByView(secondView,0);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_rightByView(UIView *secondView, CGFloat constant) {
    return p_dl_layout_maker(secondView, constant, NSLayoutAttributeRight, NSLayoutAttributeLeft);
}

__attribute__((__overloadable__)) DLAutoLayoutFactory * dl_layout_rightByView(UIView *secondView) {
    return dl_layout_rightByView(secondView,0);
}

