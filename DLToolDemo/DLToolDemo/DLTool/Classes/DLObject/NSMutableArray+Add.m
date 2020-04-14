#import "NSMutableArray+Add.h"
#import "DLSafeProtector.h"
#import "NSArray+Add.h"
#import "DLToolMacro.h"

@implementation NSMutableArray (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 11.0, *)) {
            Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(objectAtIndexedSubscript:), @selector(safe_objectAtIndexedSubscriptM:));
        }
        Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(insertObject:atIndex:), @selector(safe_insertObject:atIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectAtIndex:), @selector(safe_removeObjectAtIndex:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(removeObjectsInRange:), @selector(safe_removeObjectsInRange:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectAtIndex:withObject:), @selector(safe_replaceObjectAtIndex:withObject:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSArrayM"), @selector(replaceObjectsInRange:withObjectsFromArray:), @selector(safe_replaceObjectsInRange:withObjectsFromArray:));
        if (@available(iOS 11.0, *)) {
            Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(objectAtIndexedSubscript:), @selector(safe_objectAtIndexedSubscriptCFArray:));
        }
        Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(insertObject:atIndex:), @selector(safe_insertObjectCFArray:atIndex:));
        Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(removeObjectAtIndex:), @selector(safe_removeObjectAtIndexCFArray:));
        Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(removeObjectsInRange:), @selector(safe_removeObjectsInRangeCFArray:));
        Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(replaceObjectAtIndex:withObject:), @selector(safe_replaceObjectAtIndexCFArray:withObject:));
        Safe_ExchangeMethod(objc_getClass("__NSCFArray"), @selector(replaceObjectsInRange:withObjectsFromArray:), @selector(safe_replaceObjectsInRangeCFArray:withObjectsFromArray:));
    });
}

#pragma mark - 以下为__NSCFArray

-(id)safe_objectAtIndexedSubscriptCFArray:(NSUInteger)index
{
    id object=nil;
    @try {
        object =  [self safe_objectAtIndexedSubscriptCFArray:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        return object;
    }
}

- (void)safe_insertObjectCFArray:(id)anObject atIndex:(NSUInteger)index
{
    @try {
        [self safe_insertObjectCFArray:anObject atIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

- (void)safe_removeObjectAtIndexCFArray:(NSUInteger)index
{
    @try {
        [self safe_removeObjectAtIndexCFArray:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

-(void)safe_removeObjectsInRangeCFArray:(NSRange)range
{
    @try {
        [self safe_removeObjectsInRangeCFArray:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
    }
}

- (void)safe_replaceObjectAtIndexCFArray:(NSUInteger)index withObject:(id)anObject
{
    @try {
        [self safe_replaceObjectAtIndexCFArray:index withObject:anObject];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

-(void)safe_replaceObjectsInRangeCFArray:(NSRange)range withObjectsFromArray:(NSArray *)otherArray
{
    @try {
        [self safe_replaceObjectsInRangeCFArray:range withObjectsFromArray:otherArray];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

#pragma mark - 以下为__NSArrayM
-(id)safe_objectAtIndexedSubscriptM:(NSUInteger)index
{
    id object=nil;
    @try {
        object =  [self safe_objectAtIndexedSubscriptM:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        return object;
    }
}

- (void)safe_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    @try {
        [self safe_insertObject:anObject atIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

- (void)safe_removeObjectAtIndex:(NSUInteger)index
{
    @try {
        [self safe_removeObjectAtIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

-(void)safe_removeObjectsInRange:(NSRange)range
{
    @try {
        [self safe_removeObjectsInRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
    }
}

- (void)safe_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    @try {
        [self safe_replaceObjectAtIndex:index withObject:anObject];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

-(void)safe_replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray
{
    @try {
        [self safe_replaceObjectsInRange:range withObjectsFromArray:otherArray];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableArray);
    }
    @finally {
        
    }
}

+(NSMutableArray *)dl_arrayWithPlistData:(NSData *)plist{
    if (!plist) return nil;
    NSMutableArray *array = [NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    if ([array isKindOfClass:[NSMutableArray class]]) return array;
    return nil;
}

+(NSMutableArray *)dl_arrayWithPlistString:(NSString *)plist{
    if (!plist) return nil;
    NSData* data = [plist dataUsingEncoding:NSUTF8StringEncoding];
    return [self dl_arrayWithPlistData:data];
}

-(void)dl_shuffle{
    for (NSUInteger i = self.count; i > 1; i--) {
        [self exchangeObjectAtIndex:(i - 1)
                  withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
}

@end

/**
   可避免以下crash
 
   1. - (void)addObject:(ObjectType)anObject(实际调用insertObject:)
   2. - (void)insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;
   3. - (id)objectAtIndex:(NSUInteger)index( 包含   array[index]  形式  )
   4. - (void)removeObjectAtIndex:(NSUInteger)index
   5. - (void)replaceObjectAtIndex:(NSUInteger)index
   6. - (void)removeObjectsInRange:(NSRange)range
   7. - (void)replaceObjectsInRange:(NSRange)range withObjectsFromArray:(NSArray*)otherArray;
 
*/
