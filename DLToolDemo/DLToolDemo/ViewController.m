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

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) DLPlayer *player;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.player = [DLPlayer shareInstance];
//    self.player.fatherView = self.view;
//    self.player.videoUrl = VideoUrl2;
//    self.player.skinView = [[DLVodPlayerSkinView alloc]init];
//    self.player.videoTitle = @"12222";
//    [self.player start];
    
    
    
    
    self.array = [[NSMutableArray alloc]init];
    for (int a = 0; a < 5; a++) {
        [self.array addObject:@"normal"];
    }
    
//    [UIScrollView setUpHeadFreshDefaultView:self.view];
    
    self.tableView = [[UITableView alloc]init];
//                      WithFrame:CGRectMake(0, 0, DLWidth, DLHeight)];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [self.tableView dl_AutoLayout:^(DLConstraintMaker *make) {
        make.left.equal(self.view).offset(0);
        make.right.equal(self.view).to(DLAttributeBottom).offset(0);
        make.top.equal(self.view).offset(0);
        make.bottom.equal(self.view).offset(0);
    }];
    
    
    @dl_weakify;
//    [self.tableView headFreshBlock:^{
//        @dl_strongify;
//        for (int a = 0; a < 5; a++) {
//            [self.array insertObject:[NSString stringWithFormat:@"head %u", arc4random() % 10000] atIndex:0];
//        }
//        [self.tableView reloadData];
//    }];
    
    [self.tableView footFreshBlock:^{
        @dl_strongify;
        for (int a = 0; a < 5; a++) {
            [self.array addObject:[NSString stringWithFormat:@"foot %u", arc4random() % 10000]];
        }
        [self.tableView reloadData];
    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    OneViewController *vc = [[OneViewController alloc]init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 30;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.array[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

@end
