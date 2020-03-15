//
//  OneViewController.m
//  DLToolDemo
//
//  Created by tanqiu on 2020/2/28.
//  Copyright © 2020 tanqiu. All rights reserved.
//

#import "OneViewController.h"
#import "DLTool.h"
#import "AppDelegate.h"
#import "ViewController.h"

#define VideoUrl4 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584165060138&di=152be487b8fbfc29dbce11f786705fc4&imgtype=0&src=http%3A%2F%2Fgss0.baidu.com%2F-fo3dSag_xI4khGko9WTAnF6hhy%2Fzhidao%2Fpic%2Fitem%2F3c6d55fbb2fb4316e381ec1b26a4462309f7d331.jpg"

@interface OneViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSString *str;

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation OneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    self.array = [[NSMutableArray alloc]init];
//    for (int a = 0; a < 20; a++) {
//        [self.array addObject:@"normal"];
//    }
//
//    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, DLWidth, DLHeight)];
//    [self.view addSubview:self.tableView];
//    self.tableView.delegate = self;
//    self.tableView.dataSource = self;
//    self.tableView.backgroundColor = [UIColor whiteColor];
//
//    @dl_weakify;
//    [self.tableView headFreshBlock:^{
//        @dl_strongify;
//        for (int a = 0; a < 20; a++) {
//            [self.array insertObject:@"head" atIndex:0];
//        }
//        [self.tableView reloadData];
//    }];
//
//    [self.tableView footFreshBlock:^{
//        @dl_strongify;
//        for (int a = 0; a < 20; a++) {
//            [self.array addObject:@"foot"];
//        }
//        [self.tableView reloadData];
//    }];
    
    DLScrollView *sc = [DLScrollView scrollWithFrame:CGRectMake(0, 100, 300, 300) loop:YES loopSecond:3 ImageArr:@[VideoUrl4] AndImageClickBlock:^(NSInteger index) {

    }];
    [self.view addSubview:sc];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self dismissViewControllerAnimated:YES completion:nil];
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

-(void)adddd{
    NSLog(@"222222222222");
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dealloc{
    
    NSLog(@"11111");
}

@end
