//
//  DLLayer.h
//  DLLayerDemo
//
//  Created by tanqiu on 2020/3/2.
//  Copyright © 2020 tanqiu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UIKitAttributeType) {
    dl_frame_type                   =   1,
    dl_backgroundColor_type,
    dl_text_type,
};

@interface DLLayer : CALayer<NSCopying, CALayerDelegate>

@property CGRect dl_frame;

@property CGColorRef dl_backgroundColor;

@property (nonatomic, strong) NSString *dl_text;

@property (nonatomic, strong) NSMutableDictionary *attributeDic;

-(void)install;

@end
