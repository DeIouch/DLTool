#import <UIKit/UIKit.h>
#import "DLToolMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (Add)

+ (double)dl_systemVersion;

@property (nonatomic, readonly) BOOL dl_isPad;

@property (nonatomic, readonly) BOOL dl_isSimulator;

@property (nonatomic, readonly) BOOL dl_isJailbroken;

@property (nonatomic, readonly) BOOL dl_canMakePhoneCalls NS_EXTENSION_UNAVAILABLE_IOS("");

@property (nullable, nonatomic, readonly) NSString *dl_machineModel;

@property (nullable, nonatomic, readonly) NSString *dl_machineModelName;

@property (nonatomic, readonly) NSDate *dl_systemUptime;

@property (nullable, nonatomic, readonly) NSString *dl_ipAddressWIFI;

@property (nullable, nonatomic, readonly) NSString *dl_ipAddressCell;

typedef NS_OPTIONS(NSUInteger, DLNetworkTrafficType) {
    DLNetworkTrafficTypeWWANSent     = 1 << 0,
    DLNetworkTrafficTypeWWANReceived = 1 << 1,
    DLNetworkTrafficTypeWIFISent     = 1 << 2,
    DLNetworkTrafficTypeWIFIReceived = 1 << 3,
    DLNetworkTrafficTypeAWDLSent     = 1 << 4,
    DLNetworkTrafficTypeAWDLReceived = 1 << 5,
    
    DLNetworkTrafficTypeWWAN = DLNetworkTrafficTypeWWANSent | DLNetworkTrafficTypeWWANReceived,
    DLNetworkTrafficTypeWIFI = DLNetworkTrafficTypeWIFISent | DLNetworkTrafficTypeWIFIReceived,
    DLNetworkTrafficTypeAWDL = DLNetworkTrafficTypeAWDLSent | DLNetworkTrafficTypeAWDLReceived,
    
    DLNetworkTrafficTypeALL = DLNetworkTrafficTypeWWAN |
                              DLNetworkTrafficTypeWIFI |
                              DLNetworkTrafficTypeAWDL,
};

-(uint64_t)dl_getNetworkTrafficBytes:(DLNetworkTrafficType)types;

@property(nonatomic, readonly) int64_t dl_diskSpace;

@property(nonatomic, readonly) int64_t dl_diskSpaceFree;

@property(nonatomic, readonly) int64_t dl_diskSpaceUsed;

@property(nonatomic, readonly) int64_t dl_memoryTotal;

@property(nonatomic, readonly) int64_t dl_memoryUsed;

@property(nonatomic, readonly) int64_t dl_memoryFree;

@property(nonatomic, readonly) int64_t dl_memoryActive;

@property(nonatomic, readonly) int64_t dl_memoryInactive;

@property(nonatomic, readonly) int64_t dl_memoryWired;

@property(nonatomic, readonly) int64_t dl_memoryPurgable;

@property(nonatomic, readonly) NSUInteger dl_cpuCount;

@property(nonatomic, readonly) float dl_cpuUsage;

@property(nullable, nonatomic, readonly) NSArray<NSNumber *> *dl_cpuUsagePerProcessor;

@end

NS_ASSUME_NONNULL_END

