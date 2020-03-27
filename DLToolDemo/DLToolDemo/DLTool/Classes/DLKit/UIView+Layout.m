#import "UIView+Layout.h"
#import <objc/runtime.h>
#import "DLToolMacro.h"
#import "UIView+Add.h"

@implementation DLLayout

-(DLLayout *(^)(UIView *view))equal{
    return ^(UIView *view){
        self.secondView = view;
        return self;
    };
}

-(DLLayout *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        self.constant = constant;
        return self;
    };
}

@end

@implementation DLLayoutMark

-(instancetype)init{
    if ([super init]) {
        self.array = [[NSMutableArray alloc]init];
        self.needInstall = NO;
    }
    return self;
}

-(DLLayout *)leftConstraint{
    if (!_leftConstraint) {
        _leftConstraint = [[DLLayout alloc]init];
        _leftConstraint.firstAttribute = NSLayoutAttributeLeft;
        _leftConstraint.layoutRelation = NSLayoutRelationEqual;
        _leftConstraint.multiplied = 1;
    }
    return _leftConstraint;
}

-(DLLayout *)rightConstraint{
    if (!_rightConstraint) {
        _rightConstraint = [[DLLayout alloc]init];
        _rightConstraint.firstAttribute = NSLayoutAttributeRight;
        _rightConstraint.layoutRelation = NSLayoutRelationEqual;
        _rightConstraint.multiplied = 1;
    }
    return _rightConstraint;
}

-(DLLayout *)topConstraint{
    if (!_topConstraint) {
        _topConstraint = [[DLLayout alloc]init];
        _topConstraint.firstAttribute = NSLayoutAttributeTop;
        _topConstraint.layoutRelation = NSLayoutRelationEqual;
        _topConstraint.multiplied = 1;
    }
    return _topConstraint;
}

-(DLLayout *)bottomConstraint{
    if (!_bottomConstraint) {
        _bottomConstraint = [[DLLayout alloc]init];
        _bottomConstraint.firstAttribute = NSLayoutAttributeBottom;
        _bottomConstraint.layoutRelation = NSLayoutRelationEqual;
        _bottomConstraint.multiplied = 1;
    }
    return _bottomConstraint;
}

-(DLLayoutMark *(^)(UIView *view))equal{
    return ^(UIView *view){
        self.needInstall = YES;
        for (DLLayout *layout in self.array) {
            layout.secondView = view;
        }
        return self;
    };
}

-(DLLayoutMark *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        self.needInstall = YES;
        for (DLLayout *layout in self.array) {
            layout.constant = constant;
        }
        return self;
    };
}

-(DLLayoutMark *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant){
        self.needInstall = YES;
        for (DLLayout *layout in self.array) {
            layout.multiplied = constant;
        }
        return self;
    };
}

-(void)install{
    for (DLLayout *layout in self.array) {
        if (layout.needDelete) {
            continue;
        }
        if (!layout.needInstall) {
            continue;
        }
        UIView *view;
        if (!layout.secondView) {
            view = layout.firstView.superview;
        }else if (layout.firstView.superview == layout.secondView) {
            view = layout.secondView;
        }else{
            view = [layout.firstView getCommonSuperView:layout.secondView];;
        }
        layout.item = view;
        NSLayoutConstraint *constraint = [self addConstraint:layout];
        layout.constraint = constraint;
        layout.fatherView = view;
        layout.needInstall = NO;
//        @try {
        
        
            [view addConstraint:constraint];
//        } @catch (NSException *exception) {
//            DLSafeProtectionCrashLog(exception, DLSafeProtectorCrashTypeViewLayout);
//        }
    }
    [self.array removeAllObjects];
    self.needInstall = NO;
}


-(NSLayoutConstraint *)addConstraint:(DLLayout *)layout{
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:layout.firstView attribute:layout.firstAttribute relatedBy:layout.layoutRelation toItem:layout.item attribute:layout.secondAttribute multiplier:layout.multiplied constant:layout.constant];
    return constraint;
}

@end



static char const autolayout_markKey;

@implementation UIView (Layout)

-(UIView *(^)(UIView *view))left{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.leftConstraint.needInstall = YES;
        self.mark.leftConstraint.secondAttribute = NSLayoutAttributeLeft;
        self.mark.leftConstraint.firstView = self;
        self.mark.leftConstraint.secondView = view;
        [self.mark.array addObject:self.mark.leftConstraint];
        return self;
    };
}

-(UIView *(^)(UIView *view))right{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.rightConstraint.needInstall = YES;
        self.mark.rightConstraint.secondAttribute = NSLayoutAttributeRight;
        self.mark.rightConstraint.firstView = self;
        [self.mark.array addObject:self.mark.rightConstraint];
        self.mark.rightConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))top{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.topConstraint.needInstall = YES;
        self.mark.topConstraint.secondAttribute = NSLayoutAttributeTop;
        self.mark.topConstraint.firstView = self;
        [self.mark.array addObject:self.mark.topConstraint];
        self.mark.topConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))bottom{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.bottomConstraint.needInstall = YES;
        self.mark.bottomConstraint.secondAttribute = NSLayoutAttributeBottom;
        self.mark.bottomConstraint.firstView = self;
        [self.mark.array addObject:self.mark.bottomConstraint];
        self.mark.bottomConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))leftTo{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.leftConstraint.needInstall = YES;
        self.mark.leftConstraint.firstView = self;
        self.mark.leftConstraint.secondAttribute = NSLayoutAttributeRight;
        [self.mark.array addObject:self.mark.leftConstraint];
        self.mark.leftConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))rightTo{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.rightConstraint.needInstall = YES;
        self.mark.rightConstraint.secondAttribute = NSLayoutAttributeLeft;
        self.mark.rightConstraint.firstView = self;
        [self.mark.array addObject:self.mark.rightConstraint];
        self.mark.rightConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))topTo{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.topConstraint.needInstall = YES;
        self.mark.topConstraint.secondAttribute = NSLayoutAttributeBottom;
        self.mark.topConstraint.firstView = self;
        [self.mark.array addObject:self.mark.topConstraint];
        self.mark.topConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(UIView *view))bottomTo{
    return ^(UIView *view){
        if (self.mark.needInstall) {
            [self.mark install];
        }
        self.mark.bottomConstraint.needInstall = YES;
        self.mark.bottomConstraint.secondAttribute = NSLayoutAttributeTop;
        self.mark.bottomConstraint.firstView = self;
        [self.mark.array addObject:self.mark.bottomConstraint];
        self.mark.bottomConstraint.secondView = view;
        return self;
    };
}

-(UIView *(^)(CGFloat constant))offset{
    return ^(CGFloat constant){
        if (self.mark.array.count > 0) {
            self.mark.offset(constant);
        }
        return self;
    };
}

-(UIView *(^)(UIView *view))equal{
    return ^(UIView *view){
        if (self.mark.array.count > 0) {
            self.mark.equal(view);
        }
        return self;
    };
}

-(UIView *(^)(CGFloat constant))multipliedBy{
    return ^(CGFloat constant){
        if (self.mark.array.count > 0) {
            self.mark.multipliedBy(constant);
        }
        return self;
    };
}

-(UIView *(^)(void))layout_install{
    return ^(void){
        [self.mark install];
        return self;
    };
}





















-(DLLayoutMark *)mark{
    DLLayoutMark *tempMark = objc_getAssociatedObject(self, &autolayout_markKey);
    if (!tempMark) {
        tempMark = [[DLLayoutMark alloc]init];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        objc_setAssociatedObject(self, &autolayout_markKey, tempMark, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tempMark;
}

-(void)setMark:(DLLayoutMark *)mark{
    objc_setAssociatedObject(self, &autolayout_markKey, mark, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
