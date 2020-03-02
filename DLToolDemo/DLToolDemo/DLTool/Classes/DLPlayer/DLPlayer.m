#import "DLPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "DLAlert.h"
#import "DLLoad.h"
#import "DLTimer.h"
#import "DLToolMacro.h"
#import "UIView+Add.h"
#import "NSObject+Add.h"
#import "DLNoti.h"

@interface DLPlayer()

/// 播放器视图
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *currentPlayerItem;

@property (nonatomic, strong) UIView *playerView;

@property (nonatomic, assign) BOOL haveNoti;

@property (nonatomic, strong) NSString *timeIdentifier;

@end

@implementation DLPlayer

static DLPlayer *player = nil;
+(DLPlayer *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[self alloc] init];
    });
    return player;
}

-(void)start{
    if (self.videoUrl.length == 0) {
        [[DLAlert shareInstance]alertMessage:@"播放地址为空" cancelTitle:@"取消" sureTitle:@"确定" sureBlock:nil];
        return;
    }
    _skinView.isPlay = YES;
    [self.player play];
}

-(void)setIsRefresh:(BOOL)isRefresh{
    _isRefresh = isRefresh;
    if (isRefresh) {
        [[DLLoad shareInstance]showLoadTitle:@"" loadType:LoadShowing backView:self.fatherView];
//        [self.skinView.playButton viewHidden:0];
    }else{
        [[DLLoad shareInstance]viewHidden];
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground:(NSNotification *)notify {
    self.skinView.didEnterBackground = YES;
    if (self.skinView.isPauseByUser) {
        [self pause];
        self.skinView.isPauseByUser = YES;
    }else{
        [self pause];
    }
    
}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground:(NSNotification *)notify {
    self.skinView.didEnterBackground = NO;
    if (!self.skinView.isPauseByUser) {
        [self start];
    }
}

-(void)pause{
    _skinView.isPlay = NO;
    
}

-(void)setVideoUrl:(NSString *)videoUrl{
    _videoUrl = videoUrl;
    if (videoUrl.length > 0 && self.fatherView != nil) {
        [self.fatherView addSubview:self.playerView];
        self.playerView.dl_left_to_layout(self.fatherView, 0).dl_top_to_layout(self.fatherView, 0).dl_right_to_layout(self.fatherView, 0).dl_bottom_to_layout(self.fatherView, 0);
        [self.fatherView bringSubviewToFront:self.playerView];
        [self addNoti];
        self.isRefresh = YES;
    }else{
        [self pause];
    }
}

-(void)removeNoti{
    if (self.haveNoti) {
        
        self.haveNoti = NO;
    }
}

-(void)addNoti{
    if (!self.haveNoti) {
        self.haveNoti = YES;
        
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}


-(void)setFatherView:(UIView *)fatherView{
    [_playerView removeFromSuperview];
    _fatherView = fatherView;
    [DLTimer cancelTask:self.timeIdentifier];
    if (self.videoUrl.length == 0) {
        _fatherView = fatherView;
        return;
    }
    if (fatherView == nil) {
        [self pause];
        [self removeNoti];
    }else{
        [_fatherView addSubview:self.playerView];
        self.playerView.dl_left_to_layout(fatherView, 0).dl_top_to_layout(fatherView, 0).dl_right_to_layout(fatherView, 0).dl_bottom_to_layout(fatherView, 0);
        [_fatherView bringSubviewToFront:self.playerView];
        [self addNoti];
    }
}

-(UIView *)playerView {
    if (!_playerView) {
        _playerView = [UIView dl_view:^(UIView * _Nonnull view) {
            view.dl_backColor(@[@"FFFFFF"]);
//            [view addSubview:self.ijkPlayer.view];
        }];
    }
    return _playerView;
}

-(void)setSkinView:(DLPlayerSkinView *)skinView {
    if (_skinView == skinView) {
        return;
    }
    [_skinView removeFromSuperview];
    _skinView = skinView;
    [self.playerView addSubview:_skinView];
    _skinView.titleLabel.dl_text(_videoTitle);
    _skinView.dl_left_to_layout(self.playerView, 0).dl_top_to_layout(self.playerView, 0).dl_right_to_layout(self.playerView, 0).dl_bottom_to_layout(self.playerView, 0);
    _skinView.player = self;
//    [[DLLoad shareInstance]showLoadTitle:@"" loadType:LoadShowing backView:self.fatherView];
//    [self.skinView.playButton viewHidden:0];
    self.isRefresh = YES;
    if ([@"DLVodPlayerSkinView" isEqualToString:NSStringFromClass([skinView class])]) {
        self.isVod = YES;
    }else{
        self.isVod = NO;
    }
}

-(void)setVideoTitle:(NSString *)videoTitle {
    _videoTitle = videoTitle;
    if (_skinView != nil) {
        _skinView.titleLabel.dl_text(videoTitle);
    }
}

@end


@implementation DLPlayerSkinView

static UISlider * _volumeSlider;

-(instancetype)init{
    if ([super init]) {
        self.backgroundColor = [UIColor clearColor];
        _isPlay = YES;
        self.identifierStr = @"DLPlayerSkinView";
        [self addGestureRecognizer:self.singleTap];
        [self addGestureRecognizer:self.panRecognizer];
//        CGRect frame = CGRectMake(0, -100, 10, 0);
//        self.volumeView = [[MPVolumeView alloc] initWithFrame:frame];
//        [self.volumeView sizeToFit];
//        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
//            if (!window.isHidden) {
//                [window addSubview:self.volumeView];
//                break;
//            }
//        }
//
//        // 单例slider
//        _volumeSlider = nil;
//        for (UIView *view in [self.volumeView subviews]){
//            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
//                _volumeSlider = (UISlider *)view;
//                break;
//            }
//        }
        self.topFuncView.hidden = YES;
        self.bottomFuncView.hidden = NO;
        self.playButton.hidden = NO;
        self.screenButton.hidden = NO;
        [self funcExtension];
        [self viewTouch];
    }
    return self;
}

-(void)funcExtension{

}

+(UISlider *)volumeViewSlider {
    return _volumeSlider;
}

-(void)setClarityArray:(NSArray *)clarityArray{
    _clarityArray = clarityArray;
    if (clarityArray.count == 0) {
        return;
    }
    self.clarityButton.hidden = NO;
    self.clarityView.clarityArray = clarityArray;
}

-(UIButton *)clarityButton{
    if (!_clarityButton) {
        _clarityButton = [UIButton dl_view:^(UIView *view) {
            view.dl_backView(self.topFuncView).dl_text(@"清晰度").dl_fontSize(13).dl_textColor(@"#FFFFFF").dl_top_to_layout(self.topFuncView, 10.5).dl_right_to_layout(self.topFuncView, 97).dl_height_layout(23);
            view.dl_clickEdge(20);
            [view layoutSubviews];
            view.layer.cornerRadius = 12;
            view.layer.masksToBounds = YES;
            view.layer.borderColor = [[UIColor whiteColor]CGColor];
            view.layer.borderWidth = 1;
            @dl_weakify;
            
            view.clickAction = ^(UIView *view) {
                @dl_strongify;
                [self viewTouch];
                                [[DLLoad shareInstance]viewHidden];
                                self.clarityView.hidden = NO;
                //                if (self.screenType == VideoFullScreen) {
                //                    [UIView animateWithDuration:0.5 animations:^{
                //                        self.clarityView.dl_top_to_layout(self, 0).dl_right_to_layout(self, 0).dl_bottom_to_layout(self, 0).dl_width_multiplier_layout(self, 0.5);
                //                        [self layoutIfNeeded];
                //                    }];
                //                }else if (self.screenType == VideoSmallScreen) {
                                    [UIView animateWithDuration:0.5 animations:^{
                                        self.clarityView.dl_left_to_layout(self, 0).dl_top_to_layout(self, 0).dl_right_to_layout(self, 0).dl_bottom_to_layout(self, 0);
                                        [self layoutIfNeeded];
                                    }];
                //                }
            };
        }];
    }
    return _clarityButton;
}

-(ClarityView *)clarityView{
    if (!_clarityView) {
        _clarityView = [[ClarityView alloc]init];
        [self addSubview:_clarityView];
        _clarityView.hidden = YES;
        _clarityView.dl_left_by_layout(self, 0).dl_top_to_layout(self, 0).dl_bottom_to_layout(self, 0);
        @dl_weakify;
        
        _clarityView.closeButton.clickAction = ^(UIView *view) {
           @dl_strongify;
            [self viewTouch];
            [UIView animateWithDuration:0.5 animations:^{
                self.clarityView.dl_left_by_layout(self, 0).dl_width_layout(0);
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                if (finished) {
                    self.clarityView.hidden = YES;
                }
            }];
            self.player.isRefresh = self.player.isRefresh;
        };
    }
    return _clarityView;
}

-(UITapGestureRecognizer *)singleTap {
    if (!_singleTap) {
        _singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(viewTouch)];
        _singleTap.delegate                = self;
        _singleTap.numberOfTouchesRequired = 1; //手指数
        _singleTap.numberOfTapsRequired    = 1;
    }
    return _singleTap;
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    // self.contentView为子控件
//    if ([NSStringFromClass([touch.view class]) isEqualToString:@"DLPlayerSkinView"] || [NSStringFromClass([touch.view class]) isEqualToString:@"DLLivePlayerSkinView"] || [NSStringFromClass([touch.view class]) isEqualToString:@"DLVodPlayerSkinView"]) {
//        return YES;
//    }
    
    if ([touch.view.identifierStr isEqualToString:@"DLPlayerSkinView"]) {
        return YES;
    }
    return NO;
}

-(void)viewTouch {
    if (self.topFuncView.hidden) {
        [[self.topFuncView dl_viewShow] dl_viewHidden:5];
        [[self.bottomFuncView dl_viewShow] dl_viewHidden:5];
        if ([DLLoad shareInstance].loadShowBOOL) {
            [[self.playButton dl_viewShow] dl_viewHidden:5];
        }else{
            [self.playButton dl_viewHidden:5];
        }
    }else{
        [self.topFuncView dl_viewHidden:0];
        [self.bottomFuncView dl_viewHidden:0];
        [self.playButton dl_viewHidden:0];
    }
}

-(UIPanGestureRecognizer *)panRecognizer{
    if (!_panRecognizer) {
        _panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
        _panRecognizer.delegate = self;
        [_panRecognizer setMaximumNumberOfTouches:1];
        [_panRecognizer setDelaysTouchesBegan:YES];
        [_panRecognizer setDelaysTouchesEnded:YES];
        [_panRecognizer setCancelsTouchesInView:YES];
    }
    return _panRecognizer;
}

-(void)panDirection:(UIPanGestureRecognizer *)pan{
    if (self.player.isVod) {
        CGPoint locationPoint = [pan locationInView:self];
        CGPoint veloctyPoint = [pan velocityInView:self];
//        if (!self.player.ijkPlayer.isPlaying) {
//            return;
//        }
        switch (pan.state) {
            case UIGestureRecognizerStateBegan:
                {
                    CGFloat x = fabs(veloctyPoint.x);
                    CGFloat y = fabs(veloctyPoint.y);
                    if (x > y) {    //  水平移动
                        self.panDirection = PanDirectionHorizontalMoved;
                    }else if (x < y) {  //  垂直移动
                        self.panDirection = PanDirectionVerticalMoved;
                        // 开始滑动的时候,状态改为正在控制音量
                        if (locationPoint.x > self.bounds.size.width / 2) {
                            self.isVolume = YES;
                        }else { // 状态改为显示亮度调节
                            self.isVolume = NO;
                        }
                        self.isDragging = YES;
                        [self.player.skinView dl_viewHidden:0.2];
                    }
                }
                break;
                
            case UIGestureRecognizerStateChanged:{ // 正在移动
                switch (self.panDirection) {
                    case PanDirectionHorizontalMoved:{
                        [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                        break;
                    }
                    case PanDirectionVerticalMoved:{
                        [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                        break;
                    }
                    default:
                        break;
                }
                self.isDragging = YES;
                break;
            }
                
            case UIGestureRecognizerStateEnded:{ // 移动停止
                // 移动结束也需要判断垂直或者平移
                // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
                switch (self.panDirection) {
                    case PanDirectionHorizontalMoved:{
                        self.isPauseByUser = NO;
//                        self.player.ijkPlayer.currentPlaybackTime = self.sumTime;
                        // 把sumTime滞空，不然会越加越多
                        self.sumTime = 0;
                        break;
                    }
                    case PanDirectionVerticalMoved:{
                        // 垂直移动结束后，把状态改为不再控制音量
                        self.isVolume = NO;
                        break;
                    }
                    default:
                        break;
                }
//                    [self fastViewUnavaliable];
                self.isDragging = NO;
                break;
            }
                
            case UIGestureRecognizerStateCancelled: {
                self.sumTime = 0;
                self.isVolume = NO;
                self.isDragging = NO;
            }
                break;
                
            default:
                break;
        }
    }
}

//  pan垂直移动的方法
-(void)verticalMoved:(CGFloat)value {
    if (self.isVolume) {
        [[self class] volumeViewSlider].value -= value / 10000;
    }
}

//  pan水平移动的方法
-(void)horizontalMoved:(CGFloat)value {
    // 每次滑动需要叠加时间
    CGFloat totalMovieDuration = [self allDuration];
    CGFloat changeDuration = value / 10000 * totalMovieDuration;
    if (!self.isDragging) {
        self.sumTime = [self playDuration];
    }
    self.sumTime += changeDuration;
    if (self.sumTime > totalMovieDuration) {
        self.sumTime = totalMovieDuration;
    }
    if (self.sumTime < 0) {
        self.sumTime = 0;
    }
    [[DLNoti shareInstance] showNotiTitle:[NSString stringWithFormat:@"%@", [self converTimeStr:(int)self.sumTime]] backView:self];
}

-(NSString *)converTimeStr:(int)time{
    return [NSString stringWithFormat:@"%0.2d:%0.2d", time / 60 , time % 60];
}

- (void)volumeChanged:(NSNotification *)notification {
    if (self.isDragging)
        return; // 正在拖动，不响应音量事件
    if (![[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
        return;
    }
//    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
}

- (CGFloat)playDuration {
//    CMTimeGetSeconds(<#CMTime time#>)
//    return self.player.currentPlayerItem.duration;
    return 10;
}

- (CGFloat)allDuration {
//    return self.player.ijkPlayer.duration;
    return 10;
}

//-(void)setIsPlay:(BOOL)isPlay {
//    _isPlay = isPlay;
//    self.playButton.selected = !isPlay;
//    if (isPlay) {
//        [self.player.ijkPlayer play];
//    }else{
//        [self.player.ijkPlayer pause];
//    }
//    self.isPauseByUser = NO;
//}

-(UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton dl_view:^(UIView *view) {
            view.dl_backView(self).dl_normalImage(@"play").dl_selectImage(@"pause").dl_centerX_layout(self, 0).dl_centerY_layout(self, 0).dl_width_layout(50).dl_height_layout(50);
        }];
        @dl_weakify;
        _playButton.clickAction = ^(UIView *view) {
            @dl_strongify;
            self.isPlay = !self.isPlay;
            self.isPauseByUser = YES;
        };
    }
    return _playButton;
}

-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel dl_view:^(UIView *view) {
            view.dl_backView(self.topFuncView).dl_fontSize(18).dl_textColor(@[@"FFFFFF"]).dl_alignment(NSTextAlignmentLeft).dl_left_to_layout(self.topFuncView, 38).dl_top_to_layout(self.topFuncView, 24);
        }];
    }
    return _titleLabel;
}

-(UIImageView *)topFuncView {
    if (!_topFuncView) {
        _topFuncView = [UIImageView dl_view:^(UIView * _Nonnull view) {
            view.dl_backView(self).dl_imageString(@"video_top_gray").dl_left_to_layout(self, 0).dl_right_to_layout(self, 0).dl_top_to_layout(self, 0).dl_height_layout(70);
        }];
    }
    return _topFuncView;
}

-(UIImageView *)bottomFuncView {
    if (!_bottomFuncView) {
        _bottomFuncView = [UIImageView dl_view:^(UIView * _Nonnull view) {
            view.dl_backView(self).dl_imageString(@"video_bottom_gray").dl_left_to_layout(self, 0).dl_right_to_layout(self, 0).dl_bottom_to_layout(self, 0).dl_height_layout(70);
        }];
    }
    return _bottomFuncView;
}

-(UIButton *)screenButton{
    if (!_screenButton) {
        _screenButton = [UIButton dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_normalImage(@"video_full_screen").dl_selectImage(@"video_small_screen").dl_right_to_layout(self.bottomFuncView, 22).dl_bottom_to_layout(self.bottomFuncView, 32).dl_width_layout(16).dl_height_layout(16).dl_clickEdge(30);
            @dl_weakify;
            view.clickAction = ^(UIView *view) {
                @dl_strongify;
                self.screenType = !self.screenType;
            };
        }];
    }
    return _screenButton;
}

-(void)setScreenType:(VideoScreenType)screenType{
    self.screenButton.selected = screenType;
    if (screenType == _screenType) {
        return;
    }
    _screenType = screenType;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    switch (screenType) {
        case VideoFullScreen:
            {
                if (window == nil) {
                    return;
                }
                window.windowLevel = UIWindowLevelStatusBar + 1;
                [self.player.playerView removeFromSuperview];
                [window addSubview:self.player.playerView];
                self.player.playerView.dl_top_to_layout(window, 0).dl_right_by_layout(window, 0).dl_top_to_layout(window, 0).dl_bottom_to_layout(window, 0);
//                if (self.player.ijkPlayer.naturalSize.width >= self.player.ijkPlayer.naturalSize.height) {
//                    [self orientationToPortrait:UIInterfaceOrientationLandscapeRight];
//                }else{
//                    [self orientationToPortrait:UIInterfaceOrientationPortrait];
//                }
            }
            break;

        case VideoSmallScreen:
            {
                window.windowLevel = UIWindowLevelNormal;
                [self orientationToPortrait:UIInterfaceOrientationPortrait];
                [self.player.fatherView addSubview:self.player.playerView];
                self.player.playerView.dl_top_to_layout(self.player.fatherView, 0).dl_right_by_layout(self.player.fatherView, 0).dl_top_to_layout(self.player.fatherView, 0).dl_bottom_to_layout(self.player.fatherView, 0);
            }
            break;

        default:
            break;
    }
}

-(DLPlayer *)player{
    if (!_player) {
        _player = [DLPlayer shareInstance];
    }
    return _player;
}

//强制旋转屏幕
- (void)orientationToPortrait:(UIInterfaceOrientation)orientation{
    
    SEL selector = NSSelectorFromString(@"setOrientation:");
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    
    [invocation setSelector:selector];
    
    [invocation setTarget:[UIDevice currentDevice]];
    
    int val = (int)orientation;
    
    [invocation setArgument:&val atIndex:2];//前两个参数已被target和selector占用
    
    [invocation invoke];
}

@end


@implementation DLLivePlayerSkinView

-(void)funcExtension{
    NSLog(@"funcExtension 2");
}

@end


@implementation DLVodPlayerSkinView

-(UILabel *)playTimeLabel{
    if (!_playTimeLabel) {
        _playTimeLabel = [UILabel dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_textColor(@"#FFFFFFF").dl_fontSize(14).dl_alignment(NSTextAlignmentCenter).dl_text(@"00:00").dl_left_to_layout(self.bottomFuncView, 4).dl_bottom_to_layout(self.bottomFuncView, 32).dl_width_layout(68);
        }];
    }
    return _playTimeLabel;
}

-(UILabel *)allTimeLabel{
    if (!_allTimeLabel) {
        _allTimeLabel = [UILabel dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_textColor(@"#FFFFFFF").dl_fontSize(14).dl_alignment(NSTextAlignmentCenter).dl_text(@"00:00").dl_right_to_layout(self.bottomFuncView, 52).dl_bottom_to_layout(self.bottomFuncView, 32).dl_width_layout(66);
        }];
    }
    return _allTimeLabel;
}

-(UIView *)playProgressView{
    if (!_playProgressView) {
        _playProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_left_to_layout(self.bottomFuncView, 72.5).dl_bottom_to_layout(self.bottomFuncView, 39.5).dl_height_layout(2).dl_width_multiplier_layout(self.allProgressView, 1).dl_backColor(@"#279858");
        }];
    }
    return _playProgressView;
}

-(UIView *)cacheProgressView{
    if (!_cacheProgressView) {
        _cacheProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_left_to_layout(self.bottomFuncView, 72.5).dl_bottom_to_layout(self.bottomFuncView, 39.5).dl_height_layout(2).dl_width_multiplier_layout(self.allProgressView, 1).dl_backColor(@"#F4FDF3");
        }];
    }
    return _cacheProgressView;
}

-(UIView *)allProgressView{
    if (!_allProgressView) {
        _allProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_backView(self.bottomFuncView).dl_left_to_layout(self.bottomFuncView, 72.5).dl_bottom_to_layout(self.bottomFuncView, 39.5).dl_height_layout(2).dl_right_to_layout(self.bottomFuncView, 118).dl_backColor(@"#778666");
        }];
    }
    return _allProgressView;
}

-(void)funcExtension{
    NSLog(@"funcExtension 3");
    
    [self.bottomFuncView addSubview:self.playTimeLabel];
    [self.bottomFuncView addSubview:self.allTimeLabel];
    [self.bottomFuncView addSubview:self.allProgressView];
    [self.bottomFuncView addSubview:self.cacheProgressView];
    [self.bottomFuncView addSubview:self.playProgressView];
    
    self.player.timeIdentifier = [DLTimer doTask:^{
//        if (self.player.ijkPlayer.duration <= 0) {
//            return;
//        }
//       self.playTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", ((int)self.player.ijkPlayer.currentPlaybackTime / 60), ((int)self.player.ijkPlayer.currentPlaybackTime % 60)];
//       self.allTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", ((int)self.player.ijkPlayer.duration / 60), ((int)self.player.ijkPlayer.duration % 60)];
//       self.playProgressView.dl_width_multiplier_layout(self.allProgressView, self.player.ijkPlayer.currentPlaybackTime / self.player.ijkPlayer.duration);
//        self.cacheProgressView.dl_width_multiplier_layout(self.allProgressView, self.player.ijkPlayer.playableDuration / self.player.ijkPlayer.duration);
//        self.allProgressView.allCorner(2);
//        self.cacheProgressView.allCorner(2);
//        self.playProgressView.allCorner(2);
   } start:0 interval:1 repeats:YES async:NO];
}

@end



@implementation ClarityView

-(DLPlayer *)player{
    if (!_player) {
        _player = [DLPlayer shareInstance];
    }
    return _player;
}

-(instancetype)init{
    if ([super init]) {
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.75;
        [UILabel dl_view:^(UIView *view) {
            view.dl_backView(self).dl_text(@"清晰度").dl_textColor(@"FFFFFF").dl_fontSize(15).dl_left_to_layout(self, 66).dl_top_to_layout(self, 69).dl_height_layout(15);
        }];
        self.closeButton = [UIButton dl_view:^(UIView *view) {
            view.dl_backView(self).dl_normalImage(@"close_white").dl_right_to_layout(self, 20).dl_top_to_layout(self, 29 + DLStatusBarHeight).dl_width_layout(13).dl_height_layout(13).dl_clickEdge(30);
        }];
    }
    return self;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ClarityCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ClarityCollectionViewCell" forIndexPath:indexPath];
    PlaysUrlModel *model = self.clarityArray[indexPath.row];
    cell.clarityString = model.zhTitle;
    cell.chooseState = (self.player.skinView.urlModel.clarityInteger == model.clarityInteger);
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self.player.skinView viewTouch];
    [UIView animateWithDuration:0.5 animations:^{
        self.dl_left_to_layout(self.player.skinView, DLWidth).dl_width_layout(0);
        [self.player.skinView layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            self.hidden = YES;
        }
    }];
    self.player.skinView.urlModel = self.clarityArray[indexPath.row];
    self.player.skinView.clarityButton.dl_normalTitle([NSString stringWithFormat:@"   %@   ", self.player.skinView.urlModel.zhTitle]);
    self.player.videoUrl = self.player.skinView.urlModel.url;
    [self.player start];
    [self.collectionView reloadData];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _clarityArray.count;
}

-(void)setClarityArray:(NSArray *)clarityArray{
    if (clarityArray.count > 0) {
        NSMutableArray *array = [[NSMutableArray alloc]init];
        for (NSDictionary *dic in clarityArray) {
            [array addObject:[PlaysUrlModel dl_modelWithDictionary:dic]];
        }
        _clarityArray = array;
        self.player.skinView.urlModel = _clarityArray.firstObject;
        self.player.skinView.clarityButton.dl_normalTitle([NSString stringWithFormat:@"   %@   ", self.player.skinView.urlModel.zhTitle]);
        [self.collectionView reloadData];
    }
}

-(UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.itemSize = CGSizeMake(87, 40);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(66, 118, 300, 200) collectionViewLayout:layout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.alwaysBounceHorizontal = YES;
        _collectionView.alwaysBounceVertical = NO;
        _collectionView.userInteractionEnabled = YES;
        [_collectionView registerClass:[ClarityCollectionViewCell class] forCellWithReuseIdentifier:@"ClarityCollectionViewCell"];
        [self addSubview:self.collectionView];
        _collectionView.dl_left_to_layout(self, 66).dl_right_to_layout(self, 26).dl_top_to_layout(self, 98).dl_bottom_to_layout(self, 40);
    }
    return _collectionView;
}

@end


@implementation ClarityCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backImageView = [UIImageView dl_view:^(UIView *view) {
            view.dl_backView(self.contentView).dl_imageString(@"ClarityDefault");
            view.frame = CGRectMake(0, 0, 69, 27);
        }];
        
        self.clarityLabel = [UILabel dl_view:^(UIView *view) {
            view.dl_backView(self.contentView).dl_textColor(@"FFFFFF").dl_fontSize(14).dl_alignment(NSTextAlignmentCenter);
            view.frame = CGRectMake(0, 0, 69, 27);
        }];
    }
    return self;
}

-(void)setChooseState:(BOOL)chooseState{
    if (chooseState) {
        self.backImageView.dl_imageString(@"ClaritySelected");
        self.clarityLabel.dl_textColor(@"4AB134");
    }else{
        self.backImageView.dl_imageString(@"ClarityDefault");
        self.clarityLabel.dl_textColor(@"ffffff");
    }
}

-(void)setClarityString:(NSString *)clarityString{
    self.clarityLabel.dl_text(clarityString);
}

@end

@implementation PlaysUrlModel


@end
