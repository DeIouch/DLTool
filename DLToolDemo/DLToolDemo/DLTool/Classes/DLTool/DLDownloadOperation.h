//  下载类


#import <Foundation/Foundation.h>

@interface DLDownloadOperation : NSOperation

+(instancetype)downloadOperationWithURLString:(NSString *)urlString finishedBlock:(void (^)(NSData *data))finishedBlock;

@end
