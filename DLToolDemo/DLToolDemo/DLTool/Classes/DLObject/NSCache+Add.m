#import "NSCache+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>
#import "DLToolMacro.h"

@implementation NSCache (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod(NSClassFromString(@"NSCache"), @selector(setObject:forKey:), @selector(safe_setObject:forKey:));
        Safe_ExchangeMethod(NSClassFromString(@"NSCache"), @selector(setObject:forKey:cost:), @selector(safe_setObject:forKey:cost:));
    });
}

-(void)safe_setObject:(id)obj forKey:(id)key
{
    if(key&&obj){
        [self safe_setObject:obj forKey:key];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSCache %@ key and value can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSCache);
    }
}
-(void)safe_setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
{
    if(key&&obj){
        [self safe_setObject:obj forKey:key cost:g];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSCache %@ key and value can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSCache);
    }
}

@end

/*
可避免以下crash
setObject:forKey:
setObject:forKey:cost:

*/
