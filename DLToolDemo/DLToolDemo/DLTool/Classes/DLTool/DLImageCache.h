#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DLImageCache : NSObject

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

+(void)loadImage:(UIImageView *)imageview imageUrl:(NSString *)imageUrl;

@end
