//  线程池管理

#import <Foundation/Foundation.h>

@interface DLThread : NSObject

/// 创建执行线程
/// @param task 执行的block
/// @param async 是否异步
+(void)doTask:(void(^)(void))task async:(BOOL)async;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
