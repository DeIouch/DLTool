#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class DLConstraint;

typedef NS_ENUM(NSInteger, AttributeType) {
    attributeLeft   =   1,
    attributeRight,
    attributeTop,
    attributeBottom,
    attributeWidth,
    attributeHeight,
    attributeCenterX,
    attributeCenterY,
    attributeNotAn,
    attributeSafeLeft,
    attributeSafeRight,
    attributeSafeTop,
    attributeSafeBottom,
};

@interface DLConstraintMaker : NSObject

-(DLConstraint *)left;

-(DLConstraint *)right;

-(DLConstraint *)top;

-(DLConstraint *)bottom;

-(DLConstraint *)width;

-(DLConstraint *)height;

-(DLConstraint *)centerX;

-(DLConstraint *)centerY;

-(instancetype)initWithView:(UIView *)view;

-(void)install;

@end

@interface DLConstraint : NSObject

-(DLConstraint *(^)(UIView *view))equal;

-(DLConstraint *(^)(AttributeType type))to;

-(DLConstraint *(^)(UIView *view))greater_Then;

-(DLConstraint *(^)(UIView *view))less_Then;

-(DLConstraint *(^)(CGFloat constant))multipliedBy;

-(DLConstraint *(^)(CGFloat constant))offset;

@end
