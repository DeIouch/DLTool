#import "DLConstraintMaker.h"

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

@property (nonatomic, assign) BOOL hasInstall;

@end

@interface DLConstraintMaker ()

@property (nonatomic, weak) UIView *view;

@property (nonatomic, strong) DLConstraint *leftConstraint;

@property (nonatomic, strong) DLConstraint *rightConstraint;

@property (nonatomic, strong) DLConstraint *topConstraint;

@property (nonatomic, strong) DLConstraint *bottomConstraint;

@property (nonatomic, strong) DLConstraint *centerXConstraint;

@property (nonatomic, strong) DLConstraint *centerYConstraint;

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

- (NSArray <UIView *> *)findCommonSuperView:(UIView *)viewOne other:(UIView *)viewOther{
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
    // 初始化为第一父视图
    UIView *temp = view.superview;
    // 保存结果的数组
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:view];
    while (temp) {
        [result addObject:temp];
        // 顺着superview指针一直向上查找
        temp = temp.superview;
    }
    return result;
}

-(void)install{
    for (DLConstraint *constraint in self.constraintArray) {
        UIView *view;
        if (!constraint.secondView) {
            constraint.secondView = self.view.superview;
            view = self.view.superview;
        }else if (self.view.superview == constraint.secondView) {
            view = constraint.secondView;
        }else{
            view = [self findCommonSuperView:self.view other:constraint.secondView][0];
        }
        if (constraint.type == attributeSafeBottom || constraint.type == attributeSafeTop || constraint.type == attributeSafeRight || constraint.type == attributeSafeLeft) {
            constraint.item = view.safeAreaLayoutGuide;
        }else{
            constraint.item = constraint.secondView;
        }
        [view addConstraint:[self addConstraint:constraint]];
        constraint.hasInstall = YES;
    }
}

-(NSLayoutConstraint *)addConstraint:(DLConstraint *)constraint{
    NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self.view attribute:constraint.firstAttribute relatedBy:constraint.layoutRelation toItem:constraint.item attribute:constraint.secondAttribute ? constraint.secondAttribute : constraint.firstAttribute multiplier:constraint.multiplier constant:constraint.constant];
    return cons;
}

-(DLConstraint *)left{
    self.leftConstraint.firstView = self.view;
    self.leftConstraint.multiplier = 1;
    self.leftConstraint.constant = 0;
    self.leftConstraint.firstAttribute = NSLayoutAttributeLeft;
    [self.constraintArray addObject:self.leftConstraint];
    return self.leftConstraint;
}

-(DLConstraint *)right{
    self.rightConstraint.firstView = self.view;
    self.rightConstraint.multiplier = 1;
    self.rightConstraint.constant = 0;
    self.rightConstraint.firstAttribute = NSLayoutAttributeRight;
    [self.constraintArray addObject:self.rightConstraint];
    return self.rightConstraint;
}

-(DLConstraint *)top{
    self.topConstraint.firstView = self.view;
    self.topConstraint.multiplier = 1;
    self.topConstraint.constant = 0;
    self.topConstraint.firstAttribute = NSLayoutAttributeTop;
    [self.constraintArray addObject:self.topConstraint];
    return self.topConstraint;
}

-(DLConstraint *)bottom{
    self.bottomConstraint.firstView = self.view;
    self.bottomConstraint.multiplier = 1;
    self.bottomConstraint.constant = 0;
    self.bottomConstraint.firstAttribute = NSLayoutAttributeBottom;
    [self.constraintArray addObject:self.bottomConstraint];
    return self.bottomConstraint;
}

-(DLConstraint *)width{
    DLConstraint *constraint = [[DLConstraint alloc]init];
    constraint.firstView = self.view;
    constraint.multiplier = 0;
    constraint.constant = 0;
    constraint.firstAttribute = NSLayoutAttributeWidth;
    [self.constraintArray addObject:constraint];
    return constraint;
}

-(DLConstraint *)height{
    DLConstraint *constraint = [[DLConstraint alloc]init];
    constraint.multiplier = 0;
    constraint.constant = 0;
    constraint.firstAttribute = NSLayoutAttributeHeight;
    [self.constraintArray addObject:constraint];
    return constraint;
}

-(DLConstraint *)centerX{
    self.centerXConstraint.firstView = self.view;
    self.centerXConstraint.multiplier = 1;
    self.centerXConstraint.constant = 0;
    self.centerXConstraint.firstAttribute = NSLayoutAttributeCenterX;
    [self.constraintArray addObject:self.centerXConstraint];
    return self.centerXConstraint;
}

-(DLConstraint *)centerY{
    self.centerYConstraint.firstView = self.view;
    self.centerYConstraint.multiplier = 1;
    self.centerYConstraint.constant = 0;
    self.centerYConstraint.firstAttribute = NSLayoutAttributeCenterY;
    [self.constraintArray addObject:self.centerYConstraint];
    return self.centerYConstraint;
}

-(DLConstraint *)leftConstraint{
    if (!_leftConstraint) {
        _leftConstraint = [[DLConstraint alloc]init];
        _leftConstraint.hasInstall = NO;
    }
    return _leftConstraint;
}

-(DLConstraint *)rightConstraint{
    if (!_rightConstraint) {
        _rightConstraint = [[DLConstraint alloc]init];
        _rightConstraint.hasInstall = NO;
    }
    return _rightConstraint;
}

-(DLConstraint *)topConstraint{
    if (!_topConstraint) {
        _topConstraint = [[DLConstraint alloc]init];
        _topConstraint.hasInstall = NO;
    }
    return _topConstraint;
}

-(DLConstraint *)bottomConstraint{
    if (!_bottomConstraint) {
        _bottomConstraint = [[DLConstraint alloc]init];
        _bottomConstraint.hasInstall = NO;
    }
    return _bottomConstraint;
}

-(DLConstraint *)centerXConstraint{
    if (!_centerXConstraint) {
        _centerXConstraint = [[DLConstraint alloc]init];
        _centerXConstraint.hasInstall = NO;
    }
    return _centerXConstraint;
}

-(DLConstraint *)centerYConstraint{
    if (!_centerYConstraint) {
        _centerYConstraint = [[DLConstraint alloc]init];
        _centerYConstraint.hasInstall = NO;
    }
    return _centerYConstraint;
}

@end

@implementation DLConstraint

-(DLConstraint *(^)(UIView *view))equal{
    return ^(UIView *view) {
        self.secondView = view;
        self.layoutRelation = NSLayoutRelationEqual;
        if ((self.firstAttribute == NSLayoutAttributeWidth || self.firstAttribute == NSLayoutAttributeHeight) && !self.multiplier) {
            self.multiplier = 1;
        }
        self.secondAttribute = self.firstAttribute;
        return self;
    };
}

-(DLConstraint *(^)(AttributeType type))to{
    return ^(AttributeType type) {
        self.type = type;
        switch (type) {
            case attributeLeft:
                self.secondAttribute = NSLayoutAttributeLeft;
                break;
                
            case attributeRight:
                self.secondAttribute = NSLayoutAttributeRight;
                break;
                
            case attributeTop:
                self.secondAttribute = NSLayoutAttributeTop;
                break;
                
            case attributeBottom:
                self.secondAttribute = NSLayoutAttributeBottom;
                break;
                
            case attributeWidth:
                self.secondAttribute = NSLayoutAttributeWidth;
                break;
                
            case attributeHeight:
                self.secondAttribute = NSLayoutAttributeHeight;
                break;
                
            case attributeCenterX:
                self.secondAttribute = NSLayoutAttributeCenterX;
                break;
                
            case attributeCenterY:
                self.secondAttribute = NSLayoutAttributeCenterY;
                break;
                
            case attributeSafeTop:
                self.secondAttribute = NSLayoutAttributeTop;
                break;
                
            case attributeSafeLeft:
                self.secondAttribute = NSLayoutAttributeLeft;
                break;
                
            case attributeSafeRight:
                self.secondAttribute = NSLayoutAttributeRight;
                break;
                
            case attributeSafeBottom:
                self.secondAttribute = NSLayoutAttributeBottom;
                break;
                
            default:
                self.secondAttribute = NSLayoutAttributeNotAnAttribute;
                break;
        }
        return self;
    };
}

-(DLConstraint *(^)(UIView *view))greater_Then{
    return ^(UIView *view) {
        self.secondView = view;
        self.layoutRelation = NSLayoutRelationGreaterThanOrEqual;
        return self;
    };
}

-(DLConstraint *(^)(UIView *view))less_Then{
    return ^(UIView *view) {
        self.secondView = view;
        self.layoutRelation = NSLayoutRelationLessThanOrEqual;
        return self;
    };
}

-(DLConstraint *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant) {
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

@end



