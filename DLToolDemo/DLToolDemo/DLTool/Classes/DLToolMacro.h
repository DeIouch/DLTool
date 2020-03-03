#import <sys/time.h>
#import <pthread.h>

#ifndef DLToolMacro_h
#define DLToolMacro_h

#ifndef dl_weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define dl_weakify autoreleasepool{} __weak __typeof__(self) weak##_##self = self;
        #else
        #define dl_weakify autoreleasepool{} __block __typeof__(self) block##_##self = self;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define dl_weakify try{} @finally{} {} __weak __typeof__(self) weak##_##self = self;
        #else
        #define dl_weakify try{} @finally{} {} __block __typeof__(self) block##_##self = self;
        #endif
    #endif
#endif

#ifndef dl_strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define dl_strongify autoreleasepool{} __typeof__(self) self = weak##_##self;
        #else
        #define dl_strongify autoreleasepool{} __typeof__(self) self = block##_##self;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define dl_strongify try{} @finally{} __typeof__(self) self = weak##_##self;
        #else
        #define dl_strongify try{} @finally{} __typeof__(self) self = block##_##self;
        #endif
    #endif
#endif


#ifdef DEBUG

#define DLLog(...) NSLog(__VA_ARGS__)

#define debugMethod() NSLog(@"%s", __func__)

#else

#define DLLog(...)

#define debugMethod()

#endif


#ifndef kSystemVersion
#define kSystemVersion [UIDevice systemVersion]
#endif

#ifndef kiOS6Later
#define kiOS6Later (kSystemVersion >= 6)
#endif

#ifndef kiOS7Later
#define kiOS7Later (kSystemVersion >= 7)
#endif

#ifndef kiOS8Later
#define kiOS8Later (kSystemVersion >= 8)
#endif

#ifndef kiOS9Later
#define kiOS9Later (kSystemVersion >= 9)
#endif


#define DLWidth [UIScreen mainScreen].bounds.size.width

#define DLHeight [UIScreen mainScreen].bounds.size.height

#define DLScreen [UIScreen mainScreen].bounds.size.width/375.0

#define DLIphoneX_XS (DLWidth == 375.f && DLHeight == 812.f ? YES : NO)

#define DLIphoneXR_XSMax (DLWidth == 414.f && DLHeight == 896.f ? YES : NO)

#define DLFullScreen (DLIphoneX_XS || DLIphoneXR_XSMax)

#define DLStatusBarHeight (DLFullScreen ? 44.f : 20.f)

#define DLNavigationBarHeight 44.f

#define DLTabbarHeight (DLFullScreen ? (49.f+34.f) : 49.f)

#define DLTabbarSafeBottomMargin (DLFullScreen ? 34.f : 0.f)

#define DLStatusBarAndNavigationBarHeight (DLFullScreen ? 88.f : 64.f)




// 颜色
#define DLColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]

// 颜色+透明度
#define DLColorAlpha(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

// 根据rgbValue获取对应的颜色
#define DLColorFromRGB(__rgbValue) [UIColor colorWithRed:((float)((__rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((__rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(__rgbValue & 0xFF))/255.0 alpha:1.0]

#define DLColorFromRGBAlpha(rgbValue, a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]



/**
 Synthsize a dynamic object property in @implementation scope.
 It allows us to add custom properties to existing classes in categories.
 
 @param association  ASSIGN / RETAIN / COPY / RETAIN_NONATOMIC / COPY_NONATOMIC
 @warning #import <objc/runtime.h>
 *******************************************************************************
 Example:
     @interface NSObject (MyAdd)
     @property (nonatomic, retain) UIColor *myColor;
     @end
     
     #import <objc/runtime.h>
     @implementation NSObject (MyAdd)
     DLSYNTH_DYNAMIC_PROPERTY_OBJECT(myColor, setMyColor, RETAIN, UIColor *)
     @end
 */
#ifndef DLSYNTH_DYNAMIC_PROPERTY_OBJECT
#define DLSYNTH_DYNAMIC_PROPERTY_OBJECT(_getter_, _setter_, _association_, _type_) \
- (void)_setter_ : (_type_)object { \
    [self willChangeValueForKey:@#_getter_]; \
    objc_setAssociatedObject(self, _cmd, object, OBJC_ASSOCIATION_ ## _association_); \
    [self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
    return objc_getAssociatedObject(self, @selector(_setter_:)); \
}
#endif



/**
 Whether in main queue/thread.
 */
static inline bool dispatch_is_main_queue() {
    return pthread_main_np() != 0;
}

/**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
static inline void dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/**
 Submits a block for execution on a main queue and waits until the block completes.
 */
static inline void dispatch_sync_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}


#endif
