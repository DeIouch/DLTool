#import "DLAlert.h"
#include <objc/runtime.h>
#import "UIView+Add.h"
#import "DLAutoLayout.h"
@class DLAlertView;

@interface DLAlert ()

@property (nonatomic, strong) DLAlertView *alertView;

@end

/// 提示框视图
@interface DLAlertView : UIView

/// 提示信息
@property (nonatomic, strong) UILabel *messageLabel;

/// 取消按钮
@property (nonatomic, strong) UIButton *cancelButton;

/// 确认按钮
@property (nonatomic, strong) UIButton *sureButton;

/// 背景视图
@property (nonatomic, strong) UIView *backView;

@end

@implementation DLAlert

static DLAlert *alert = nil;

//- (instancetype)init {
//    DLSafeProtectionCrashLog([NSException exceptionWithName:@"DLAlert初始化失败" reason:@"使用'shareInstance'初始化" userInfo:nil],DLSafeProtectorCrashTypeInitError);
//    return [super init];
//}

- (instancetype)_init {
    self = [super init];
    return self;
}

+(DLAlert *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alert = [[self alloc] _init];
    });
    return alert;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alert = [super allocWithZone:zone];
    });
    return alert;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    return alert;
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone {
    return [self copyWithZone:zone];
}

-(void)alertAttMessage:(NSAttributedString *)message
           cancelTitle:(NSString *)cancelTitle
             sureTitle:(NSString *)sureTitle
             sureBlock:(DLAlertSureBlock)sureBlock
{
    self.alertView.hidden = NO;
    if (sureTitle.length > 0) {
        self.alertView.sureButton.dl_normalTitle(sureTitle);
    }
    if (cancelTitle.length > 0) {
        self.alertView.cancelButton.dl_normalTitle(cancelTitle);
    }
    self.alertView.messageLabel.attributedText = message;
    [self.alertView.backView dl_updateAutoLayouts:^{
        dl_layout_height(70 + [self.alertView.backView dl_fittingHeightWithSubview:self.alertView.messageLabel]);
    }];
    [self alertShow];
    __weak typeof(self) weakself = self;
    [self.alertView.sureButton addClickAction:^(UIView *view) {
        !sureBlock ? : sureBlock();
        [weakself alertHidden];
    }];
}

-(void)alertMessage:(NSString *)message
        cancelTitle:(NSString *)cancelTitle
          sureTitle:(NSString *)sureTitle
          sureBlock:(DLAlertSureBlock)sureBlock
{
    self.alertView.hidden = NO;
    if (sureTitle.length > 0) {
        self.alertView.sureButton.dl_normalTitle(sureTitle);
    }
    if (cancelTitle.length > 0) {
        self.alertView.cancelButton.dl_normalTitle(cancelTitle);
    }
    self.alertView.messageLabel.text = message;
    [self.alertView.backView dl_updateAutoLayouts:^{
        dl_layout_height(70 + [self.alertView.backView dl_fittingHeightWithSubview:self.alertView.messageLabel]);
    }];
    [self alertShow];
    __weak typeof(self) weakself = self;
    [self.alertView.sureButton addClickAction:^(UIView *view) {
        !sureBlock ? : sureBlock();
        [weakself alertHidden];
    }];
}

-(void)alertShow{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animation];
    bounceAnimation.duration = 0.3;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:1.05],
                              [NSNumber numberWithFloat:0.95],
                              [NSNumber numberWithFloat:1.0],
                              nil];
    [self.alertView.backView.layer addAnimation:bounceAnimation forKey:@"transform.scale"];
}

-(void)alertHidden{
    __weak typeof(self) weakself = self;
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animation];
    bounceAnimation.duration = 0.16;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:0.6],
                              [NSNumber numberWithFloat:0.4],
                              [NSNumber numberWithFloat:0.2],
                              [NSNumber numberWithFloat:0],
                              nil];
    [weakself.alertView.backView.layer addAnimation:bounceAnimation forKey:@"transform.scale"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakself.alertView.hidden = YES;
    });
}

-(DLAlertView *)alertView{
    if (!_alertView) {
        _alertView = [[DLAlertView alloc]init];
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
        [window addSubview:_alertView];
        [_alertView dl_addConstraints:^(DLAutoLayoutMaker *layout) {
            layout.edgeEqualTo(window);
        }];
        __weak typeof(self) weakself = self;
        [_alertView.sureButton addClickAction:^(UIView *view) {
            [weakself alertHidden];
        }];
        _alertView.backView.dl_allCorner(5);
    }
    return _alertView;
}

@end

@implementation DLAlertView

-(instancetype)init{
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.backgroundColor = [[UIColor colorWithRed:16/255.0 green:16/255.0 blue:16/255.0 alpha:1] colorWithAlphaComponent:0.6];
        self.backView = [UIView dl_view:^(UIView *view) {
            view.dl_backView(self).dl_backColor(@"#FFFFFF");
            [view dl_addAutoLayouts:^{
                dl_layout_rightEqualTo(self, 38);
                dl_layout_leftEqualTo(self, 38);
                dl_layout_centerY(self);
                dl_layout_height([UIScreen mainScreen].bounds.size.height);
            }];
        }];
        
        self.messageLabel = [UILabel dl_view:^(UILabel *label) {
            label.dl_backView(self.backView);
            label.dl_backColor(@"#FFFFFF");
            label.dl_fontSize(15).dl_alignment(NSTextAlignmentCenter).dl_textColor(@"#777777").dl_lines(0);
            [label dl_addAutoLayouts:^{
                dl_layout_leftEqualTo(self.backView, 40);
                dl_layout_rightEqualTo(self.backView, 40);
                dl_layout_topEqualTo(self.backView, 25);
                dl_layout_heightGreaterThanOrEqual(40);
            }];
        }];

        self.cancelButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self.backView).dl_backColor(@"#FFFFFF");
            button.dl_normalTitle(@"取消").dl_normalTitleColor(@"#777777").dl_fontSize(16);
            [button dl_addAutoLayouts:^{
                dl_layout_leftEqualTo(self.backView, 0);
                dl_layout_bottomEqualTo(self.backView, 0);
                dl_layout_width(([UIScreen mainScreen].bounds.size.width - 76) * 0.5);
                dl_layout_height(47);
            }];
        }];
        
        self.sureButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self.backView).dl_backColor(@"#FFFFFF");
            button.dl_normalTitle(@"确定").dl_normalTitleColor(@"#4AB134").dl_fontSize(16);
            [button dl_addAutoLayouts:^{
                dl_layout_rightEqualTo(self.backView, 0);
                dl_layout_bottomEqualTo(self.backView, 0);
                dl_layout_width(([UIScreen mainScreen].bounds.size.width - 76) * 0.5);
                dl_layout_height(47);
            }];
        }];
        
        [UIView dl_view:^(UIView *view) {
            view.dl_backView(self.backView);
            view.dl_backColor(@"#E6E6E6");
            [view dl_addAutoLayouts:^{
                dl_layout_leftEqualTo(self.backView, 0);
                dl_layout_rightEqualTo(self.backView, 0);
                dl_layout_height(1);
                dl_layout_bottomEqualTo(self.backView, 47);
            }];
        }];

        [UIView dl_view:^(UIView *view) {
            view.dl_backView(self.backView);
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.dl_backColor(@"#E6E6E6");
            [view dl_addAutoLayouts:^{
                dl_layout_width(1);
                dl_layout_height(48);
                dl_layout_leftEqualTo(self.sureButton, 0);
                dl_layout_bottomEqualTo(self.backView, 0);
            }];
        }];
        
        
    }
    return self;
}

@end
