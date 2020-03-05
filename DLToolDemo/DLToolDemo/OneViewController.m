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

@interface OneViewController ()

@property (nonatomic, strong) NSString *str;

@end

@implementation OneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIView *view = [UIView dl_view:^(UIView *view) {
        view.dl_backView(self.view).frame = CGRectMake(100, 100, 100, 100);
        view.dl_backColor(@"FF0000");
        view.dl_clickTime(5);
        view.dl_clickEdge(100);
    }];
    
    Method method = class_getClassMethod([self class], @selector(adddd));
    class_addMethod([self class], @selector(adddd), method_getImplementation(method), "v@:");
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(adddd) userInfo:nil repeats:YES];
    
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
