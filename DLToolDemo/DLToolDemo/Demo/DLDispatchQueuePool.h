#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DLDispatchQueuePool : NSObject

//  UNAVAILABLE_ATTRIBUTE，标记方法不可用
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 创建并返回调度队列池。
 @param name       队列标签
 @param queueCount 队列数，在 (1, 32)之间.
 @param qos        队列优先级
 @return 返回一个队列池子或者错误信息
 */
- (instancetype)initWithName:(nullable NSString *)name queueCount:(NSUInteger)queueCount qos:(NSQualityOfService)qos;

/// 队列标签
@property (nullable, nonatomic, readonly) NSString *name;

/// 获取队列
- (dispatch_queue_t)queue;

+ (instancetype)defaultPoolForQOS:(NSQualityOfService)qos;

@end

/// 根据优先级获取队列池(name,queueCount默认配置)
extern dispatch_queue_t DLDispatchQueueGetForQOS(NSQualityOfService qos);

NS_ASSUME_NONNULL_END
