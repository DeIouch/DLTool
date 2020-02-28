#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLColor : NSObject

+(UIColor *)DLColorWithRed:(CGFloat)red Green:(CGFloat)green Blue:(CGFloat)blue Alpha:(CGFloat)alpha;

+(UIColor *)DLColorWithAHEXColor:(NSString *)apexColor;

@end
