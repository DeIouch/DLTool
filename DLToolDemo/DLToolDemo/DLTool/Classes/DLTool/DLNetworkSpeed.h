//  网速监听


#import <Foundation/Foundation.h>

@interface DLNetworkSpeed : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@property (nonatomic, copy, readonly) NSString*downloadNetworkSpeed;

@property (nonatomic, copy, readonly) NSString *uploadNetworkSpeed;

+ (instancetype)shareInstance;
//开始监听
- (void)start;
//停止监听
- (void)stop;

@end
