//  键盘遮挡管理器（父视图为windows的view暂时无效）


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLKeyboardManage : NSObject

@end

@interface UIView (KeyBoardManage)

/// 响应键盘移动的控件（默认移动当前vc的self.view，如果是加在window上面的，就移动window的上一层view，如果只想移动某个特定的view，设置这个即可）
@property (nonatomic, weak) UIView *singleMeView;

///// 是否响应管理器（默认为NO，如果要自定义该控件的操作，设置为YES）
//@property (nonatomic, assign) BOOL notManageBOOL;

@end
