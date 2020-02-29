#import <UIKit/UIKit.h>
#import "LayoutAtt.h"
#import "DLConstraintMaker.h"

@interface UIView (layoutAdd)

@property (nonatomic, assign, readonly) NSLayoutAttribute left;

@property (nonatomic, assign, readonly) NSLayoutAttribute right;

@property (nonatomic, assign, readonly) NSLayoutAttribute top;

@property (nonatomic, assign, readonly) NSLayoutAttribute bottom;

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_leftAttri;

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_rightAttri;

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_topAttri;

-(UIView *(^) (UIView *view, NSLayoutAttribute attribute, CGFloat constant))add_bottomAttri;


-(void)add_dlAutoLayout:(void (^)(DLConstraintMaker *make))block;


@end
