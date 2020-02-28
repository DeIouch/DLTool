#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface DLNoti : NSObject

+(DLNoti *)shareInstance;

-(void)showNotiTitle:(NSString *)titleString backView:(UIView *)backView;

-(void)viewHidden;

@end
