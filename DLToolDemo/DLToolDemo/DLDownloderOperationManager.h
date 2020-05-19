#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLDownloderOperationManager : NSObject

+ (instancetype)sharedManager;

//下载图片
+(void)downloadWithURLString:(NSString *)urlString withImageView:(UIImageView *)imageView;

//取消操作
+(void)cancelOperation:(NSString *)urlString;

@end
