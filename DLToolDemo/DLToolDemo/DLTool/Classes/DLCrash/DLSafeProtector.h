#import <Foundation/Foundation.h>
#import "DLSafeProtectorDefine.h"

#define DLKVOSafeLog(fmt, ...) safe_KVOCustomLog(fmt,##__VA_ARGS__)

@interface DLSafeProtector : NSObject

/**
打开目前所支持的所有安全保护(但不包含KVO防护，如果需要开启包含KVO在内的所有防护，需要使用下面的方法，设置types为：DLSafeProtectorCrashTypeAll)
 
 @param isDebug
 //isDebug=YES 代表测试环境，当捕获到crash时会利用断言闪退， 同时回调block
 //isDebug=NO  代表正式环境，当捕获到crash时不会利用断言闪退，会回调block
 @param block  回调的block
 */
+ (void)openSafeProtectorWithIsDebug:(BOOL)isDebug block:(DLSafeProtectorBlock)block;

/**
开启防止指定类型的crash

 @param isDebug
 //isDebug=YES 代表测试环境，当捕获到crash时会利用断言闪退， 同时回调block
 //isDebug=NO  代表正式环境，当捕获到crash时不会利用断言闪退，会回调block
 @param types 想防止哪些类crash
 @param block 回调的block
 */
+ (void)openSafeProtectorWithIsDebug:(BOOL)isDebug types:(DLSafeProtectorCrashType)types block:(DLSafeProtectorBlock)block;

+ (void)safe_logCrashWithException:(NSException *)exception crashType:(DLSafeProtectorCrashType)crashType;

//是否开启KVO添加移除日志信息，默认为NO
+ (void)setLogEnable:(BOOL)enable;
//自定义log函数
void safe_KVOCustomLog(NSString *format,...);


@end

//[DLSafeProtector openSafeProtectorWithIsDebug:isDebug types:DLSafeProtectorCrashTypeNSArrayContainer|DLSafeProtectorCrashTypeNSDictionaryContainer block:^(NSException *exception, DLSafeProtectorCrashType crashType) {
////此方法方便在bugly后台查看bug崩溃位置，而不用点击跟踪数据，再点击crash_attach.log来查看崩溃位置
//[Bugly reportExceptionWithCategory:3 name:exception.name reason:[NSString stringWithFormat:@"%@  崩溃位置:%@",exception.reason,exception.userInfo[@"location"]] callStack:@[exception.userInfo[@"callStackSymbols"]] extraInfo:exception.userInfo terminateApp:NO];
//}];
////打开KVO添加，移除的日志信息
//[DLSafeProtector setLogEnable:YES];
