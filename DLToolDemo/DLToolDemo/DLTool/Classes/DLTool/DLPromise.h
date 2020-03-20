//  异步队列顺序执行


#import <Foundation/Foundation.h>

@interface DLPromise : NSObject

-(DLPromise *)then:(id(^)(id obj))thenBlock;

+(DLPromise *)sync:(id(^)(void))doBlock;

+(DLPromise *)async:(id(^)(void))doBlock;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
