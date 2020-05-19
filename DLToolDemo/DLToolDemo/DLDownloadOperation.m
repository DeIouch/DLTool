#import "DLDownloadOperation.h"
#import <ImageIO/ImageIO.h>
#import <CoreFoundation/CoreFoundation.h>

@interface DLDownloadOperation ()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>{
    BOOL _isFinished;
    BOOL _isExecuting;
}

@end

@implementation DLDownloadOperation

-(instancetype)downloaderOperationWithURLString:(NSString *)urlString withOperationQueue:(NSOperationQueue *)queue finishedBlock:(void (^)(UIImage *image))finishedBlock{
    if ([super init]) {
//        self = [self all];
        self.urlString = urlString;
        self.finishedBlock = finishedBlock;
        self.queue = queue;
        self.data = [NSMutableData data];
        [self start];
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.queue];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
        [task resume];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response
    completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    self.datalength = response.expectedContentLength;
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.data appendData:data];
//    int64_t totalSize = dataTask.countOfBytesExpectedToReceive;
//    CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
//    CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)self.data, totalSize == self.data.length);
//
//    //通过关联到ImageSource上的Data来创建一个CGImage对象，第一个参数传入更新数据之后的imageSource；第二个参数是图片的索引，一般传0；第三个参数跟创建的时候一样，传NULL就行。
//    __block CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
//
//    //释放创建的CGImageSourceRef对象
////    CFRelease(imageSource);
////
////    //在主线程中更新UI
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //其实可以直接把CGImageRef对象赋值给layer的contents属性，翻开苹果的头文件看就知道，
//        //一个UIView之所以能显示内容，就是因为CALayer的原因，而CALayer显示内容的属性就是contents，而contents通常就是CGImageRef。
//        //self.imageView.layer.contents = (__bridge id _Nullable)(image);
////        self.imageView.image = [UIImage imageWithCGImage:image];
//
//        //释放创建的CGImageRef对象
//
//
//        [self willChangeValueForKey:@"isFinished"];
//        [self willChangeValueForKey:@"isExecuting"];
//        self->_isFinished = YES;
//        self->_isExecuting = NO;
//        [self didChangeValueForKey:@"isFinished"];
//        [self didChangeValueForKey:@"isExecuting"];
//        if (self.finishedBlock) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.finishedBlock([UIImage imageWithCGImage:image]);
//                NSLog(@"当前线程为： %@",[NSThread currentThread]);
//            });
//        }
//        CFRelease(imageSource);
//        CGImageRelease(image);
//    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _isFinished = YES;
    _isExecuting = NO;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
//    if (self.finishedBlock) {
        
//        [NSThread performSelectorOnMainThread:@selector(blockImage:) withObject:[UIImage imageWithData:self.data] waitUntilDone:YES modes:[NSArray arrayWithObject:(__bridge NSString*)kCFRunLoopCommonModes]];
        
        NSLog(@"当前线程为： %@",[NSThread currentThread]);
//        dispatch_async(dispatch_get_main_queue(), ^{
            self.finishedBlock([UIImage imageWithData:self.data]);
            NSLog(@"当前线程为： %@",[NSThread currentThread]);
//        });
//    }
}

-(void)blockImage:(UIImage *)image{
    if (self.finishedBlock) {
        self.finishedBlock(image);
    }
}

- (void)start {
    if ([self isCancelled]){
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = NO;
        [self didChangeValueForKey:@"isFinished"];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
        _isExecuting = YES;
        [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}

@end
