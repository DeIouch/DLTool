#import "NSArray+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>
#import "NSData+Add.h"
#import "DLToolMacro.h"

@implementation NSArray (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod(objc_getClass("__NSPlaceholderArray"), @selector(initWithObjects:count:), @selector(initWithObjects:count:));
        Safe_ExchangeMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:), @selector(safe_objectAtIndexI:));
        Safe_ExchangeMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndexedSubscript:), @selector(safe_objectAtIndexedSubscriptI:));
        Safe_ExchangeMethod(objc_getClass("__NSArray0"), @selector(objectAtIndex:), @selector(safe_objectAtIndex0:));
        Safe_ExchangeMethod(objc_getClass("__NSSingleObjectArrayI"), @selector(objectAtIndex:), @selector(safe_objectAtIndexSI:));
    });
}

-(instancetype)safe_initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt
{
    id instance = nil;
    @try {
        instance = [self safe_initWithObjects:objects count:cnt];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSArray);
        
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

-(id)safe_objectAtIndexedSubscriptI:(NSUInteger)index
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndexedSubscriptI:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSArray);
    }
    @finally {
        return object;
    }
}
-(id)safe_objectAtIndexI:(NSUInteger)index
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndexI:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSArray);
    }
    @finally {
        return object;
    }
}

-(id)safe_objectAtIndex0:(NSUInteger)index
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndex0:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSArray);
    }
    @finally {
        return object;
    }
}

-(id)safe_objectAtIndexSI:(NSUInteger)index
{
    id object=nil;
    @try {
        object = [self safe_objectAtIndexSI:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSArray);
    }
    @finally {
        return object;
    }
}


+(NSArray *)dl_arrayWithPlistData:(NSData *)plist{
    if (!plist) return nil;
    NSArray *array = [NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListImmutable format:NULL error:NULL];
    if ([array isKindOfClass:[NSArray class]]) return array;
    return nil;
}

+(NSArray *)dl_arrayWithPlistString:(NSString *)plist{
    if (!plist) return nil;
    NSData* data = [plist dataUsingEncoding:NSUTF8StringEncoding];
    return [self dl_arrayWithPlistData:data];
}

-(NSData *)dl_plistData{
    return [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListBinaryFormat_v1_0 options:kNilOptions error:NULL];
}

-(NSString *)dl_plistString{
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListXMLFormat_v1_0 options:kNilOptions error:NULL];
    if (xmlData) return xmlData.dl_utf8String;
    return nil;
}

-(id)dl_randomObject{
    if (self.count) {
        return self[arc4random_uniform((u_int32_t)self.count)];
    }
    return nil;
}

-(NSString *)dl_jsonStringEncoded{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

-(NSString *)dl_jsonPrettyStringEncoded{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

@end

// 类继承关系
// __NSArrayI                 继承于 NSArray
// __NSSingleObjectArrayI     继承于 NSArray
// __NSArray0                 继承于 NSArray
// __NSFrozenArrayM           继承于 NSArray
// __NSArrayM                 继承于 NSMutableArray
// __NSCFArray                继承于 NSMutableArray
// NSMutableArray             继承于 NSArray
// NSArray                    继承于 NSObject

// < = iOS 8:下都是__NSArrayI 如果是通过json转成的id 为__NSCFArray
//iOS9 @[] 是__NSArray0  @[@"fd"]是__NSArrayI
//iOS10以后(含10): 分 __NSArrayI、  __NSArray0、__NSSingleObjectArrayI


//__NSArrayM   NSMutableArray创建的都为__NSArrayM
//__NSArray0   除__NSArrayM 0个元素都为__NSArray0
// __NSSingleObjectArrayI @[@"fds"]只有此形式创建而且仅一个元素为__NSSingleObjectArrayI
//__NSArrayI   @[@"fds",@"fsd"]方式创建多于1个元素 或者 arrayWith创建都是__NSArrayI


//__NSCFArray
//arr@[11]
// >=11 调用 [__NSCFArray objectAtIndexedSubscript:]
// < 11  调用 [__NSCFArray objectAtIndex:]

//__NSArrayI
//arr@[11]
// >=11  调用 [__NSArrayI objectAtIndexedSubscript:]
// < 11  调用 [__NSArrayI objectAtIndex:]

//__NSArray0
//arr@[11]   不区分系统调用的是  [__NSArray0 objectAtIndex:]

//__NSSingleObjectArrayI
//arr@[11] 不区分系统 调用的是  [__NSSingleObjectArrayI objectAtIndex:]

//不可变数组
// <  iOS11： arr@[11]  调用的是[__NSArrayI objectAtIndex:]
// >= iOS11： arr@[11]  调用的是[__NSArrayI objectAtIndexedSubscript]
//  任意系统   [arr objectAtIndex:111]  调用的都是[__NSArrayM objectAtIndex:]

//可变数组
// <  iOS11： arr@[11]  调用的是[__NSArrayM objectAtIndex:]
// >= iOS11： arr@[11]  调用的是[__NSArrayM objectAtIndexedSubscript]
//  任意系统   [arr objectAtIndex:111]  调用的都是[__NSArrayI objectAtIndex:]

/* 特殊类型
1.__NSFrozenArrayM  应该和__NSFrozenDictionaryM类似，但是没有找到触发条件

2.__NSCFArray 以下情况获得
 
[[NSUserDefaults standardUserDefaults] setObject:[NSMutableArray array] forKey:@"name"];
NSMutableArray *array=[[NSUserDefaults standardUserDefaults] objectForKey:@"name"];

*/


/*
   目前能避免以下crash
 
   1. NSArray的快速创建方式 NSArray *array = @[@"chenfanfang", @"AvoidCrash"];//其实调用的是3中的方法
   2. + (instancetype)arrayWithObjects:(const ObjectType _Nonnull [_Nonnull])objects count:(NSUInteger)cnt;调用的也是3中的方法
   3. - (instancetype)initWithObjects:(const ObjectType _Nonnull [_Nullable])objects count
   4. - (id)objectAtIndex:(NSUInteger)index
 
 */
