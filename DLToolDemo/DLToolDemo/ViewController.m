#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.view.dl_backColor(@"FF0000");
//
//    self.view.dl_clickTime(5);
//
//    self.view.tapAction = ^{
//        OneViewController *vc = [[OneViewController alloc]init];
//        vc.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:vc animated:YES completion:nil];
//    };
    
//    self.view.tapAction = ^(UIView *view) {
//        OneViewController *vc = [[OneViewController alloc]init];
//        vc.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:vc animated:YES completion:nil];
//    };
    
    
    UIView *view = [UIView dl_view:^(UIView *view) {
        view.dl_backView(self.view).frame = CGRectMake(100, 100, 100, 100);
        view.dl_backColor(@"FF0000");
//        view.dl_clickTime(5);
    }];
    
    view.clickAction = ^ {
        NSLog(@"111111");
    };
//
//    view.tapAction = ^(UIView *view) {
//        NSLog(@"%@", view);
//    };
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
