#ifndef DLSafeProtectorDefine_h
#define DLSafeProtectorDefine_h
@class DLSafeProtector;

#define  DLSafeLog(fmt, ...)  NSLog(fmt, ##__VA_ARGS__)
#define  DLSafeProtectionCrashLog(exception,crash)   [DLSafeProtector safe_logCrashWithException:exception crashType:crash]

//NSNotificationCenter 即使设置LogTypeAll 也不会打印，
//iOS9之后系统已经优化了，即使不移除也不会崩溃， 所以仅iOS8系统会出现此类型carsh,但是有的类是在dealloc里移除通知，而我们是在所有类的dealloc方法之前检测是否移除，没移除则去移除所以会误报crash，干脆直接不报此类型crash了

typedef enum : NSUInteger {
    DLSafeProtectorLogTypeNone,//所有log都不打印
    DLSafeProtectorLogTypeAll,//打印所有log
} DLSafeProtectorLogType;

//哪个类型的crash
typedef NS_OPTIONS(NSUInteger,DLSafeProtectorCrashType)
{
    DLSafeProtectorCrashTypeSelector                  = 1 << 0,
    DLSafeProtectorCrashTypeKVO                       = 1 << 1,
    DLSafeProtectorCrashTypeNSNotificationCenter      = 1 << 2,
    DLSafeProtectorCrashTypeNSUserDefaults            = 1 << 3,
    DLSafeProtectorCrashTypeNSCache                   = 1 << 4,
    
    DLSafeProtectorCrashTypeNSArray                   = 1 << 5,
    DLSafeProtectorCrashTypeNSMutableArray            = 1 << 6,
    
    DLSafeProtectorCrashTypeNSDictionary              = 1 << 7,
    DLSafeProtectorCrashTypeNSMutableDictionary       = 1 << 8,
    
    DLSafeProtectorCrashTypeNSStirng                  = 1 << 9,
    DLSafeProtectorCrashTypeNSMutableString           = 1 << 10,
    
    DLSafeProtectorCrashTypeNSAttributedString        = 1 << 11,
    DLSafeProtectorCrashTypeNSMutableAttributedString = 1 << 12,
    
    DLSafeProtectorCrashTypeNSSet                     = 1 << 13,
    DLSafeProtectorCrashTypeNSMutableSet              = 1 << 14,
    
    DLSafeProtectorCrashTypeNSData                    = 1 << 15,
    DLSafeProtectorCrashTypeNSMutableData             = 1 << 16,
    
    DLSafeProtectorCrashTypeNSOrderedSet              = 1 << 17,
    DLSafeProtectorCrashTypeNSMutableOrderedSet       = 1 << 18,
    DLSafeProtectorCrashTypeViewAsyncThread           = 1 << 19,
    DLSafeProtectorCrashTypeViewLayout                = 1 << 20,
    
    DLSafeProtectorCrashTypeNSArrayContainer = DLSafeProtectorCrashTypeNSArray|DLSafeProtectorCrashTypeNSMutableArray,
    
    DLSafeProtectorCrashTypeNSDictionaryContainer = DLSafeProtectorCrashTypeNSDictionary|DLSafeProtectorCrashTypeNSMutableDictionary,
    
    DLSafeProtectorCrashTypeNSStringContainer = DLSafeProtectorCrashTypeNSStirng|DLSafeProtectorCrashTypeNSMutableString,
    
    DLSafeProtectorCrashTypeNSAttributedStringContainer = DLSafeProtectorCrashTypeNSAttributedString|DLSafeProtectorCrashTypeNSMutableAttributedString,
    
    DLSafeProtectorCrashTypeNSSetContainer = DLSafeProtectorCrashTypeNSSet|DLSafeProtectorCrashTypeNSMutableSet,
    
    DLSafeProtectorCrashTypeNSDataContainer = DLSafeProtectorCrashTypeNSData|DLSafeProtectorCrashTypeNSMutableData,
    
      DLSafeProtectorCrashTypeNSOrderedSetContainer = DLSafeProtectorCrashTypeNSOrderedSet|DLSafeProtectorCrashTypeNSMutableOrderedSet,
    
    DLSafeProtectorCrashTypeAll =
        //支持所有类型的crash
    DLSafeProtectorCrashTypeSelector
    |DLSafeProtectorCrashTypeKVO
    |DLSafeProtectorCrashTypeNSNotificationCenter
    |DLSafeProtectorCrashTypeNSUserDefaults
    |DLSafeProtectorCrashTypeNSCache
    |DLSafeProtectorCrashTypeNSArrayContainer
    |DLSafeProtectorCrashTypeNSDictionaryContainer
    |DLSafeProtectorCrashTypeNSStringContainer
    |DLSafeProtectorCrashTypeNSAttributedStringContainer
    |DLSafeProtectorCrashTypeNSSetContainer
    |DLSafeProtectorCrashTypeNSDataContainer
    |DLSafeProtectorCrashTypeNSOrderedSetContainer
};



typedef void(^DLSafeProtectorBlock)(NSException *exception,DLSafeProtectorCrashType crashType);


#endif /* DLSafeProtectorDefine_h */
