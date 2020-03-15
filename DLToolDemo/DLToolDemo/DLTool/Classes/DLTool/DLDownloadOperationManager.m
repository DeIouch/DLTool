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
    if (self.operationCache[urlString]) {
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
                if (image.size.width <= imageview.frame.size.width && image.size.height <= imageview.frame.size.height) {
                    multiple = 1;
                }else {
                    multiple = image.size.height / imageview.frame.size.height > image.size.width / imageview.frame.size.width ? image.size.height / imageview.frame.size.height : image.size.width / imageview.frame.size.width;
                }
                [DLThread doTask:^{
                    image = [self compressOriginalImage:[UIImage imageWithData:data] toSize:CGSizeMake(image.size.width / multiple, image.size.height / multiple)];
                    finishedBlock(image);
                    [self.cache setObject:image forKey:key withBlock:nil];
                } async:YES];
            });
        }else{
            [DLThread doTask:^{
                UIImage *image = [UIImage imageWithData:data];
                finishedBlock(image);
                [self.cache setObject:image forKey:key withBlock:nil];
            } async:YES];
        }
    }];
    [self.queue addOperation:op];
    self.operationCache[urlString] = op;
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

@end
