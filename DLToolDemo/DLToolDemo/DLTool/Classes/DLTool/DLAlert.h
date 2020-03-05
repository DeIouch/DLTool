//  弹窗
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^DLAlertSureBlock)(void);

typedef void(^DLAlertCancelBlock)(void);

@interface DLAlert : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(DLAlert *)shareInstance;

-(void)alertAttMessage:(NSAttributedString *)message
           cancelTitle:(NSString *)cancelTitle
             sureTitle:(NSString *)sureTitle
             sureBlock:(DLAlertSureBlock)sureBlock;

-(void)alertMessage:(NSString *)message
        cancelTitle:(NSString *)cancelTitle
          sureTitle:(NSString *)sureTitle
          sureBlock:(DLAlertSureBlock)sureBlock;

@end
