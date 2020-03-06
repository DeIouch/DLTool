#import "DLConstraintMaker.h"
#import "UIView+Add.h"

typedef NS_ENUM(NSInteger, ConstraintType) {
    Left   =   1,
    Right,
    Top,
    Bottom,
    Width,
    Height,
    LessWidth,
    LessHeight,
    GreatWidth,
    GreatHeight,
    CenterX,
    CenterY,
};

@interface DLConstraint ()

@property (nonatomic, weak) UIView *firstView;

@property (nonatomic, weak) UIView *secondView;

@property (nonatomic, weak) id item;

@property (nonatomic, assign) AttributeType type;

@property (nonatomic, assign) NSLayoutAttribute firstAttribute;

@property (nonatomic, assign) NSLayoutAttribute secondAttribute;

@property (nonatomic, assign) NSLayoutRelation layoutRelation;

@property (nonatomic, assign) CGFloat multiplier;

@property (nonatomic, assign) CGFloat constant;

@property (nonatomic, assign) BOOL needInstall;

@property (nonatomic, assign) ConstraintType constraintType;

@property (nonatomic, strong) NSLayoutConstraint *constraint;

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, assign) BOOL needDelete;

@end

@interface DLConstraintMaker ()

@property (nonatomic, weak) UIView *view;

@property (nonatomic, strong) DLConstraint *leftConstraint;

@property (nonatomic, strong) DLConstraint *rightConstraint;

@property (nonatomic, strong) DLConstraint *topConstraint;

@property (nonatomic, strong) DLConstraint *bottomConstraint;

@property (nonatomic, strong) DLConstraint *centerXConstraint;

@property (nonatomic, strong) DLConstraint *centerYConstraint;

@property (nonatomic, strong) DLConstraint *widthConstraint;

@property (nonatomic, strong) DLConstraint *heightConstraint;

@property (nonatomic, strong) DLConstraint *lessWidthConstraint;

@property (nonatomic, strong) DLConstraint *lessHeightConstraint;

@property (nonatomic, strong) DLConstraint *greatWidthConstraint;

@property (nonatomic, strong) DLConstraint *greatHeightConstraint;

@property (nonatomic, strong) NSMutableArray *constraintArray;

@end

@implementation DLConstraintMaker

-(instancetype)initWithView:(UIView *)view{
    if ([super init]) {
        self.view = view;
        self.constraintArray = [[NSMutableArray alloc]init];
    }
    return self;
}

-(NSArray <UIView *> *)findCommonSuperView:(UIView *)viewOne other:(UIView *)viewOther{
    NSMutableArray *result = [NSMutableArray array];
    // 查找第一个视图的所有父视图
    NSArray *arrayOne = [self findSuperViews:viewOne];
    // 查找第二个视图的所有父视图
    NSArray *arrayOther = [self findSuperViews:viewOther];
    int i = 0;
    // 越界限制条件
    while (i < MIN((int)arrayOne.count, (int)arrayOther.count)) {
        // 倒序方式获取各个视图的父视图
        UIView *superOne = [arrayOne objectAtIndex:arrayOne.count - i - 1];
        UIView *superOther = [arrayOther objectAtIndex:arrayOther.count - i - 1];
        // 比较如果相等 则为共同父视图
        if (superOne == superOther) {
            [result addObject:superOne];
            i++;
        }
        // 如果不相等，则结束遍历
        else{
            break;
        }
    }
    return result;
}

-(NSArray <UIView *> *)findSuperViews:(UIView *)view{
    UIView *temp = view.superview;
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:view];
    while (temp) {
        [result addObject:temp];
        temp = temp.superview;
    }
    return result;
}

-(void)install{
    for (DLConstraint *constraint in self.constraintArray) {
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
            view = [self.view getCommonSuperView:constraint.secondView];;
        }
        if (constraint.type == DLAttributeSafeBottom || constraint.type == DLAttributeSafeTop || constraint.type == DLAttributeSafeRight || constraint.type == DLAttributeSafeLeft) {
            if (@available(iOS 11.0, *)) {
                constraint.item = view.safeAreaLayoutGuide;
            } else {
                constraint.item = constraint.secondView;
            }
        }else{
            constraint.item = constraint.secondView;
        }
        NSLayoutConstraint *constra = [self addConstraint:constraint];
        constraint.constraint = constra;
        constraint.fatherView = view;
        constraint.needInstall = NO;
        [view addConstraint:constra];
    }
    [self.constraintArray removeAllObjects];
}

-(NSLayoutConstraint *)addConstraint:(DLConstraint *)constraint{
    NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self.view attribute:constraint.firstAttribute relatedBy:constraint.layoutRelation toItem:constraint.item attribute:constraint.secondAttribute ? constraint.secondAttribute : constraint.firstAttribute multiplier:constraint.multiplier constant:constraint.constant];
    return cons;
}

-(void)deleteConstraint:(DLConstraint *)constraint{
    if (constraint.fatherView) {
        [constraint.fatherView removeConstraint:constraint.constraint];
        [self.constraintArray removeObject:constraint];
    }
}

-(void)insertConstraint:(DLConstraint *)constraint{
    if ([self.constraintArray containsObject:constraint]) {
        [self.constraintArray replaceObjectAtIndex:[self.constraintArray indexOfObject:constraint] withObject:constraint];
    }else{
        [self.constraintArray addObject:constraint];
    }
}

-(DLConstraint *)left{
    [self deleteConstraint:self.leftConstraint];
    self.leftConstraint.multiplier = 1;
    self.leftConstraint.constant = 0;
    self.leftConstraint.needInstall = YES;
    self.leftConstraint.needDelete = NO;
    [self insertConstraint:self.leftConstraint];
    return self.leftConstraint;
}

-(DLConstraint *)right{
    [self deleteConstraint:self.rightConstraint];
    self.rightConstraint.multiplier = 1;
    self.rightConstraint.constant = 0;
    self.rightConstraint.needInstall = YES;
    self.rightConstraint.needDelete = NO;
    [self insertConstraint:self.rightConstraint];
    return self.rightConstraint;
}

-(DLConstraint *)top{
    [self deleteConstraint:self.topConstraint];
    self.topConstraint.multiplier = 1;
    self.topConstraint.constant = 0;
    self.topConstraint.needInstall = YES;
    self.topConstraint.needDelete = NO;
    [self insertConstraint:self.topConstraint];
    return self.topConstraint;
}

-(DLConstraint *)bottom{
    [self deleteConstraint:self.bottomConstraint];
    self.bottomConstraint.multiplier = 1;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.needInstall = YES;
    self.bottomConstraint.needDelete = NO;
    [self insertConstraint:self.bottomConstraint];
    return self.bottomConstraint;
}

-(DLConstraint *)width{
    [self deleteConstraint:self.widthConstraint];
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.needInstall = YES;
    self.widthConstraint.needDelete = NO;
    self.widthConstraint.secondView = self.view;
    [self insertConstraint:self.widthConstraint];
    return self.widthConstraint;
}

-(DLConstraint *)height{
    [self deleteConstraint:self.heightConstraint];
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.needInstall = YES;
    self.heightConstraint.needDelete = NO;
    self.heightConstraint.secondView = self.view;
    [self insertConstraint:self.heightConstraint];
    return self.heightConstraint;
}

-(DLConstraint *)lessWidth{
    [self deleteConstraint:self.lessWidthConstraint];
    self.lessWidthConstraint.multiplier = 0;
    self.lessWidthConstraint.constant = 0;
    self.lessWidthConstraint.needInstall = YES;
    self.lessWidthConstraint.needDelete = NO;
    self.lessWidthConstraint.secondView = self.view;
    [self insertConstraint:self.lessWidthConstraint];
    return self.lessWidthConstraint;
}

-(DLConstraint *)lessHeight{
    [self deleteConstraint:self.lessHeightConstraint];
    self.lessHeightConstraint.multiplier = 0;
    self.lessHeightConstraint.constant = 0;
    self.lessHeightConstraint.needInstall = YES;
    self.lessHeightConstraint.needDelete = NO;
    self.lessHeightConstraint.secondView = self.view;
    [self insertConstraint:self.lessHeightConstraint];
    return self.lessHeightConstraint;
}

-(DLConstraint *)greatWidth{
    [self deleteConstraint:self.greatWidthConstraint];
    self.greatWidthConstraint.multiplier = 0;
    self.greatWidthConstraint.constant = 0;
    self.greatWidthConstraint.needInstall = YES;
    self.greatWidthConstraint.needDelete = NO;
    self.greatWidthConstraint.secondView = self.view;
    [self insertConstraint:self.greatWidthConstraint];
    return self.greatWidthConstraint;
}

-(DLConstraint *)greatHeight{
    [self deleteConstraint:self.greatHeightConstraint];
    self.greatHeightConstraint.multiplier = 0;
    self.greatHeightConstraint.constant = 0;
    self.greatHeightConstraint.needInstall = YES;
    self.greatHeightConstraint.secondView = self.view;
    self.greatHeightConstraint.needDelete = NO;
    [self insertConstraint:self.greatHeightConstraint];
    return self.greatHeightConstraint;
}

-(DLConstraint *)centerX{
    [self deleteConstraint:self.centerXConstraint];
    self.centerXConstraint.multiplier = 1;
    self.centerXConstraint.constant = 0;
    self.centerXConstraint.needInstall = YES;
    self.centerXConstraint.needDelete = NO;
    [self insertConstraint:self.centerXConstraint];
    return self.centerXConstraint;
}

-(DLConstraint *)centerY{
    [self deleteConstraint:self.centerYConstraint];
    self.centerYConstraint.multiplier = 1;
    self.centerYConstraint.constant = 0;
    self.centerYConstraint.needInstall = YES;
    self.centerYConstraint.needDelete = NO;
    [self insertConstraint:self.centerYConstraint];
    return self.centerYConstraint;
}

-(DLConstraint *)leftConstraint{
    if (!_leftConstraint) {
        _leftConstraint = [[DLConstraint alloc]init];
        _leftConstraint.needInstall = NO;
        _leftConstraint.firstView = self.view;
        _leftConstraint.constraintType = Left;
        _leftConstraint.layoutRelation = NSLayoutRelationEqual;
        _leftConstraint.firstAttribute = NSLayoutAttributeLeft;
    }
    return _leftConstraint;
}

-(DLConstraint *)rightConstraint{
    if (!_rightConstraint) {
        _rightConstraint = [[DLConstraint alloc]init];
        _rightConstraint.needInstall = NO;
        _rightConstraint.firstView = self.view;
        _rightConstraint.constraintType = Right;
        _rightConstraint.layoutRelation = NSLayoutRelationEqual;
        _rightConstraint.firstAttribute = NSLayoutAttributeRight;
    }
    return _rightConstraint;
}

-(DLConstraint *)topConstraint{
    if (!_topConstraint) {
        _topConstraint = [[DLConstraint alloc]init];
        _topConstraint.needInstall = NO;
        _topConstraint.firstView = self.view;
        _topConstraint.constraintType = Top;
        _topConstraint.layoutRelation = NSLayoutRelationEqual;
        _topConstraint.firstAttribute = NSLayoutAttributeTop;
    }
    return _topConstraint;
}

-(DLConstraint *)bottomConstraint{
    if (!_bottomConstraint) {
        _bottomConstraint = [[DLConstraint alloc]init];
        _bottomConstraint.needInstall = NO;
        _bottomConstraint.firstView = self.view;
        _bottomConstraint.constraintType = Bottom;
        _bottomConstraint.layoutRelation = NSLayoutRelationEqual;
        _bottomConstraint.firstAttribute = NSLayoutAttributeBottom;
    }
    return _bottomConstraint;
}

-(DLConstraint *)centerXConstraint{
    if (!_centerXConstraint) {
        _centerXConstraint = [[DLConstraint alloc]init];
        _centerXConstraint.needInstall = NO;
        _centerXConstraint.firstView = self.view;
        _centerXConstraint.constraintType = CenterX;
        _centerXConstraint.layoutRelation = NSLayoutRelationEqual;
        _centerXConstraint.firstAttribute = NSLayoutAttributeCenterX;
    }
    return _centerXConstraint;
}

-(DLConstraint *)centerYConstraint{
    if (!_centerYConstraint) {
        _centerYConstraint = [[DLConstraint alloc]init];
        _centerYConstraint.needInstall = NO;
        _centerYConstraint.firstView = self.view;
        _centerYConstraint.constraintType = CenterY;
        _centerYConstraint.layoutRelation = NSLayoutRelationEqual;
        _centerYConstraint.firstAttribute = NSLayoutAttributeCenterY;
    }
    return _centerYConstraint;
}

-(DLConstraint *)widthConstraint{
    if (!_widthConstraint) {
        _widthConstraint = [[DLConstraint alloc]init];
        _widthConstraint.needInstall = NO;
        _widthConstraint.firstView = self.view;
        _widthConstraint.secondView = self.view;
        _widthConstraint.constraintType = Height;
        _widthConstraint.layoutRelation = NSLayoutRelationEqual;
        _widthConstraint.firstAttribute = NSLayoutAttributeWidth;
    }
    return _widthConstraint;
}

-(DLConstraint *)heightConstraint{
    if (!_heightConstraint) {
        _heightConstraint = [[DLConstraint alloc]init];
        _heightConstraint.needInstall = NO;
        _heightConstraint.firstView = self.view;
        _heightConstraint.secondView = self.view;
        _heightConstraint.constraintType = Height;
        _heightConstraint.layoutRelation = NSLayoutRelationEqual;
        _heightConstraint.firstAttribute = NSLayoutAttributeHeight;
    }
    return _heightConstraint;
}

-(DLConstraint *)lessWidthConstraint{
    if (!_lessWidthConstraint) {
        _lessWidthConstraint = [[DLConstraint alloc]init];
        _lessWidthConstraint.needInstall = NO;
        _lessWidthConstraint.firstView = self.view;
        _lessWidthConstraint.secondView = self.view;
        _lessWidthConstraint.constraintType = LessHeight;
        _lessWidthConstraint.layoutRelation = NSLayoutRelationLessThanOrEqual;
        _lessWidthConstraint.firstAttribute = NSLayoutAttributeWidth;
    }
    return _lessWidthConstraint;
}

-(DLConstraint *)lessHeightConstraint{
    if (!_lessHeightConstraint) {
        _lessHeightConstraint = [[DLConstraint alloc]init];
        _lessHeightConstraint.needInstall = NO;
        _lessHeightConstraint.firstView = self.view;
        _lessHeightConstraint.constraintType = LessHeight;
        _lessHeightConstraint.secondView = self.view;
        _lessHeightConstraint.layoutRelation = NSLayoutRelationLessThanOrEqual;
        _lessHeightConstraint.firstAttribute = NSLayoutAttributeHeight;
    }
    return _lessHeightConstraint;
}

-(DLConstraint *)greatWidthConstraint{
    if (!_greatWidthConstraint) {
        _greatWidthConstraint = [[DLConstraint alloc]init];
        _greatWidthConstraint.needInstall = NO;
        _greatWidthConstraint.firstView = self.view;
        _greatWidthConstraint.secondView = self.view;
        _greatWidthConstraint.constraintType = GreatWidth;
        _greatWidthConstraint.firstAttribute = NSLayoutAttributeWidth;
        _greatWidthConstraint.layoutRelation = NSLayoutRelationGreaterThanOrEqual;
    }
    return _greatWidthConstraint;
}

-(DLConstraint *)greatHeightConstraint{
    if (!_greatHeightConstraint) {
        _greatHeightConstraint = [[DLConstraint alloc]init];
        _greatHeightConstraint.needInstall = NO;
        _greatHeightConstraint.firstView = self.view;
        _greatHeightConstraint.secondView = self.view;
        _greatHeightConstraint.constraintType = GreatHeight;
        _greatHeightConstraint.layoutRelation = NSLayoutRelationGreaterThanOrEqual;
        _greatHeightConstraint.firstAttribute = NSLayoutAttributeHeight;
    }
    return _greatHeightConstraint;
}

@end

@implementation DLConstraint

-(DLConstraint *(^)(UIView *view))equal{
    return ^(UIView *view) {
        self.secondView = view;
        self.secondAttribute = self.firstAttribute;
        return self;
    };
}

-(DLConstraint *(^)(AttributeType type))to{
    return ^(AttributeType type) {
        self.type = type;
        switch (type) {
            case DLAttributeLeft:
                self.secondAttribute = NSLayoutAttributeLeft;
                break;
                
            case DLAttributeRight:
                self.secondAttribute = NSLayoutAttributeRight;
                break;
                
            case DLAttributeTop:
                self.secondAttribute = NSLayoutAttributeTop;
                break;
                
            case DLAttributeBottom:
                self.secondAttribute = NSLayoutAttributeBottom;
                break;
                
            case DLAttributeWidth:
                self.secondAttribute = NSLayoutAttributeWidth;
                break;
                
            case DLAttributeHeight:
                self.secondAttribute = NSLayoutAttributeHeight;
                break;
                
            case DLAttributeCenterX:
                self.secondAttribute = NSLayoutAttributeCenterX;
                break;
                
            case DLAttributeCenterY:
                self.secondAttribute = NSLayoutAttributeCenterY;
                break;
                
            case DLAttributeSafeTop:
                self.secondAttribute = NSLayoutAttributeTop;
                break;
                
            case DLAttributeSafeLeft:
                self.secondAttribute = NSLayoutAttributeLeft;
                break;
                
            case DLAttributeSafeRight:
                self.secondAttribute = NSLayoutAttributeRight;
                break;
                
            case DLAttributeSafeBottom:
                self.secondAttribute = NSLayoutAttributeBottom;
                break;
                
            default:
                self.secondAttribute = NSLayoutAttributeNotAnAttribute;
                break;
        }
        return self;
    };
}

-(DLConstraint *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant) {
        if (constant > 1) {
            constant = 1;
        }else if (constant < 0) {
            constant = 0;
        }
        self.multiplier = constant;
        return self;
    };
}

-(DLConstraint *(^)(CGFloat constant))offset{
    return ^(CGFloat constant) {
        self.constant = constant;
        return self;
    };
}

-(DLConstraint *(^)(void))remove{
    return ^(void) {
        self.needDelete = YES;
        return self;
    };
}

@end
