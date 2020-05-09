#import "DLDownloadOperationManager.h"
#import "DLCache.h"
#import "DLDownloadOperation.h"
#import "DLThread.h"
#import "DLPromise.h"
#import <GLKit/GLKit.h>
#import <pthread.h>
#import "NSString+Add.h"

//全局队列
static NSOperationQueue *queue;

//下载操作缓存池   这里不能改为NSCache，因为收到内存警告后NSCache移除所有对象，之后NSCache中就无法继续添加数据了
static NSMutableDictionary *operationCache;

static DLCache *cache;

// 相同请求的字典
static NSMutableDictionary *unenforcedDic;

@interface DLDownloadOperationManager ()

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

+(void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc]init];
        queue.maxConcurrentOperationCount = (int)[NSProcessInfo processInfo].processorCount * 2;
        cache = [[DLCache alloc]initWithFileName:@"imageCache"];
        operationCache = [[NSMutableDictionary alloc]init];
        unenforcedDic = [[NSMutableDictionary alloc]init];
    });
}

-(instancetype)_init{
    self = [super init];
    return self;
}

-(void)downloadWithUrlString:(NSString *)urlString imageView:(UIImageView *)imageview finishedBlock:(void (^)(UIImage *image))finishedBlock{
    @autoreleasepool {
//    pthread_mutex_lock(&_lock);
    NSString *key = [urlString md5];
        if (operationCache[key]) {
            NSMutableArray *array = [[NSMutableArray alloc]initWithArray:unenforcedDic[key]];
            [array addObject:imageview];
            [unenforcedDic setObject:array forKey:key];
            return;
        }
//        if (imageview) {
//            key = [NSString stringWithFormat:@"reduce%@", urlString];
//        }
//        if ([cache containsObjectForKey:key]) {
//            finishedBlock((UIImage *)[cache objectForKey:key]);
//            return;
//        }
        
        DLDownloadOperation *op = [DLDownloadOperation downloadOperationWithURLString:urlString imageView:imageview finishedBlock:^(BOOL isFinish, UIImage *image) {
            operationCache[key] = nil;
            [operationCache removeObjectForKey:key];
//            if (imageview) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [imageview layoutIfNeeded];
//                    __block UIImage *image = [UIImage imageWithData:data];
//                    CGFloat multiple;
//                    if (image.size.width * 3 <= imageview.frame.size.width && image.size.height * 3 <= imageview.frame.size.height) {
//                        multiple = 1;
//                    }else {
//                        multiple = image.size.height / imageview.frame.size.height > image.size.width / imageview.frame.size.width ? image.size.height / imageview.frame.size.height : image.size.width / imageview.frame.size.width;
//                    }
//                    [DLThread doTask:^{
//                        image = [self compressOriginalImage:[UIImage imageWithData:data] toSize:CGSizeMake(image.size.width * 3 / multiple, image.size.height * 3 / multiple)];
//                        image = [self decodedImageWithImage:image];
//                        finishedBlock(image);
//                        NSMutableArray *tempArray = self.unenforcedDic[urlString];
//                        if (tempArray.count > 0) {
//                            void (^block)(UIImage *image);
//                            for (int a = 0; a < tempArray.count; a++) {
//                                block = tempArray[a];
//                                image = [self decodedImageWithImage:image];
//                                block(image);
//                            }
//                        }
//                        [self.unenforcedDic removeObjectForKey:urlString];
//                        [self.cache setObject:image forKey:key withBlock:nil];
//                    } async:YES];
//                });
//            }else{
                [DLThread doTask:^{
                    UIImage *tempImage = [self decodedImageWithImage:image];
                    imageview.image = tempImage;
                    NSMutableArray *tempArray = unenforcedDic[key];
                    [unenforcedDic removeObjectForKey:key];
//                    [cache setObject:image forKey:key withBlock:nil];
                    if (tempArray.count > 0) {
                        for (int a = 0; a < tempArray.count; a++) {
                            imageview.image = tempImage;
                        }
                    }
                } async:NO];
//            }
        }];
    [queue addOperation:op];
    [operationCache setObject:op forKey:key];
    
//    pthread_mutex_unlock(&_lock);
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
    [operationCache[urlString] cancel];
    [operationCache removeObjectForKey:[urlString md5]];
}

@end
