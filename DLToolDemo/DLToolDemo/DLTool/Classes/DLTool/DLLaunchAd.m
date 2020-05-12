#import "DLLaunchAd.h"
#import "UIView+Add.h"
#import "DLTimer.h"
#import "DLToolMacro.h"
#import <UIKit/UIKit.h>

@interface DLLaunchAdView : UIView

@property (nonatomic,weak) UIImageView *adImageView;

@property (nonatomic, copy) void(^touchAd)(void);

@property (nonatomic, copy) void(^timeArrive)(void);

@property (nonatomic, copy) NSString *timerStr;

@property (nonatomic, weak) UIButton *skipButton;

@property (nonatomic, assign) NSInteger second;

@property (nonatomic, strong) NSString *imageUrl;

@end

@implementation DLLaunchAdView

-(instancetype)init{
    if ([super init]) {
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
        [window addSubview:self];
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.adImageView = [UIImageView dl_view:^(UIImageView *imageView) {
            imageView.dl_backView(self);
            imageView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }];
        @dl_weakify;
        [self.adImageView addClickAction:^(UIView *view) {
            @dl_strongify;
            if (self.touchAd) {
                self.touchAd();
            }
        }];        
    }
    return self;
}


-(UIButton *)skipButton{
    if (!_skipButton) {
        _skipButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self).dl_normalTitle(@"跳过").dl_fontSize(13).dl_normalTitleColor(@"FFFFFF").dl_alignment(NSTextAlignmentCenter);
            button.backgroundColor = [[UIColor colorWithRed:16/255.0 green:16/255.0 blue:16/255.0 alpha:1] colorWithAlphaComponent:0.6];
            [button dl_AutoLayout:^(DLConstraintMaker *make) {
                make.width.offset(62);
                make.height.offset(26);
                make.right.equal(self).offset(-16);
                make.top.equal(self).to(DLAttributeSafeTop).offset(20);
            }];
            button.dl_allCorner(10);
        }];
        @dl_weakify;
        [_skipButton addClickAction:^(UIView *view) {
            @dl_strongify;
            [DLTimer cancelTask:self.timerStr];
            if (self.timeArrive) {
                self.timeArrive();
            }
        }];
    }
    return _skipButton;
}

-(void)setImageUrl:(NSString *)imageUrl{
    _imageUrl = imageUrl;
//    self.adImageView.dl_urlReduceImageString(imageUrl);
    __block NSInteger second = self.second;
    [self.skipButton setTitle:[NSString stringWithFormat:@"%ldS 跳过", (long)second] forState:UIControlStateNormal];
    self.timerStr = [DLTimer doTask:^{
        if (second) {
            second--;
            [self.skipButton setTitle:[NSString stringWithFormat:@"%ldS 跳过", (long)second] forState:UIControlStateNormal];
        }else{
            if (self.timeArrive) {
                self.timeArrive();
            }
            [DLTimer cancelTask:self.timerStr];
        }
    } start:0 interval:1 repeats:YES async:NO];
}

@end


@interface DLLaunchAd()

@property (nonatomic, strong) DLLaunchAdView *adView;

@end

@implementation DLLaunchAd

-(instancetype)_init{
    self = [super init];
    return self;
}

-(DLLaunchAdView *)adView{
    if (!_adView) {
        _adView = [[DLLaunchAdView alloc]init];
    }
    return _adView;
}

+(void)addLaunchAd:(NSString *)imageUrl secondTime:(NSInteger)second clickBlock:(void (^)(void))clickBlock timeArrierBlock:(void (^)(void))timeArrierBlock{
    DLLaunchAd *launchAd = [[DLLaunchAd alloc]_init];
    launchAd.adView.second = second;
    launchAd.adView.imageUrl = imageUrl;
    launchAd.adView.touchAd = [clickBlock copy];
    launchAd.adView.timeArrive = [timeArrierBlock copy];
}

@end
