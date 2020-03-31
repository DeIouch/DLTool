//
//  DLDemoTableViewCell.m
//  DLToolDemo
//
//  Created by tanqiu on 2020/3/16.
//  Copyright © 2020 戴青. All rights reserved.
//

#import "DLDemoTableViewCell.h"

@implementation DLDemoTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.imageview = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 30)];
        
        [self.contentView addSubview:self.imageview];
    }
    return self;
}

@end
