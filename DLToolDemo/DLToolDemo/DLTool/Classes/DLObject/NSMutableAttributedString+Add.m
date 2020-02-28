#import "NSMutableAttributedString+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSMutableAttributedString (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class dClass = NSClassFromString(@"NSConcreteMutableAttributedString");
        
        //initWithString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithString:) newSel:@selector(safe_initWithString:)];
        
        //initWithAttributedString
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithString:attributes:) newSel:@selector(safe_initWithString:attributes:)];
        
        //initWithString:attributes:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(initWithAttributedString:) newSel:@selector(safe_initWithAttributedString:)];
        
        
        //以下为NSMutableAttributedString特有方法
        //4.replaceCharactersInRange:withString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceCharactersInRange:withString:) newSel:@selector(safe_replaceCharactersInRange:withString:)];
        
        //5.setAttributes:range:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(setAttributes:range:) newSel:@selector(safe_setAttributes:range:)];
        
        
        
        //6.addAttribute:value:range:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(addAttribute:value:range:) newSel:@selector(safe_addAttribute:value:range:)];
        
        //7.addAttributes:range:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(addAttributes:range:) newSel:@selector(safe_addAttributes:range:)];
        
        //8.removeAttribute:range:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(removeAttribute:range:) newSel:@selector(safe_removeAttribute:range:)];
        
        //9.replaceCharactersInRange:withAttributedString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceCharactersInRange:withAttributedString:) newSel:@selector(safe_replaceCharactersInRange:withAttributedString:)];
        
        
        //10.insertAttributedString:atIndex:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(insertAttributedString:atIndex:) newSel:@selector(safe_insertAttributedString:atIndex:)];
        
        
        //11.appendAttributedString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(appendAttributedString:) newSel:@selector(safe_appendAttributedString:)];
        
        //12.deleteCharactersInRange:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(deleteCharactersInRange:) newSel:@selector(safe_deleteCharactersInRange:)];
        
        //13.setAttributedString:
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(setAttributedString:) newSel:@selector(safe_setAttributedString:)];
        
        
    });
}

- (instancetype)safe_initWithString:(NSString *)str {
    id object = nil;
    @try {
        object = [self safe_initWithString:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
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
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
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
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
        return object;
    }
}


-(void)safe_replaceCharactersInRange:(NSRange)range withString:(nonnull NSString *)aString
{
    @try {
        [self safe_replaceCharactersInRange:range withString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range
{
    @try {
        [self safe_setAttributes:attrs range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_addAttribute:(NSAttributedStringKey)name value:(id)value range:(NSRange)range
{
    @try {
        [self safe_addAttribute:name value:value range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}
-(void)safe_addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range
{
    @try {
        [self safe_addAttributes:attrs range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_removeAttribute:(NSAttributedStringKey)name range:(NSRange)range
{
    @try {
        [self safe_removeAttribute:name range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_replaceCharactersInRange:range withAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}


-(void)safe_insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc
{
    @try {
        [self safe_insertAttributedString:attrString atIndex:loc];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}


-(void)safe_appendAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_appendAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
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
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_setAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_setAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

@end


/*

目前可避免以下方法crash
1.- (instancetype)initWithString:(NSString *)str;
2.- (instancetype)initWithString:(NSString *)str attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;
3.- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr;

4. - (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str;
5.- (void)setAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;

6.- (void)addAttribute:(NSAttributedStringKey)name value:(id)value range:(NSRange)range;
7.- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;
8.- (void)removeAttribute:(NSAttributedStringKey)name range:(NSRange)range;

9.- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString;
10.- (void)insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc;
11.- (void)appendAttributedString:(NSAttributedString *)attrString;
12.- (void)deleteCharactersInRange:(NSRange)range;
13.- (void)setAttributedString:(NSAttributedString *)attrString;


*/
