#import "DLDownloadOperation.h"
#import "DLCache.h"

@interface DLDownloadOperation()

@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, copy) void (^finishedBlock)(NSData *data);

@end

@implementation DLDownloadOperation

-(void)main {
    @autoreleasepool {
        if (self.urlString.length == 0) {
            return;
        }
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];        
        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (self.isCancelled) {
                return;
            }
            if (data) {
                self.finishedBlock(data);
            }
        }];
        [task resume];
    }
}

+(instancetype)downloadOperationWithURLString:(NSString *)urlString finishedBlock:(void (^)(NSData *data))finishedBlock{
    DLDownloadOperation *op = [[DLDownloadOperation alloc]init];
    op.urlString = urlString;
    op.finishedBlock = [finishedBlock copy];
    return op;
}

@end
