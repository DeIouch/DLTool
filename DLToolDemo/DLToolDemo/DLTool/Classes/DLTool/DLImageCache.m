#import "DLImageCache.h"
#import "DLThread.h"
#import "DLCache.h"

@interface DLImageCache()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation DLImageCache

+(void)loadImage:(UIImageView *)imageview imageUrl:(NSString *)imageUrl{
    [imageview layoutIfNeeded];
    __block UIImage *image;
//    = [DLCache getImageCache:imageUrl];
//    = (UIImage *)[[DLCache shareInstance]objectForKey:imageUrl];
    if (image) {
        imageview.image = image;
        image = nil;
        return;
    }
    [DLThread doTask:^{
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        image = [UIImage imageWithData:imgData];
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat multiple;
            if (image.size.width <= imageview.frame.size.width && image.size.height <= imageview.frame.size.height) {
                multiple = 1;
            }else {
                multiple = image.size.height / imageview.frame.size.height > image.size.width / imageview.frame.size.width ? image.size.height / imageview.frame.size.height : image.size.width / imageview.frame.size.width;
            }
            image = [DLImageCache compressOriginalImage:[UIImage imageWithData:imgData] toSize:CGSizeMake(image.size.width / multiple, image.size.height / multiple)];
            imageview.image = image;
            [DLCache saveImageCache:image imageUrl:imageUrl];
            image = nil;
        });
    } async:YES];
}

+(UIImage *)compressOriginalImage:(UIImage *)image toSize:(CGSize)size{
    UIImage *resultImage;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

@end
