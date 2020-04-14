#import "NSMutableSet+Add.h"
#import "DLSafeProtector.h"
#import "DLToolMacro.h"

@implementation NSMutableSet (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod(NSClassFromString(@"__NSSetM"), @selector(addObject:), @selector(safe_addObject:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSSetM"), @selector(removeObject:), @selector(safe_removeObject:));
    });
}

- (void)safe_addObject:(id)object
{
    @try {
        [self safe_addObject:object];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableSet);
    }
    @finally {
    }
}

- (void)safe_removeObject:(id)object
{
    @try {
        [self safe_removeObject:object];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableSet);
    }
    @finally {
    }
}

@end

/*
可避免以下crash
1.setWithObject:
2.(instancetype)initWithObjects:(ObjectType)firstObj
3.setWithObjects:(ObjectType)firstObj
4.addObject:
5.removeObject:
*/
