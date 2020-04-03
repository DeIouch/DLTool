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


#define VideoUrl @"http://testplay001.tanqiu.com/live/CR65409930.flv?auth_key=1583637866-RWTORW-0-0ddeadaad92d7edab9de6ad352f9afb7"

#define VideoUrl1 @"https://vdse.bdstatic.com//f11546e6b21bb6f60f025df3d5cb5735?authorization=bce-auth-v1/fb297a5cc0fb434c971b8fa103e8dd7b/2017-05-11T09:02:31Z/-1//560f50696b0d906271532cf3868d7a3baf6e4f7ffbe74e8dff982ed57f72c088.mp4"

#define VideoUrl2 @"http://vfx.mtime.cn/Video/2019/02/04/mp4/190204084208765161.mp4"

#define VideoUrl3 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584165060138&di=152be487b8fbfc29dbce11f786705fc4&imgtype=0&src=http%3A%2F%2Fgss0.baidu.com%2F-fo3dSag_xI4khGko9WTAnF6hhy%2Fzhidao%2Fpic%2Fitem%2F3c6d55fbb2fb4316e381ec1b26a4462309f7d331.jpg"

#define VideoUrl4 @"http://vjs.zencdn.net/v/oceans.mp4"

#define VideoUrl5 @"http://i1.fuimg.com/714379/fdb945e4f87789ad.jpg"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) DLPlayer *player;

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation ViewController{
    UITextField *textField;
    UITextView *atextField;
    UITableView *tableView;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    [DLPerformance openMonitoring];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    NSMutableArray *array = [[NSMutableArray alloc]init];
    for (int a = 0; a < 10; a ++) {
        NSMutableDictionary *tempDic = [[NSMutableDictionary alloc]init];
        [tempDic setObject:@"11" forKey:@"id"];
        for (int i = 0; i < 10; i++) {
            NSNumber *number = [NSNumber numberWithInt:i];
            [tempDic setObject:number forKey:[NSString stringWithFormat:@"tempDic%d", i]];
        }
        [array addObject:tempDic];
        [dic setObject:tempDic forKey:[NSString stringWithFormat:@"key%d", a]];
    }
    [dic setObject:array forKey:@"data"];
    
    NSLog(@"%d", [DLJsonToModel dl_createModelWithDic:dic modelName:@"TestModel"]);
    
//    [DLJsonToModel dl_createModelWithJson:dic fileName:@"ATest" extensionName:@"Model" fileURL:[NSURL URLWithString:@"/Users/tanqiu/Desktop/"] error:^(NSError *error) {
//
//    }];
    
    
//    tableView = [[UITableView alloc]initWithFrame:self.view.bounds];
//
//    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    
//    [self.view addSubview:tableView];
//    tableView.delegate = self;
//    tableView.dataSource = self;
    
//    textField = [[UITextField alloc]init];
//    [self.view addSubview:textField];
//    textField.backgroundColor = [UIColor redColor];
//    textField.dl_layout.left.right.bottom.height.offset(50).install();
//    textField.singleMeView = textField;
//
//
//    atextField = [[UITextView alloc]init];
//    [self.view addSubview:atextField];
//    atextField.backgroundColor = [UIColor greenColor];
//    atextField.dl_layout.left.right.height.offset(50).bottom.offset(280).install();
//    atextField.notManageBOOL = YES;
//    atextField.singleMeView = textField;
    
    
//    NSLog(@"%@", atextField.subviews);
    
    
//    self.player = [DLPlayer shareInstance];
//    self.player.fatherView = self.view;
//    self.player.videoUrl = VideoUrl4;
//    self.player.skinView = [[DLVodPlayerSkinView alloc]init];
//    self.player.videoTitle = @"12222";
//    [self.player start];
    
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

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    
//    OneViewController *vc = [[OneViewController alloc]init];
//    vc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [self presentViewController:vc animated:YES completion:nil];
//    [self.navigationController pushViewController:vc animated:YES];
    
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:touch.view];
    
    if (point.y < 150) {
        OneViewController *vc = [[OneViewController alloc]init];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        [atextField resignFirstResponder];
        [textField resignFirstResponder];
    }
//    [atextField resignFirstResponder];
}



@end
