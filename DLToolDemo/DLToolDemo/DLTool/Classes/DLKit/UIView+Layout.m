#import "UIView+Layout.h"
#import "DLToolMacro.h"

static char const layout_Key;

typedef NS_ENUM(NSInteger, ConstraintType) {
    Left                =   1,
    Right,
    Top,
    Bottom,
    SafeTop,
    SafeBottom,
    SafeRight,
    SafeLeft,
    Width,
    Height,
    LessOrThanWidth,
    LessOrThanHeight,
    GreatOrThanWidth,
    GreatOrThanHeight,
    CenterX,
    CenterY,
};

@interface Constraint : NSObject

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, weak) UIView *firstView;

@property (nonatomic, weak) UIView *secondView;

@property (nonatomic, assign) NSLayoutAttribute firstAttribute;

@property (nonatomic, assign) NSLayoutAttribute secondAttribute;

@property (nonatomic, assign) NSLayoutRelation layoutRelation;

@property (nonatomic, assign) CGFloat multiplier;

@property (nonatomic, assign) CGFloat constant;

@property (nonatomic, strong) NSLayoutConstraint *constraint;

@property (nonatomic, assign) ConstraintType constraintType;

@property (nonatomic, weak) id item;

@property (nonatomic, assign) NSInteger priority;

@end

@implementation Constraint

-(void)setConstraintType:(ConstraintType)constraintType{
    _constraintType = constraintType;
    switch (constraintType) {
        case Left:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeLeft;
            }
            break;
            
        case Right:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeRight;
            }
            break;
            
        case Top:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeTop;
            }
            break;
            
        case Bottom:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeBottom;
            }
            break;
            
        case SafeLeft:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeLeft;
            }
            break;
            
        case SafeRight:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeRight;
            }
            break;
            
        case SafeTop:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeTop;
            }
            break;
            
        case SafeBottom:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeBottom;
            }
            break;
            
        case Width:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeWidth;
            }
            break;
            
        case Height:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeHeight;
            }
            break;
            
        case LessOrThanWidth:
            {
                self.layoutRelation = NSLayoutRelationLessThanOrEqual;
                self.firstAttribute = NSLayoutAttributeWidth;
            }
            break;
            
        case LessOrThanHeight:
            {
                self.layoutRelation = NSLayoutRelationLessThanOrEqual;
                self.firstAttribute = NSLayoutAttributeHeight;
            }
            break;
            
        case GreatOrThanWidth:
            {
                self.layoutRelation = NSLayoutRelationGreaterThanOrEqual;
                self.firstAttribute = NSLayoutAttributeWidth;
            }
            break;
            
        case GreatOrThanHeight:
            {
                self.layoutRelation = NSLayoutRelationGreaterThanOrEqual;
                self.firstAttribute = NSLayoutAttributeHeight;
            }
            break;
            
        case CenterX:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeCenterX;
            }
            break;
            
        case CenterY:
            {
                self.layoutRelation = NSLayoutRelationEqual;
                self.firstAttribute = NSLayoutAttributeCenterY;
            }
            break;
            
        default:
            break;
    }
}

-(instancetype)initWithView:(UIView *)view{
    if (self = [super init]) {
        self.firstView = view;
    }
    return self;
}

@end;

@interface DLLayout : NSObject

@end

@interface DLLayout ()

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) NSMutableArray *oldArray;

@property (nonatomic, weak) UIView *view;

@property (nonatomic, strong) Constraint *leftConstraint;

@property (nonatomic, strong) Constraint *rightConstraint;

@property (nonatomic, strong) Constraint *topConstraint;

@property (nonatomic, strong) Constraint *bottomConstraint;

@property (nonatomic, strong) Constraint *widthConstraint;

@property (nonatomic, strong) Constraint *heightConstraint;

@property (nonatomic, strong) Constraint *centerXConstraint;

@property (nonatomic, strong) Constraint *centerYConstraint;

@end


@implementation DLLayout

-(instancetype)initWithView:(UIView *)view{
    if (self = [super init]) {
        self.array = [[NSMutableArray alloc]init];
        self.view = view;
        self.oldArray = [[NSMutableArray alloc]init];
    }
    return self;
}

-(DLLayout *(^)(NSInteger constant))priority{
    return ^(NSInteger constant) {
        if (constant > 1000) {
            constant = 1000;
        }else if (constant < 0) {
            constant = 0;
        }
        for (Constraint *constraint in self.array) {
            constraint.priority = constant;
        }
        return self;
    };
}

-(DLLayout *(^)(UIView *view))equal{
    return ^(UIView *view){
        for (Constraint *constraint in self.array) {
            constraint.secondView = view;
            constraint.multiplier = 1;
            constraint.secondAttribute = constraint.firstAttribute;
        }
        return self;
    };
}

-(DLLayout *(^)(UIView *view))equal_to{
    return ^(UIView *view){
        for (Constraint *constraint in self.array) {
            constraint.secondView = view;
            constraint.multiplier = 1;
            switch (constraint.firstAttribute) {
                case NSLayoutAttributeLeft:
                    constraint.secondAttribute = NSLayoutAttributeRight;
                    break;
                    
                case NSLayoutAttributeRight:
                    constraint.secondAttribute = NSLayoutAttributeLeft;
                    break;
                    
                case NSLayoutAttributeTop:
                    constraint.secondAttribute = NSLayoutAttributeBottom;
                    break;
                    
                case NSLayoutAttributeBottom:
                    constraint.secondAttribute = NSLayoutAttributeTop;
                    break;
                    
                default:
                    constraint.secondAttribute = constraint.firstAttribute;
                    break;
            }
        }
        return self;
    };
}

-(DLLayout *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant){
        for (Constraint *constraint in self.array) {
            constraint.multiplier = constant;
        }
        return self;
    };
}

-(DLLayout *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        for (Constraint *constraint in self.array) {
            switch (constraint.constraintType) {
                case Bottom:
                case SafeBottom:
                case Right:
                case SafeRight:
                    constraint.constant = -constant;
                    break;
                    
                default:
                    constraint.constant = constant;
                    break;
            }
        }
        return self;
    };
}

-(void)installConstraint{
    @autoreleasepool {
        for (Constraint *constraint in self.oldArray) {
            UIView *view;
            if (!constraint.secondView) {
                constraint.secondView = self.view.superview;
                view = self.view.superview;
            }else if (self.view.superview == constraint.secondView) {
                view = constraint.secondView;
            }else{
                view = [self dl_getCommonSuperView:constraint.secondView forView:self.view];
            }
            if (constraint.constraintType == SafeBottom || constraint.constraintType == SafeTop || constraint.constraintType == SafeRight || constraint.constraintType == SafeLeft) {
                if (@available(iOS 11.0, *)) {
                    constraint.item = view.safeAreaLayoutGuide;
                } else {
                    constraint.item = constraint.secondView;
                }
            }else{
                constraint.item = constraint.secondView;
            }
            NSLayoutConstraint *cons = [self addConstraint:constraint];
            constraint.constraint = cons;
            constraint.fatherView = view;
            [view addConstraint:cons];
        }
        [self.oldArray removeAllObjects];
    }
}

-(UIView *)dl_getCommonSuperView:(UIView *)view forView:(UIView *)myView{
    @autoreleasepool {
        UIView *commonSuperview = nil;
        UIView *secondViewSuperview = view;
        while (!commonSuperview && secondViewSuperview) {
            UIView *firstViewSuperview = myView;
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
}

-(NSLayoutConstraint *)addConstraint:(Constraint *)constraint{
    NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self.view attribute:constraint.firstAttribute relatedBy:constraint.layoutRelation toItem:constraint.item attribute:constraint.secondAttribute ? constraint.secondAttribute : constraint.firstAttribute multiplier:constraint.multiplier constant:constraint.constant];
    if (constraint.priority > 0) {
        cons.priority = constraint.priority;
    }
    return cons;
}

-(void)removeConstraint{
    @autoreleasepool {
        for (Constraint *constraint in self.array) {
            if (constraint.fatherView && constraint.constraint) {
                [constraint.fatherView removeConstraint:constraint.constraint];
            }
        }
        [self.array removeAllObjects];
    }
}

-(DLLayout *)left{
    [self deleteConstraint:self.leftConstraint];
    self.leftConstraint.multiplier = 1.0;
    self.leftConstraint.constant = 0;
    self.leftConstraint.constraintType = Left;
    [self.array addObject:self.leftConstraint];
    return self;
}

-(DLLayout *)right{
    [self deleteConstraint:self.rightConstraint];
    self.rightConstraint.multiplier = 1.0;
    self.rightConstraint.constant = 0;
    self.rightConstraint.constraintType = Right;
    [self.array addObject:self.rightConstraint];
    return self;
}

-(DLLayout *)top{
    [self deleteConstraint:self.topConstraint];
    self.topConstraint.multiplier = 1.0;
    self.topConstraint.constant = 0;
    self.topConstraint.constraintType = Top;
    [self.array addObject:self.topConstraint];
    return self;
}

-(DLLayout *)bottom{
    [self deleteConstraint:self.bottomConstraint];
    [self dl_removalDuplicateConstraints:self.bottomConstraint];
    self.bottomConstraint.multiplier = 1.0;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.constraintType = Bottom;
    [self.array addObject:self.bottomConstraint];
    return self;
}

- (void)dl_removalDuplicateConstraints:(Constraint *)constraint{
    NSArray<__kindof NSLayoutConstraint *> *constrain = constraint.firstView.constraints;
    NSArray<__kindof NSLayoutConstraint *> *superConstrain = constraint.firstView.superview.constraints;
    NSMutableArray<__kindof NSLayoutConstraint *> *array = [NSMutableArray array];
    [array addObjectsFromArray:constrain];
    [array addObjectsFromArray:superConstrain];
    [array enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.firstItem == constraint.firstView && obj.firstAttribute == constraint.firstAttribute && constraint.fatherView) {
            [constraint.fatherView removeConstraint:obj];
        }
    }];
}

-(DLLayout *)safeTop{
    [self deleteConstraint:self.topConstraint];
    self.topConstraint.multiplier = 1.0;
    self.topConstraint.constant = 0;
    self.topConstraint.constraintType = SafeTop;
    [self.array addObject:self.topConstraint];
    
    return self;
}

-(DLLayout *)safeBottom{
    [self deleteConstraint:self.bottomConstraint];
    self.bottomConstraint.multiplier = 1.0;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.constraintType = SafeBottom;
    [self.array addObject:self.bottomConstraint];
    return self;
}

-(DLLayout *)width{
    [self deleteConstraint:self.widthConstraint];
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.constraintType = Width;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)height{
    [self deleteConstraint:self.heightConstraint];
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.constraintType = Height;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)lessOrThanWidth{
    [self deleteConstraint:self.widthConstraint];
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.constraintType = LessOrThanWidth;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)lessOrThanHeight{
    [self deleteConstraint:self.heightConstraint];
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.constraintType = LessOrThanHeight;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)greatOrThenWidth{
    [self deleteConstraint:self.widthConstraint];
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.constraintType = GreatOrThanWidth;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)greatOrThanHeight{
    [self deleteConstraint:self.heightConstraint];
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.constraintType = GreatOrThanHeight;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)centerX{
    [self deleteConstraint:self.centerXConstraint];
    self.centerXConstraint.multiplier = 1;
    self.centerXConstraint.constant = 0;
    self.centerXConstraint.constraintType = CenterX;
    [self.array addObject:self.centerXConstraint];
    return self;
}

-(DLLayout *)centerY{
    [self deleteConstraint:self.centerYConstraint];
    self.centerYConstraint.multiplier = 1;
    self.centerYConstraint.constant = 0;
    self.centerYConstraint.constraintType = CenterY;
    [self.array addObject:self.centerYConstraint];
    return self;
}

-(void)deleteConstraint:(Constraint *)constraint{
    if (constraint.fatherView) {
        [constraint.fatherView removeConstraint:constraint.constraint];
        [self.array removeObject:constraint];
        [self.oldArray removeObject:constraint];
    }
}

-(Constraint *)leftConstraint{
    if (!_leftConstraint) {
        _leftConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _leftConstraint;
}

-(Constraint *)rightConstraint{
    if (!_rightConstraint) {
        _rightConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _rightConstraint;
}

-(Constraint *)topConstraint{
    if (!_topConstraint) {
        _topConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _topConstraint;
}

-(Constraint *)bottomConstraint{
    if (!_bottomConstraint) {
        _bottomConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _bottomConstraint;
}

-(Constraint *)widthConstraint{
    if (!_widthConstraint) {
        _widthConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _widthConstraint;
}

-(Constraint *)heightConstraint{
    if (!_heightConstraint) {
        _heightConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _heightConstraint;
}

-(Constraint *)centerXConstraint{
    if (!_centerXConstraint) {
        _centerXConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _centerXConstraint;
}

-(Constraint *)centerYConstraint{
    if (!_centerYConstraint) {
        _centerYConstraint = [[Constraint alloc]initWithView:self.view];
    }
    return _centerYConstraint;
}

@end

@implementation UIView (Layout)

+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(addSubview:), @selector(dl_addSubview:));
    });
}

-(void)dl_addSubview:(UIView *)view{
    [self dl_addSubview:view];
    if (objc_getAssociatedObject(view, &layout_Key)) {
        DLLayout *layout = [view layout];
        [layout.oldArray addObjectsFromArray:layout.array];
        [layout.array removeAllObjects];
        if (layout.oldArray.count > 0) {
             [layout installConstraint];
        }
    }
}

-(void)dl_layoutSubviews{
    if (!self.superview) {
        return;
    }
    if (objc_getAssociatedObject(self, &layout_Key)) {
        DLLayout *layout = [self layout];
        [layout.oldArray addObjectsFromArray:layout.array];
        [layout.array removeAllObjects];
        if (layout.oldArray.count > 0) {
             [layout installConstraint];
        }
    }
}

-(UIView *(^)(DLLayoutType type))dl_layout{
    return ^(DLLayoutType type){
        if (self.superview) {
            @dl_weakify;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0000001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @dl_strongify;
                [self dl_layoutSubviews];
            });
        }
        DLLayout *layout = [self layout];
        [layout.oldArray addObjectsFromArray:layout.array];
        [layout.array removeAllObjects];
        if (type & DL_left) {
            [layout left];
        }
        
        if (type & DL_right) {
            [layout right];
        }
        
        if (type & DL_top) {
            [layout top];
        }
        
        if (type & DL_bottom) {
            [layout bottom];
        }
        
        if (type & DL_safeTop) {
            [layout safeTop];
        }
        
        if (type & DL_safeBottom) {
            [layout safeBottom];
        }
        
        if (type & DL_width) {
            [layout width];
        }
        
        if (type & DL_lessOrThanWidth) {
            [layout lessOrThanWidth];
        }
        
        if (type & DL_greatOrThenWidth) {
            [layout greatOrThenWidth];
        }
        
        if (type & DL_height) {
            [layout height];
        }
        
        if (type & DL_lessOrThanHeight) {
            [layout lessOrThanHeight];
        }
        
        if (type & DL_centerX) {
            [layout centerX];
        }
        
        if (type & DL_centerY) {
            [layout centerY];
        }
        
        if (type & DL_greatOrThanHeight) {
            [layout lessOrThanHeight];
        }
        return self;
    };
}

-(UIView *(^)(DLLayoutType type))dl_remove_layout{
    return ^(DLLayoutType type){
        DLLayout *layout = [self layout];
        if (type & DL_left) {
            [layout deleteConstraint:layout.leftConstraint];
        }
        
        if (type & DL_right) {
            [layout deleteConstraint:layout.rightConstraint];
        }
        
        if (type & DL_top) {
            [layout deleteConstraint:layout.topConstraint];
        }
        
        if (type & DL_bottom) {
            [layout deleteConstraint:layout.bottomConstraint];
        }
        
        if (type & DL_safeTop) {
            [layout deleteConstraint:layout.topConstraint];
        }
        
        if (type & DL_safeBottom) {
            [layout deleteConstraint:layout.bottomConstraint];
        }
        
        if (type & DL_width) {
            [layout deleteConstraint:layout.widthConstraint];
        }
        
        if (type & DL_lessOrThanWidth) {
            [layout deleteConstraint:layout.widthConstraint];
        }
        
        if (type & DL_greatOrThenWidth) {
            [layout deleteConstraint:layout.widthConstraint];
        }
        
        if (type & DL_height) {
            [layout deleteConstraint:layout.heightConstraint];
        }
        
        if (type & DL_lessOrThanHeight) {
            [layout deleteConstraint:layout.heightConstraint];
        }
        
        if (type & DL_centerX) {
            [layout deleteConstraint:layout.centerXConstraint];
        }
        
        if (type & DL_centerY) {
            [layout deleteConstraint:layout.centerYConstraint];
        }
        
        if (type & DL_greatOrThanHeight) {
            [layout deleteConstraint:layout.heightConstraint];
        }
        return self;
    };
}

-(UIView *(^)(NSInteger constant))priority{
    return ^(NSInteger constant) {
        if (constant > 1000) {
            constant = 1000;
        }else if (constant < 0) {
            constant = 0;
        }
        DLLayout *layout = [self layout];
        for (Constraint *constraint in layout.array) {
            constraint.priority = constant;
        }
        return self;
    };
}

-(UIView *(^)(UIView *view))equal{
    return ^(UIView *view){
        DLLayout *layout = [self layout];
        for (Constraint *constraint in layout.array) {
            constraint.secondView = view;
            constraint.multiplier = 1;
            constraint.secondAttribute = constraint.firstAttribute;
        }
        return self;
    };
}

-(UIView *(^)(UIView *view))equal_to{
    return ^(UIView *view){
        DLLayout *layout = [self layout];
        for (Constraint *constraint in layout.array) {
            constraint.secondView = view;
            constraint.multiplier = 1;
            switch (constraint.firstAttribute) {
                case NSLayoutAttributeLeft:
                    constraint.secondAttribute = NSLayoutAttributeRight;
                    break;
                    
                case NSLayoutAttributeRight:
                    constraint.secondAttribute = NSLayoutAttributeLeft;
                    break;
                    
                case NSLayoutAttributeTop:
                    constraint.secondAttribute = NSLayoutAttributeBottom;
                    break;
                    
                case NSLayoutAttributeBottom:
                    constraint.secondAttribute = NSLayoutAttributeTop;
                    break;
                    
                default:
                    constraint.secondAttribute = constraint.firstAttribute;
                    break;
            }
        }
        return self;
    };
}

-(UIView *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant){
        DLLayout *layout = [self layout];
        for (Constraint *constraint in layout.array) {
            constraint.multiplier = constant;
        }
        return self;
    };
}

-(UIView *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        DLLayout *layout = [self layout];
        for (Constraint *constraint in layout.array) {
            switch (constraint.constraintType) {
                case Bottom:
                case SafeBottom:
                case Right:
                case SafeRight:
                    constraint.constant = -constant;
                    break;
                    
                default:
                    constraint.constant = constant;
                    break;
            }
        }
        return self;
    };
}

-(DLLayout *)layout{
    DLLayout *tempLayout = objc_getAssociatedObject(self, &layout_Key);
    if (![[NSThread currentThread] isMainThread]) {
        #if defined(DEBUG)||defined(_DEBUG)
        assert(NO&&"约束只能在主线程中添加");
        #endif
    }else{
        if (!tempLayout) {
            self.translatesAutoresizingMaskIntoConstraints = NO;
            tempLayout = [[DLLayout alloc]initWithView:self];
            objc_setAssociatedObject(self, &layout_Key, tempLayout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return tempLayout;
}

@end
