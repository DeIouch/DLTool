#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLDownloadOperation : NSOperation

//下载图片的地址
@property(nonatomic,copy)NSString *urlString;

@property(nonatomic, strong) NSMutableData *data;

@property(nonatomic, assign) long long datalength;

@property (nonatomic, assign) BOOL taskIsFinished;

@property (nonatomic, strong) NSOperationQueue *queue;

//执行完成任务之后的回调block
@property(nonatomic,copy)void (^finishedBlock)(UIImage *img);

-(instancetype)downloaderOperationWithURLString:(NSString *)urlString withOperationQueue:(NSOperationQueue *)queue finishedBlock:(void (^)(UIImage *image))finishedBlock;

@end
