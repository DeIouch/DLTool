#import "NSAttributedString+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSAttributedString (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class dClass = NSClassFromString(@"NSConcreteAttributedString");
        
        //initWithString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithString:) newSel:@selector(safe_initWithString:)];
        
        //initWithAttributedString
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithString:attributes:) newSel:@selector(safe_initWithString:attributes:)];
        
        //initWithString:attributes:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithAttributedString:) newSel:@selector(safe_initWithAttributedString:)];
        
    });
}

- (instancetype)safe_initWithString:(NSString *)str {
    id object = nil;
    @try {
        object = [self safe_initWithString:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSAttributedString);
    }
    @finally {
        return object;
    }
}

#pragma mark - initWithAttributedString
- (instancetype)safe_initWithAttributedString:(NSAttributedString *)attrStr {
    id object = nil;
    
    @try {
        object = [self safe_initWithAttributedString:attrStr];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSAttributedString);
    }
    @finally {
        return object;
    }
}

#pragma mark - initWithString:attributes:
- (instancetype)safe_initWithString:(NSString *)str attributes:(NSDictionary<NSString *,id> *)attrs {
    id object = nil;
    
    @try {
        object = [self safe_initWithString:str attributes:attrs];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSAttributedString);
    }
    @finally {
        return object;
    }
}

@end


/*

目前可避免以下方法crash
   1.- (instancetype)initWithString:(NSString *)str;
   2.- (instancetype)initWithString:(NSString *)str attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;
   3.- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr;

*/
