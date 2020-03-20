#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LayoutType) {
    To          =   1,              //  同一侧
    By,                              //  另一侧
};

@interface UIView (Layout)

-(UIView *(^)(UIView *view, CGFloat constant, LayoutType type))left_constant_view;

-(UIView *(^)(UIView *view, CGFloat constant, LayoutType type))right_constant_view;

-(UIView *(^)(UIView *view, CGFloat constant, LayoutType type))top_constant_view;

-(UIView *(^)(UIView *view, CGFloat constant, LayoutType type))bottom_constant_view;

-(UIView *(^)(UIView *view, CGFloat multiplied))left_multiplied_view;

-(UIView *(^)(UIView *view, CGFloat multiplied))right_multiplied_view;

-(UIView *(^)(UIView *view, CGFloat multiplied))top_multiplied_view;

-(UIView *(^)(UIView *view, CGFloat multiplied))bottom_multiplied_view;

@end
