#import <Foundation/Foundation.h>

@interface DLDownloadModel : NSObject

@property (nonatomic, strong) NSString *downloadUrl;

@property (nonatomic, strong) NSString *fileName;

@property (nonatomic, strong) NSString *filePath;

@property (nonatomic, assign) NSInteger fileLength;

@property (nonatomic, assign) NSInteger currentLength;

@property (nonatomic, strong) NSFileHandle *fileHandle;

@property (nonatomic, strong) NSURLSessionDataTask *downloadTask;

@property (nonatomic, copy) id progress;

@end
