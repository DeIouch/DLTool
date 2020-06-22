#import "DLDownloderOperationManager.h"
#import "DLDownloadOperation.h"
#import "DLCache.h"
#import "UIImageView+DLWeb.h"
#import <CommonCrypto/CommonCrypto.h>
#import "DLThread.h"
#import "DLToolMacro.h"

@interface DLDownloadOperationModel : NSObject

@property (nonatomic, strong) DLDownloadOperation *opera;

@property (nonatomic, assign) BOOL isFree;

@end

static NSOperationQueue *_queue;

static NSMutableDictionary *_operationCache;

static DLCache *_cache;

static NSMutableDictionary *_taskDic;

@interface DLDownloderOperationManager()

@end

@implementation DLDownloderOperationManager

static DLDownloderOperationManager *manager = nil;

+(void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _cache = [[DLCache alloc]initWithFileName:@"dl_image_cache"];
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 4;
        _operationCache = [[NSMutableDictionary alloc]init];
        _taskDic = [[NSMutableDictionary alloc]init];
    });
}

+ (instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DLDownloderOperationManager alloc]init];
    });
    return manager;
}

static NSString *DLNSStringMD5(NSString *string) {
    if (!string) return nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
                @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                result[0],  result[1],  result[2],  result[3],
                result[4],  result[5],  result[6],  result[7],
                result[8],  result[9],  result[10], result[11],
                result[12], result[13], result[14], result[15]
            ];
}

//下载图片
+(void)downloadWithURLString:(NSString *)urlString withImageView:(UIImageView *)imageView{
    if (!urlString || urlString.length == 0 || !imageView) {
        return;
    }
    @autoreleasepool {
        NSString *key = DLNSStringMD5(urlString);
            if (_operationCache[key]) {
                if (_taskDic[key]) {
                    NSMutableArray *array = (NSMutableArray *)_taskDic[key];
                    [array addObject:imageView];
                    [_taskDic setObject:array forKey:key];
                }
                return;
            }
            UIImage *cacheImage = (UIImage *)[_cache objectForKey:key];
            if (cacheImage) {
                imageView.image = cacheImage;
                return;
            }
            [_taskDic setObject:[[NSMutableArray alloc]init] forKey:key];
            DLDownloadOperation *op = [[DLDownloadOperation alloc]downloaderOperationWithURLString:urlString withOperationQueue:nil finishedBlock:^(UIImage *image) {
                if (!image) {
                    return;
                }
                dl_dispatch_main_sync_safe(^{
                    imageView.image = image;
                    [_operationCache removeObjectForKey:key];
                    if (_taskDic[key]) {
                        NSMutableArray *array = (NSMutableArray *)_taskDic[key];
                        [_taskDic removeObjectForKey:key];
                        for (UIImageView *imageView in array) {
                            imageView.image = image;
                        }
                    }
                });
                
//            [_cache setObject:image forKey:key];
        }];
//        [_queue addOperation:op];
        [_operationCache setObject:op forKey:key];
    }
}

//取消操作
+(void)cancelOperation:(NSString *)urlString{
    if (!urlString || urlString.length == 0) {
        return;
    }
    [_operationCache[urlString] cancel];
    [_operationCache removeObjectForKey:urlString];
}

@end
