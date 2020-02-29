#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class DLConstraint;

typedef NS_ENUM(NSInteger, ConstraintType) {
    ConstraintLeft  = NSLayoutAttributeLeft,
    ConstraintRight  = NSLayoutAttributeRight,
    ConstraintTop  = NSLayoutAttributeTop,
    ConstraintBottom  = NSLayoutAttributeBottom,
//    ConstraintSafeGuide  = NSLayoutAttributeLeft,
};


@interface DLConstraintMaker : NSObject

//-(DLConstraint *(^)(CGFloat constant))left;
//
//-(DLConstraint *(^)(CGFloat constant))right;
//
//-(DLConstraint *(^)(CGFloat constant))top;
//
//-(DLConstraint *(^)(CGFloat constant))bottom;
//
//-(DLConstraint *(^)(CGFloat constant))width;
//
//-(DLConstraint *(^)(CGFloat constant))height;
//
//-(DLConstraint *(^)(CGFloat constant))centerX;
//
//-(DLConstraint *(^)(CGFloat constant))centerY;


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

-(DLConstraint *(^)(id guide))equal;

-(DLConstraint *(^)(NSLayoutAttribute attribute))to;

//-(DLConstraint *(^)(id guide))safeGuide;

-(DLConstraint *(^)(UIView *view))greater_Then;

-(DLConstraint *(^)(UIView *view))less_Then;

-(DLConstraint *(^)(CGFloat constant))multipliedBy;

-(DLConstraint *(^)(CGFloat constant))offset;

@end
