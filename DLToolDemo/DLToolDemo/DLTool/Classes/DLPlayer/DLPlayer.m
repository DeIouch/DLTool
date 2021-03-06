#import "DLPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "DLAlert.h"
#import "DLLoad.h"
#import "DLTimer.h"
#import "DLToolMacro.h"
#import "UIView+Add.h"
#import "NSObject+Add.h"
#import "DLNoti.h"
#include <objc/runtime.h>
#import "DLColor.h"
#import <UIKit/UIKit.h>
#import "UIView+Layout.h"


typedef NS_ENUM(NSInteger, DLBarrageDataType) {
    DLBarrageNormalType      =   0,        //  普通用户
    DLBarrageMemberType,                   //  VIP用户
};


typedef NS_ENUM(NSUInteger, DLBarrageViewStatus) {
    DLBarrageViewStatusStart         = 0,  //开始
    DLBarrageViewStatusEnter         = 1,  //完全进入到屏幕
    DLBarrageViewStatusEnd           = 2   //完全离开屏幕
};

@interface DLBarrageModel : NSObject

@property (nonatomic, strong) NSString *title;

@property (nonatomic, assign) DLBarrageDataType dataType;

-(instancetype)initWithTitle:(NSString *)title
                    dataType:(DLBarrageDataType)dataType;

@end

@interface DLBarrageView : UIView

typedef void(^MovementStatus)(DLBarrageViewStatus status,NSUInteger indexOfTracks,DLBarrageView *view);

@property (nonatomic, strong) DLBarrageModel *model;

@property (nonatomic, copy) MovementStatus movementStatus;

@property (nonatomic, assign) DLBarrageViewStatus status;

@property (nonatomic, assign) NSTimeInterval animationDuration;

@property (nonatomic, assign) NSUInteger indexOfTracks;

- (void)srartWithAnimationDuration:(NSTimeInterval)duration animationScreenWidth:(CGFloat)Width;

@property (nonatomic, strong) UILabel *title;

@property (nonatomic, strong) UIImageView *imageView;

@end


@protocol DLBarrageMangerDataSource;

@interface DLBarrageViewManager : NSObject

@property (nonatomic, weak) id<DLBarrageMangerDataSource> dataSource;

@property (nonatomic, assign) BOOL isStarted;

@property (nonatomic, assign) BOOL isFinished;

+(DLBarrageViewManager *)shareInstance;

-(void)packageData;

-(void)start;

-(void)stop;

-(void)appendData;

@end

@protocol DLBarrageMangerDataSource <NSObject>

@required;

- (NSUInteger)numberOfItemsControlleredByDanmakuManger:(DLBarrageViewManager *)manger;

- (DLBarrageModel *)danmakuManger:(DLBarrageViewManager *)manger informationForItem:(NSUInteger)index;

@end

@interface DLPlayer()<DLBarrageMangerDataSource>

/// 播放器
@property (nonatomic, strong) AVPlayer *avPlayer;

/// 播放器的视图
@property (nonatomic, strong) UIView *playerView;

/// 是否已经添加通知
@property (nonatomic, assign) BOOL haveNoti;

/// 弹幕管理器
@property (nonatomic, strong) DLBarrageViewManager *manager;

/// 弹道数
@property (nonatomic, assign) NSInteger numberOfTrack;

/// 定时器标识符
@property (nonatomic, strong) NSString *timeIdentifier;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

/// 视频是否播放完成
@property (nonatomic, assign) BOOL isFinish;

/// 缓存长度
@property (nonatomic, assign) NSTimeInterval cacheTime;

/// 弹幕数组
@property (nonatomic, strong) NSMutableArray *barrageArray;

@end

@implementation DLPlayer

static DLPlayer *player = nil;

-(NSMutableArray *)barrageArray{
    if (!_barrageArray) {
        _barrageArray = [[NSMutableArray alloc]init];
    }
    return _barrageArray;
}

-(NSTimeInterval)barrageDuration{
    return _barrageDuration > 0 ? _barrageDuration : 10.f;
}

-(void)setBarrageShowType:(BarrageShowType)barrageShowType{
    _barrageShowType = barrageShowType;
    switch (barrageShowType) {
        case BarrageShowFullScreen:
            [self.manager start];
            break;
            
        case BarrageShowCleanScreen:
            [self.manager stop];
            break;
            
        default:
            break;
    }
}

-(void)addBarrageString:(NSString *)barrageStr isMember:(BOOL)isMember{
    if (self.barrageShowType == BarrageShowFullScreen && self.skinView.screenType == VideoFullScreen) {
        [self.barrageArray addObject: [[DLBarrageModel alloc]initWithTitle:barrageStr dataType:isMember]];
        [self.manager packageData];
        [self.manager start];
    }
}

- (NSUInteger)numberOfItemsControlleredByDanmakuManger:(DLBarrageViewManager *)manger {
    return self.barrageArray.count;
}

- (DLBarrageModel *)danmakuManger:(DLBarrageViewManager *)manger informationForItem:(NSUInteger)index {
    return self.barrageArray[index];
}

-(NSString *)barrageNormalColorHexStr{
    return _barrageNormalColorHexStr.length > 0 ? _barrageNormalColorHexStr : @"#FFFFFF";
}

-(NSString *)barrageMemberColorHexStr{
    return _barrageMemberColorHexStr.length > 0 ? _barrageMemberColorHexStr : @"#FFFFFF";
}

-(NSInteger)numberOfTrack{
    return ([UIScreen mainScreen].bounds.size.width - 40)/(self.barrageTitleSize + 4);
}

-(DLBarrageViewManager *)manager{
    if (!_manager) {
        _manager = [DLBarrageViewManager shareInstance];
        _manager.dataSource = self;
        [_manager packageData];
    }
    return _manager;
}

-(CGFloat)barrageTitleSize{
    return _barrageTitleSize > 0 ? _barrageTitleSize : 16;
}

+(DLPlayer *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        player = [[self alloc] init];
    });
    return player;
}

-(AVPlayer *)avPlayer{
    if (!_avPlayer) {
        _avPlayer = [[AVPlayer alloc]init];
    }
    return _avPlayer;
}

-(void)start{
    if (self.videoUrl.length == 0) {
        [[DLAlert shareInstance]alertMessage:@"播放地址为空" cancelTitle:@"取消" sureTitle:@"确定" sureBlock:nil];
        return;
    }
    _skinView.isPlay = YES;
    [self.avPlayer play];
    self.skinView.repeatPlayButton.hidden = YES;
}

-(void)setIsRefresh:(BOOL)isRefresh{
    if (_isRefresh == isRefresh) {
        return;
    }
    _isRefresh = isRefresh;
    if (isRefresh) {
        [[DLLoad shareInstance]showLoadTitle:@"" loadType:LoadShowing backView:self.fatherView];
        [self.skinView.playButton dl_viewHidden:0];
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
    self.isFinish = NO;
    if (videoUrl.length > 0 && self.fatherView != nil) {
        self.playerView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self.fatherView).offset(0);
        [self.fatherView addSubview:self.playerView];
        [self.avPlayer replaceCurrentItemWithPlayerItem:[[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:videoUrl]]];
        [self.playerView layoutIfNeeded];
        self.playerLayer.frame = self.playerView.bounds;
        [self.fatherView bringSubviewToFront:self.playerView];
        [self addNoti];
        self.isRefresh = YES;
    }else{
        [self pause];
    }
}

-(void)removeNoti{
    if (self.haveNoti) {
        [[NSNotificationCenter defaultCenter] dl_removeObserverBlocks];
        self.haveNoti = NO;
    }
}

-(void)addNoti{
    if (!self.haveNoti) {
        self.haveNoti = YES;
        
        // 观察Status属性，可以在加载成功之后得到视频的长度
        [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        
        // 观察loadedTimeRanges，可以获取缓存进度，实现缓冲进度条
        [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        
        // 视频播放完成
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        //  监听屏幕方向
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didChangeRotate:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
}

-(void)avPlayToEndTime:(NSNotification*)notice{
    [[DLLoad shareInstance] viewHidden];
    self.isFinish = YES;
    self.skinView.repeatPlayButton.hidden = NO;
}

-(void)didChangeRotate:(NSNotification*)notice{
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationUnknown:
            {
                
            }
            break;
            
        case UIInterfaceOrientationPortrait:
            {
                self.skinView.screenButton.selected = NO;
                if (self.skinView.initiativeRotate) {
                    _skinView.screenType = VideoSmallScreen;
                }else{
                    self.skinView.screenType = VideoSmallScreen;
                }
                
            }
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            {
                NSLog(@"倒立屏幕");
            }
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            {
                self.skinView.screenButton.selected = YES;
                if (self.skinView.initiativeRotate) {
                    _skinView.screenType = VideoFullScreen;
                }else{
                    self.skinView.screenType = VideoFullScreen;
                }
            }
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            {
                self.skinView.screenButton.selected = YES;
                if (self.skinView.initiativeRotate) {
                    _skinView.screenType = VideoFullScreen;
                }else{
                    self.skinView.screenType = VideoFullScreen;
                }
            }
            break;
            
            
        default:
            break;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:{
                self.skinView.durationTime = CMTimeGetSeconds(playerItem.duration);
                [[DLLoad shareInstance]viewHidden];
                break;
            }
            case AVPlayerStatusFailed:{//视频加载失败，点击重新加载
                [[DLLoad shareInstance]viewHidden];
                [[DLLoad shareInstance]showLoadTitle:@"加载失败" loadType:LoadFailed backView:self.playerView];
                break;
            }
            case AVPlayerStatusUnknown:{
                NSLog(@"加载遇到未知问题:AVPlayerStatusUnknown");
                [[DLLoad shareInstance]viewHidden];
                [[DLLoad shareInstance]showLoadTitle:@"加载失败" loadType:LoadFailed backView:self.playerView];
                break;
            }
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //获取视频缓冲进度数组，这些缓冲的数组可能不是连续的
        NSArray *loadedTimeRanges = playerItem.loadedTimeRanges;
        //获取最新的缓冲区间
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
        //缓冲区间的开始的时间
        NSTimeInterval loadStartSeconds = CMTimeGetSeconds(timeRange.start);
        //缓冲区间的时长
        NSTimeInterval loadDurationSeconds = CMTimeGetSeconds(timeRange.duration);
        //当前视频缓冲时间总长度
        NSTimeInterval currentLoadTotalTime = loadStartSeconds + loadDurationSeconds;
        self.skinView.cacheTime = currentLoadTotalTime;
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
//        [self.playerView dl_AutoLayout:^(DLConstraintMaker *make) {
//            make.left.equal(fatherView).offset(0);
//            make.right.equal(fatherView).offset(0);
//            make.top.equal(fatherView).offset(0);
//            make.bottom.equal(fatherView).offset(0);
//        }];
        
        self.playerView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(fatherView).offset(0);
        
        [self.playerView layoutIfNeeded];
        self.playerLayer.frame = self.playerView.bounds;
        [_fatherView bringSubviewToFront:self.playerView];
        [self addNoti];
    }
}

-(UIView *)playerView {
    if (!_playerView) {
        _playerView = [UIView dl_view:^(UIView *view) {
            view.dl_backColor(@"000000");
        }];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [_playerView.layer addSublayer:_playerLayer];
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
//    [_skinView dl_AutoLayout:^(DLConstraintMaker *make) {
//        make.left.equal(self.playerView).offset(0);
//        make.top.equal(self.playerView).offset(0);
//        make.right.equal(self.playerView).offset(0);
//        make.bottom.equal(self.playerView).offset(0);
//    }];
    
    _skinView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self.playerView).offset(0);
    
    _skinView.clarityArray = @[
                            @{
                                @"zhTitle" : @"标清",
                                @"url" : @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"
                            },
                            @{
                                @"zhTitle" : @"高清",
                                @"url" : @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"
                            }];
    [[DLLoad shareInstance]showLoadTitle:@"" loadType:LoadShowing backView:self.fatherView];
    [self.skinView.playButton dl_viewHidden:0];
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


@interface DLPlayerSkinView()

@property (nonatomic, strong) DLPlayer *player;

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
        _clarityButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self.topFuncView).dl_text(@"清晰度").dl_fontSize(13).dl_textColor(@"#FFFFFF");
            button.dl_layout(DL_Right).equal(self.topFuncView).offset(97).dl_layout(DL_Height).offset(23).dl_layout(DL_CenterY).equal(self.titleLabel);
            button.dl_clickEdge(20);
            [button layoutSubviews];
            button.layer.cornerRadius = 12;
            button.layer.masksToBounds = YES;
            button.layer.borderColor = [[UIColor whiteColor]CGColor];
            button.layer.borderWidth = 1;
        }];
        
        @dl_weakify;
        [_clarityButton addClickAction:^(UIView *view) {
            @dl_strongify;
            [self viewTouch];
            [[DLLoad shareInstance]viewHidden];
            self.clarityView.hidden = NO;
            [UIView animateWithDuration:0.5 animations:^{
                self.clarityView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self).offset(0);
                [self layoutIfNeeded];
            }];
        }];
    }
    return _clarityButton;
}

-(ClarityView *)clarityView{
    if (!_clarityView) {
        _clarityView = [[ClarityView alloc]init];
        [self addSubview:_clarityView];
        _clarityView.hidden = YES;
        _clarityView.dl_layout(DL_Left | DL_Top | DL_Bottom).offset(0);
        
        @dl_weakify;
        [_clarityView.closeButton addClickAction:^(UIView *view) {
            @dl_strongify;
            [self viewTouch];
            [UIView animateWithDuration:0.5 animations:^{
                self.clarityView.dl_layout(DL_Left | DL_Top | DL_Bottom).offset(0);
                self.clarityView.dl_remove_layout(DL_Right);
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                if (finished) {
                    self.clarityView.hidden = YES;
                }
            }];
            self.player.isRefresh = self.player.isRefresh;
        }];
    }
    return _clarityView;
}

-(UITapGestureRecognizer *)singleTap{
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
    if ([touch.view.identifierStr isEqualToString:@"DLPlayerSkinView"]) {
        return YES;
    }
    return NO;
}

-(void)viewTouch {
    if (self.topFuncView.hidden) {
        [[self.topFuncView dl_viewShow] dl_viewHidden:5];
        if (self.player.isFinish) {
            [self.bottomFuncView dl_viewHidden:5];
            [self.playButton dl_viewHidden:5];
        }else{
            [[self.bottomFuncView dl_viewShow] dl_viewHidden:5];
            if ([DLLoad shareInstance].loadShowBOOL) {
                [[self.playButton dl_viewShow] dl_viewHidden:5];
            }else{
                [self.playButton dl_viewHidden:5];
            }
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
                        [[DLLoad shareInstance]showLoadTitle:nil loadType:LoadShowing backView:self.player.playerView];
                        [self.player.avPlayer seekToTime:CMTimeMake(self.sumTime, 1) completionHandler:^(BOOL finished) {
                            [[DLLoad shareInstance] viewHidden];
                        }];
                        
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
    [[DLNoti shareInstance] showNotiTitle:[NSString stringWithFormat:@"%@", converTimeStr((int)self.sumTime)] backView:self];
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
    return CMTimeGetSeconds(self.player.avPlayer.currentTime);
}

- (CGFloat)allDuration {
    return CMTimeGetSeconds(self.player.avPlayer.currentItem.duration);
}

-(void)setIsPlay:(BOOL)isPlay {
    _isPlay = isPlay;
    if (isPlay) {
        [self.player.avPlayer play];
        self.playButton.dl_imageString(@"play");
    }else{
        [self.player.avPlayer pause];
        self.playButton.dl_imageString(@"pause");
    }
    self.isPauseByUser = NO;
}

-(UIImageView *)playButton {
    if (!_playButton) {
        _playButton = [UIImageView dl_view:^(UIImageView *imageView) {
            imageView.dl_backView(self);
            imageView.dl_imageString(@"play");
            imageView.dl_layout(DL_Width | DL_Height).offset(50).dl_layout(DL_CenterY | DL_CenterX).equal(self).offset(0);
        }];
        @dl_weakify;
        [_playButton addClickAction:^(UIView *view) {
            @dl_strongify;
            self.isPlay = !self.isPlay;
            self.isPauseByUser = YES;
        }];
    }
    return _playButton;
}

-(void)playerButtonClick{
    self.isPlay = !self.isPlay;
    self.isPauseByUser = YES;
}

-(UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel dl_view:^(UILabel *label) {
            label.dl_backView(self.topFuncView).dl_fontSize(18).dl_textColor(@"FFFFFF").dl_alignment(NSTextAlignmentLeft);
            label.dl_layout(DL_Left).equal(self.topFuncView).offset(38).dl_layout(DL_Top).equal(self.topFuncView).offset(24);
        }];
    }
    return _titleLabel;
}

-(UIImageView *)topFuncView {
    if (!_topFuncView) {
        _topFuncView = [UIImageView dl_view:^(UIView * _Nonnull view) {
            view.dl_backView(self).dl_imageString(@"video_top_gray");
            view.dl_layout(DL_Left | DL_Right | DL_SafeTop).equal(self).offset(0).dl_layout(DL_Height).offset(70);
        }];
    }
    return _topFuncView;
}

-(UIImageView *)bottomFuncView {
    if (!_bottomFuncView) {
        _bottomFuncView = [UIImageView dl_view:^(UIImageView *imageView) {
            imageView.dl_backView(self).dl_imageString(@"video_bottom_gray");
            imageView.dl_layout(DL_Left | DL_Right | DL_SafeBottom).equal(self).offset(0).dl_layout(DL_Height).offset(70);
        }];
    }
    return _bottomFuncView;
}

-(UIButton *)screenButton{
    if (!_screenButton) {
        _screenButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self.bottomFuncView).dl_normalImage(@"video_full_screen").dl_selectImage(@"video_small_screen").dl_clickEdge(30);
            button.selected = NO;
            button.dl_layout(DL_Height | DL_Width).offset(16).dl_layout(DL_Right).equal(self.bottomFuncView).offset(22).dl_layout(DL_Top).equal(self.bottomFuncView).offset(32);
            @dl_weakify;
            [button addClickAction:^(UIView *view) {
                @dl_strongify;
                self.initiativeRotate = YES;
                switch ((int)self.screenButton.selected) {
                    case 0:
                        {
                            self.screenType = VideoFullScreen;
                            [self orientationToPortrait:UIInterfaceOrientationLandscapeRight];
                        }
                        break;
                        
                    case 1:
                        {
                            self.screenType = VideoSmallScreen;
                            [self orientationToPortrait:UIInterfaceOrientationPortrait];
                        }
                        break;
                        
                    default:
                        break;
                }
            }];
        }];
    }
    return _screenButton;
}

-(void)setScreenType:(VideoScreenType)screenType{
    _screenType = screenType;
    self.initiativeRotate = NO;
    [self.player.playerView removeFromSuperview];
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    switch (screenType) {
        case VideoFullScreen:
            {
                if (window == nil) {
                    return;
                }
                window.windowLevel = UIWindowLevelStatusBar + 1;
                [window addSubview:self.player.playerView];
                self.player.playerView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(window).offset(0);
                self.player.playerLayer.frame = CGRectMake(0, 0, DLWidth, DLHeight);
            }
            break;

        case VideoSmallScreen:
            {
                window.windowLevel = UIWindowLevelNormal;
                self.player.playerView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self.player.fatherView).offset(0);
                [self.player.fatherView addSubview:self.player.playerView];
                [self.player.playerView layoutIfNeeded];
                self.player.playerLayer.frame = self.player.playerView.bounds;
            }
            break;

        default:
            break;
    }
}

-(UIImageView *)repeatPlayButton{
    if (!_repeatPlayButton) {
        _repeatPlayButton = [UIImageView dl_view:^(UIImageView *imageView) {
            imageView.dl_backView(self).dl_imageString(@"repeatPlay");
            imageView.dl_layout(DL_CenterY | DL_CenterX).equal(self).dl_layout(DL_Width | DL_Height).offset(60);
        }];
        
        @dl_weakify;
        [_repeatPlayButton addClickAction:^(UIView *view) {
            @dl_strongify;
            [[DLLoad shareInstance]showLoadTitle:nil loadType:LoadShowing backView:self.player.playerView];
            [self.player.avPlayer seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
                [[DLLoad shareInstance] viewHidden];
            }];
            view.hidden = YES;
            self.player.isFinish = NO;
        }];
    }
    return _repeatPlayButton;
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


@implementation DLVodPlayerSkinView{
    NSTimeInterval vodPlayTime;
    NSTimeInterval vodCacheTime;
    NSTimeInterval vodDurationTime;
}

-(void)funcExtension{    
    [self.bottomFuncView addSubview:self.playTimeLabel];
    [self.bottomFuncView addSubview:self.allTimeLabel];
    [self.bottomFuncView addSubview:self.allProgressView];
    [self.bottomFuncView addSubview:self.cacheProgressView];
    [self.bottomFuncView addSubview:self.playProgressView];
    
    self.player.timeIdentifier = [DLTimer doTask:^{
        if (self->vodCacheTime < 0.5 && self.player.isFinish) {
            self.player.isRefresh = YES;
            return;
        }
        if (self.player.isFinish) {
            self.player.isRefresh = NO;
            return;
        }
        if (CMTimeGetSeconds(self.player.avPlayer.currentTime) <= 1 || CMTimeGetSeconds(self.player.avPlayer.currentItem.duration) <= 1) {
            return;
        }
        self->vodPlayTime = CMTimeGetSeconds(self.player.avPlayer.currentTime);
        self.playTimeLabel.dl_text(converTimeStr(self->vodPlayTime));
        self.playProgressView.dl_layout(DL_Width).equal(self.allProgressView).multipliedBy(self->vodPlayTime / self->vodDurationTime);
        if (fabs(self->vodCacheTime - self->vodPlayTime) <= 1) {
            self.player.isRefresh = YES;
        }else if (fabs(self->vodCacheTime - self->vodPlayTime) > 1) {
            self.player.isRefresh = NO;
        }
   } start:0 interval:1 repeats:YES async:NO];
}

-(void)setCacheTime:(NSTimeInterval)cacheTime{
    vodCacheTime = cacheTime;
    if (cacheTime > 0 && vodDurationTime > 0) {
        self.cacheProgressView.dl_layout(DL_Width).equal(self.allProgressView).multipliedBy(cacheTime / self->vodDurationTime);
    }
}

-(void)setDurationTime:(NSTimeInterval)durationTime{
    vodDurationTime = durationTime;
    self.allTimeLabel.dl_text(converTimeStr(durationTime));
}

-(NSTimeInterval)durationTime{
    return vodDurationTime;
}

-(NSTimeInterval)cacheTime{
    return vodCacheTime;
}

-(NSTimeInterval)playTime{
    return vodPlayTime;
}

-(UILabel *)playTimeLabel{
    if (!_playTimeLabel) {
        _playTimeLabel = [UILabel dl_view:^(UILabel *label) {
            label.dl_backView(self.bottomFuncView).dl_textColor(@"#FFFFFFF").dl_fontSize(14).dl_alignment(NSTextAlignmentCenter).dl_text(@"00:00");
            label.dl_layout(DL_Left).equal(self.bottomFuncView).offset(4).dl_layout(DL_Bottom).equal(self.bottomFuncView).offset(22).dl_layout(DL_Width).offset(68);
        }];
    }
    return _playTimeLabel;
}

-(UILabel *)allTimeLabel{
    if (!_allTimeLabel) {
        _allTimeLabel = [UILabel dl_view:^(UILabel *label) {
            label.dl_layout(DL_Right).equal(self.bottomFuncView).offset(52).dl_layout(DL_Bottom).equal(self.bottomFuncView).offset(22).dl_layout(DL_Width).offset(66);
            label.dl_backView(self.bottomFuncView).dl_textColor(@"#FFFFFFF").dl_fontSize(14).dl_alignment(NSTextAlignmentCenter).dl_text(@"00:00");
        }];
    }
    return _allTimeLabel;
}

-(UIView *)playProgressView{
    if (!_playProgressView) {
        _playProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_layout(DL_Left).equal(self.bottomFuncView).offset(72.5).dl_layout(DL_Bottom).equal(self.bottomFuncView).offset(29.5).dl_layout(DL_Height).offset(2).dl_layout(DL_Width).equal(self.allProgressView).multipliedBy(1);
            view.dl_backView(self.bottomFuncView).dl_backColor(@"#279858");
        }];
    }
    return _playProgressView;
}

-(UIView *)cacheProgressView{
    if (!_cacheProgressView) {
        _cacheProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_layout(DL_Left).equal(self.bottomFuncView).offset(72.5).dl_layout(DL_Bottom).equal(self.bottomFuncView).offset(29.5).dl_layout(DL_Height).offset(2).dl_layout(DL_Width).equal(self.allProgressView).multipliedBy(1);
            view.dl_backView(self.bottomFuncView).dl_backColor(@"#F4FDF3");
        }];
    }
    return _cacheProgressView;
}

-(UIView *)allProgressView{
    if (!_allProgressView) {
        _allProgressView = [UIView dl_view:^(UIView *view) {
            view.dl_layout(DL_Left).equal(self.bottomFuncView).offset(72.5).dl_layout(DL_Bottom).equal(self.bottomFuncView).offset(29.5).dl_layout(DL_Height).offset(2).dl_layout(DL_Right).equal(self.bottomFuncView).offset(118);
            view.dl_backView(self.bottomFuncView).dl_backColor(@"#778666");
        }];
    }
    return _allProgressView;
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
        [UILabel dl_view:^(UILabel *label) {
            label.dl_backView(self).dl_text(@"清晰度").dl_textColor(@"FFFFFF").dl_fontSize(15);
            label.dl_layout(DL_Left).equal(self).offset(66).dl_layout(DL_Top).equal(self).offset(69).dl_layout(DL_Height).offset(15);
        }];
        self.closeButton = [UIButton dl_view:^(UIButton *button) {
            button.dl_backView(self).dl_normalImage(@"close_white").dl_clickEdge(30);
            button.dl_layout(DL_Right).equal(self).offset(20).dl_layout(DL_SafeTop).equal(self).offset(29).dl_layout(DL_Height | DL_Width).offset(13);
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
        self.dl_layout(DL_Left).equal_to(self.player.skinView).offset(0).dl_layout(DL_Width).offset(0);
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
            [array addObject:[[PlaysUrlModel alloc]initModelWithDic:dic]];
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
        _collectionView.dl_layout(DL_Left).equal(self).offset(66).dl_layout(DL_Right).offset(-26).dl_layout(DL_Top).equal(self).offset(98).dl_layout(DL_Bottom).equal(self).offset(40);
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

-(instancetype)initModelWithDic:(NSDictionary *)dic{
    if ([super init]) {
        self.enTitle = dic[@"enTitle"];
        self.type = dic[@"type"];
        self.url = dic[@"url"];
        self.zhTitle = dic[@"zhTitle"];
    }
    return self;
}

@end

@interface DLBarrageViewManager ()

@property (nonatomic, strong) NSMutableArray *widthArr;

@property (nonatomic, strong) NSMutableArray *sourceArr;     //数据

@property (nonatomic, strong) NSMutableArray *cacheArr;      //缓存复用

@property (nonatomic, strong) NSMutableArray *trackArray;    //记录弹道

@property (nonatomic, strong) NSMutableDictionary *displayingDic;

@property (nonatomic, assign) BOOL isBeingExecuted;

@property (nonatomic, assign) NSUInteger index;              //出现弹幕的序列号

@property (nonatomic, assign) NSUInteger count;              //记录

@property (nonatomic, strong) DLPlayer *player;

@end

@implementation DLBarrageViewManager

-(DLPlayer *)player{
    if (!_player) {
        _player = [DLPlayer shareInstance];
    }
    return _player;
}

static DLBarrageViewManager *manager = nil;

+(DLBarrageViewManager *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.widthArr = [NSMutableArray array];
        self.sourceArr = [NSMutableArray array];
        self.cacheArr = [NSMutableArray array];
        self.trackArray = [NSMutableArray array];
        self.displayingDic = [NSMutableDictionary dictionary];
        for (int i = 0; i < self.player.numberOfTrack; i++) {
            [self.trackArray addObject:@(i)];
        }
    }
    return self;
}

#pragma mark - Public Method
- (void)packageData {
    [self _getData];
}

- (void)appendData {
    [self _getData];
    if (self.isBeingExecuted == NO &&self.isStarted == YES) {
        [self start];
    }
}

- (void)start {
    [self _updateStatusStart:YES isFinished:NO];
    [self go];
}

- (void)stop {
    self.index = 0;
    [self _updateStatusStart:NO isFinished:YES];
    for (UIView *view in self.player.playerView.subviews) {
        if ([view isMemberOfClass:[DLBarrageView class]]) {
          [view removeFromSuperview];
        }
    }
}

#pragma mark - Private Method
- (void)_updateStatusStart:(BOOL)isStarted isFinished:(BOOL)isFinished {
    self.isFinished = isFinished;
    self.isStarted = isStarted;
}

- (BOOL)_isContainedKey:(NSString *)key {
    if ([self.displayingDic.allKeys containsObject:key]) {
        return YES;
    }
    return NO;
}

- (NSInteger)_getIndexOfTracks {
    if (self.trackArray.count == 0)  return -1;
    NSUInteger randomIndex = random()%self.trackArray.count;
    NSInteger indexOfTracks = [self.trackArray[randomIndex] integerValue];
    return indexOfTracks;
}

-(void)go{
    NSUInteger indexOfTrack;
    if (((indexOfTrack = [self _getIndexOfTracks]) == -1 || self.index >= self.sourceArr.count) || self.isFinished == YES) {
        if(self.index >= self.sourceArr.count) {
           self.isBeingExecuted = NO;
        }
        return;
    }
    self.isBeingExecuted = YES;
    [self.trackArray removeObject:@(indexOfTrack)];
    //生成弹幕视图
    DLBarrageView *barrageView;
    if (self.cacheArr.count != 0) {
        barrageView  = [self.cacheArr firstObject];
        [self.cacheArr removeObjectAtIndex:0];
    }
    if (barrageView == nil) {
        barrageView = [[DLBarrageView alloc] init];
    }
    barrageView.frame = CGRectMake(self.player.playerView.frame.size.width + [UIScreen mainScreen].bounds.size.width, indexOfTrack * (self.player.barrageTitleSize + 4), [self.widthArr[self.index] floatValue], (self.player.barrageTitleSize + 4));
    DLBarrageModel *model = self.sourceArr[self.index];
    barrageView.indexOfTracks = indexOfTrack;
    barrageView.model = model;
    barrageView.tag = self.index;
    switch (model.dataType) {
        case DLBarrageNormalType:
            barrageView.title.textColor = [DLColor DLColorWithAHEXColor:self.player.barrageNormalColorHexStr];
            break;
            
        case DLBarrageMemberType:
            barrageView.title.textColor = [DLColor DLColorWithAHEXColor:self.player.barrageMemberColorHexStr];
            break;
            
        default:
            break;
    }
    barrageView.title.font = [UIFont systemFontOfSize:self.player.barrageTitleSize];
    [self.player.playerView addSubview:barrageView];
    barrageView.movementStatus = ^(DLBarrageViewStatus status,NSUInteger indexOfTracks,DLBarrageView *view) {
        switch (status) {
            case DLBarrageViewStatusStart:{
                //将出现的视图根据轨道编号添加字典中，当点击时候直接取出相应轨道的数组来遍历。
                NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)indexOfTrack];
                if ([self _isContainedKey:key]) {
                    NSMutableArray *arr =  self.displayingDic[key];
                    [arr addObject:view];
                }else {
                    NSMutableArray *arr = [NSMutableArray array];
                    [arr addObject:view];
                    [self.displayingDic setObject:arr forKey:key];
                }
                break;}
            case DLBarrageViewStatusEnter:{
                if (![self.trackArray containsObject:@(indexOfTrack)]) {
                    [self.trackArray addObject:@(indexOfTrack)];
                }
                break;}
            case DLBarrageViewStatusEnd:{
                //将消失的视图从字典中移除掉。
                NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)indexOfTrack];
                if ([self _isContainedKey:key]) {
                    [self.displayingDic[key] removeObject:view];
                }
                //将消息的视图添加到缓存数组中，这样直接先从缓存来拿，拿不到再创建
                [self.cacheArr addObject:view];
                if (self.isBeingExecuted == NO) { //如果因为轨道满了停止了则继续递归
                  [self go];
                }
                
                break; }
            default:
                break;
        }
    };
    [barrageView srartWithAnimationDuration:self.player.barrageDuration animationScreenWidth:CGRectGetWidth(self.player.playerView.frame)];
    self.index ++;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self go];
    });
}

- (void)_getData {
    if ([self.dataSource respondsToSelector:@selector(numberOfItemsControlleredByDanmakuManger:)] && [self.dataSource respondsToSelector:@selector(danmakuManger:informationForItem:)]) {
        NSUInteger number = [self.dataSource numberOfItemsControlleredByDanmakuManger:self];
        while ((number - self.count)>0) {
            DLBarrageModel *model = [self.dataSource danmakuManger:self informationForItem:self.count];
            CGFloat eachWidth = [self widthFromString:model.title withFont:[UIFont systemFontOfSize:self.player.barrageTitleSize] constraintToHeight:(self.player.barrageTitleSize + 4)];
            [self.sourceArr addObject:model];
            [self.widthArr addObject:@(eachWidth)];
            self.count ++;
        }
    }
}

-(CGFloat)widthFromString:(NSString*)text withFont:(UIFont*)font constraintToHeight:(CGFloat)height{
    return [text boundingRectWithSize:CGSizeMake(1000, height) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width;
}

@end

@implementation DLBarrageView

- (void)layoutSubviews {
    [super layoutSubviews];
    _title.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width + 40, self.bounds.size.height + 10);
}

- (void)setModel:(DLBarrageModel *)model {
    _model = model;
    self.title.text = model.title;
    self.title.textColor = [UIColor whiteColor];
}

- (void)srartWithAnimationDuration:(NSTimeInterval)duration animationScreenWidth:(CGFloat)Width {
    self.animationDuration  = duration;
    CGFloat totalWidth = self.frame.size.width + Width;
    CGFloat speed = totalWidth/self.animationDuration;
    CGFloat timeToenterScreenCompletely = self.frame.size.width/speed;
    if (self.movementStatus) {
        self.movementStatus(DLBarrageViewStatusStart,self.indexOfTracks,self);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToenterScreenCompletely * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.movementStatus) {
            self.movementStatus(DLBarrageViewStatusEnter,self.indexOfTracks,self);
        }
    });
    __block CGRect frame  = self.frame;
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveLinear animations:^{
        frame.origin.x = -CGRectGetWidth(frame);
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (self.movementStatus) {
            self.movementStatus(DLBarrageViewStatusEnd,self.indexOfTracks,self);
        }
        if (self.superview) {
            [self removeFromSuperview];
        }
    }];
}

#pragma mark - get
- (UILabel *)title {
    if (_title == nil) {
        _title = [[UILabel alloc] init];
        _title.textAlignment = NSTextAlignmentRight;
        [self addSubview:_title];
    }
    return _title;
}


@end

@implementation DLBarrageModel

-(instancetype)initWithTitle:(NSString *)title dataType:(DLBarrageDataType)dataType{
    if (self = [super init]) {
        self.title = title;
        self.dataType = dataType;
    }
    return self;
}

@end







/*
 AVPlayer
 AVPlayer相比上述两种方式，播放视频功能更加强大，使用也十分灵活，因为它更加接近底层。但是AVPlayer本身是不能直接显示视频的，必须创建一个播放层AVPlayerLayer并将其添加到其他的视图Layer上才能显示。
 测试网络视频url  https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4
 
 
 
 1. 使用AVPlayer需要了解的常用类

 AVAsset：一个用于获取多媒体信息的抽象类，但不能直接使用
 AVURLAsset：AVAsset的子类，可以根据一个URL路径创建一个包含媒体信息的AVURLAsset对象
 AVPlayerItem：一个媒体资源管理对象，用于管理视频的基本信息和状态，一个AVPlayerItem对应一个视频资源
 AVPlayer：负责视频播放、暂停、时间控制等操作
 AVPlayerLayer：负责显示视频的图层，如果不设置此属性，视频就只有声音没有图像
 
 
 
 
 2.AVPlayer的使用步骤
 
 //第一步:引用AVFoundation框架，添加播放器属性
         #import <AVFoundation/AVFoundation.h>
 
         @property (nonatomic,strong)AVPlayer *player;//播放器对象
 
         @property (nonatomic,strong)AVPlayerItem *currentPlayerItem;
 
 
 
 //第二步:获取播放地址URL
         //本地视频路径
         NSString* localFilePath=[[NSBundle mainBundle]pathForResource:@"不能说的秘密" ofType:@"mp4"];
         NSURL *localVideoUrl = [NSURL fileURLWithPath:localFilePath];
         
         //网络视频路径
         NSString *webVideoPath = @"http://api.junqingguanchashi.net/yunpan/bd/c.php?vid=/junqing/1129.mp4";
         NSURL *webVideoUrl = [NSURL URLWithString:webVideoPath];
 
 
 
 //第三步:创建播放器(四种方法)
         //如果使用URL创建的方式会默认为AVPlayer创建一个AVPlayerItem
         //self.player = [AVPlayer playerWithURL:localVideoUrl];
         //self.player = [[AVPlayer alloc] initWithURL:localVideoUrl];
         //self.player = [AVPlayer playerWithPlayerItem:playerItem];
 
         AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:webVideoUrl];
         self.currentPlayerItem = playerItem;
         self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
 
 
 
 //第四步:创建显示视频的AVPlayerLayer,设置视频显示属性，并添加视频图层
         //contentView是一个普通View,用于放置视频视图
           AVLayerVideoGravityResizeAspectFill等比例铺满，宽或高有可能出屏幕
           AVLayerVideoGravityResizeAspect 等比例  默认
           AVLayerVideoGravityResize 完全适应宽高
 
             AVPlayerLayer *avLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
             avLayer.videoGravity = AVLayerVideoGravityResizeAspect;
             avLayer.frame = _containerView.bounds;
             [_containerView.layer addSublayer:avLayer];

 
 
 //第六步：执行play方法，开始播放
             //本地视频可以直接播放
             //网络视频需要监测AVPlayerItem的status属性为AVPlayerStatusReadyToPlay时方法才会生效
             [self.player play];
 
 
 
 3. 添加属性观察
 一个AVPlayerItem对象对应着一个视频，我们需要通过AVPlayerItem来获取视频属性。但是AVPlayerItem必须是在视频资源加载到可以播放的时候才能使用，这是受限于网络的原因。解决这一问题，我们需要使用KVO监测AVPlayerItem的status属性，当其为AVPlayerItemStatusReadyToPlay的时候我们才能获取视频相关属性。相关的代码示例如下：
 
     //1.注册观察者，监测播放器属性
     //观察Status属性，可以在加载成功之后得到视频的长度
         [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
     //观察loadedTimeRanges，可以获取缓存进度，实现缓冲进度条
         [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
 
 
 
     //2.添加属性观察
         - (void)observeValueForKeyPath:(NSString *)keyPath
                               ofObject:(id)object
                                 change:(NSDictionary *)change
                                context:(void *)context {
             AVPlayerItem *playerItem = (AVPlayerItem *)object;
             if ([keyPath isEqualToString:@"status"]) {
                 //获取playerItem的status属性最新的状态
                 AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
                 switch (status) {
                     case AVPlayerStatusReadyToPlay:{
                         //获取视频长度
                         CMTime duration = playerItem.duration;
                         //更新显示:视频总时长(自定义方法显示时间的格式)
                         self.totalNeedPlayTimeLabel.text = [self formatTimeWithTimeInterVal:CMTimeGetSeconds(duration)];
                         //开启滑块的滑动功能
                         self.sliderView.enabled = YES;
                         //关闭加载Loading提示
                         [self showaAtivityInDicatorView:NO];
                         //开始播放视频
                         [self.player play];
                         break;
                     }
                     case AVPlayerStatusFailed:{//视频加载失败，点击重新加载
                         [self showaAtivityInDicatorView:NO];//关闭Loading视图
                         self.playerInfoButton.hidden = NO; //显示错误提示按钮，点击后重新加载视频
                         [self.playerInfoButton setTitle:@"资源加载失败，点击继续尝试加载" forState: UIControlStateNormal];
                         break;
                     }
                     case AVPlayerStatusUnknown:{
                         NSLog(@"加载遇到未知问题:AVPlayerStatusUnknown");
                         break;
                     }
                     default:
                         break;
                 }
             } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
                 //获取视频缓冲进度数组，这些缓冲的数组可能不是连续的
                 NSArray *loadedTimeRanges = playerItem.loadedTimeRanges;
                 //获取最新的缓冲区间
                 CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
                 //缓冲区间的开始的时间
                 NSTimeInterval loadStartSeconds = CMTimeGetSeconds(timeRange.start);
                 //缓冲区间的时长
                 NSTimeInterval loadDurationSeconds = CMTimeGetSeconds(timeRange.duration);
                 //当前视频缓冲时间总长度
                 NSTimeInterval currentLoadTotalTime = loadStartSeconds + loadDurationSeconds;
                 //NSLog(@"开始缓冲:%f,缓冲时长:%f,总时间:%f", loadStartSeconds, loadDurationSeconds, currentLoadTotalTime);
                 //更新显示：当前缓冲总时长
                 _currentLoadTimeLabel.text = [self formatTimeWithTimeInterVal:currentLoadTotalTime];
                 //更新显示：视频的总时长
                 _totalNeedLoadTimeLabel.text = [self formatTimeWithTimeInterVal:CMTimeGetSeconds(self.player.currentItem.duration)];
                 //更新显示：缓冲进度条的值
                 _progressView.progress = currentLoadTotalTime/CMTimeGetSeconds(self.player.currentItem.duration);
             }
         }
 
 
     //转换时间格式的方法
         - (NSString *)formatTimeWithTimeInterVal:(NSTimeInterval)timeInterVal{
             int minute = 0, hour = 0, secend = timeInterVal;
             minute = (secend % 3600)/60;
             hour = secend / 3600;
             secend = secend % 60;
             return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, secend];
         }
 
 
 4. 获取当前播放时间与总时间
     在此之前我们需要首先了解一个数据类型，也就是上述操作中的CMTime, 在AVPlayer的使用中我们会经常用到它，其实CMTime是一个结构体如下：
         typedef struct{
             CMTimeValue    value;      // 帧数
             CMTimeScale    timescale;  // 帧率（影片每秒有几帧）
             CMTimeFlags    flags;
             CMTimeEpoch    epoch;
         } CMTime
     
     在上面的操作中我们看到AVPlayerItem的Duration属性就是一个CMTime类型的数据。所以获取视频的总时长(秒)需要duration.value/duration.timeScale。当然系统也为我们提供了CMTimeGetSeconds函数更加方便计算:
             总时长: duration.value == CMTimeGetSeconds(duration) 。
 
     在快进视频到某一个位置的时候我们也需要创建CMTime作为参数，那么CMTime的创建方法有两种:
     //方法1：
         CMTimeMakeWithSeconds(Flout64 seconds, int32_t scale)
     //方法2：
         CMTimeMake(int64_t value, int32_t scale)
     //注：两者的区别在于方法一的第一个参数可以是float
 
 
     至于获取视频的总时间在上述代码中已有体现，是在检测播放状态变为AVPlayerStatusReadyToPlay的时候获取的
 
     //视频总时长，在AVPlayerItem状态为AVPlayerStatusReadyToPlay时获取
         CMTime duration = self.player.currentItem.duration;
         CGFloat totalTime = CMTimeGetSeconds(duration);
     //当前AVPlayer的播放时长
         CMTime cmTime = self.player.currentTime;
         CGFloat currentTime  = CMTimeGetSeconds(cmTime);
 
 
 
 5. 播放进度与状态的刷新
 
     实时更新当前播放时间，这时候我们不必使用定时器，因为AVPlayer已经提供了方法：
 
         addPeriodicTimeObserverForInterval: queue: usingBlock。当播放进度改变的时候方法中的回调会被执行。我们可以在这里做刷新时间的操作，代码示例如下：
         __weak __typeof(self) weakSelf = self;
         self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
              //当前播放的时间
              NSTimeInterval currentTime = CMTimeGetSeconds(time);
              //视频的总时间
              NSTimeInterval totalTime = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
              //设置滑块的当前进度
              weakSelf.sliderView.value = currentTime/totalTime;
              //设置显示的时间：以00:00:00的格式
              weakSelf.currentTimeLabel.text = [weakSelf formatTimeWithTimeInterVal:currentTime];
             }];

         //移除时，调用removeTimeObserver
         // [self.player removeTimeObserver:self.timeObserver];
 
         注意：使用addPeriodicTimeObserverForInterval必须持有返回对象，且在不需要播放器的时候移除此对象；
         否则将会导致undefined behavior，这一点可以从文档是这样说明的：
         You must retain this returned value as long as you want the time observer to be invoked by the player.
         Pass this object to -removeTimeObserver: to cancel time observation.
         Releasing the observer object without a call to -removeTimeObserver: will result in undefined behavior
 
 
 
 6. 滑块拖拽修改视频播放进度
 
     //UISlider的响应方法:拖动滑块，改变播放进度
         - (IBAction)sliderViewChange:(id)sender {
             if(self.player.status == AVPlayerStatusReadyToPlay){
                 NSTimeInterval playTime = self.sliderView.value * CMTimeGetSeconds(self.player.currentItem.duration);
                 CMTime seekTime = CMTimeMake(playTime, 1);
                 [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
                 }];
             }
         }
 
 
 
 7.AVPlayerItem 通知
         // notifications description
         AVF_EXPORT NSString *const AVPlayerItemTimeJumpedNotification            NS_AVAILABLE(10_7, 5_0);   // the item's current time has changed discontinuously
         AVF_EXPORT NSString *const AVPlayerItemDidPlayToEndTimeNotification      NS_AVAILABLE(10_7, 4_0);   // item has played to its end time
         AVF_EXPORT NSString *const AVPlayerItemFailedToPlayToEndTimeNotification NS_AVAILABLE(10_7, 4_3);   // item has failed to play to its end time
         AVF_EXPORT NSString *const AVPlayerItemPlaybackStalledNotification       NS_AVAILABLE(10_9, 6_0);    // media did not arrive in time to continue playback
         AVF_EXPORT NSString *const AVPlayerItemNewAccessLogEntryNotification     NS_AVAILABLE(10_9, 6_0);   // a new access log entry has been added
         AVF_EXPORT NSString *const AVPlayerItemNewErrorLogEntryNotification      NS_AVAILABLE(10_9, 6_0);   // a new error log entry has been added

         // notification userInfo key                                                                    type
         AVF_EXPORT NSString *const AVPlayerItemFailedToPlayToEndTimeErrorKey     NS_AVAILABLE(10_7, 4_3);   // NSError
 
 
 
 
 使用 AVPlayer 的时候，一定要注意 AVPlayer 、 AVPlayerLayer 和 AVPlayerItem 三者之间的关系。 AVPlayer 负责控制播放， layer 显示播放， item 提供数据，当前播放时间， 已加载情况。 Item 中一些基本的属性, status, duration, loadedTimeRanges， currentTime（当前播放时间）。
 
 
 */
