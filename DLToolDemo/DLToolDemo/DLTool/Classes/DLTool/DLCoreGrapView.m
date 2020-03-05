#import "DLCoreGrapView.h"
#include <objc/runtime.h>
#import "DLColor.h"

@interface DLCoreGrapView()

@property (nonatomic, strong) NSArray *pointArray;

@property (nonatomic, strong) NSArray *strokeColor;

@property (nonatomic, strong) NSArray *fillColor;

@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, assign) DrawViewType type;

@property (nonatomic, assign) CGPathDrawingMode mode;

@property (nonatomic, assign) CGFloat circleX;

@property (nonatomic, assign) CGFloat circleY;

@property (nonatomic, assign) CGFloat circleRadius;

@property (nonatomic, assign) CGFloat circleStartAngle;

@property (nonatomic, assign) CGFloat circleEndAngle;

@property (nonatomic, assign) int circleClockwise;

@property (nonatomic, assign) CGRect rect;

@property (nonatomic, strong) NSString *imageString;

@property (nonatomic, strong) NSString *titleString;

@property (nonatomic, strong) NSDictionary *titleDic;

@property (nonatomic, assign) CGPoint curvePoint;

@property (nonatomic, strong) NSArray *curveArray;

@end

@implementation DLCoreGrapView

-(DLCoreGrapView *(^)(NSArray *colorArray))DLStrokeColor{
    return ^(NSArray *colorArray){
        self.strokeColor = colorArray;
        self.mode = kCGPathFillStroke;
        return self;
    };
}

-(DLCoreGrapView *(^)(NSArray *colorArray))DLFillColor{
    return ^(NSArray *colorArray){
        self.fillColor = colorArray;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGFloat lineWidth))DLLineWidth{
    return ^(CGFloat lineWidth){
        self.lineWidth = lineWidth;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGPathDrawingMode mode))DLMode{
    return ^(CGPathDrawingMode mode){
        self.mode = mode;
        return self;
    };
}

-(DLCoreGrapView *(^)(NSArray *pointArray))DLLine{
    return ^(NSArray *pointArray){
        self.pointArray = pointArray;
        self.type = DrawLineView;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGFloat x, CGFloat y, CGFloat radius, CGFloat startAngle, CGFloat endAngle, int clockwise))DLCircleView{
    return ^(CGFloat x, CGFloat y, CGFloat radius, CGFloat startAngle, CGFloat endAngle, int clockwise){
        self.circleX = x;
        self.circleY = y;
        self.circleRadius = radius;
        self.circleStartAngle = startAngle;
        self.circleEndAngle = endAngle;
        self.circleClockwise = clockwise;
        self.type = DrawCircleView;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGRect rect))DLEllipseView{
    return ^(CGRect rect){
        self.rect = rect;
        self.type = DrawEllipseView;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGRect rect, NSString *imageString))DLPictView{
    return ^(CGRect rect, NSString *imageString){
        self.rect = rect;
        self.imageString = imageString;
        self.type = DrawPictView;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGRect rect, NSString *titleString, NSDictionary *dic))DLTextView{
    return ^(CGRect rect, NSString *titleString, NSDictionary *dic){
        self.rect = rect;
        self.titleString = titleString;
        self.titleDic = dic;
        self.type = DrawTextView;
        return self;
    };
}

-(DLCoreGrapView *(^)(CGPoint point, NSArray *array))DLCurveView{
    return ^(CGPoint point, NSArray *array){
        self.curveArray = array;
        self.curvePoint = point;
        self.type = DrawCurveView;
        return self;
    };
}

-(instancetype)init{
    if (self = [super init]) {
        self.backgroundColor = [UIColor whiteColor];
        self.mode = kCGPathFill;
        self.lineWidth = 1;
    }
    return self;
}

-(void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (self.strokeColor) {
        UIColor *stroke;
        if (@available(iOS 13.0, *)) {
//            stroke = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//                if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                    return [DLColor DLColorWithAHEXColor:(self.strokeColor.count == 1) ? self.strokeColor[0] : self.strokeColor[1]];
//                }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                    return [DLColor DLColorWithAHEXColor:self.strokeColor[0]];
//                }
//                return [DLColor DLColorWithAHEXColor:self.strokeColor[0]];
//            }];
        }else{
            stroke = [DLColor DLColorWithAHEXColor:self.strokeColor[0]];
        };
        CGContextSetStrokeColorWithColor(ctx, stroke.CGColor);
        CGContextSetLineWidth(ctx, self.lineWidth);
    }
    
    UIColor *fill;
    if (@available(iOS 13.0, *)) {
//        fill = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
//            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
//                return [DLColor DLColorWithAHEXColor:(self.fillColor.count == 1) ? self.fillColor[0] : self.fillColor[1]];
//            }else if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleLight) {
//                return [DLColor DLColorWithAHEXColor:self.fillColor[0]];
//            }
//            return [DLColor DLColorWithAHEXColor:self.fillColor[0]];
//        }];
    }else{
        fill = [DLColor DLColorWithAHEXColor:self.fillColor[0]];
    };
    CGContextSetFillColorWithColor(ctx, fill.CGColor);
    
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    switch (self.type) {
        case DrawLineView:
            {
                [self drawLine:ctx];
            }
            break;
            
        case DrawCircleView:
            {
                [self drawCircle:ctx];
            }
            break;
                
        case DrawEllipseView:
            {
                [self drawEllipse:ctx];
            }
            break;
                
        case DrawPictView:
            {
                [self drawPict:ctx];
            }
            break;
                
        case DrawTextView:
            {
                [self drawText:ctx];
            }
            break;
            
        case DrawCurveView:
            {
                [self drawCurve:ctx];
            }
            break;
            
        default:
            break;
    }
}

-(void)drawLine:(CGContextRef)ctx{
    if (self.pointArray.count < 1) {
        return;
    }
    NSMutableArray *array = [[NSMutableArray alloc]initWithArray:self.pointArray];
    [array removeObjectAtIndex:0];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint point = CGPointFromString(self.pointArray.firstObject);
    CGPathMoveToPoint(path, &CGAffineTransformIdentity, point.x, point.y);
    for (id point in array) {
        CGPoint otherPoint = CGPointFromString(point);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, otherPoint.x, otherPoint.y);
    }
    CGPathCloseSubpath(path);
    CGContextAddPath(ctx, path);
    CGContextDrawPath(ctx, self.mode);
}

-(void)drawCircle:(CGContextRef)ctx{
    CGContextAddArc (ctx, self.circleX, self.circleY, self.circleRadius, self.circleStartAngle, self.circleEndAngle, self.circleClockwise);
    CGContextDrawPath(ctx, self.mode);
}

-(void)drawEllipse:(CGContextRef)ctx{
    CGContextAddEllipseInRect(ctx, self.rect);
    CGContextDrawPath(ctx, self.mode);
}

-(void)drawPict:(CGContextRef)ctx{
    [[UIImage imageNamed:self.imageString] drawInRect:self.rect];
    CGContextDrawPath(ctx, self.mode);
}

-(void)drawText:(CGContextRef)ctx{
    [self.titleString drawInRect:self.rect withAttributes:self.titleDic];
    CGContextDrawPath(ctx, self.mode);
}

-(void)drawCurve:(CGContextRef)ctx{
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, self.curvePoint.x, self.curvePoint.y);
    for (NSString *str in self.curveArray) {
        CGRect rect = CGRectFromString(str);
        CGContextAddQuadCurveToPoint(ctx, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    }
    CGContextDrawPath(ctx, self.mode);
}

@end
