#import <UIKit/UIKit.h>
#import "DLConstraintMaker.h"
@class DefaulterImage;

@interface UIView (Add)

+(instancetype)dl_view:(void (^) (UIView *view))block;

@property (nonatomic, strong) NSString *identifierStr;

-(void)dl_AutoLayout:(void (^)(DLConstraintMaker *make))block;

-(void)dl_remove_allLayout;

@property (nonatomic) CGFloat left_dl;

@property (nonatomic) CGFloat top_dl;

@property (nonatomic) CGFloat right_dl;

@property (nonatomic) CGFloat bottom_dl;

@property (assign,nonatomic) CGFloat x_dl;

@property (assign,nonatomic) CGFloat y_dl;

@property (nonatomic, assign) CGSize size_dl;

@property (nonatomic, assign) CGPoint origin_dl;

@property (nonatomic, assign) CGFloat centerX_dl;

@property (nonatomic, assign) CGFloat centerY_dl;

@property (nonatomic, assign) CGFloat width_dl;

@property (nonatomic, assign) CGFloat height_dl;

@property (nonatomic, assign ,readonly) CGFloat maxX_dl;

@property (nonatomic, assign ,readonly) CGFloat maxY_dl;

@property (nonatomic, assign ,readonly) CGFloat minX_dl;

@property (nonatomic, assign ,readonly) CGFloat minY_dl;

@property (nonatomic, assign ,readonly) CGFloat midX_dl;

@property (nonatomic, assign ,readonly) CGFloat midY_dl;


/// 获取view的高
/// @param view view的高
-(CGFloat)dl_fittingHeight:(UIView *)view;

/// 获取view的宽
/// @param view view的宽
-(CGFloat)dl_fittingWidth:(UIView *)view;

- (CGFloat)dl_fittingHeightWithSubview:(UIView *)view;

/// 查找两个view的公共父视图
/// @param view 公共父视图
-(instancetype)getCommonSuperView:(UIView *)view;

-(UIViewController *)fatherViewController;

/// 背景颜色
-(UIView *(^) (NSString *color))dl_backColor;

/// 暗黑模式的背景颜色
-(UIView *(^) (NSString *color))dl_dark_backColor;

-(UIView *(^) (UIView *view))dl_backView;


#pragma mark 圆角

-(UIView *(^) (CGFloat radius))dl_topLeftCorner;

-(UIView *(^) (CGFloat radius))dl_bottomLeftCorner;

-(UIView *(^) (CGFloat radius))dl_topRightCorner;

-(UIView *(^) (CGFloat radius))dl_bottomRightCorner;

-(UIView *(^) (CGFloat radius))dl_allCorner;

-(UIView *)dl_viewShow;

-(void)dl_viewHidden:(float)delay;

-(void)dl_cancelFadeOut;



//-(UIView *(^) (NSString *imageString))dl_urlReduceImageString;
//
//-(UIView *(^) (NSString *imageString))dl_urlImageString;

/**
 设置imageview图片，也可当作占位图设置
 */
-(UIView *(^) (NSString *imageString))dl_imageString;



#pragma mark UIButton
/**
 按钮文字
 */
-(UIView *(^)(NSString *title))dl_normalTitle;

/**
 按钮选中的文字
 */
-(UIView *(^)(NSString *title))dl_selectTitle;

/**
 按钮高亮时的文字
 */
-(UIView *(^)(NSString *title))dl_highlightTitle;

/**
 按钮的字体大小
 */
-(UIView *(^)(CGFloat fontSize))dl_fontSize;

/**
 按钮普通状态下的图片
 */
-(UIView *(^)(NSString *image))dl_normalImage;

/**
 按钮选中状态下的图片
 */
-(UIView *(^)(NSString *image))dl_selectImage;

/**
 按钮高亮状态下的图片
 */
-(UIView *(^)(NSString *image))dl_highlightImage;

/**
 按钮普通状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_normalTitleColor;

/**
 按钮选中状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_selectTitleColor;

/**
 按钮高亮状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_highlightTitleColor;

/**
 按钮普通状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_dark_normalTitleColor;

/**
 按钮选中状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_dark_selectTitleColor;

/**
 按钮高亮状态下的文字颜色
 */
-(UIView *(^)(NSString *color))dl_dark_highlightTitleColor;


#pragma mark UILabel
/**
 设置文字
 */
-(UIView *(^) (NSString *title))dl_text;

/**
 设置文字颜色
 */
-(UIView *(^) (NSString *color))dl_textColor;

/**
 设置文字颜色
 */
-(UIView *(^) (NSString *color))dl_dark_textColor;

/**
 设置对齐方式
 */
-(UIView *(^) (NSTextAlignment alignment))dl_alignment;

/**
 设置行数
 */
-(UIView *(^) (NSInteger lines))dl_lines;

/**
设置跑马灯
*/
-(UIView *(^) (CGFloat speed))dl_animationSpeed;

#pragma mark 点击事件相关
/**
设置点击范围
*/
-(UIView *(^)(CGFloat size))dl_clickEdge;

/**
设置点击范围
*/
-(UIView *(^)(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left))dl_clickFrame;

/**
设置点击间隔
 */
-(UIView *(^)(NSTimeInterval time))dl_clickTime;



/**
 添加点击事件
 */
- (void)addClickAction:(void (^)(UIView *view))block;

/**
 添加长按事件
 */
- (void)addLongClickAction:(void (^)(UIView *view))block;



-(UIImage *)dl_snapshotImage;

-(UIImage *)dl_snapshotImageAfterScreenUpdates:(BOOL)afterUpdates;

-(NSData *)dl_snapshotPDF;

-(CGPoint)dl_convertPoint:(CGPoint)point toViewOrWindow:(UIView *)view;

-(CGPoint)dl_convertPoint:(CGPoint)point fromViewOrWindow:(UIView *)view;

-(CGRect)dl_convertRect:(CGRect)rect toViewOrWindow:(UIView *)view;

-(CGRect)dl_convertRect:(CGRect)rect fromViewOrWindow:(UIView *)view;

@end

@interface DefaulterImage : UIImage

+(UIImage *)createDefaulterImage:(UIImageView *)imageView;

@end


@interface UIButton(Add)

+(instancetype)dl_view:(void (^) (UIButton *button))block;

@end

@interface UITextField(Add)

+(instancetype)dl_view:(void (^) (UITextField *textField))block;

-(void)editChange:(void (^)(UITextField *textField))block;

-(void)editBegin:(void (^)(UITextField *textField))block;

-(void)editEnd:(void (^)(UITextField *textField))block;

-(void)editExit:(void (^)(UITextField *textField))block;

@end

@interface UIImageView(Add)

+(instancetype)dl_view:(void (^) (UIImageView *imageView))block;

@end

@interface UILabel(Add)

+(instancetype)dl_view:(void (^) (UILabel *label))block;

@end

@interface UITextView(Add)

+(instancetype)dl_view:(void (^) (UITextView *textView))block;

@end
