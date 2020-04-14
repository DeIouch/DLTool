#import "NSUserDefaults+Add.h"
#import "DLSafeProtector.h"
#import "DLToolMacro.h"

@implementation NSUserDefaults (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(setObject:forKey:), @selector(safe_setObject:forKey:));
        Safe_ExchangeMethod([self class], @selector(objectForKey:), @selector(safe_objectForKey:));
        Safe_ExchangeMethod([self class], @selector(stringForKey:), @selector(safe_stringForKey:));
        Safe_ExchangeMethod([self class], @selector(arrayForKey:), @selector(safe_arrayForKey:));
        Safe_ExchangeMethod([self class], @selector(dataForKey:), @selector(safe_dataForKey:));
        Safe_ExchangeMethod([self class], @selector(URLForKey:), @selector(safe_URLForKey:));
        Safe_ExchangeMethod([self class], @selector(stringArrayForKey:), @selector(safe_stringArrayForKey:));
        Safe_ExchangeMethod([self class], @selector(floatForKey:), @selector(safe_floatForKey:));
        Safe_ExchangeMethod([self class], @selector(doubleForKey:), @selector(safe_doubleForKey:));
        Safe_ExchangeMethod([self class], @selector(integerForKey:), @selector(safe_integerForKey:));
        Safe_ExchangeMethod([self class], @selector(boolForKey:), @selector(safe_boolForKey:));
    });
}

-(void)safe_setObject:(id)value forKey:(NSString *)defaultName
{
    if(!defaultName){
        //defaultName空才会崩溃
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key  can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }else{
        [self safe_setObject:value forKey:defaultName];
    }
}

-(id)safe_objectForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_objectForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSString *)safe_stringForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_stringForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSArray *)safe_arrayForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_arrayForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSData *)safe_dataForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_dataForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSURL *)safe_URLForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_URLForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSArray<NSString *> *)safe_stringArrayForKey:(NSString *)defaultName
{
    id obj=nil;
    if(defaultName){
        obj=[self safe_stringArrayForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(float)safe_floatForKey:(NSString *)defaultName
{
    float obj=0;
    if(defaultName){
        obj=[self safe_floatForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(double)safe_doubleForKey:(NSString *)defaultName
{
    double obj=0;
    if(defaultName){
        obj=[self safe_doubleForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(NSInteger)safe_integerForKey:(NSString *)defaultName
{
    NSInteger obj=0;
    if(defaultName){
        obj=[self safe_integerForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

-(BOOL)safe_boolForKey:(NSString *)defaultName
{
    BOOL obj=NO;
    if(defaultName){
        obj=[self safe_boolForKey:defaultName];
    }else{
        NSString *reason=[NSString stringWithFormat:@"NSUserDefaults %@ key can`t be nil",NSStringFromSelector(_cmd)];
        NSException *exception=[NSException exceptionWithName:reason reason:reason userInfo:nil];
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSUserDefaults);
    }
    return obj;
}

@end


/*
可避免以下方法  key=nil时的crash
    1.objectForKey:
    2.stringForKey:
    3.arrayForKey:
    4.dataForKey:
    5.URLForKey:
    6.stringArrayForKey:
    7.floatForKey:
    8.doubleForKey:
    9.integerForKey:
    10.boolForKey:
    11.setObject:forKey:
*/
