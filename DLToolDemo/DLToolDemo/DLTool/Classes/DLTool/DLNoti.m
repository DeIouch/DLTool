#import "DLNoti.h"
#include <objc/runtime.h>
#import "UIView+Add.h"
#import "DLLoad.h"

@interface DLNotiView : UIView

@property (nonatomic, strong) UILabel *notiLabel;

@end

@interface DLNoti()

@property (nonatomic, strong) DLNotiView *notiView;

@property (nonatomic, strong) UIView *backView;

@end

@implementation DLNoti

static DLNoti *noti = nil;

//- (instancetype)init {
//    DLSafeProtectionCrashLog([NSException exceptionWithName:@"DLNoti初始化失败" reason:@"使用'shareInstance'初始化" userInfo:nil],DLSafeProtectorCrashTypeInitError);
//    return [super init];
//}

- (instancetype)_init {
    self = [super init];
    return self;
}

+(DLNoti *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        noti = [[self alloc] _init];
    });
    return noti;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        noti = [super allocWithZone:zone];
    });
    return noti;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return noti;
}

-(void)showNotiTitle:(NSString *)titleString backView:(UIView *)backView{
    self.backView = backView ? backView : [[UIApplication sharedApplication].windows lastObject];
    self.notiView.notiLabel.dl_text(titleString);
    self.notiView.hidden = NO;
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(viewHidden) object:self];
    [self performSelector:@selector(viewHidden) withObject:self afterDelay:1.5];
    [[DLLoad shareInstance] viewHidden];
}

-(void)viewHidden{
    if (!_notiView.hidden) {
        _notiView.hidden = YES;
        [_notiView removeFromSuperview];
        _notiView = nil;
    }
}

-(DLNotiView *)notiView{
    if (!_notiView) {
        _notiView = [[DLNotiView alloc]init];
        [_backView addSubview:_notiView];
        _notiView.translatesAutoresizingMaskIntoConstraints = NO;
        [_backView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:_notiView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
            [NSLayoutConstraint constraintWithItem:_notiView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
        ]];
        [_notiView layoutIfNeeded];
        _notiView.layer.masksToBounds = YES;
        _notiView.layer.cornerRadius = 5;
    }
    return _notiView;
}

-(UIView *)backView{
    if (!_backView) {
        _backView = [[UIView alloc]init];
        _backView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _backView;
}

@end


@implementation DLNotiView

-(instancetype)init{
    if (self = [super init]) {
        self.dl_backColor(@[@"#00000030"]);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.notiLabel = [UILabel dl_view:^(UIView *view) {
            view.translatesAutoresizingMaskIntoConstraints = NO;
            view.dl_backView(self);
            view.dl_textColor(@[@"#ffffff"]).dl_lines(0).dl_alignment(NSTextAlignmentCenter).dl_fontSize(15);
            [self addConstraints:@[
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20],
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20],
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:10],
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-10],
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:60],
                [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:[UIScreen mainScreen].bounds.size.width - 100],
            ]];
        }];
    }
    return self;
}

@end
