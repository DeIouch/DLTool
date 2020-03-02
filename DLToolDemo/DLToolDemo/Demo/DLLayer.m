//
//  DLLayer.m
//  DLLayerDemo
//
//  Created by tanqiu on 2020/3/2.
//  Copyright © 2020 tanqiu. All rights reserved.
//

#import "DLLayer.h"
#import "DLThread.h"
#import <CoreText/CoreText.h>

@implementation DLLayer

-(instancetype)init{
    if ([super init]) {
        self.attributeDic = [[NSMutableDictionary alloc]init];
        self.drawsAsynchronously = YES;
        self.delegate = self;
        self.contentsScale = [UIScreen mainScreen].scale;
    }
    return self;
}

+(Class)layerClass{
    return [DLLayer class];
}

-(id)copyWithZone:(NSZone *)zone{
    return self;
}

-(id)MutableCopyWithZone:(NSZone *)zone{
    return self;
}

-(void)displayLayer:(CALayer *)layer{
    NSLog(@"11111");
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    NSLog(@"22222");
}

- (void)layerWillDraw:(CALayer *)layer{
    NSLog(@"33333");
}

- (void)layoutSublayersOfLayer:(CALayer *)layer{
    NSLog(@"44444");
}

- (nullable id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event{
    NSLog(@"55555");
    return nil;
}

-(void)install{
    [DLThread doTask:^{
        NSArray *array = [self.attributeDic allKeys];
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.contentsScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
        
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:self.dl_text];
        
        CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attStr);
        CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attStr.length), path, NULL);
        CTFrameDraw(frame, context);
        
        
        for (NSString *attributeType in array) {
            switch ([attributeType intValue]) {
                case dl_backgroundColor_type:
                    {
                        UIColor *color = (UIColor *)[self.attributeDic objectForKey:attributeType];
                        self.backgroundColor = color.CGColor;
                    }
                    break;
                    
                case dl_text_type:
                    {
                        
                    }
                    break;
                    
                default:
                    break;
            }
        }
        
        self.masksToBounds = YES;
        self.cornerRadius = 25;
        
        UIImage *getImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contents = (__bridge id)getImg.CGImage;
            [self.attributeDic removeAllObjects];
        });
        
    } start:0 async:YES];
}

@end
