//
//  ViewController.m
//  DLToolDemo
//
//  Created by 戴青 on 2020/3/5.
//  Copyright © 2020年 戴青. All rights reserved.
//

#import "ViewController.h"
#import "OneViewController.h"
#import "DLTool.h"
#import "DLLaunchAd.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
//#import "DLSQL.h"
#import "DLModelDemo.h"
#import "DLPromise.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "DLPerformance.h"
#import "UIView+Layout.h"
#import "DLAutoLayout.h"


#define VideoUrl @"http://testplay001.tanqiu.com/live/CR65409930.flv?auth_key=1583637866-RWTORW-0-0ddeadaad92d7edab9de6ad352f9afb7"

#define VideoUrl1 @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"

#define VideoUrl2 @"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"

#define VideoUrl3 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584165060138&di=152be487b8fbfc29dbce11f786705fc4&imgtype=0&src=http%3A%2F%2Fgss0.baidu.com%2F-fo3dSag_xI4khGko9WTAnF6hhy%2Fzhidao%2Fpic%2Fitem%2F3c6d55fbb2fb4316e381ec1b26a4462309f7d331.jpg"

#define VideoUrl4 @"http://vjs.zencdn.net/v/oceans.mp4"

@interface ViewController ()

@property (nonatomic, strong) DLPlayer *player;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    self.navigationController.navigationBarHidden = YES;
}

-(void)aaa{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    [DLPerformanceLabel openMonitoring];
    
    
    [DLPerformance openMonitoring];
    
    UIView *view = [[UIView alloc]init];
    [self.view addSubview:view];
    view.backgroundColor = [UIColor greenColor];
    
//    view.top.left.offset(100).right.offset(0).bottom.offset(0).layout_install;
    
    view.top(self.view).left(self.view).offset(100).right(self.view).bottom(self.view).offset(-100).layout_install();
    
    [view dl_printConstraintsForSelf];
    
    /*
    [view dl_AutoLayout:^(DLConstraintMaker *make) {
        make.left.equal(self.view).offset(0);
        make.right.equal(self.view).offset(0);
        make.top.equal(self.view).offset(0);
        make.bottom.equal(self.view).offset(0);
    }];
    */
     
    [view layoutIfNeeded];
    NSLog(@"%@", view);
    
//    self.player = [DLPlayer shareInstance];
//    self.player.fatherView = self.view;
//    self.player.videoUrl = VideoUrl4;
//    self.player.skinView = [[DLVodPlayerSkinView alloc]init];
//    self.player.videoTitle = @"12222";
//    [self.player start];
        
//    DLLaunchAdModel *model = [[DLLaunchAdModel alloc]init];
//    model.adUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584165060138&di=152be487b8fbfc29dbce11f786705fc4&imgtype=0&src=http%3A%2F%2Fgss0.baidu.com%2F-fo3dSag_xI4khGko9WTAnF6hhy%2Fzhidao%2Fpic%2Fitem%2F3c6d55fbb2fb4316e381ec1b26a4462309f7d331.jpg";
//
//    model.adCount = 3;
//    model.pushUrl = @"11111";
    
    
//    UIImageView *image = [UIImageView dl_view:^(UIImageView *imageView) {
//        imageView.dl_backView(self.view).dl_urlReduceImageString(@"http://h.hiphotos.baidu.com/zhidao/pic/item/7e3e6709c93d70cffcb36aaafbdcd100bba12bc8.jpg");
//        imageView.frame = self.view.frame;
//    }];
    
    
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
//    NSLog(@"touchup");
}

@end
