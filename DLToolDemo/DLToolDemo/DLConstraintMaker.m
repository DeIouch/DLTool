#import "DLConstraintMaker.h"

@interface DLConstraint ()

@property (nonatomic, weak) UIView *firstView;

@property (nonatomic, weak) id secondView;

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

@property (nonatomic, strong) DLConstraint *widthConstraint;

@property (nonatomic, strong) DLConstraint *heightConstraint;

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

-(void)install{
    for (DLConstraint *constraint in self.constraintArray) {
        
        NSLog(@"secondView  ==  %@", [constraint.secondView class]);
        if ([NSStringFromClass([constraint.secondView class]) isEqualToString:@"UILayoutGuide"]) {
            [self.view.superview addConstraint:[self addConstraint:constraint]];
        }else{
            UIView *view = (UIView *)constraint.secondView;
//            if ([constraint.firstView.superview isEqual:view.superview]) {
//                [view.superview addConstraint:[self addConstraint:constraint]];
//            }else{
                [view.superview addConstraint:[self addConstraint:constraint]];
//            }
        }
        constraint.hasInstall = YES;
    }
}

-(NSLayoutConstraint *)addConstraint:(DLConstraint *)constraint {
    NSLayoutConstraint *cons = [NSLayoutConstraint constraintWithItem:self.view attribute:constraint.firstAttribute relatedBy:constraint.layoutRelation toItem:constraint.secondView ? constraint.secondView : self.view.superview attribute:constraint.secondAttribute ? constraint.secondAttribute : constraint.firstAttribute multiplier:constraint.multiplier constant:constraint.constant];
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
    self.widthConstraint.firstView = self.view;
    self.widthConstraint.multiplier = 0;
    self.widthConstraint.constant = 0;
    self.widthConstraint.firstAttribute = NSLayoutAttributeWidth;
    [self.constraintArray addObject:self.widthConstraint];
    return self.widthConstraint;
}

-(DLConstraint *)height{
    self.heightConstraint.firstView = self.view;
    self.heightConstraint.multiplier = 0;
    self.heightConstraint.constant = 0;
    self.heightConstraint.firstAttribute = NSLayoutAttributeHeight;
    [self.constraintArray addObject:self.heightConstraint];
    return self.heightConstraint;
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

-(DLConstraint *)widthConstraint{
    if (!_widthConstraint) {
        _widthConstraint = [[DLConstraint alloc]init];
        _widthConstraint.hasInstall = NO;
    }
    return _widthConstraint;
}

-(DLConstraint *)heightConstraint{
    if (!_heightConstraint) {
        _heightConstraint = [[DLConstraint alloc]init];
        _heightConstraint.hasInstall = NO;
    }
    return _heightConstraint;
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

-(DLConstraint *(^)(id guide))equal{
    return ^(id guide) {
        self.secondView = guide;
        self.layoutRelation = NSLayoutRelationEqual;
        if ((self.firstAttribute == NSLayoutAttributeWidth || self.firstAttribute == NSLayoutAttributeHeight) && !self.multiplier) {
            self.multiplier = 1;
        }
        self.secondAttribute = self.firstAttribute;
        return self;
    };
}

-(DLConstraint *(^)(NSLayoutAttribute attribute))to{
    return ^(NSLayoutAttribute attribute) {
        self.secondAttribute = attribute;
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


