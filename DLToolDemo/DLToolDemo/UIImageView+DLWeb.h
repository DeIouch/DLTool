#import <UIKit/UIKit.h>

@interface UIImageView (DLWeb)

@property (nonatomic, strong) NSString *urlString;

-(void)dl_setWebImage:(NSString *)urlStr;

@end
