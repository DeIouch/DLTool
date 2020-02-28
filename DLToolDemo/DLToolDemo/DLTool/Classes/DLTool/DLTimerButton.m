#import "DLTimerButton.h"
#include <objc/runtime.h>

@interface DLTimerButton()

/**
 *  控件的状态
 */
@property(nonatomic,assign)DLButtonState statusType;
/**
 *  计时的时间
 */
@property(nonatomic,assign)NSInteger timeCount;
/**
 *  计时原始时间
 */
@property(nonatomic,assign)NSInteger oldTimeCount;
/**
 *  计时器
 */
@property(weak, nonatomic) NSTimer *timer;

/// 计时器进入后台的时间
@property (nonatomic, assign) NSTimeInterval didEnterBackgroundTimestamp;

/**
 *  按钮默认情况下的文字颜色
 */
@property(nonatomic,strong)UIColor *normalTextColor;

@property(nonatomic,copy)NSString  *normalText;

/**
 *  按钮的初始背景色
 */
@property(nonatomic,strong)UIColor *normalBgColor;

@end

//用于关联block
static void *statusBlockKey = @"statusBlockKey";

@implementation DLTimerButton

/**
 *  设置计时按钮的时长和状态的回调
 *
 *  @param durtaion   时间 单位秒
 *  @param bustatus   状态的回调
 */
-(void)setDLTimerButtonWithDuration:(NSInteger)durtaion runingColor:(UIColor*)runingColor runingTextColor:(UIColor *)runingTextColor formatStr:(NSString *)formatStr buStatus:(void(^)(DLButtonState status))bustatus{
    _timeCount          = durtaion;
    _oldTimeCount       = durtaion;
    _statusType         = DLStatesNone;
    _formatStr          = formatStr;
    _runingColor        = runingColor;
    _runingTextColor    = runingTextColor;
    objc_setAssociatedObject(self, statusBlockKey, bustatus, OBJC_ASSOCIATION_COPY);
    bustatus(_statusType);
}

/**
 *  开始计时
 */
-(void)beginTimers{
    
    if (!self.timer) {
      NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(next) userInfo:nil repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
      self.timer = timer;
    }
    //更新时间
    _timeCount = _oldTimeCount;
    //记录按钮的原始状态
    _normalBgColor       = self.backgroundColor;
    _normalTextColor     = self.currentTitleColor;
    _normalText          = self.currentTitle;
    //设置按钮计时时的样式
    if (_runingColor) {
        [self setBackgroundColor:_runingColor];
    }
    if (_runingTextColor) {
        [self setTitleColor:_runingTextColor forState:UIControlStateNormal];
    }
    //让按钮不可以点击
    self.userInteractionEnabled = NO;
    self.titleLabel.adjustsFontSizeToFitWidth=YES;
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self next];
    _statusType     = DLStatusRuning;
    void (^statusBlock)(NSInteger) = objc_getAssociatedObject(self, statusBlockKey);
    statusBlock(_statusType);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

}
/**
 *  结束计时
 */
-(void)stopTimers{
    [self.timer invalidate];
     self.timer = nil;
    void (^statusBlock)(NSInteger) = objc_getAssociatedObject(self, statusBlockKey);
    
    if (_timeCount ==0) {//超时了
        _statusType     = DLStatusFinish;
        statusBlock(_statusType);
    }else{
        _statusType     = DLStatusCancel;
        //结束了但没有超时
        statusBlock(_statusType);
    }
    [self setBackgroundColor:_normalBgColor];
    [self setTitleColor:_normalTextColor forState:UIControlStateNormal];
    [self setTitle:_normalText forState:UIControlStateNormal];
    self.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)next
{
    if (_timeCount<1) {
        //结束了 超时了
        [self stopTimers];
    }else{
        //改文字
        if (_formatStr.length>0) {
           [self setTitle:[NSString stringWithFormat:_formatStr,_timeCount] forState:UIControlStateNormal];
        }else{
            [self setTitle:[NSString stringWithFormat:@"%zdS",_timeCount] forState:UIControlStateNormal];
        }
        _timeCount--;
    }
}

- (void)applicationDidEnterBackground:(id)sender {
    _didEnterBackgroundTimestamp = [[NSDate date] timeIntervalSince1970];
}

- (void)applicationWillEnterForeground:(id)sender {
    NSTimeInterval willEnterForegroundTimestamp = [[NSDate date] timeIntervalSince1970];
    NSInteger onBackgroundSeconds = floor((_didEnterBackgroundTimestamp == 0)? 0: (willEnterForegroundTimestamp - _didEnterBackgroundTimestamp));
    _timeCount -= onBackgroundSeconds;
}

-(void)dealloc{
//    NSLog(@"定时器被销毁了");
}

@end
