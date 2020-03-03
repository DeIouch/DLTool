#import <UIKit/UIKit.h>

@interface UIGestureRecognizer (Add)

-(instancetype)initWithActionBlock:(void (^)(id sender))block;

-(void)dl_addActionBlock:(void (^)(id sender))block;

-(void)dl_removeAllActionBlocks;

@end
