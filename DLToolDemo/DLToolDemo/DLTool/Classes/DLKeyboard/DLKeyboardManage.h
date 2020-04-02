//  键盘移动管理器


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLKeyboardManage : NSObject

@end

@interface UIView (KeyBoardManage)

/// 响应键盘移动的控件（默认移动当前vc的self.view，如果只想移动某个特定的view，设置这个即可）
@property (nonatomic, weak) UIView *singleMeView;

@end
