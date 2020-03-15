#import <UIKit/UIKit.h>

@interface DLScrollView : UIView

//初始化图片格式的HADirect
+(DLScrollView *)scrollWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ImageArr:(NSArray *)imageNameArray AndImageClickBlock:(void (^)(NSInteger index))clickBlock;

//初始化自定义样式的HADirect
+(DLScrollView *)scrollWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ViewArr:(NSArray *)customViewArr AndClickBlock:(void (^)(NSInteger index))clickBlock;

-(void)cancelLoop;

@end
