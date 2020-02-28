#import "NSMutableOrderedSet+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSMutableOrderedSet (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class dClass=NSClassFromString(@"__NSOrderedSetM");
        
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(objectAtIndex:) newSel:@selector(safe_objectAtIndex:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(insertObject:atIndex:) newSel:@selector(safe_insertObject:atIndex:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(removeObjectAtIndex:) newSel:@selector(safe_removeObjectAtIndex:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(replaceObjectAtIndex:withObject:) newSel:@selector(safe_replaceObjectAtIndex:withObject:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(addObject:) newSel:@selector(safe_addObject:)];
    });
}

-(id)safe_objectAtIndex:(NSUInteger)idx
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndex:idx];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableOrderedSet);
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
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableOrderedSet);
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
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableOrderedSet);
    }
    @finally {
        
    }
}

- (void)safe_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    @try {
        [self safe_replaceObjectAtIndex:index withObject:anObject];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableOrderedSet);
    }
    @finally {
        
    }
}

- (void)safe_addObject:(id)object{
    @try {
        [self safe_addObject:object];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableOrderedSet);
    }
    @finally {
        
    }
}

@end


/**
可避免以下crash

1. - (void)addObject:(ObjectType)anObject
2. - (void)insertObject:(ObjectType)anObject atIndex:(NSUInteger)index;
3. - (id)objectAtIndex:(NSUInteger)index( 包含   array[index]  形式  )
4. - (void)removeObjectAtIndex:(NSUInteger)index
5. - (void)replaceObjectAtIndex:(NSUInteger)index

*/
