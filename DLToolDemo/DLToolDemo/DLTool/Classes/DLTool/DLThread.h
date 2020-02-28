#import <Foundation/Foundation.h>

@interface DLThread : NSObject

/// 创建延迟执行线程
/// @param task 执行的block
/// @param start 延迟时间
/// @param async 是否异步
+(void)doTask:(void(^)(void))task start:(NSTimeInterval)start async:(BOOL)async;

/// 创建队列
/// @param block 执行的block
-(DLThread *)addTask:(void (^)(void))block;

/// 开启线程
/// @param async 是否异步
+(DLThread *)doAsync:(BOOL)async;

/// 队列开始执行，iOS13之前需要加，iOS13之后不需要
-(DLThread *)startTask;

//  队列取消执行
-(void)cancelTask;

//  队列暂停执行
-(void)pauseTask;

//  队列恢复执行  
-(void)resumeTask;

@end
