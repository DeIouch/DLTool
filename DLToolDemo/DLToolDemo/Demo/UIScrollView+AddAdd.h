#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    DLAnimationTypeNormal,
    DLAnimationTypeCircle,
    DLAnimationTypeSemiCircle,
    DLAnimationTypePoint,
    DLAnimationTypeStar,
} DLAnimationType;

@interface FreshBaseView : UIView

- (void)readyRefresh;

- (void)beginRefresh;

- (void)endRefresh;

@end

@interface UIScrollView (AddAdd)

-(void)headFreshBlock:(void (^)(void))block;

-(void)footFreshBlock:(void (^)(void))block;

/// 设置单个的刷新头视图
@property (nonatomic, strong) FreshBaseView *headFreshView;

/// 设置单个的刷新尾视图
@property (nonatomic, strong) FreshBaseView *footFreshView;

/// 设置默认的刷新头视图
/// @param view 默认的刷新头视图
+(void)setUpHeadFreshDefaultView:(FreshBaseView *)view;

/// 设置默认的刷新尾视图
/// @param view 默认的刷新尾视图
+(void)setUpFootFreshDefaultView:(FreshBaseView *)view;

@end
