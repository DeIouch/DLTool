#import <Foundation/Foundation.h>

@interface DLWeakProxy : NSProxy

@property (nonatomic, weak, readonly) id target;

-(instancetype)initWithTarget:(id)target;

+(instancetype)proxyWithTarget:(id)target;

@end
