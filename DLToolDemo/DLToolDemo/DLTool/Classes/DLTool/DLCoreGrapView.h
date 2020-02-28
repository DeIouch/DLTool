#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DrawViewType) {
    DrawLineView    =   0,
    DrawCircleView  =   1,
    DrawEllipseView =   2,
    DrawPictView    =   3,
    DrawTextView    =   4,
    DrawCurveView   =   5,
};

@interface DLCoreGrapView : UIView

-(DLCoreGrapView *(^)(NSArray *colorArray))DLStrokeColor;

-(DLCoreGrapView *(^)(NSArray *colorArray))DLFillColor;

-(DLCoreGrapView *(^)(CGFloat lineWidth))DLLineWidth;

-(DLCoreGrapView *(^)(CGPathDrawingMode mode))DLMode;

-(DLCoreGrapView *(^)(NSArray *pointArray))DLLine;

-(DLCoreGrapView *(^)(CGFloat x, CGFloat y, CGFloat radius, CGFloat startAngle, CGFloat endAngle, int clockwise))DLCircleView;

-(DLCoreGrapView *(^)(CGRect rect))DLEllipseView;

-(DLCoreGrapView *(^)(CGRect rect, NSString *imageString))DLPictView;

-(DLCoreGrapView *(^)(CGRect rect, NSString *titleString, NSDictionary *dic))DLTextView;

-(DLCoreGrapView *(^)(CGPoint point, NSArray *array))DLCurveView;

@end
