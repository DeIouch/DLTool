#import "DLNetworkManager.h"
#import "AFNetworking.h"
#import "DLCache.h"
#import "YYCache.h"

@interface DLNetworkManager()<NSURLSessionDelegate>

@property (nonatomic, strong) NSMutableDictionary *taskDic;

@property (nonatomic, strong) AFHTTPSessionManager *afHTTPSessionManager;

@property (nonatomic, strong) NSMutableDictionary *headerDic;

@property (nonatomic, assign) NSInteger timeOut;

@property (nonatomic, strong) NSMutableDictionary *downloadTaskDic;

@end

@implementation DLNetworkManager

static DLNetworkManager *networkManager = NULL;

+(DLNetworkManager *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkManager = [[DLNetworkManager alloc]_init];
    });
    return networkManager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkManager = [super allocWithZone:zone];
    });
    return networkManager;
}

-(instancetype)_init{
    self = [super init];
    self.afHTTPSessionManager = [[AFHTTPSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.afHTTPSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    self.afHTTPSessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    self.headerDic = [[NSMutableDictionary alloc]init];
    self.taskDic = [[NSMutableDictionary alloc]init];
    self.downloadTaskDic = [[NSMutableDictionary alloc]init];
    self.timeOut = 10;
    return self;
}

+(void)setRequestHeader:(NSMutableDictionary *)headerDic{
    [DLNetworkManager shareInstance].headerDic = headerDic;
}

+(void)setRequestTimeOut:(NSInteger)requestTimeOut{
    [DLNetworkManager shareInstance].timeOut = requestTimeOut;
}

+(void)sendGetRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    [[DLNetworkManager shareInstance] _sendGetRequest:[NSString stringWithFormat:@"%@%@", DLBaseUrl, url] parameters:parameters success:successBlock defeat:defeatBlock failure:failureBlock];
}

+(void)sendPostRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    [[DLNetworkManager shareInstance] _sendGetRequest:[NSString stringWithFormat:@"%@%@", DLBaseUrl, url] parameters:parameters success:successBlock defeat:defeatBlock failure:failureBlock];
}

-(void)_sendGetRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    NSString *cacheIdentifies = [NSString stringWithFormat:@"%@%@", url,parameters ? [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:parameters  options:0 error:0] encoding:NSUTF8StringEncoding] : @""];
    NSString *identifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    NSURLSessionTask *task = [self.afHTTPSessionManager GET:url parameters:parameters headers:self.headerDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if ([[NSString stringWithFormat:@"%@", [dic objectForKey:DLHTTPServiceResponseStatusKey]] isEqualToString:DLHTTPServiceSuccessKey]) {
            [DLCache setObject:[dic objectForKey:DLHTTPServiceResponseDataKey] forKey:cacheIdentifies];
            successBlock(0 ,[dic objectForKey:DLHTTPServiceResponseDataKey]);
        }else{
            defeatBlock([dic objectForKey:DLHTTPServiceResponseMsgKey], [[dic objectForKey:DLHTTPServiceResponseStatusKey] intValue]);
            successBlock(1 ,[DLCache objectForKey:cacheIdentifies]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock(error);
        successBlock(1 ,[DLCache objectForKey:cacheIdentifies]);
    }];
    [self.taskDic setObject:task forKey:identifies];
    if (self.timeOut) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeOut * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.taskDic removeObjectForKey:identifies];
            [task cancel];
        });
    }
}

-(void)_sendPostRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    NSString *cacheIdentifies = [NSString stringWithFormat:@"%@%@", url,parameters ? [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:parameters  options:0 error:0] encoding:NSUTF8StringEncoding] : @""];
    NSString *identifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    NSURLSessionTask *task = [self.afHTTPSessionManager POST:url parameters:parameters headers:self.headerDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        if ([dic[@"code"] intValue] == 200) {
            successBlock(0 ,[dic objectForKey:DLHTTPServiceResponseDataKey]);
            [DLCache setObject:[dic objectForKey:DLHTTPServiceResponseDataKey] forKey:cacheIdentifies];
        }else{
            defeatBlock(dic[@"message"], [dic[@"code"] intValue]);
            successBlock(1 ,[DLCache objectForKey:cacheIdentifies]);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        failureBlock(error);
        successBlock(1 ,[DLCache objectForKey:cacheIdentifies]);
    }];
    [self.taskDic setObject:task forKey:identifies];
    if (self.timeOut) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeOut * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.taskDic removeObjectForKey:identifies];
            [task cancel];
        });
    }
}

+(void)cancelRequest:(NSString *)url{
    NSString *identifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    NSURLSessionTask *task = [[DLNetworkManager shareInstance].taskDic objectForKey:identifies];
    if (task) {
        [task cancel];
    }
}

+(void)downloadRequest:(NSString *)url downloadFilePath:(NSString *)downloadFilePath resumable:(BOOL)resumable backgroundSupport:(BOOL)backgroundSupport progress:(DLNetworkTaskProgress)progress success:(DLNetworkTaskSuccessBlock)successBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    [[DLNetworkManager shareInstance]_downloadRequest:url downloadFilePath:downloadFilePath resumable:resumable backgroundSupport:backgroundSupport progress:progress success:successBlock failure:failureBlock];
}

-(void)_downloadRequest:(NSString *)url downloadFilePath:(NSString *)downloadFilePath resumable:(BOOL)resumable backgroundSupport:(BOOL)backgroundSupport progress:(DLNetworkTaskProgress)progress success:(DLNetworkTaskSuccessBlock)successBlock failure:(DLNetworkTaskFailureBlock)failureBlock{
    NSString *downloadIdentifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    DLDownloadModel *downloadModel = [self.downloadTaskDic objectForKey:downloadIdentifies];
    if (!downloadModel) {
        downloadModel = [[DLDownloadModel alloc]init];
        downloadModel.downloadUrl = url;
        downloadModel.fileName = url.lastPathComponent;
        downloadModel.filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:url.lastPathComponent];
        downloadModel.currentLength = [self fileLengthForPath:downloadModel.filePath];
    }
    downloadModel.progress = progress;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", downloadModel.currentLength];
    [request setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
    downloadModel.downloadTask = task;
    [self.downloadTaskDic setObject:downloadModel forKey:downloadIdentifies];
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    NSString *url = [response.URL absoluteString];
    NSString *downloadIdentifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    DLDownloadModel *downloadModel = [self.downloadTaskDic objectForKey:downloadIdentifies];
    downloadModel.fileLength = response.expectedContentLength + downloadModel.currentLength;
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:downloadModel.filePath]) {
        [manager createFileAtPath:downloadModel.filePath contents:nil attributes:nil];
    }
    downloadModel.fileHandle = [NSFileHandle fileHandleForWritingAtPath:downloadModel.filePath];
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    NSString *url = [dataTask.response.URL absoluteString];
    NSString *downloadIdentifies = [NSString stringWithFormat:@"%lu", (unsigned long)url.hash];
    DLDownloadModel *downloadModel = [self.downloadTaskDic objectForKey:downloadIdentifies];
    [downloadModel.fileHandle seekToEndOfFile];
    [downloadModel.fileHandle writeData:data];
    downloadModel.currentLength += data.length;
    DLNetworkTaskProgress progress = downloadModel.progress;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        progress(downloadModel.fileLength / 1024.0, downloadModel.currentLength / 1024.0, 100.0 * downloadModel.currentLength / downloadModel.fileLength);
        if (downloadModel.currentLength == downloadModel.fileLength) {
            [downloadModel.fileHandle closeFile];
            downloadModel.fileHandle = nil;
            downloadModel.currentLength = 0;
            downloadModel.fileLength = 0;
        }
    }];
}

+(void)pauseDownloadRequest:(NSString *)url{
    DLDownloadModel *model = [[DLNetworkManager shareInstance].downloadTaskDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)url.hash]];
    if (model.downloadTask) {
        [model.downloadTask response];
    }
}

+(void)cancelDownloadRequest:(NSString *)url{
    DLDownloadModel *model = [[DLNetworkManager shareInstance].downloadTaskDic objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)url.hash]];
    if (model.downloadTask) {
        [model.downloadTask response];
        model.downloadTask = nil;
        [model.fileHandle closeFile];
        model.fileHandle = nil;
        model.currentLength = 0;
        model.fileLength = 0;
        [[NSFileManager defaultManager] removeItemAtPath:model.filePath error:nil];
    }
}

-(NSInteger)fileLengthForPath:(NSString *)path {
    NSInteger fileLength = 0;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileLength = [fileDict fileSize];
        }
    }
    return fileLength;
}

@end
