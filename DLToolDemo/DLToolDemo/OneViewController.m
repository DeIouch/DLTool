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
#import "DLDemoTableViewCell.h"
#import "TestView.h"
#import "UIImageView+DLWeb.h"
#import "UIImageView+WebCache.h"

#define VideoUrl4 @"https://s1.ax1x.com/2020/05/14/YBiSOS.jpg"


#define VideoUrl5 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829650&di=8612ffc828197b60da29e66eb56ffee0&imgtype=0&src=http%3A%2F%2Fi1.hdslb.com%2Fbfs%2Farchive%2Ff47d9b1af8b8c790a6a1ebdde3f0c0943d726869.jpg"


#define VideoUrl6 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829649&di=83cdd7132caad90213c9f30675cff0ae&imgtype=0&src=http%3A%2F%2Fi1.hdslb.com%2Fbfs%2Farchive%2F0412734947cc0e79810675f20448e70257d2dec3.jpg"


#define VideoUrl7 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829649&di=85738262df68d8c38108c9f507b5f284&imgtype=0&src=http%3A%2F%2Fc.hiphotos.baidu.com%2Fzhidao%2Fpic%2Fitem%2F8b82b9014a90f60399d5bdee3e12b31bb051ed36.jpg"


#define VideoUrl8 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829649&di=2f5d7b132bf493eb7f548187312b3ee7&imgtype=0&src=http%3A%2F%2Fhbimg.b0.upaiyun.com%2Fc4406b693041c569327dba318e316be839faf2538414-fYFGb4_fw658"

#define VideoUrl9 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829648&di=84f34c07df76276b062cad1522f85a99&imgtype=0&src=http%3A%2F%2F5b0988e595225.cdn.sohucs.com%2Fimages%2F20171108%2F3fe473acfc39476db58fadd7fbaf97ff.jpeg"


#define VideoUrl10 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829647&di=3b35f63770eda31f7772b5bbaf2bc93e&imgtype=0&src=http%3A%2F%2Fg.hiphotos.baidu.com%2Fzhidao%2Fpic%2Fitem%2Fdbb44aed2e738bd4fd9139baa48b87d6267ff98d.jpg"


#define VideoUrl11 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829647&di=297b171202fe229454545cd9eb62a329&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201607%2F22%2F20160722180244_4QYLN.jpeg"

#define VideoUrl12 @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1584335829647&di=0deef904f0a10ec9712d2cea5ba84605&imgtype=0&src=http%3A%2F%2Fimage.woshipm.com%2Fwp-files%2F2015%2F11%2FQQ%25E6%2588%25AA%25E5%259B%25BE20151112171615_%25E5%2589%25AF%25E6%259C%25AC.png"

@interface OneViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSString *str;

@end

@implementation OneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"fffffffff");
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    self.array = [[NSMutableArray alloc]init];
    for (int a = 0; a < 100; a++) {
        [self.array addObject:VideoUrl6];
    }

//    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, DLWidth, DLHeight)];
    
    self.tableView = [[UITableView alloc]init];
    self.tableView.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self.view).offset(0);
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
//    self.tableView.estimatedRowHeight = 10;
//    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.tableView reloadData];
    
    @dl_weakify;
    [self.tableView headFreshBlock:^{
        @dl_strongify;
//        [self.array addObject:VideoUrl4];
//        [self.array addObject:VideoUrl5];
//        [self.array addObject:VideoUrl6];
//        [self.array addObject:VideoUrl7];
//        [self.array addObject:VideoUrl8];
//        [self.array addObject:VideoUrl9];
//        [self.array addObject:VideoUrl10];
//        [self.array addObject:VideoUrl11];
//        [self.array addObject:VideoUrl12];
        [self.tableView reloadData];
        NSLog(@"刷新完成");
    }];

//    [self.tableView footFreshBlock:^{
//        @dl_strongify;
//        [self.array addObject:VideoUrl4];
//        [self.array addObject:VideoUrl5];
//        [self.array addObject:VideoUrl6];
//        [self.array addObject:VideoUrl7];
//        [self.array addObject:VideoUrl8];
//        [self.array addObject:VideoUrl9];
//        [self.array addObject:VideoUrl10];
//        [self.array addObject:VideoUrl11];
//        [self.array addObject:VideoUrl12];
//
//        [self.tableView reloadData];
//    }];
        
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [self.tableView getCellHeightWithIndex:indexPath];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DLDemoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[DLDemoTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
//    [cell.dl_imageview dl_setWebImage:self.array[indexPath.row]];
    [cell.dl_imageview sd_setImageWithURL:[NSURL URLWithString:self.array[indexPath.row]]];
//    [self.tableView setCellHeight:cell WithIndex:indexPath];
    return cell;
}

-(void)adddd{
    NSLog(@"222222222222");
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)dealloc{
    NSLog(@"dealloc");
}

@end


