//  下载类


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLDownloadOperation : NSOperation

+(instancetype)downloadOperationWithURLString:(NSString *)urlString imageView:(UIImageView *)imageView finishedBlock:(void (^)(BOOL isFinish, UIImage *image))finishedBlock;

@end
