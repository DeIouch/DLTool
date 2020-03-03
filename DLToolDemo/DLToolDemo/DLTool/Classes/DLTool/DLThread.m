#import "DLThread.h"
#import "DLSafeProtector.h"
@class DLThreadModel;

static NSMutableDictionary *threadDic;
static dispatch_semaphore_t semaphore;
static NSMutableArray *taskArray;

@interface DLThread()

@property (nonatomic, strong) NSString *threadIdent;

@property (nonatomic, strong) NSMutableArray *threadArray;

@property (nonatomic, strong) NSOperationQueue *queue;

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
        semaphore = dispatch_semaphore_create(1);
        taskArray = [[NSMutableArray alloc]init];
    });
}

+(NSString *)getQueue:(void(^)(void))task{
    NSString *queueKey;
    NSMutableDictionary *tempDic = threadDic.mutableCopy;
    for (NSString *key in tempDic) {
        DLThreadModel *tempModel = tempDic[key];
        if (tempModel.isFree) {
            tempModel.isFree = NO;
            queueKey = key;
            [threadDic addEntriesFromDictionary:@{key : tempModel}];
            return queueKey;
        }
    }
    if (tempDic.allKeys.count < 12) {
        DLThreadModel *model = [[DLThreadModel alloc]init];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        model.isFree = NO;
        model.queue = dispatch_get_global_queue(0, 0);
        queueKey = [NSString stringWithFormat:@"%zd", threadDic.count];
        [threadDic setObject:model forKey:queueKey];
        dispatch_semaphore_signal(semaphore);
        return queueKey;
    }else{
        [taskArray addObject:[task copy]];
    }
    return queueKey;
}

+(void)doTask:(void(^)(void))task async:(BOOL)async{
    if (!task)  return;
    dispatch_queue_t queue;
    if (async) {
        NSString *queueKey = [DLThread getQueue:[task copy]];
        if (queueKey.length) {
            DLThreadModel *model = [threadDic objectForKey:queueKey];
            queue = model.queue;
            dispatch_async(queue, ^{
                task();
                model.isFree = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [threadDic addEntriesFromDictionary:@{queueKey : model}];
                    if (taskArray.count > 0) {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW);
                        void (^block)(void);
                        block = [taskArray.firstObject copy];
                        [taskArray removeObject:taskArray.firstObject];
                        dispatch_semaphore_signal(semaphore);
                            [DLThread doTask:^{
                                block();
                            } async:YES];
                    }
                });
            });
        }
    }else{
        queue = dispatch_get_main_queue();
        dispatch_async(queue, ^{
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

+(DLThread *)doAsync:(BOOL)async{
    DLThread *thread = [[DLThread alloc]_init];
    NSOperationQueue *queue = async ? [[NSOperationQueue alloc]init] : [NSOperationQueue mainQueue];
//    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    NSString *threadIdentifier = [NSString stringWithFormat:@"%zd", threadDic.count];
//    thread.threadIdent = threadIdentifier;
//    [threadDic setObject:queue forKey:threadIdentifier];
    dispatch_semaphore_signal(semaphore);
    thread.queue = queue;
    thread.threadArray = [[NSMutableArray alloc]init];
    return thread;
}

-(DLThread *)addTask:(void (^)(void))block{
    if (!block)  return self;
    if (@available(iOS 13.0, *)) {
        [self.queue addBarrierBlock:^{
            block();
        }];
    } else {
        [self.threadArray addObject:block];
    }
    return self;
}

-(DLThread *)startTask{
    if (self.threadArray.count == 0) {
        return self;
    }
    NSMutableArray *operationArray = [[NSMutableArray alloc]init];
    void (^block)(void);
    for (int a = 0; a < self.threadArray.count; a++) {
        block = self.threadArray[a];
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            block();
        }];
        if (operationArray.count > 0) {
            [operation addDependency:operationArray.lastObject];
        }
        [operationArray addObject:operation];
    }
    [self.queue addOperations:operationArray waitUntilFinished:NO];
    return self;
}

-(void)cancelTask{
    [self.queue cancelAllOperations];
}

-(void)pauseTask{
    self.queue.suspended = YES;
}

-(void)resumeTask{
    self.queue.suspended = NO;
}

@end




