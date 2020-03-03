#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import "AppDelegate.h"
#import <sys/time.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __block int a = 50000000;
    while (a) {
        [DLThread doTask:^{
            NSLog(@"doTask == %d", a);
        } async:YES];
        a --;
    }
    
    
    
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];

}

@end
