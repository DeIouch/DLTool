#import "NSMutableData+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSMutableData (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class dClass=NSClassFromString(@"NSConcreteMutableData");
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(subdataWithRange:) newSel:@selector(safe_subdataWithRangeMutableConcreteData:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(rangeOfData:options:range:) newSel:@selector(safe_rangeOfDataMutableConcreteData:options:range:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(resetBytesInRange:) newSel:@selector(safe_resetBytesInRange:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceBytesInRange:withBytes:) newSel:@selector(safe_replaceBytesInRange:withBytes:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceBytesInRange:withBytes:length:) newSel:@selector(safe_replaceBytesInRange:withBytes:length:)];
    });
}

-(NSData *)safe_subdataWithRangeMutableConcreteData:(NSRange)range
{
    id object=nil;
    @try {
        object =  [self safe_subdataWithRangeMutableConcreteData:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableData);
    }
    @finally {
        return object;
    }
}

-(NSRange)safe_rangeOfDataMutableConcreteData:(NSData *)dataToFind options:(NSDataSearchOptions)mask range:(NSRange)searchRange
{
    NSRange object;
    @try {
        object =  [self safe_rangeOfDataMutableConcreteData:dataToFind options:mask range:searchRange];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableData);
    }
    @finally {
        return object;
    }
}

- (void)safe_resetBytesInRange:(NSRange)range
{
    @try {
        [self safe_resetBytesInRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableData);
    }
    @finally {
    }
}

- (void)safe_replaceBytesInRange:(NSRange)range withBytes:(const void *)bytes
{
    @try {
        [self safe_replaceBytesInRange:range withBytes:bytes];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableData);
    }
    @finally {
    }
}

- (void)safe_replaceBytesInRange:(NSRange)range withBytes:(const void *)replacementBytes length:(NSUInteger)replacementLength
{
    @try {
        [self safe_replaceBytesInRange:range withBytes:replacementBytes length:replacementLength];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableData);
    }
    @finally {
    }
}

@end

/*
可防止以下crash
 1.subdataWithRange:
 2.rangeOfData:options:range:
 3.resetBytesInRange:
 4.replaceBytesInRange:withBytes:
 5.replaceBytesInRange:withBytes:length:
 
 */
