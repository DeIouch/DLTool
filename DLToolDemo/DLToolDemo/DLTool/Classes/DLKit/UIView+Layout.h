#import <UIKit/UIKit.h>

//  优点：
//          约束不会冲突，同一个方向的约束只会生效设置的最后一条
//          可以在任意位置添加约束，可以在添加到父视图之前添加约束，不会崩溃

typedef NS_OPTIONS(NSInteger, DLLayoutType) {
    DL_left                                                     =   1 << 0,
    DL_right                                                   =   1 << 1,
    DL_top                                                     =   1 << 2,
    DL_bottom                                               =   1 << 3,
    DL_safeTop                                              =   1 << 4,
    DL_safeBottom                                         =   1 << 5,
    DL_width                                                  =   1 << 6,
    DL_lessOrThanWidth                                  =   1 << 7,
    DL_greatOrThenWidth                                =   1 << 8,
    DL_height                                                 =   1 << 9,
    DL_lessOrThanHeight                                 =   1 << 10,
    DL_greatOrThanHeight                               =   1 << 11,
    DL_centerX                                               =   1 << 12,
    DL_centerY                                               =   1 << 13,
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
