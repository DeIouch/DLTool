#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) DLPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    self.player = [DLPlayer shareInstance];
    self.player.fatherView = self.view;
    self.player.videoUrl = @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4";
    self.player.skinView = [[DLLivePlayerSkinView alloc]init];
    [self.player start];
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];

}

@end
