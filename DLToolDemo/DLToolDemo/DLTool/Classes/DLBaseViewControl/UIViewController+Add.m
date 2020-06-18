#import "UIViewController+Add.h"

@implementation UIViewController (Add)

-(void)dl_presentVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^ __nullable)(void))completion{
    Class vcClass = NSClassFromString(vc);
    if (vcClass != nil) {
        UIViewController *popVC = [[vcClass alloc]init];
        NSArray *allKey = parameters.allKeys;
        for (NSString *key in allKey) {
            @try {
                [popVC setValue:parameters[key] forKey:key];
            }
            @catch (NSException *exception) {}
        }
        [self presentViewController:popVC animated:YES completion:completion];
    }else{
        NSLog(@"类不存在");
    }
}

-(void)dl_pushVC:(NSString *)vc parameters:(NSDictionary *)parameters completion:(void (^ __nullable)(void))completion{
    Class vcClass = NSClassFromString(vc);
    if (vcClass != nil) {
        UIViewController *popVC = [[vcClass alloc]init];
        NSArray *allKey = parameters.allKeys;
        for (NSString *key in allKey) {
            @try {
                [popVC setValue:parameters[key] forKey:key];
            }
            @catch (NSException *exception) {}
        }
        [self.navigationController pushViewController:popVC animated:YES];
        if (completion) {
            completion();
        }
    }else{
        NSLog(@"类不存在");
    }
}

+(UIViewController *)dl_getRootViewController{
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    return window.rootViewController;
}

@end
