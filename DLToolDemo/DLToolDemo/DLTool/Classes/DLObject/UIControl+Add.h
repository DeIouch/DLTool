#import <UIKit/UIKit.h>

@interface UIControl (Add)

-(void)dl_removeAllTargets;

-(void)dl_addBlockForControlEvents:(UIControlEvents)controlEvents block:(void (^)(id sender))block;

-(void)dl_removeAllBlocksForControlEvents:(UIControlEvents)controlEvents;

@end
