#import "DLPerformanceLabel.h"
#import "DLWeakProxy.h"
#import "DLSafeProtector.h"
#import "UIView+Add.h"
#import "UIApplication+Add.h"

#define kSize CGSizeMake(55, 20)

@interface DLPerformanceLabel ()

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end

@implementation DLPerformanceLabel{
    CADisplayLink *_link;
    NSUInteger _count;
    NSTimeInterval _lastTime;
    UIFont *_font;
    UIFont *_subFont;
    NSTimeInterval _llll;
}

+(void)openMonitoring{
    [DLPerformanceLabel shareInstance].hidden = NO;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        performanceLabel = [super allocWithZone:zone];
    });
    return performanceLabel;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return performanceLabel;
}

- (instancetype)init {
    DLSafeProtectionCrashLog([NSException exceptionWithName:@"DLPerformanceLabel初始化失败" reason:@"使用'openMonitoring'开启监测" userInfo:nil],DLSafeProtectorCrashTypeInitError);
    return [super init];
}

- (instancetype)_init {
    if ([super init]) {
        self.layer.cornerRadius = 5;
        self.clipsToBounds = YES;
        self.textAlignment = NSTextAlignmentCenter;
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
        _font = [UIFont fontWithName:@"Menlo" size:14];
        if (_font) {
            _subFont = [UIFont fontWithName:@"Menlo" size:4];
        } else {
            _font = [UIFont fontWithName:@"Courier" size:14];
            _subFont = [UIFont fontWithName:@"Courier" size:4];
        }
        _link = [CADisplayLink displayLinkWithTarget:[DLWeakProxy proxyWithTarget:self] selector:@selector(tick:)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
        [window addSubview:self];
        [self dl_AutoLayout:^(DLConstraintMaker *make) {
            make.right.equal(window).offset(-10);
            make.top.equal(window).to(attributeSafeTop).offset(65);
            make.height.offset(50);
        }];
    }
    return self;
}

static DLPerformanceLabel *performanceLabel;

+(DLPerformanceLabel *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        performanceLabel = [[self alloc]_init];
    });
    return performanceLabel;
}

- (void)dealloc {
    [_link invalidate];
}

- (void)tick:(CADisplayLink *)link {
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    _count++;
    NSTimeInterval delta = link.timestamp - _lastTime;
    if (delta < 1) return;
    _lastTime = link.timestamp;
    float fps = _count / delta;
    _count = 0;
    CGFloat progress = fps / 60.0;
    UIColor *color = [UIColor colorWithHue:0.27 * (progress - 0.2) saturation:1 brightness:0.9 alpha:1];
    self.text = [NSString stringWithFormat:@"%d  FPS",(int)round(fps)];
    NSLog(@"%@ == %lf == %lld", self.text, [UIApplication sharedExtensionApplication].dl_cpuUsage, [UIApplication sharedExtensionApplication].dl_memoryUsage);
    self.textColor = color;
    self.font = _font;
}

@end
