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
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#define VideoUrl @"http://testplay001.tanqiu.com/live/CR65409930.flv?auth_key=1583637866-RWTORW-0-0ddeadaad92d7edab9de6ad352f9afb7"

#define VideoUrl1 @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"

#define VideoUrl2 @"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) DLPlayer *player;

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [DLPlayer shareInstance];
    self.player.fatherView = self.view;
    self.player.videoUrl = VideoUrl2;
    self.player.skinView = [[DLVodPlayerSkinView alloc]init];
    self.player.videoTitle = @"12222";
    [self.player start];
    
//    self.player.barrageShowType = BarrageShowFullScreen;
    
    self.player.barrageMemberColorHexStr = @"FF0000";
    
    [DLTimer doTask:^{
        [self.player addBarrageString:@"123123" isMember:random() % 2];
    } start:0 interval:1 repeats:YES async:NO];
    
}



@end
