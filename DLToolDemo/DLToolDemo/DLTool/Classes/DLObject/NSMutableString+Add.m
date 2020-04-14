#import "NSMutableString+Add.h"
#import "DLToolMacro.h"
#import "DLSafeProtector.h"

@implementation NSMutableString (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod(NSClassFromString(@"NSPlaceholderMutableString"), @selector(initWithString:), @selector(safe_initWithString:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(hasPrefix:), @selector(safe_hasPrefix:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(hasSuffix:), @selector(safe_hasSuffix:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(substringFromIndex:), @selector(safe_substringFromIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(substringToIndex:), @selector(substringToIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(substringWithRange:), @selector(safe_substringWithRange:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(characterAtIndex:), @selector(safe_characterAtIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(stringByReplacingOccurrencesOfString:withString:options:range:), @selector(safe_stringByReplacingOccurrencesOfString:withString:options:range:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(stringByReplacingCharactersInRange:withString:), @selector(safe_stringByReplacingCharactersInRange:withString:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(replaceCharactersInRange:withString:), @selector(safe_replaceCharactersInRange:withString:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(replaceOccurrencesOfString:withString:options:range:), @selector(safe_replaceOccurrencesOfString:withString:options:range:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(insertString:atIndex:), @selector(safe_insertString:atIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(deleteCharactersInRange:), @selector(safe_deleteCharactersInRange:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(appendString:), @selector(safe_appendString:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSCFString"), @selector(setString:), @selector(safe_setString:));
    });
}

-(instancetype)safe_initWithString:(NSString *)aString
{
    id instance = nil;
    @try {
        instance = [self safe_initWithString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
        return instance;
    }
}

-(BOOL)safe_hasPrefix:(NSString *)str
{
    BOOL has = NO;
    @try {
        has = [self safe_hasPrefix:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
        return has;
    }
}

-(BOOL)safe_hasSuffix:(NSString *)str
{
    BOOL has = NO;
    @try {
        has = [self safe_hasSuffix:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
        return has;
    }
}

- (NSString *)safe_substringFromIndex:(NSUInteger)from {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringFromIndex:from];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (NSString *)safe_substringToIndex:(NSUInteger)index {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringToIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (NSString *)safe_substringWithRange:(NSRange)range {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringWithRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (unichar)safe_characterAtIndex:(NSUInteger)index {
    unichar characteristic;
    @try {
        characteristic = [self safe_characterAtIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
        return characteristic;
    }
}

- (NSString *)safe_stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange {
    NSString *newStr = nil;
    @try {
        newStr = [self safe_stringByReplacingOccurrencesOfString:target withString:replacement options:options range:searchRange];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
        newStr = nil;
    }
    @finally {
        return newStr;
    }
}

- (NSString *)safe_stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement {
    NSString *newStr = nil;
    @try {
        newStr = [self safe_stringByReplacingCharactersInRange:range withString:replacement];
    }
    @catch (NSException *exception) {
       DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
        newStr = nil;
    }
    @finally {
        return newStr;
    }
}

#pragma mark - NSMutableString特有的

-(void)safe_replaceCharactersInRange:(NSRange)range withString:(NSString *)aString
{
    @try {
         [self safe_replaceCharactersInRange:range withString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
    }
}

-(NSUInteger)safe_replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange
{
    NSUInteger index=0;
    @try {
       index= [self safe_replaceOccurrencesOfString:target withString:replacement options:options range:searchRange];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
        return index;
    }
}

-(void)safe_insertString:(NSString *)aString atIndex:(NSUInteger)loc
{
    @try {
        [self safe_insertString:aString atIndex:loc];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
    }
}

-(void)safe_deleteCharactersInRange:(NSRange)range
{
    @try {
        [self safe_deleteCharactersInRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
    }
}

-(void)safe_appendString:(NSString *)aString
{
    @try {
        [self safe_appendString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
    }
}

-(void)safe_setString:(NSString *)aString
{
    @try {
        [self safe_setString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableString);
    }
    @finally {
    }
}


@end


/*
 
除NSString的一些方法外又额外避免了一些方法crash
 
 1.- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)aString;
 2.- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange;
 3.- (void)insertString:(NSString *)aString atIndex:(NSUInteger)loc;
 4.- (void)deleteCharactersInRange:(NSRange)range;
 5.- (void)appendString:(NSString *)aString;
 6.- (void)setString:(NSString *)aString;
 
*/
