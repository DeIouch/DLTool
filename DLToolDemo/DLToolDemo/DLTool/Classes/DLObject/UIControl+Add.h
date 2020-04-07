#import <UIKit/UIKit.h>

@interface UIControl (Add)

-(void)addClick:(UIControlEvents)controlEvents block:(void (^)(id vc))action;

@end
