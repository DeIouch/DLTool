#import <UIKit/UIKit.h>

//  优点：
//          约束不会冲突，同一个方向的约束只会生效设置的最后一条
//          可以在任意位置添加约束，可以在添加到父视图之前添加约束，不会崩溃

typedef NS_OPTIONS(NSInteger, DLLayoutType) {
    DL_Left                                                     =   1 << 0,
    DL_Right                                                   =   1 << 1,
    DL_Top                                                     =   1 << 2,
    DL_Bottom                                               =   1 << 3,
    DL_SafeTop                                              =   1 << 4,
    DL_SafeBottom                                         =   1 << 5,
    DL_Width                                                  =   1 << 6,
    DL_LessOrThanWidth                                  =   1 << 7,
    DL_GreatOrThenWidth                                =   1 << 8,
    DL_Height                                                 =   1 << 9,
    DL_LessOrThanHeight                                 =   1 << 10,
    DL_GreatOrThanHeight                               =   1 << 11,
    DL_CenterX                                               =   1 << 12,
    DL_CenterY                                               =   1 << 13,
};

@interface UIView (Layout)

-(UIView *(^)(DLLayoutType type))dl_layout;

-(UIView *(^)(DLLayoutType type))dl_remove_layout;

-(UIView *(^)(UIView *view))equal;

-(UIView *(^)(UIView *view))equal_to;

-(UIView *(^)(CGFloat constant))multipliedBy;

-(UIView *(^)(CGFloat constant))offset;

-(UIView *(^)(NSInteger constant))priority;

@end
