#import "NSOrderedSet+Add.h"
#import "DLSafeProtector.h"
#import "DLToolMacro.h"

@implementation NSOrderedSet (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod(NSClassFromString(@"__NSPlaceholderOrderedSet"), @selector(initWithObjects:count:), @selector(safe_initWithObjects:count:));
        Safe_ExchangeMethod(NSClassFromString(@"__NSOrderedSetI"), @selector(objectAtIndex:), @selector(safe_objectAtIndex:));
    });
}

-(instancetype)safe_initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt
{
    id instance = nil;
    @try {
        instance = [self safe_initWithObjects:objects count:cnt];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSOrderedSet);        
        //以下是对错误数据的处理，把为nil的数据去掉,然后初始化数组
        NSInteger newObjsIndex = 0;
        id   newObjects[cnt];
        for (int i = 0; i < cnt; i++) {
            if (objects[i] != nil) {
                newObjects[newObjsIndex] = objects[i];
                newObjsIndex++;
            }
        }
        instance = [self safe_initWithObjects:newObjects count:newObjsIndex];
    }
    @finally {
        return instance;
    }
}

-(id)safe_objectAtIndex:(NSUInteger)idx
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndex:idx];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSOrderedSet);
    }
    @finally {
        return object;
    }
}

@end

/*
可避免以下crash

1.orderedSetWithSet
2.initWithObjects:count:
3.objectAtIndex:

*/
