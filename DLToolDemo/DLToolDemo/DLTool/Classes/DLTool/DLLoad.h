#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DLLoadType) {
    LoadShowing     = 1,    //  加载中
    LoadSuccess     = 2,    //  加载成功
    LoadFailed      = 3,    //  加载失败
};

@interface DLLoad : NSObject

+(DLLoad *)shareInstance;

-(void)showLoadTitle:(NSString *)titleString loadType:(DLLoadType)loadType backView:(UIView *)backView;

-(void)viewHidden;

@property (nonatomic, assign) BOOL loadShowBOOL;

@end
