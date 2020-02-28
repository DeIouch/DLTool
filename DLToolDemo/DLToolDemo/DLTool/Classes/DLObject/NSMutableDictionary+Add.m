#import "NSMutableDictionary+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSMutableDictionary (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class dClass=NSClassFromString(@"__NSDictionaryM");
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(setObject:forKey:) newSel:@selector(safe_setObject:forKey:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(setObject:forKeyedSubscript:) newSel:@selector(safe_setObject:forKeyedSubscript:)];
        [self safe_exchangeInstanceMethod:dClass originalSel:@selector(removeObjectForKey:) newSel:@selector(safe_removeObjectForKey:)];


        //__NSCFDictionary
         [self safe_exchangeInstanceMethod:NSClassFromString(@"__NSCFDictionary") originalSel:@selector(setObject:forKey:) newSel:@selector(safe_setObjectCFDictionary:forKey:)];

         [self safe_exchangeInstanceMethod:NSClassFromString(@"__NSCFDictionary") originalSel:@selector(removeObjectForKey:) newSel:@selector(safe_removeObjectForKeyCFDictionary:)];

    });
}

#pragma mark - __NSCFDictionary
- (void)safe_setObjectCFDictionary:(id)anObject forKey:(id<NSCopying>)aKey {
    
    @try {
        [self safe_setObjectCFDictionary:anObject forKey:aKey];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableDictionary);
    }
    @finally {
    }
}

- (void)safe_removeObjectForKeyCFDictionary:(id)aKey {
    
    @try {
        [self safe_removeObjectForKeyCFDictionary:aKey];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableDictionary);
    }
    @finally {
    }
}

#pragma mark - __NSDictionaryM
- (void)safe_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    
    @try {
        [self safe_setObject:anObject forKey:aKey];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableDictionary);
    }
    @finally {
    }
}

- (void)safe_setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)aKey {
    
    @try {
        [self safe_setObject:anObject forKeyedSubscript:aKey];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableDictionary);
    }
    @finally {
    }
}

- (void)safe_removeObjectForKey:(id)aKey {
    
    @try {
        [self safe_removeObjectForKey:aKey];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableDictionary);
    }
    @finally {
    }
}

+(NSMutableDictionary *)dl_dictionaryWithPlistData:(NSData *)plist {
    if (!plist) return nil;
    NSMutableDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
    if ([dictionary isKindOfClass:[NSMutableDictionary class]]) return dictionary;
    return nil;
}

+(NSMutableDictionary *)dl_dictionaryWithPlistString:(NSString *)plist {
    if (!plist) return nil;
    NSData* data = [plist dataUsingEncoding:NSUTF8StringEncoding];
    return [self dl_dictionaryWithPlistData:data];
}

-(id)dl_popObjectForKey:(id)aKey {
    if (!aKey) return nil;
    id value = self[aKey];
    [self removeObjectForKey:aKey];
    return value;
}

-(NSDictionary *)dl_popEntriesForKeys:(NSArray *)keys {
    NSMutableDictionary *dic = [NSMutableDictionary new];
    for (id key in keys) {
        id value = self[key];
        if (value) {
            [self removeObjectForKey:key];
            dic[key] = value;
        }
    }
    return dic;
}

@end


/*
目前可避免以下crash

1.直接调用 setObject:forKey
2.通过下标方式赋值的时候，value为nil不会崩溃
   iOS11之前会调用 setObject:forKey
   iOS11之后（含11)  setObject:forKeyedSubscript:
3.removeObjectForKey


*/
