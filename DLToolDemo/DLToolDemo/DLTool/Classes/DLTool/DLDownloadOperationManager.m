#import "DLDownloadOperationManager.h"
#import "DLCache.h"
#import "DLDownloadOperation.h"
#import "DLThread.h"

@interface DLDownloadOperationManager ()

//全局队列
@property(nonatomic,strong)NSOperationQueue *queue;

//下载操作缓存池   这里不能改为NSCache，因为收到内存警告后NSCache移除所有对象，之后NSCache中就无法继续添加数据了
@property(nonatomic,strong)NSMutableDictionary *operationCache;

@property (nonatomic, strong) DLCache *cache;

/// 相同请求的字典
@property (nonatomic, strong) NSMutableDictionary *unenforcedDic;

@end

@implementation DLDownloadOperationManager

static DLDownloadOperationManager *manager = nil;
+(DLDownloadOperationManager *)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DLDownloadOperationManager alloc]_init];
    });
    return manager;
}

-(instancetype)_init{
    self = [super init];
    return self;
}

-(void)downloadWithUrlString:(NSString *)urlString imageView:(UIImageView *)imageview finishedBlock:(void (^)(UIImage *image))finishedBlock{
    @autoreleasepool {
        if (self.operationCache[urlString]) {
            NSMutableArray *array = [[NSMutableArray alloc]initWithArray:self.unenforcedDic[urlString]];
            [array addObject:[finishedBlock copy]];
            [self.unenforcedDic setObject:array forKey:urlString];
            return;
        }
        NSString *key = urlString;
        if (imageview) {
            key = [NSString stringWithFormat:@"reduce%@", urlString];
        }
        if ([self.cache containsObjectForKey:key]) {
            finishedBlock((UIImage *)[self.cache objectForKey:key]);
            return;
        }
        DLDownloadOperation *op = [DLDownloadOperation downloadOperationWithURLString:urlString finishedBlock:^(NSData *data) {
            [self.operationCache removeObjectForKey:urlString];
            if (imageview) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [imageview layoutIfNeeded];
                    __block UIImage *image = [UIImage imageWithData:data];
                    CGFloat multiple;
                    if (image.size.width * 3 <= imageview.frame.size.width && image.size.height * 3 <= imageview.frame.size.height) {
                        multiple = 1;
                    }else {
                        multiple = image.size.height / imageview.frame.size.height > image.size.width / imageview.frame.size.width ? image.size.height / imageview.frame.size.height : image.size.width / imageview.frame.size.width;
                    }
                    [DLThread doTask:^{
                        image = [self compressOriginalImage:[UIImage imageWithData:data] toSize:CGSizeMake(image.size.width * 3 / multiple, image.size.height * 3 / multiple)];
                        image = [self decodedImageWithImage:image];
                        finishedBlock(image);
                        NSMutableArray *tempArray = self.unenforcedDic[urlString];
                        if (tempArray.count > 0) {
                            void (^block)(UIImage *image);
                            for (int a = 0; a < tempArray.count; a++) {
                                block = tempArray[a];
                                image = [self decodedImageWithImage:image];
                                block(image);
                            }
                        }
                        [self.unenforcedDic removeObjectForKey:urlString];
                        [self.cache setObject:image forKey:key withBlock:nil];
                    } async:YES];
                });
            }else{
                [DLThread doTask:^{
                    UIImage *image = [UIImage imageWithData:data];
                    image = [self decodedImageWithImage:image];
                    finishedBlock(image);
                    NSMutableArray *tempArray = self.unenforcedDic[urlString];
                    if (tempArray.count > 0) {
                        void (^block)(UIImage *image);
                        for (int a = 0; a < tempArray.count; a++) {
                            block = tempArray[a];
                            image = [self decodedImageWithImage:image];
                            block(image);
                        }
                    }
                    [self.unenforcedDic removeObjectForKey:urlString];
                    [self.cache setObject:image forKey:key withBlock:nil];
                } async:YES];
            }
        }];
        [self.queue addOperation:op];
        self.operationCache[urlString] = op;
    }
}

-(UIImage *)decodedImageWithImage:(UIImage *)image {
    if (image == nil) {
        return nil;
    }
    @autoreleasepool{
        if (image.images != nil) {
            return image;
        }
        CGImageRef imageRef = image.CGImage;
        //如果有alpha信息，则不转化，直接返回image
        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                         alpha == kCGImageAlphaLast ||
                         alpha == kCGImageAlphaPremultipliedFirst ||
                         alpha == kCGImageAlphaPremultipliedLast);
        if (anyAlpha) {
            return image;
        }
        //获取图像的相关参数
        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
        
        BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                      imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                      imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                      imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace) {
            colorspaceRef = CGColorSpaceCreateDeviceRGB();
        }
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        //创建context
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                      kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        
        // 画图像
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        //获取位图图像
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
         //创建UIImage对象
        UIImage *imageWithoutAlpha = [UIImage imageWithCGImage:imageRefWithoutAlpha scale:image.scale                                            orientation:image.imageOrientation];
        
        if (unsupportedColorSpace) {
            CGColorSpaceRelease(colorspaceRef);
        }
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        return imageWithoutAlpha;
    }
}

-(UIImage *)compressOriginalImage:(UIImage *)image toSize:(CGSize)size{
    UIImage *resultImage;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

-(void)cancelOperation:(NSString *)urlString{
    if (urlString == nil) {
        return;
    }
    [self.operationCache[urlString] cancel];
    [self.operationCache removeObjectForKey:urlString];
}

-(DLCache *)cache{
    if (!_cache) {
        _cache = [[DLCache alloc]initWithPath:[NSString stringWithFormat:@"%@/imageCache", [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) firstObject]]];
    }
    return _cache;
}

-(NSOperationQueue *)queue{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = (int)[NSProcessInfo processInfo].processorCount * 2;
    }
    return _queue;
}

-(NSMutableDictionary *)operationCache{
    if (!_operationCache) {
        _operationCache = [[NSMutableDictionary alloc]init];
    }
    return _operationCache;
}

-(NSMutableDictionary *)unenforcedDic{
    if (!_unenforcedDic) {
        _unenforcedDic = [[NSMutableDictionary alloc]init];
    }
    return _unenforcedDic;
}

@end
