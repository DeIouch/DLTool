#import "DLThread.h"
#import "DLSafeProtector.h"
#import <CoreFoundation/CoreFoundation.h>
#import "DLToolMacro.h"
@class DLThreadModel;

static NSMutableDictionary *threadDic;

static NSMutableDictionary *tempDic;

static dispatch_semaphore_t semaphore;

static CFMutableArrayRef cacheArray;

static CFMutableArrayRef queueIsFreeArray;

@interface DLThread()

@property (nonatomic, strong) NSString *threadIdent;

@property (nonatomic, strong) NSMutableArray *threadArray;

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) id obj;

@property (nonatomic, copy) id (^taskBlock)(id obj);

@end

@interface DLThreadModel : NSObject

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign) BOOL isFree;

@end

@implementation DLThreadModel

@end

@implementation DLThread

+(void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        threadDic = [NSMutableDictionary dictionary];
        tempDic = [NSMutableDictionary dictionary];
        semaphore = dispatch_semaphore_create(1);
        cacheArray = CFArrayCreateMutable(kCFAllocatorDefault, 0,  NULL);
        queueIsFreeArray = CFArrayCreateMutable(kCFAllocatorDefault, 0,  NULL);
    });
}

+(NSString *)getQueue:(void(^)(void))task{
    @autoreleasepool {
        NSString *queueKey;
        for (NSString *key in tempDic) {
            DLThreadModel *tempModel = tempDic[key];
            if (tempModel.isFree) {
                tempModel.isFree = NO;
                queueKey = key;
                [threadDic addEntriesFromDictionary:@{key : tempModel}];
                return queueKey;
            }
        }
        if (tempDic.allKeys.count < (int)[NSProcessInfo processInfo].activeProcessorCount * 2) {
            DLThreadModel *model = [[DLThreadModel alloc]init];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            model.isFree = NO;
            model.queue = dispatch_get_global_queue(0, 0);
            queueKey = [NSString stringWithFormat:@"%zd", threadDic.count];
            [threadDic setObject:model forKey:queueKey];
            [tempDic setObject:model forKey:queueKey];
            dispatch_semaphore_signal(semaphore);
            return queueKey;
        }else{
            if (CFArrayGetCount(cacheArray) >= 10000) {
                [NSThread sleepForTimeInterval:0.001];
            }else if (CFArrayGetCount(cacheArray) >= 20000) {
                [NSThread sleepForTimeInterval:0.005];
            }else if (CFArrayGetCount(cacheArray) >= 30000) {
                [NSThread sleepForTimeInterval:0.01];
            }
            CFArrayAppendValue(cacheArray, CFBridgingRetain(task));
        }
    }
    return nil;
}

+(void)doTask:(void(^)(void))task async:(BOOL)async{
    if (!task)  return;
    if (async) {
        @autoreleasepool {
            NSString *queueKey = [DLThread getQueue:[task copy]];
            if (queueKey.length) {
                DLThreadModel *model = [threadDic objectForKey:queueKey];
                dispatch_async(model.queue, ^{
                    task();
                    model.isFree = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CFArrayAppendValue(queueIsFreeArray, (__bridge const void *)(model));
                        [threadDic addEntriesFromDictionary:@{queueKey : model}];
                        if (CFArrayGetCount(cacheArray) > 0) {
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW);
                            void (^block)(void);
                            block = CFArrayGetValueAtIndex(cacheArray, 0);
                            CFArrayRemoveValueAtIndex(cacheArray, 0);
                            dispatch_semaphore_signal(semaphore);
                                [DLThread doTask:^{
                                    block();
                                } async:YES];
                        }
                    });
                });
            }
        }
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            task();
        });
    }
}

-(instancetype)init{
    DLSafeProtectionCrashLog([NSException exceptionWithName:@"DLThread初始化失败" reason:@"使用'shareInstance'初始化" userInfo:nil],DLSafeProtectorCrashTypeInitError);
    return [super init];
    return self;
}

-(instancetype)_init{
    self = [super init];
    return self;
}

@end
