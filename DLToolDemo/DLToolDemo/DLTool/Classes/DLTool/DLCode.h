//  二维码扫描

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLCode : NSObject

-(instancetype)init NS_UNAVAILABLE;

-(instancetype)new NS_UNAVAILABLE;

/// 添加二维码扫描界面
/// @param backView 父视图
/// @param success 扫描成功的block
/// @param failure 扫描失败的block
+(void)codeScanBackView:(UIView *)backView SuccessBlock:(void(^)(NSString *codeString))success failureBlock:(void(^)(void))failure;

/// 移除二维码扫描界面
+(void)removeCodeView;

//  是否添加返回按钮和返回按钮的点击事件
+(void)addBackButton:(BOOL)addBOOL buttonBlock:(void(^)(void))block;

@end
