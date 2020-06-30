//
//  DLDemoTableViewCell.m
//  DLToolDemo
//
//  Created by tanqiu on 2020/3/16.
//  Copyright © 2020 戴青. All rights reserved.
//

#import "DLDemoTableViewCell.h"
#import "UIView+Layout.h"

#define random(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/255.0]

#define randomColor random(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

@implementation DLDemoTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
//        self.dl_imageview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 30)];
        self.dl_imageview = [[UIImageView alloc]init];
//        self.dl_imageview.image = [UIImage imageNamed:@"1.jpeg"];
        self.dl_imageview.dl_layout(DL_Left | DL_Right | DL_Top | DL_Bottom).equal(self.contentView).offset(0);

        [self.contentView addSubview:self.dl_imageview];
        
//        self.textField = [[UITextField alloc]initWithFrame:self.contentView.bounds];
//        [self.contentView addSubview:self.textField];
//        self.textField.backgroundColor = randomColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

@end
