#import "DLThread.h"
//#include <objc/runtime.h>

static NSMutableDictionary *threadDic;
static dispatch_semaphore_t semaphore;

@interface DLThread()

@property (nonatomic, strong) NSString *threadIdent;

@property (nonatomic, strong) NSMutableArray *threadArray;

@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation DLThread

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        threadDic = [NSMutableDictionary dictionary];
        semaphore = dispatch_semaphore_create(1);
    });
}

+(void)doTask:(void(^)(void))task start:(NSTimeInterval)start async:(BOOL)async{
    if (!task)  return;
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) : dispatch_get_main_queue();
    if (start > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(start * NSEC_PER_SEC)), queue, ^{
            task();
        });
    }else{
        dispatch_async(queue, ^{
            task();
        });
    }
}

+(dispatch_queue_t)getQueue:(NSString *)queueIdentifier{
    if (queueIdentifier.length == 0) {
        return nil;
    }
    dispatch_queue_t queue = [threadDic valueForKey:queueIdentifier];
    return queue;
}

+(DLThread *)doAsync:(BOOL)async{
    DLThread *thread = [[DLThread alloc]init];
    NSOperationQueue *queue = async ? [[NSOperationQueue alloc]init] : [NSOperationQueue mainQueue];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSString *threadIdentifier = [NSString stringWithFormat:@"%zd", threadDic.count];
    thread.threadIdent = threadIdentifier;
    [threadDic setObject:queue forKey:threadIdentifier];
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
            
            if (a == self.threadArray.count - 1) {
                NSLog(@"1111111");
            }
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
