#import "DLLoad.h"
#include <objc/runtime.h>
#import "UIView+Add.h"
#import "DLNoti.h"
#import "DLSafeProtector.h"

/// 加载视图
@interface DLLoadView : UIView

/// 加载图片
@property (nonatomic, strong) UIImageView *loadImageView;

/// 加载文字
@property (nonatomic, strong) UILabel *titleLabel;

@end

@interface DLLoad()

@property (nonatomic, strong) DLLoadView *loadView;

@property (nonatomic, strong) UIView *backView;

@end


@implementation DLLoad

static DLLoad *load = nil;

- (instancetype)init {
    DLSafeProtectionCrashLog([NSException exceptionWithName:@"DLLoad初始化失败" reason:@"使用'shareInstance'初始化" userInfo:nil],DLSafeProtectorCrashTypeInitError);
    return [super init];
}

- (instancetype)_init {
    self = [super init];
    return self;
}

+(DLLoad *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        load = [[self alloc] _init];
        load.loadShowBOOL = YES;
    });
    return load;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        load = [super allocWithZone:zone];
    });
    return load;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return load;
}

-(void)showLoadTitle:(NSString *)titleString loadType:(DLLoadType)loadType backView:(UIView *)backView{
    self.backView = backView ? backView : [[UIApplication sharedApplication] keyWindow];
    self.loadView.hidden = NO;
    self.loadShowBOOL = NO;
    [self.loadView.layer removeAllAnimations];
    switch (loadType) {
        case LoadShowing:
            {
                self.loadView.loadImageView.dl_imageString(@"loading");
                NSString *keyPath = @"transform.rotation.z";
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
                animation.fillMode = kCAFillModeForwards;
                animation.removedOnCompletion = NO;
                //值
                animation.fromValue = [NSNumber numberWithFloat:0];
                animation.toValue = [NSNumber numberWithFloat:2*M_PI];
                animation.duration = 1.5;
                CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
                groupAnnimation.duration = 1.5;
                groupAnnimation.repeatCount = MAXFLOAT;
                groupAnnimation.animations = @[animation];
                groupAnnimation.fillMode = kCAFillModeForwards;
                groupAnnimation.removedOnCompletion = NO;
                [self.loadView.loadImageView.layer addAnimation:groupAnnimation forKey:@"group"];
                self.loadView.titleLabel.text = titleString.length > 0 ? titleString : @"加载中";
            }
            break;
            
        case LoadSuccess:
            {
                self.loadView.loadImageView.dl_imageString(@"loadSuccess");
                self.loadView.titleLabel.text = titleString.length > 0 ? titleString : @"加载成功";
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(viewHidden) object:self];
                [self performSelector:@selector(viewHidden) withObject:self afterDelay:1.5];
            }
            break;
            
        case LoadFailed:
            {
                self.loadView.loadImageView.dl_imageString(@"loadFail");
                self.loadView.titleLabel.text = titleString.length > 0 ? titleString : @"加载失败";
                [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(viewHidden) object:self];
                [self performSelector:@selector(viewHidden) withObject:self afterDelay:1.5];
            }
            break;
            
        default:
            break;
    }
    [[DLNoti shareInstance] viewHidden];
}

-(void)viewHidden{
    if (!_loadView.hidden) {
        _loadView.hidden = YES;
        self.loadShowBOOL = YES;
        [_loadView.loadImageView.layer removeAllAnimations];
    }
}

-(DLLoadView *)loadView{
    if (!_loadView) {
        _loadView = [[DLLoadView alloc]init];
        [self.backView addSubview:_loadView];
        _loadView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.backView addConstraints:@[
            [NSLayoutConstraint constraintWithItem:_loadView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
            [NSLayoutConstraint constraintWithItem:_loadView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_backView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
        ]];
        _loadView.dl_allCorner(5);
    }
    return _loadView;
}

-(UIView *)backView{
    if (!_backView) {
        _backView = [[UIView alloc]init];
        _backView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _backView;
}

@end

@implementation DLLoadView

-(instancetype)init{
    if (self = [super init]) {
        self.dl_backColor(@[@"#00000030"]);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.loadImageView = [UIImageView dl_view:^(UIImageView *imageView) {
            imageView.dl_backView(self);
            imageView.translatesAutoresizingMaskIntoConstraints = NO;
            [self addConstraints:@[
                [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50],
                [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:50],
                [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20],
                [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20],
                [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:20],
            ]];
        }];
        
        self.titleLabel = [UILabel dl_view:^(UILabel *label) {
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.dl_backView(self);
            label.dl_lines(1).dl_textColor(@[@"#FFFFFF"]).dl_fontSize(12).dl_alignment(NSTextAlignmentCenter);
            [self addConstraints:@[
                [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:20],
                [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:-20],
                [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.loadImageView attribute:NSLayoutAttributeBottom multiplier:1 constant:10],
                [NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-25],
            ]];
        }];
    }
    return self;
}

@end
