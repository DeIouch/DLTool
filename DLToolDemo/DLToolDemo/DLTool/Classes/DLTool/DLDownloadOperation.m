#import "DLDownloadOperation.h"
#import "DLCache.h"

@interface DLDownloadOperation()
//<NSURLSessionDataDelegate>

@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, copy) void (^finishedBlock)(BOOL isFinish, UIImage *image);

@property (nonatomic, strong) NSMutableData *haveReceivedData;

@property (nonatomic, strong) UIImageView *imageView;

//@property (nonatomic, strong) NSURLSessionTask *task;
//
//@property (nonatomic, strong) NSURLSession *session;

@end

@implementation DLDownloadOperation

-(void)main {
    @autoreleasepool {
        if (self.urlString.length == 0) {
            return;
        }
//        self.haveReceivedData = [NSMutableData data];
//        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
//        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:nil delegateQueue:nil];
////        self.task = [self.session dataTaskWithURL:[NSURL URLWithString:self.urlString]];
//        self.task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            if (self.isCancelled) {
//                return;
//            }
//            if (data) {
//                UIImage *image = [UIImage imageWithData:data];
//                self.finishedBlock(YES, image);
//                [self cancel];
//            }
//        }];
//        [self.task resume];
        
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlString]];
        [[[NSURLSession sharedSession] dataTaskWithRequest:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlString]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (self.isCancelled) {
                return;
            }
            if (data) {
                UIImage *image = [UIImage imageWithData:data];
                self.finishedBlock(YES, image);
                [self cancel];
            }
        }] resume];
        
    }
}

-(void)dealloc{
//    [self cancel];
    NSLog(@"dealloc");
}

//- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
//    //存储已经下载的图片二进制数据。
//
//    [self.haveReceivedData appendData:data];
//
//    //总共需要下载的图片数据的大小。
//    __block int64_t totalSize = dataTask.countOfBytesExpectedToReceive;
//
//    //创建一个递增的ImageSource，一般传NULL。
//    CGImageSourceRef imageSource = CGImageSourceCreateIncremental(NULL);
//
//    //使用最新的数据更新递增的ImageSource，第二个参数是已经接收到的Data，第三个参数表示是否已经是最后一个Data了。
//    CGImageSourceUpdateData(imageSource, (__bridge CFDataRef)self.haveReceivedData, totalSize == self.haveReceivedData.length);
//
//
//    //通过关联到ImageSource上的Data来创建一个CGImage对象，第一个参数传入更新数据之后的imageSource；第二个参数是图片的索引，一般传0；第三个参数跟创建的时候一样，传NULL就行。
//    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
//
//    //释放创建的CGImageSourceRef对象
//    CFRelease(imageSource);
//
//    //在主线程中更新UI
//    dispatch_async(dispatch_get_main_queue(), ^{
//        //其实可以直接把CGImageRef对象赋值给layer的contents属性，翻开苹果的头文件看就知道，一个UIView之所以能显示内容，就是因为CALayer的原因，而CALayer显示内容的属性就是contents，而contents通常就是CGImageRef。
//
//        NSLog(@"%lu", (unsigned long)self.haveReceivedData.length);
//
//        self.imageView.layer.contents = (__bridge id _Nullable)(image);
//
//        if (totalSize == self.haveReceivedData.length) {
//            self.finishedBlock(YES, [UIImage imageWithData:self.haveReceivedData]);
////            self.imageView.image = [UIImage imageWithData:self.haveReceivedData];
//            [self cancel];
//        }
//        //释放创建的CGImageRef对象
//        CGImageRelease(image);
//    });
//}

+(instancetype)downloadOperationWithURLString:(NSString *)urlString imageView:(UIImageView *)imageView finishedBlock:(void (^)(BOOL isFinish, UIImage *image))finishedBlock{
    DLDownloadOperation *op = [[DLDownloadOperation alloc]init];
    op.urlString = urlString;
    [imageView layoutIfNeeded];
    op.imageView = imageView;
    op.finishedBlock = [finishedBlock copy];
//    [op start];
    return op;
}

@end
