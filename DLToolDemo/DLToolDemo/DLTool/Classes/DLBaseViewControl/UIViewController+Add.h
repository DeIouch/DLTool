#import <UIKit/UIKit.h>

@interface UIViewController (Add)

-(void)dl_presentVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^ __nullable)(void))completion;

-(void)dl_pushVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^ __nullable)(void))completion;

@end
