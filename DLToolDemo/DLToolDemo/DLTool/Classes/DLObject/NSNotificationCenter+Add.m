#import "NSNotificationCenter+Add.h"
#import "DLSafeProtector.h"
#import <objc/message.h>
#include <pthread.h>
#import "DLToolMacro.h"

@interface NSNotificationCenter (DLNotificationCenterSafe)

@property (nonatomic,assign) BOOL isNotification;

@end

@implementation NSObject(DLNotificationCenterSafe)

static NSMutableSet *NSNotificationCenterSafeSwizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    return swizzledClasses;
}

-(void)safe_changeDidDeallocSignal{
    //此处交换dealloc方法是借鉴RAC源码
    Class classToSwizzle=[self class];
    @synchronized (NSNotificationCenterSafeSwizzledClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([NSNotificationCenterSafeSwizzledClasses() containsObject:className]) return;
        SEL deallocSelector = sel_registerName("dealloc");
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        id newDealloc = ^(__unsafe_unretained id self) {
            [self safe_NotificationDealloc];
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };
                
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
        };
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        [NSNotificationCenterSafeSwizzledClasses() addObject:className];
    }
}

-(void)safe_NotificationDealloc{
    if ([self isNotification]) {
//        NSException *exception=[NSException exceptionWithName:@"dealloc时通知中心未移除本对象" reason:[NSString stringWithFormat:@"dealloc时通知中心未移除本对象  Class:%@",[self class]] userInfo:nil]; LSSafeProtectionCrashLog(exception,LSSafeProtectorCrashTypeNSNotificationCenter);
        [[NSNotificationCenter defaultCenter]removeObserver:self];
    }
}

-(void)setIsNotification:(BOOL)isNotification{
    objc_setAssociatedObject(self, @selector(isNotification), @(isNotification), OBJC_ASSOCIATION_RETAIN);
}

-(BOOL)isNotification{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

@implementation NSNotificationCenter (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([NSNotificationCenter class], @selector(addObserver:selector:name:object:), @selector(safe_addObserver:selector:name:object:));
    });
}

-(void)safe_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject{
    [observer setIsNotification:YES];
    [observer safe_changeDidDeallocSignal];
    [self safe_addObserver:observer selector:aSelector name:aName object:anObject];
}

-(void)dl_postNotificationOnMainThread:(NSNotification *)notification {
    if (pthread_main_np()) return [self postNotification:notification];
    [self dl_postNotificationOnMainThread:notification waitUntilDone:NO];
}

-(void)dl_postNotificationOnMainThread:(NSNotification *)notification waitUntilDone:(BOOL)wait {
    if (pthread_main_np()) return [self postNotification:notification];
    [[self class] performSelectorOnMainThread:@selector(_dl_postNotification:) withObject:notification waitUntilDone:wait];
}

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(id)object {
    if (pthread_main_np()) return [self postNotificationName:name object:object userInfo:nil];
    [self dl_postNotificationOnMainThreadWithName:name object:object userInfo:nil waitUntilDone:NO];
}

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
    if (pthread_main_np()) return [self postNotificationName:name object:object userInfo:userInfo];
    [self dl_postNotificationOnMainThreadWithName:name object:object userInfo:userInfo waitUntilDone:NO];
}

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo waitUntilDone:(BOOL)wait {
    if (pthread_main_np()) return [self postNotificationName:name object:object userInfo:userInfo];
    NSMutableDictionary *info = [[NSMutableDictionary allocWithZone:nil] initWithCapacity:3];
    if (name) [info setObject:name forKey:@"name"];
    if (object) [info setObject:object forKey:@"object"];
    if (userInfo) [info setObject:userInfo forKey:@"userInfo"];
    [[self class] performSelectorOnMainThread:@selector(_dl_postNotificationName:) withObject:info waitUntilDone:wait];
}

+(void)_dl_postNotification:(NSNotification *)notification {
    [[self defaultCenter] postNotification:notification];
}

+(void)_dl_postNotificationName:(NSDictionary *)info {
    NSString *name = [info objectForKey:@"name"];
    id object = [info objectForKey:@"object"];
    NSDictionary *userInfo = [info objectForKey:@"userInfo"];
    [[self defaultCenter] postNotificationName:name object:object userInfo:userInfo];
}

@end

/**
当一个对象添加了notification之后，如果dealloc的时候，仍然持有notification，就会出现NSNotification类型的crash。

iOS9之后专门针对于这种情况做了处理，所以在iOS9之后，即使开发者没有移除observer，Notification crash也不会再产生了
*/
