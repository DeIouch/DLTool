#import "DLPopView.h"
@interface DLPopView ()

@property (nonatomic, strong) UILabel *contentLabel;
@end

@implementation DLPopView

- (instancetype)init{
    self = [super init];
    if (self) {
        [self addSubViews];
    }
    return self;
}

-(void)addSubViews{
    self.contentLabel = [[UILabel alloc]init];
    self.contentLabel.font = [UIFont systemFontOfSize:16.0];
    self.contentLabel.numberOfLines = 0;
    self.contentLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.contentLabel];
}

- (void)setUpPop{
    CGFloat leftSpace = 5;
    CGSize maxSize = CGSizeMake(200, 990);
    CGSize size = [self.contentLabel sizeThatFits:maxSize];
    self.contentLabel.frame = CGRectMake(5, 10, size.width, size.height);
    CGFloat radius = 10.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(leftSpace,0)];
    [path addLineToPoint:CGPointMake(size.width+ leftSpace - radius,0)];
    [path addArcWithCenter:CGPointMake(size.width + leftSpace, radius) radius:radius startAngle:- M_PI_2 endAngle:0 clockwise:YES];//右上
    [path addLineToPoint:CGPointMake(size.width+ leftSpace + radius , size.height - radius)];
    [path addArcWithCenter:CGPointMake(size.width + leftSpace, size.height + radius) radius:radius startAngle:0 endAngle:M_PI_2 clockwise:YES];//右下
    [path addLineToPoint:CGPointMake(leftSpace,size.height + radius + radius)];
    [path addArcWithCenter:CGPointMake(leftSpace, size.height + radius) radius:radius startAngle:-M_PI*3/2.0 endAngle:-M_PI clockwise:YES];//左下
    [path addLineToPoint:CGPointMake(leftSpace -10.0,30.0 - 10)];
    [path addLineToPoint:CGPointMake(leftSpace -20.0,25.0 - 10)];
    [path addLineToPoint:CGPointMake(leftSpace -10.0,20.0 - 10)];
    [path addLineToPoint:CGPointMake(leftSpace -10.0,20.0 - 10)];
    [path addLineToPoint:CGPointMake(leftSpace - radius, radius)];
    [path addArcWithCenter:CGPointMake(leftSpace, radius) radius:radius startAngle:-M_PI endAngle:-M_PI_2 clockwise:YES];//左上
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth=0.5;
    layer.strokeColor=[UIColor colorWithRed:127/255.0 green:127/255.0 blue:127/255.0 alpha:1.0].CGColor;
    layer.path= path.CGPath;
    [self.layer addSublayer:layer];
}

-(void)setContentText:(NSString *)text
{
    self.contentLabel.text = text;
    [self setUpPop];
}





@end
