#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DLDownloadModel.h"

#define DLBaseUrl @"https://test.api.tanqiu.com"

#define DLHTTPServiceResponseStatusKey @"status"

#define DLHTTPServiceResponseMsgKey    @"msg"

#define DLHTTPServiceResponseDataKey   @"data"

#define DLHTTPServiceSuccessKey   @"200"

typedef void(^DLNetworkTaskProgress)(CGFloat totalDataCount, CGFloat downloadDataCount, CGFloat progress);

//  objectType,等于0属于网络请求的数据，等于1属于缓存的数据
typedef void(^DLNetworkTaskSuccessBlock)(int objectType, id responseObject);
typedef void(^DLNetworkTaskDefeatBlock)(NSString *message, NSInteger statusCode);
typedef void(^DLNetworkTaskFailureBlock)(NSError *error);

@interface DLNetworkManager : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(DLNetworkManager *)shareInstance;

+(void)setRequestHeader:(NSMutableDictionary *)headDic;

+(void)setRequestTimeOut:(NSInteger)requestTimeOut;

+(void)sendGetRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock;

+(void)sendPostRequest:(NSString *)url parameters:(NSDictionary *)parameters success:(DLNetworkTaskSuccessBlock)successBlock defeat:(DLNetworkTaskDefeatBlock)defeatBlock failure:(DLNetworkTaskFailureBlock)failureBlock;

+(void)downloadRequest:(NSString *)url downloadFilePath:(NSString *)downloadFilePath resumable:(BOOL)resumable backgroundSupport:(BOOL)backgroundSupport progress:(DLNetworkTaskProgress)progress success:(DLNetworkTaskSuccessBlock)successBlock failure:(DLNetworkTaskFailureBlock)failureBlock;

+(void)cancelRequest:(NSString *)url;

+(void)pauseDownloadRequest:(NSString *)url;

+(void)cancelDownloadRequest:(NSString *)url;

@end
