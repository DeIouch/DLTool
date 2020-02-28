#import "NSMutableArray+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>
#import "NSArray+Add.h"

@implementation NSMutableArray (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //方法交换只要一次就好
        Class dClass=NSClassFromString(@"__NSArrayM");

        //因为11.0以上系统才会调用此方法，所以大于11.0才交换此方法
        if (@available(iOS 11.0, *)) {
            [self safe_exchangeInstanceMethod:dClass originalSel:@selector(objectAtIndexedSubscript:) newSel:@selector(safe_objectAtIndexedSubscriptM:)];
        }

        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(insertObject:atIndex:) newSel:@selector(safe_insertObject:atIndex:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(removeObjectAtIndex:) newSel:@selector(safe_removeObjectAtIndex:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(removeObjectsInRange:) newSel:@selector(safe_removeObjectsInRange:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceObjectAtIndex:withObject:) newSel:@selector(safe_replaceObjectAtIndex:withObject:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceObjectsInRange:withObjectsFromArray:) newSel:@selector(safe_replaceObjectsInRange:withObjectsFromArray:)];

        // 下面为*********  __NSCFArray   *************
        //因为11.0以上系统才会调用此方法，所以大于11.0才交换此方法
        if (@available(iOS 11.0, *)) {
            [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(objectAtIndexedSubscript:) newSel:@selector(safe_objectAtIndexedSubscriptCFArray:)];
        }

        [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(insertObject:atIndex:) newSel:@selector(safe_insertObjectCFArray:atIndex:)];

        [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(removeObjectAtIndex:) newSel:@selector(safe_removeObjectAtIndexCFArray:)];

        [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(removeObjectsInRange:) newSel:@selector(safe_removeObjectsInRangeCFArray:)];

        [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(replaceObjectAtIndex:withObject:) newSel:@selector(safe_replaceObjectAtIndexCFArray:withObject:)];

         [self safe_exchangeInstanceMethod:objc_getClass("__NSCFArray") originalSel:@selector(replaceObjectsInRange:withObjectsFromArray:) newSel:@selector(safe_replaceObjectsInRangeCFArray:withObjectsFromArray:)];
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
