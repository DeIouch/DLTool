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

typedef NS_ENUM(NSInteger, BarrageShowType) {
    BarrageShowFullScreen       =   0,  //  全屏显示弹幕
    BarrageShowCleanScreen,             //  隐藏弹幕
};

@class DLPlayerSkinView;
@class ClarityView;
@class PlaysUrlModel;

@interface DLPlayer : NSObject

+(DLPlayer *)shareInstance;

/// 所有播放器的父视图
@property (nonatomic, strong) UIView *fatherView;

/// 视频网址
@property (nonatomic, strong) NSString *videoUrl;

/// 视频标题
@property (nonatomic, strong) NSString *videoTitle;

/// 视频皮肤
@property (nonatomic, strong) DLPlayerSkinView *skinView;

/// 是否是点播
@property (nonatomic, assign) BOOL isVod;

/// 是否正在刷新
@property (nonatomic, assign) BOOL isRefresh;

/// 弹幕文字大小
@property (nonatomic, assign) CGFloat barrageTitleSize;

/// 弹幕飘过的时间
@property (nonatomic, assign) NSTimeInterval barrageDuration;

/// 会员字体颜色
@property (nonatomic, copy) NSString *barrageMemberColorHexStr;

/// 正常的颜色
@property (nonatomic, copy) NSString *barrageNormalColorHexStr;

/// 弹幕显示类型
@property (nonatomic, assign) BarrageShowType barrageShowType;

/// 添加弹幕
/// @param barrageStr 弹幕内容
/// @param isMember 是否是会员
-(void)addBarrageString:(NSString *)barrageStr isMember:(BOOL)isMember;

/// 开始播放
-(void)start;

/// 暂停播放
-(void)pause;

@end


@interface DLPlayerSkinView : UIView<UIGestureRecognizerDelegate>

/// 是否正在播放
@property (nonatomic, assign) BOOL isPlay;

/// 格式
@property (nonatomic, assign) VideoScreenType screenType;

/// 播放按钮
@property (nonatomic, strong) UIImageView *playButton;

/// 全屏按钮
@property (nonatomic, strong) UIButton *screenButton;

/// 重播按钮
@property (nonatomic, strong) UIImageView *repeatPlayButton;

/// 标题
@property (nonatomic, strong) UILabel *titleLabel;

/// 上功能视图
@property (nonatomic, strong) UIImageView *topFuncView;

/// 下功能视图
@property (nonatomic, strong) UIImageView *bottomFuncView;

/// 清晰度选择
@property (nonatomic, strong) UIButton *clarityButton;

/// 清晰度数组
@property (nonatomic, strong) NSArray *clarityArray;

/// 清晰度选择视图
@property (nonatomic, strong) ClarityView *clarityView;

/// 正在播放的视频model
@property (nonatomic, strong) PlaysUrlModel *urlModel;

/// 单击手势
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;

/// 拖动手势
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

/// 用来保存快进的总时长
@property (nonatomic, assign) CGFloat                sumTime;

/// 定义一个实例变量，保存枚举值
@property (nonatomic, assign) PanDirection           panDirection;

/// 是否在调节音量
@property (nonatomic, assign) BOOL                   isVolume;

/// 是否主动旋转屏幕
@property (nonatomic, assign) BOOL                   initiativeRotate;

/// 是否被用户暂停
@property (nonatomic, assign) BOOL                   isPauseByUser;

/// 进入后台
@property (nonatomic, assign) BOOL                   didEnterBackground;

/// 是否在手势中
@property (nonatomic, assign)  BOOL isDragging;

@property (class, readonly) UISlider *volumeViewSlider;

@property MPVolumeView *volumeView;

/// 视频缓存的时间
@property (nonatomic, assign) NSTimeInterval cacheTime;

/// 视频总时长
@property (nonatomic, assign) NSTimeInterval durationTime;

/// 视频的已播放时长
@property (nonatomic, assign) NSTimeInterval playTime;

//  功能扩展
-(void)funcExtension;

-(void)viewTouch;

@end


/// 直播界面
@interface DLLivePlayerSkinView : DLPlayerSkinView



@end

/// 点播界面
@interface DLVodPlayerSkinView : DLPlayerSkinView

//  点播界面
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

/// 清晰度
@property (nonatomic, strong) UILabel *clarityLabel;

/// 清晰度链接
@property (nonatomic, strong) NSString *clarityString;

/// 是否被选择
@property (nonatomic, assign) BOOL chooseState;

@end

@interface FastView : UIView



@end
