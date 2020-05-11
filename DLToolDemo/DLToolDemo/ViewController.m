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
#import "DLModelDemo.h"
#import "DLPromise.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "DLPerformance.h"
#import "UIView+Layout.h"
#import "DLDownloadOperation.h"
#import "DLKeyboardManage.h"
#import "DLAutoLayout.h"
#import "DLDemoTableViewCell.h"
#import "DLAutoLayout.h"
#import "DLJsonToModel.h"
#import "TestModel.h"
#import "DLToolMacro.h"
#import <malloc/malloc.h>
#import "YYCache.h"

#define VideoUrl @"http://testplay001.tanqiu.com/live/CR65409930.flv?auth_key=1583637866-RWTORW-0-0ddeadaad92d7edab9de6ad352f9afb7"

#define VideoUrl1 @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"

#define VideoUrl2 @"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"

#define VideoUrl3 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584165060138&di=152be487b8fbfc29dbce11f786705fc4&imgtype=0&src=http%3A%2F%2Fgss0.baidu.com%2F-fo3dSag_xI4khGko9WTAnF6hhy%2Fzhidao%2Fpic%2Fitem%2F3c6d55fbb2fb4316e381ec1b26a4462309f7d331.jpg"

#define VideoUrl4 @"http://vjs.zencdn.net/v/oceans.mp4"

#define VideoUrl5 @"http://i1.fuimg.com/714379/fdb945e4f87789ad.jpg"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) DLPlayer *player;

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) UIButton *buttonA;

@property (nonatomic, strong) UIButton *buttonB;

@property (nonatomic, strong) UITextField *textField;

@end

@implementation ViewController{
    UITextField *textField;
    UITextView *atextField;
    UITableView *tableView;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)acb{
    NSLog(@"11111");
}

-(void)abc:(UIButton *)event{
    NSLog(@"222222 %@", event);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [DLPerformance openMonitoring];
        
//    self.player = [DLPlayer shareInstance];
//    self.player.fatherView = self.view;
//    self.player.videoUrl = VideoUrl4;
//    self.player.skinView = [[DLVodPlayerSkinView alloc]init];
//    self.player.videoTitle = @"12222";
//    [self.player start];
    
//    YYMemoryCache *cache = [[YYMemoryCache alloc]init];
    
//    YYDiskCache *cache = [[YYDiskCache alloc]initWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]];
    
    NSLog(@"%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]);
        
//    [[DLCache shareInstance] printfAllCache];
    
//    NSDate *datenow = [NSDate date];
//    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] *1000;
    
//    NSLog(@"%lf  ==  %f", CFAbsoluteTimeGetCurrent(), [[NSDate date] timeIntervalSince1970] *1000);
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    OneViewController *vc = [[OneViewController alloc]init];
//    [self.navigationController pushViewController:vc animated:YES];
    
//    YYCache *cache = [[YYCache alloc]initWithName:@"demo"];
    
    DLCache *cache = [[DLCache alloc]initWithFileName:@"dl_cach"];
    
    [self startTiming];
        
    for (int a = 0; a < 100; a++) {
        @autoreleasepool {
            NSString *str = [NSString stringWithFormat:@"%d", a];

//            DLModelDemo *model = [[DLModelDemo alloc]init];
//            model.code = @"code";
//            model.codee = @"codee";

            UIImage *model = [UIImage imageNamed:@"1.jpeg"];
            
//            NSLog(@"%lu", (unsigned long)model.hash);

            [cache setObject:model forKey:str];
            
//            [cache objectForKey:str];
        }
    }
        
//    NSLog(@"%@");
            
    [self endTiming];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 100;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DLDemoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[DLDemoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    return cell;
}

@end
