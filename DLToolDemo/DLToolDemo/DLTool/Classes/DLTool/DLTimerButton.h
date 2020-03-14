//  按钮定时器，兼容后台倒计时场景

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, DLButtonState) {
    DLStatesNone,       //  计时未开始
    DLStatusRuning,     //  计时进行中
    DLStatusCancel,     //  结束了（手动结束）
    DLStatusFinish,     //  计时结束了
};

@interface DLTimerButton : UIButton

/**
 *  格式化文字 例如（剩余时间%zd秒）
 */
@property(nonatomic,copy) NSString  *formatStr;

/**
 *  正在计时按钮的背景颜色
 */
@property(nonatomic,strong)UIColor *runingColor;

/**
 *  正在计时按钮的文字的颜色
 */
@property(nonatomic,strong)UIColor *runingTextColor;

/**
 *  设置计时按钮的时长和状态的回调(和下面的方法只用一个就行)
 *
 *  @param durtaion   时间 单位秒
 *  @param bustatus   状态的回调
 */
-(void)setDLTimerButtonWithDuration:(NSInteger)durtaion runingColor:(UIColor*)runingColor runingTextColor:(UIColor *)runingTextColor formatStr:(NSString *)formatStr buStatus:(void(^)(DLButtonState status))bustatus;

/**
 *  开始计时
 */
-(void)beginTimers;
/**
 *  结束计时
 */
-(void)stopTimers;

@end
