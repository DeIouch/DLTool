#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (DLSign)

//@property (nonatomic, assign) UIControlEvents controlEvents;

//-(void)setControlEvents:(UIControlEvents)controlEvents;

//-(void)dl_touchAction:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;



@end

@interface UIApplication (Add)

@property (nonatomic, readonly) NSURL *dl_documentsURL;

@property (nonatomic, readonly) NSString *dl_documentsPath;

@property (nonatomic, readonly) NSURL *dl_cachesURL;

@property (nonatomic, readonly) NSString *dl_cachesPath;

@property (nonatomic, readonly) NSURL *dl_libraryURL;

@property (nonatomic, readonly) NSString *dl_libraryPath;

@property (nullable, nonatomic, readonly) NSString *dl_appBundleName;

@property (nullable, nonatomic, readonly) NSString *dl_appBundleID;

@property (nullable, nonatomic, readonly) NSString *dl_appVersion;

@property (nullable, nonatomic, readonly) NSString *dl_appBuildVersion;

@property (nonatomic, readonly) BOOL dl_isPirated;

@property (nonatomic, readonly) BOOL dl_isBeingDebugged;

@property (nonatomic, readonly) int64_t dl_memoryUsage;

@property (nonatomic, readonly) float dl_cpuUsage;

-(void)dl_incrementNetworkActivityCount;

-(void)dl_decrementNetworkActivityCount;

+(BOOL)dl_isAppExtension;

+(nullable UIApplication *)sharedExtensionApplication;

@end

NS_ASSUME_NONNULL_END
