#import "UIView+Layout.h"
#import <objc/runtime.h>
#import "UIView+Add.h"

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

@property (nonatomic, assign) BOOL needInstall;

@property (nonatomic, strong) NSLayoutConstraint *constraint;

@property (nonatomic, assign) ConstraintType constraintType;

@property (nonatomic, weak) id item;

@property (nonatomic, assign) BOOL needDelete;

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


@interface DLLayout ()

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, weak) UIView *view;

@property (nonatomic, strong) Constraint *leftConstraint;

@property (nonatomic, strong) Constraint *rightConstraint;

@property (nonatomic, strong) Constraint *topConstraint;

@property (nonatomic, strong) Constraint *bottomConstraint;

@property (nonatomic, strong) Constraint *widthConstraint;

@property (nonatomic, strong) Constraint *heightConstraint;

@property (nonatomic, strong) Constraint *centerXConstraint;

@property (nonatomic, strong) Constraint *centerYConstraint;

@property (nonatomic, assign) BOOL isReset;

@end


@implementation DLLayout

-(instancetype)initWithView:(UIView *)view{
    if (self = [super init]) {
        self.array = [[NSMutableArray alloc]init];
        self.view = view;
        self.isReset = NO;
    }
    return self;
}

-(DLLayout *(^)(NSInteger constant))priority{
    return ^(NSInteger constant) {
        self.isReset = YES;
        for (Constraint *constraint in self.array) {
            constraint.priority = constant;
        }
        return self;
    };
}

-(DLLayout *(^)(UIView *view))equal{
    return ^(UIView *view){
        self.isReset = YES;
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
        self.isReset = YES;
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
        self.isReset = YES;
        for (Constraint *constraint in self.array) {
            constraint.multiplier = constant;
        }
        return self;
    };
}

-(DLLayout *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        self.isReset = YES;
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
    for (Constraint *constraint in self.array) {
        if (constraint.needDelete) {
            if (constraint.fatherView && constraint.constraint) {
                [constraint.fatherView removeConstraint:constraint.constraint];
            }
            continue;
        }
        if (!constraint.needInstall) {
            continue;
        }
        UIView *view;
        if (!constraint.secondView) {
            constraint.secondView = self.view.superview;
            view = self.view.superview;
        }else if (self.view.superview == constraint.secondView) {
            view = constraint.secondView;
        }else{
            view = [self.view getCommonSuperView:constraint.secondView];
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
        constraint.needInstall = NO;
        [view addConstraint:cons];
    }
    self.isReset = NO;
    [self.array removeAllObjects];
}

-(NSLayoutConstraint *)addConstraint:(Constraint *)constraint{
    NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self.view attribute:constraint.firstAttribute relatedBy:constraint.layoutRelation toItem:constraint.item attribute:constraint.secondAttribute ? constraint.secondAttribute : constraint.firstAttribute multiplier:constraint.multiplier constant:constraint.constant];
    if (constraint.priority > 0) {
        cons.priority = constraint.priority;
    }
    return cons;
}

-(void)removeConstraint{
    for (Constraint *constraint in self.array) {
        if (constraint.fatherView && constraint.constraint) {
            [constraint.fatherView removeConstraint:constraint.constraint];
        }
    }
    [self.array removeAllObjects];
}

-(DLLayout *)left{
    [self deleteConstraint:self.leftConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.leftConstraint.multiplier = 1.0;
    self.leftConstraint.constant = 0;
    self.leftConstraint.needInstall = YES;
    self.leftConstraint.needDelete = NO;
    self.leftConstraint.constraintType = Left;
    [self.array addObject:self.leftConstraint];
    return self;
}

-(DLLayout *)right{
    [self deleteConstraint:self.rightConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.rightConstraint.multiplier = 1.0;
    self.rightConstraint.constant = 0;
    self.rightConstraint.needInstall = YES;
    self.rightConstraint.needDelete = NO;
    self.rightConstraint.constraintType = Right;
    [self.array addObject:self.rightConstraint];
    return self;
}

-(DLLayout *)top{
    [self deleteConstraint:self.topConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.topConstraint.multiplier = 1.0;
    self.topConstraint.constant = 0;
    self.topConstraint.needInstall = YES;
    self.topConstraint.needDelete = NO;
    self.topConstraint.constraintType = Top;
    [self.array addObject:self.topConstraint];
    return self;
}

-(DLLayout *)bottom{
    [self deleteConstraint:self.bottomConstraint];
    [self dl_removalDuplicateConstraints:self.bottomConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.bottomConstraint.multiplier = 1.0;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.needInstall = YES;
    self.bottomConstraint.needDelete = NO;
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
    if (self.isReset) {
        [self installConstraint];
    }
    self.topConstraint.multiplier = 1.0;
    self.topConstraint.constant = 0;
    self.topConstraint.needInstall = YES;
    self.topConstraint.needDelete = NO;
    self.topConstraint.constraintType = SafeTop;
    [self.array addObject:self.topConstraint];
    
    return self;
}

-(DLLayout *)safeBottom{
    [self deleteConstraint:self.bottomConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.bottomConstraint.multiplier = 1.0;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.needInstall = YES;
    self.bottomConstraint.needDelete = NO;
    self.bottomConstraint.constraintType = SafeBottom;
    [self.array addObject:self.bottomConstraint];
    return self;
}

-(DLLayout *)width{
    [self deleteConstraint:self.widthConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.needInstall = YES;
    self.widthConstraint.needDelete = NO;
    self.widthConstraint.constraintType = Width;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)height{
    [self deleteConstraint:self.heightConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.needInstall = YES;
    self.heightConstraint.needDelete = NO;
    self.heightConstraint.constraintType = Height;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)lessOrThanWidth{
    [self deleteConstraint:self.widthConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.needInstall = YES;
    self.widthConstraint.needDelete = NO;
    self.widthConstraint.constraintType = LessOrThanWidth;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)lessOrThanHeight{
    [self deleteConstraint:self.heightConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.needInstall = YES;
    self.heightConstraint.needDelete = NO;
    self.heightConstraint.constraintType = LessOrThanHeight;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)greatOrThenWidth{
    [self deleteConstraint:self.widthConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.needInstall = YES;
    self.widthConstraint.needDelete = NO;
    self.widthConstraint.constraintType = GreatOrThanWidth;
    [self.array addObject:self.widthConstraint];
    return self;
}

-(DLLayout *)greatOrThanHeight{
    [self deleteConstraint:self.heightConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.needInstall = YES;
    self.heightConstraint.needDelete = NO;
    self.heightConstraint.constraintType = GreatOrThanHeight;
    [self.array addObject:self.heightConstraint];
    return self;
}

-(DLLayout *)centerX{
    [self deleteConstraint:self.centerXConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.centerXConstraint.multiplier = 1;
    self.centerXConstraint.constant = 0;
    self.centerXConstraint.needInstall = YES;
    self.centerXConstraint.needDelete = NO;
    self.centerXConstraint.constraintType = CenterX;
    [self.array addObject:self.centerXConstraint];
    return self;
}

-(DLLayout *)centerY{
    [self deleteConstraint:self.centerYConstraint];
    if (self.isReset) {
        [self installConstraint];
    }
    self.centerYConstraint.multiplier = 1;
    self.centerYConstraint.constant = 0;
    self.centerYConstraint.needInstall = YES;
    self.centerYConstraint.needDelete = NO;
    self.centerYConstraint.constraintType = CenterY;
    [self.array addObject:self.centerYConstraint];
    return self;
}

-(void *(^)(void))install{
    return ^(void) {
        [self installConstraint];
        return nil;
    };
}

-(void *(^)(void))remove{
    return ^(void) {
        [self removeConstraint];
        return nil;
    };
}

-(void)deleteConstraint:(Constraint *)constraint{
    if (constraint.fatherView) {
        [constraint.fatherView removeConstraint:constraint.constraint];
        [self.array removeObject:constraint];
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

-(DLLayout *)dl_layout{
    DLLayout *tempLayout = objc_getAssociatedObject(self, &layout_Key);
    if (!tempLayout) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        tempLayout = [[DLLayout alloc]initWithView:self];
        objc_setAssociatedObject(self, &layout_Key, tempLayout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tempLayout;
}

-(void)setDl_layout:(DLLayout *)dl_layout{
    if (self.superview == nil) {
        #if defined(DEBUG)||defined(_DEBUG)
        assert(NO&&"请先添加父视图");
        #endif
    }else if (![[NSThread currentThread] isMainThread]) {
        #if defined(DEBUG)||defined(_DEBUG)
        assert(NO&&"约束只能在主线程中添加");
        #endif
    }else{
        objc_setAssociatedObject(self, &layout_Key, dl_layout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
