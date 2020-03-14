//  提示toast


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface DLNoti : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+(DLNoti *)shareInstance;

-(void)showNotiTitle:(NSString *)titleString backView:(UIView *)backView;

-(void)viewHidden;

@end
