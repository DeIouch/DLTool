//
//  UIView+DLLLL.h
//  DLToolDemo
//
//  Created by 戴青 on 2020/3/27.
//  Copyright © 2020年 戴青. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DLLayout : NSObject

@property (nonatomic, strong) DLLayout *left;

@property (nonatomic, strong) DLLayout *right;

@property (nonatomic, strong) DLLayout *top;

@property (nonatomic, strong) DLLayout *bottom;

@property (nonatomic, strong) DLLayout *safeTop;

@property (nonatomic, strong) DLLayout *safeBottom;

@property (nonatomic, strong) DLLayout *width;

@property (nonatomic, strong) DLLayout *lessOrThanWidth;

@property (nonatomic, strong) DLLayout *greatOrThenWidth;

@property (nonatomic, strong) DLLayout *height;

@property (nonatomic, strong) DLLayout *lessOrThanHeight;

@property (nonatomic, strong) DLLayout *greatOrThanHeight;

@property (nonatomic, strong) DLLayout *centerX;

@property (nonatomic, strong) DLLayout *centerY;

-(DLLayout *(^)(UIView *view))equal;

-(DLLayout *(^)(UIView *view))equal_to;

-(DLLayout *(^)(CGFloat constant))multipliedBy;

-(DLLayout *(^)(CGFloat constant))offset;

-(void *(^)(void))install;

-(void *(^)(void))remove;

@end

@interface UIView (Layout)

@property (nonatomic, strong) DLLayout *dl_layout;

//print
//- (void)dl_printConstraintsForSelf;

@end
