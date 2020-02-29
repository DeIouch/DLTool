#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import "AppDelegate.h"
#import "UIView+layoutAdd.h"

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
    
    
//    UIView *view = [UIView dl_view:^(UIView *view) {
//        view.dl_backView(self.view).frame = CGRectMake(100, 100, 100, 100);
//        view.dl_backColor(@"FF0000");
//        view.dl_clickTime(5);
//        view.dl_clickEdge(100);
//        view.dl_allCorner(40);
//    }];
//
//    view.clickAction = ^(UIView *view) {
//        NSLog(@"111111");
//    };
//
//    view.tapAction = ^(UIView *view) {
//        NSLog(@"%@", view);
//    };
    
    UIView *view = [[UIView alloc]init];
    [self.view addSubview:view];
    view.backgroundColor = [UIColor redColor];
    
    [view add_dlAutoLayout:^(DLConstraintMaker *make) {
        make.left.equal(self.view);
        make.top.equal(self.view);
        make.bottom.equal(self.view);
        make.width.equal(self.view).multipliedBy(0.5);
    }];
    
    UIView *one = [[UIView alloc]init];
    [self.view addSubview:one];
    one.backgroundColor = [UIColor blueColor];
    
    [one add_dlAutoLayout:^(DLConstraintMaker *make) {
        make.right.equal(self.view);
        make.top.equal(self.view);
        make.bottom.equal(self.view);
        make.width.equal(self.view).multipliedBy(0.5);
    }];
    
    UIButton *two = [[UIButton alloc]init];
    [view addSubview:two];
    two.backgroundColor = [UIColor yellowColor];
    
    [two add_dlAutoLayout:^(DLConstraintMaker *make) {
        make.left.offset(50);
        make.centerY.equal(view);
        make.width.offset(50);
        make.height.offset(50);
    }];
    
    
    UIButton *three = [[UIButton alloc]init];
    [one addSubview:three];
    three.backgroundColor = [UIColor greenColor];
    
    [three add_dlAutoLayout:^(DLConstraintMaker *make) {
        make.left.equal(two).offset(50);
        make.centerY.equal(one);
        make.width.offset(50);
        make.height.offset(50);
    }];
    
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
