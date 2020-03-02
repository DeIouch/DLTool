#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import "AppDelegate.h"
#import <sys/time.h>
#import "UIView+AddDemo.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem *currentPlayerItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    UIView *view = [];
    
    
    NSString *webVideoPath = @"https://media.w3.org/2010/05/sintel/trailer.mp4";
    NSURL *webVideoUrl = [NSURL URLWithString:webVideoPath];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:webVideoUrl];
    self.currentPlayerItem = playerItem;
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    AVPlayerLayer *avLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    avLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avLayer.frame = self.view.bounds;
        
    [self.view.layer addSublayer:avLayer];
    
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
}

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
//                self.totalNeedPlayTimeLabel.text = [self formatTimeWithTimeInterVal:CMTimeGetSeconds(duration)];
//                //开启滑块的滑动功能
//                self.sliderView.enabled = YES;
//                //关闭加载Loading提示
//                [self showaAtivityInDicatorView:NO];
                //开始播放视频
                [self.player play];
                break;
            }
            case AVPlayerStatusFailed:{//视频加载失败，点击重新加载
//                [self showaAtivityInDicatorView:NO];//关闭Loading视图
//                self.playerInfoButton.hidden = NO; //显示错误提示按钮，点击后重新加载视频
//                [self.playerInfoButton setTitle:@"资源加载失败，点击继续尝试加载" forState: UIControlStateNormal];
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
        NSLog(@"开始缓冲:%f,缓冲时长:%f,总时间:%f", loadStartSeconds, loadDurationSeconds, currentLoadTotalTime);
//        //更新显示：当前缓冲总时长
//        [self formatTimeWithTimeInterVal:currentLoadTotalTime];
//        //更新显示：视频的总时长
//        [self formatTimeWithTimeInterVal:CMTimeGetSeconds(self.player.currentItem.duration)];
//        //更新显示：缓冲进度条的值
//        currentLoadTotalTime/CMTimeGetSeconds(self.player.currentItem.duration);
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

//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    OneViewController *vc = [[OneViewController alloc]init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
//}

@end
