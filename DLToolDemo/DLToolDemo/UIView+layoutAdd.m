#import "UIView+layoutAdd.h"
#include <NewsstandKit/NewsstandKit.h>

@implementation UIView (layoutAdd)

-(NSLayoutAttribute)left{
    return NSLayoutAttributeLeft;
}

-(NSLayoutAttribute)right{
    return NSLayoutAttributeRight;
}

-(NSLayoutAttribute)top{
    return NSLayoutAttributeTop;
}

-(NSLayoutAttribute)bottom{
    return NSLayoutAttributeBottom;
}

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_leftAttri{
    return ^(UIView *view, NSLayoutAttribute attribute, CGFloat constant) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:attribute multiplier:1 constant:constant]];
        return self;
    };
}

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_rightAttri{
    return ^(UIView *view, NSLayoutAttribute attribute, CGFloat constant) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:attribute multiplier:1 constant:constant]];
        return self;
    };
}

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_topAttri{
    return ^(UIView *view, NSLayoutAttribute attribute, CGFloat constant) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:attribute multiplier:1 constant:constant]];
        return self;
    };
}

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_bottomAttri{
    return ^(UIView *view, NSLayoutAttribute attribute, CGFloat constant) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [view addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:attribute multiplier:1 constant:constant]];
        return self;
    };
}

-(void)add_dlAutoLayout:(void (^)(DLConstraintMaker *make))block{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    DLConstraintMaker *constraintMaker = [[DLConstraintMaker alloc]initWithView:self];
    block(constraintMaker);
    [constraintMaker install];    
}

@end
