#import <UIKit/UIKit.h>

@interface UIViewController (Add)

-(void)dl_presentVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^)(void))completion;

-(void)dl_pushVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^)(void))completion;

@end
