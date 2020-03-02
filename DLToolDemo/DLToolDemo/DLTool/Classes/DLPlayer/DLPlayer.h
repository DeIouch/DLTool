#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIView+Add.h"
#import <MediaPlayer/MediaPlayer.h>

// 枚举值，视频的方向
typedef NS_ENUM(BOOL, VideoScreenType) {
    VideoSmallScreen = NO,   //  视频小屏
    VideoFullScreen  = YES,   //  视频全屏
};

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@class DLPlayerSkinView;
@class ClarityView;
@class PlaysUrlModel;

@interface DLPlayer : NSObject

+(DLPlayer *)shareInstance;

/// 所有播放器的父视图
@property (nonatomic, strong) UIView *fatherView;

@property (nonatomic, strong) NSString *videoUrl;

@property (nonatomic, strong) NSString *videoTitle;

@property (nonatomic, strong) DLPlayerSkinView *skinView;

@property (nonatomic, assign) BOOL isVod;

@property (nonatomic, assign) BOOL isRefresh;

-(void)start;

-(void)pause;

@end


@interface DLPlayerSkinView : UIView<UIGestureRecognizerDelegate>

@property (nonatomic, assign) NSInteger hiddenTime;

@property (nonatomic, assign) BOOL isPlay;

@property (nonatomic, strong) DLPlayer *player;

@property (nonatomic, assign) VideoScreenType screenType;

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) UIButton *screenButton;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *topFuncView;

@property (nonatomic, strong) UIImageView *bottomFuncView;

@property (nonatomic, strong) UIButton *clarityButton;

@property (nonatomic, strong) NSArray *clarityArray;

@property (nonatomic, strong) ClarityView *clarityView;

@property (nonatomic, strong) PlaysUrlModel *urlModel;

/** 单击 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat                sumTime;

@property (nonatomic, assign) CGFloat                startVeloctyPoint;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;

/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;

/** 是否被用户暂停 */
@property (nonatomic, assign) BOOL                   isPauseByUser;
/** 播放完了*/
@property (nonatomic, assign) BOOL                   playDidEnd;
/** 进入后台*/
@property (nonatomic, assign) BOOL                   didEnterBackground;

/// 是否在手势中
@property (nonatomic, assign)  BOOL isDragging;

@property (class, readonly) UISlider *volumeViewSlider;

@property MPVolumeView *volumeView;

//  功能扩展
-(void)funcExtension;

-(void)viewTouch;

@end


/// 直播界面
@interface DLLivePlayerSkinView : DLPlayerSkinView



@end

/// 点播界面
@interface DLVodPlayerSkinView : DLPlayerSkinView

@property (nonatomic, strong) UILabel *playTimeLabel;

@property (nonatomic, strong) UILabel *allTimeLabel;

@property (nonatomic, strong) UIView *allProgressView;

@property (nonatomic, strong) UIView *playProgressView;

@property (nonatomic, strong) UIView *cacheProgressView;

@end



@interface ClarityView : UIView<UICollectionViewDelegate, UICollectionViewDataSource>

@property(nonatomic, strong)UICollectionView *collectionView;

/// 关闭按钮
@property(nonatomic, strong)UIButton *closeButton;

/// 清晰度数组
@property (nonatomic, strong) NSArray *clarityArray;

/// 当前清晰度的index
@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, strong) DLPlayer *player;

@end


@interface PlaysUrlModel : NSObject

@property(nonatomic, copy)NSString *enTitle;


@property(nonatomic, copy)NSString *type;


@property(nonatomic, copy)NSString *url;


@property(nonatomic, copy)NSString *zhTitle;

/**
 清晰度
 */
@property(nonatomic, assign)NSInteger clarityInteger;

@end


@interface ClarityCollectionViewCell : UICollectionViewCell

/// 背景图片
@property (nonatomic, strong) UIImageView *backImageView;

/**
 清晰度
 */
@property (nonatomic, strong) UILabel *clarityLabel;

/// 清晰度链接
@property (nonatomic, strong) NSString *clarityString;

/// 是否被选择
@property (nonatomic, assign) BOOL chooseState;

@end

@interface FastView : UIView



@end
