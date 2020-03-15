#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLDownloadOperationManager : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(DLDownloadOperationManager *)sharedManager;

-(void)downloadWithUrlString:(NSString *)urlString imageView:(UIImageView *)imageView finishedBlock:(void (^)(UIImage *image))finishedBlock;

-(void)cancelOperation:(NSString *)urlString;

@end
