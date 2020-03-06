#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class DLConstraint;

typedef NS_ENUM(NSInteger, AttributeType) {
    DLAttributeLeft   =   1,
    DLAttributeRight,
    DLAttributeTop,
    DLAttributeBottom,
    DLAttributeWidth,
    DLAttributeHeight,
    DLAttributeCenterX,
    DLAttributeCenterY,
    DLAttributeNotAn,
    DLAttributeSafeLeft,
    DLAttributeSafeRight,
    DLAttributeSafeTop,
    DLAttributeSafeBottom,
};

@interface DLConstraintMaker : NSObject

-(DLConstraint *)left;

-(DLConstraint *)right;

-(DLConstraint *)top;

-(DLConstraint *)bottom;

-(DLConstraint *)width;

-(DLConstraint *)height;

-(DLConstraint *)lessWidth;

-(DLConstraint *)lessHeight;

-(DLConstraint *)greatWidth;

-(DLConstraint *)greatHeight;

-(DLConstraint *)centerX;

-(DLConstraint *)centerY;

-(instancetype)initWithView:(UIView *)view;

-(void)install;

@end

@interface DLConstraint : NSObject

-(DLConstraint *(^)(UIView *view))equal;

-(DLConstraint *(^)(AttributeType type))to;

-(DLConstraint *(^)(CGFloat constant))multipliedBy;

-(DLConstraint *(^)(CGFloat constant))offset;

-(DLConstraint *(^)(void))remove;

@end
