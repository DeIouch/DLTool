//
//  UIView+AddDemo.m
//  DLLayerDemo
//
//  Created by tanqiu on 2020/3/2.
//  Copyright © 2020 tanqiu. All rights reserved.
//

#import "UIView+AddDemo.h"
#import <objc/runtime.h>
#import "DLLayer.h"

@interface UIView ()

@property (nonatomic, strong) DLLayer *dl_layer;

@end

static NSString *layer_StrKey = @"layer_StrKey";

@implementation UIView (AddDemo)

+(instancetype)dl_view:(void (^) (UIView *view))block{
    UIView *view = [[UIView alloc]init];
    view.userInteractionEnabled = YES;
    block(view);
    [view.dl_layer setNeedsLayout];
    [view.dl_layer install];
    return view;
}

-(DLLayer *)dl_layer{
    DLLayer *layer = objc_getAssociatedObject(self, &layer_StrKey);
    if (!layer) {
        layer = [[DLLayer alloc]init];
        [self setValue:layer forKey:@"_layer"];
        objc_setAssociatedObject(self, &layer_StrKey, layer, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return layer;
}

-(void)setDl_layer:(CALayer *)dl_layer{
    objc_setAssociatedObject(self, &layer_StrKey, dl_layer, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(UIView *(^)(CGRect rect))dl_rect{
    return ^(CGRect rect) {
        self.dl_layer.frame = rect;
        return self;
    };
}

-(UIView *(^)(UIColor *color))dl_color{
    return ^(UIColor *color) {
        self.dl_layer.backgroundColor = color.CGColor;
//        [self.dl_layer.attributeDic setObject:color forKey:@(dl_backgroundColor_type)];
        return self;
    };
}

-(UIView *(^)(NSString *text))dl_text{
    return ^(NSString *text) {
//        [self.dl_layer.attributeDic setObject:text forKey:@(dl_text_type)];
        self.dl_layer.dl_text = text;
        return self;
    };
}

@end


@implementation UILabel (AddDemo)

+(instancetype)dl_view:(void (^) (UILabel *label))block{
    UILabel *label;
    label = [[UILabel alloc]init];
    label.userInteractionEnabled = YES;
    block(label);
    [label.dl_layer setNeedsLayout];
    [label.dl_layer install];
    return label;
}

@end
