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

#endif
