//
//  UIView+AddDemo.h
//  DLLayerDemo
//
//  Created by tanqiu on 2020/3/2.
//  Copyright © 2020 tanqiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (AddDemo)

+(instancetype)dl_view:(void (^) (UIView *view))block;

-(UIView *(^)(CGRect rect))dl_rect;

-(UIView *(^)(UIColor *color))dl_color;

-(UIView *(^)(NSString *text))dl_text;

@end
