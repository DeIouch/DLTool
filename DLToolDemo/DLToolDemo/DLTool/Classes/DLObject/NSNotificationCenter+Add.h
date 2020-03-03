#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNotificationCenter (Add)

-(void)dl_postNotificationOnMainThread:(NSNotification *)notification;

-(void)dl_postNotificationOnMainThread:(NSNotification *)notification waitUntilDone:(BOOL)wait;

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(nullable id)object;

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

-(void)dl_postNotificationOnMainThreadWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo waitUntilDone:(BOOL)wait;

@end

NS_ASSUME_NONNULL_END
