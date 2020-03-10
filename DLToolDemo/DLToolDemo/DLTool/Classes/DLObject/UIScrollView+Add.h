#import <UIKit/UIKit.h>

@interface FreshBaseView : UIView

-(void)normalRefresh:(CGFloat)rate;

-(void)readyRefresh;

-(void)beginRefresh;

-(void)endRefresh;

@end

@interface UIScrollView (Add)

-(void)dl_scrollToTopAnimated:(BOOL)animated;

-(void)dl_scrollToBottomAnimated:(BOOL)animated;

-(void)dl_scrollToLeftAnimated:(BOOL)animated;

-(void)dl_scrollToRightAnimated:(BOOL)animated;


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
