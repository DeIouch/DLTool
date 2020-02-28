#import "NSNotificationCenter+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#import <objc/message.h>
#include <objc/runtime.h>

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
-(void)safe_changeDidDeallocSignal
{
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
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        
        [NSNotificationCenterSafeSwizzledClasses() addObject:className];
    }
}
-(void)safe_NotificationDealloc
{
    if ([self isNotification]) {
//        NSException *exception=[NSException exceptionWithName:@"dealloc时通知中心未移除本对象" reason:[NSString stringWithFormat:@"dealloc时通知中心未移除本对象  Class:%@",[self class]] userInfo:nil]; LSSafeProtectionCrashLog(exception,LSSafeProtectorCrashTypeNSNotificationCenter);
        [[NSNotificationCenter defaultCenter]removeObserver:self];
    }
}
-(void)setIsNotification:(BOOL)isNotification
{
    objc_setAssociatedObject(self, @selector(isNotification), @(isNotification), OBJC_ASSOCIATION_RETAIN);
}
-(BOOL)isNotification
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

@implementation NSNotificationCenter (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self safe_exchangeInstanceMethod:[NSNotificationCenter class] originalSel:@selector(addObserver:selector:name:object:) newSel:@selector(safe_addObserver:selector:name:object:)];
    });
}

-(void)safe_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject
{
    [observer setIsNotification:YES];
    [observer safe_changeDidDeallocSignal];
    [self safe_addObserver:observer selector:aSelector name:aName object:anObject];
}

@end

/**
当一个对象添加了notification之后，如果dealloc的时候，仍然持有notification，就会出现NSNotification类型的crash。

iOS9之后专门针对于这种情况做了处理，所以在iOS9之后，即使开发者没有移除observer，Notification crash也不会再产生了
*/
