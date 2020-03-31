#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - DLStackViewType

typedef NS_ENUM(NSUInteger, DLStackViewType) {
    /**
     *  水平对齐
     */
    DLStackViewTypeHorizontal = 1,
    /**
     *  垂直对齐
     */
    DLStackViewTypeVertical
};

@class DLAutoLayoutFactory;

#pragma mark - DLStackView class

@interface DLStackView : UIView

/**
 *  内边距
 */
@property (assign,nonatomic) UIEdgeInsets padding;

/**
 *  view之间的距离
 */
@property (assign,nonatomic) CGFloat space;

/**
 *  根据对齐类型进行布局
 *
 *  @param type DLStackViewTypeHorizontal or DLStackViewTypeVertical
 */
- (void)layoutWithType:(DLStackViewType)type;

@end

#pragma mark - DLAutoLayoutMaker class

@interface DLAutoLayoutMaker : NSObject

/*
 设置在superview里的距离
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^topSpace)(CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^leftSpace)(CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^bottomSpace)(CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^rightSpace)(CGFloat value);

/**
 *  设置在superview里的top,left,bottom,right的间距
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^edgeInsets)(UIEdgeInsets insets);

/**
 *  top,left,bottom,right与某一个view的top,left,bottom,right相等
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^edgeEqualTo)(UIView *view);

/*
 居中操作,\
 第一个参数是参考某一个view进行居中
 第二个参数是参考某一个view居中过后在加上多少距离
 例子:
 layout.centerByView(superview); //在父视图中居中
 layout.centerByView(superview,100.0);//在父视图中居中并且x,y在累加100的距离
 其他用法同上~!
 */
//参考某一个view进行水平居中
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^xCenterByView)(UIView *view,CGFloat value);
//参考某一个view进行垂直居中
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^yCenterByView)(UIView *view,CGFloat value);
//参考某一个view进行居中
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^centerByView)(UIView *view,CGFloat value);

/*
 边距和宽高带有 EqualTo 或者 ByView 结尾的方法都带有两个参数.
 第一个参数为其他view
 第二个参数为在此基础之上累加的数值, 可传递可不传递,默认0. 接收浮点型
 公式: view(第一个参数) + 值(第二个参数)
 */

/*
 设置距离其它view的间距, 两个参数
 @param view  其它view
 @param ... 距离多少间距
 公式: view(第一个参数) + 值(第二个参数)
 
 例子:
 layout.topSpaceByView(otherView); //上边距离参考其他view, 也就是在某一个view的下边
 layout.topSpaceByView(otherView,100);//上边距离参考其他view, 也就是在某一个view的下边并且在累加100的距离
 其他用法同上~!
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^topSpaceByView)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^leftSpaceByView)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^bottomSpaceByView)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^rightSpaceByView)(UIView *view,CGFloat value);

/*
 @param view 设置view的距离参照与某一个view.有两个参数, 第一个是view, 第二个是value
 @param ...第二个参数
 如果第二个参数value 为0, 则距离等同于参照view的距离.
 如果第二个参数value不为0, 则在参照的view的基础之上加上这个参数的值
 公式 : 其他view的距离 + value
 例子: 同上~!
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^topSpaceEqualTo)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^leftSpaceEqualTo)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^bottomSpaceEqualTo)(UIView *view,CGFloat value);
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^rightSpaceEqualTo)(UIView *view,CGFloat value);

/*
 设置宽高与其他view相等
 公式 : 其他view的宽或者高 + value
 @param view  其它view
 @param value 在参照的view的基础之上加上这个参数的值
 例子: 同上~!
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^widthEqualTo)(UIView *view,CGFloat value);
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^heightEqualTo)(UIView *view,CGFloat value);

/*
 设置宽高
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^widthValue)(CGFloat value);
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^heightValue)(CGFloat value);

/**
 根据文字自适应高度, 只针对UILabel控件生效. 最小值为0
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^autoHeight)(CGFloat value);

/**
 根据最小值进行文字自适应高度, 只针对UILabel控件生效.
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^autoHeightByMin)(CGFloat value);

/**
 根据文字自适应宽度, 只针对UILabel控件生效. 最小值为0
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^autoWidth)(CGFloat value);

/**
 根据最小值文字自适应宽度, 只针对UILabel控件生效.
 */
@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^autoWidthByMin)(CGFloat value);

/**
 *  优先级
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^priority)(UILayoutPriority priority);

/**
 *  倍数,原始值的多少倍,此函数只针对最后一次设置的约束生效,
 例如: layout.topSpace(10).leftSpace(10).widthEqualTo(view1).multiplier(0.5).heightValue(40);
 在这行代码里的倍数,只针对宽度生效,表示宽度是view1宽度的0.5倍.
 如果想给多个属性增加倍数,则在对应的后面写上multiplier属性即可
 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^multiplier)(CGFloat multiplier);

//init
- (instancetype)initWithView:(UIView *)view type:(id)type;

#pragma mark - deprecated apis

// ---------------- 以下是1.0以前的布局方式, 不推荐使用 -------------------

@property (strong, nonatomic, readonly) DLAutoLayoutMaker *top __deprecated_msg("use topSpace"); /**< 上边距 */
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *left __deprecated_msg("use leftSpace"); /**< 左边距 */
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *bottom __deprecated_msg("use bottomSpace"); /**< 下边距 */
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *right __deprecated_msg("use rightSpace"); /**< 右边距 */
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *leading __deprecated_msg("use leftSpace");
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *trailing __deprecated_msg("use rightSpace");

//居中
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *center __deprecated_msg("use centerByView");
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *centerX __deprecated_msg("use xCenterByView");
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *centerY __deprecated_msg("use yCenterByView");

@property (strong, nonatomic, readonly) DLAutoLayoutMaker *width __deprecated_msg("use widthValue"); /**< 宽度 */
@property (strong, nonatomic, readonly) DLAutoLayoutMaker *height __deprecated_msg("use heightValue"); /**< 高度 */

@property (strong, nonatomic, readonly) DLAutoLayoutMaker *edges __deprecated_msg("use edgeInsets"); /**< add top,left,bottom, right */

@property (strong, nonatomic, readonly) DLAutoLayoutMaker *with __deprecated_msg("不推荐使用");

//---- setting constraints
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^offset)(CGFloat offset) __deprecated_msg("不推荐使用"); /**< setting constant */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^equalTo)(id value) __deprecated_msg("不推荐使用"); /**< 如果是nsnumber类型就设置约束的值 , 如果是uiview类型就设置为相等于另一个view的约束 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^sizeOffset)(CGSize size) __deprecated_msg("不推荐使用"); /**< setting width,height */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^originOffset)(CGPoint origin) __deprecated_msg("不推荐使用"); /**< setting top,left */

@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^frameOffset)(CGRect frame) __deprecated_msg("不推荐使用");

@property (copy,nonatomic,readonly) DLAutoLayoutMaker *(^insets)(UIEdgeInsets insets) __deprecated_msg("不推荐使用");

//大于等于,小于等于
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^greaterThanOrEqual)(id value) __deprecated_msg("不推荐使用"); /**< 大于等于 */
@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^lessThanOrEqual)(id value) __deprecated_msg("不推荐使用"); /**< 小于等于 */

@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^equalToWithMultiplier)(id value,CGFloat multiplier) __deprecated_msg("不推荐使用");

@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^greaterThanOrEqualWithMultiplier)(id value,CGFloat multiplier) __deprecated_msg("不推荐使用");

@property (copy, nonatomic, readonly) DLAutoLayoutMaker *(^lessThanOrEqualWithMultiplier)(id value,CGFloat multiplier) __deprecated_msg("不推荐使用");

@end

#pragma mark - category UIView + DLAdditions

@interface UIView (DLAdditions)

//attributes
@property (nonatomic,strong,readonly) id dl_top __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_left __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_bottom __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_right __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_leading __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_trailing __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_width __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_height __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_centerX __deprecated_msg("不推荐使用");
@property (nonatomic,strong,readonly) id dl_centerY __deprecated_msg("不推荐使用");

//add
- (void)dl_addConstraints:(void(^)(DLAutoLayoutMaker *layout))layout;

//update
- (void)dl_updateConstraints:(void(^)(DLAutoLayoutMaker *layout))layout;

//print
- (void)dl_printConstraintsForSelf;

#pragma mark - 2.0 全新的APIS

/**
 *  添加布局
 *  示例：[view dl_addAutoLayouts:^{
                                     dl_layout_center(self.view),
                                     dl_layout_height(100),
                                     dl_layout_widthEqualTo(self.view).multiplier(0.5)
                                     }];
 *  @param block 装载的是DLAutoLayoutFactory对象，可通过 dl_layout_xxx 函数来获取，列如dl_layout_top | dl_layout_left | dl_layout_right | dl_layout_bottom 等等，详情请参照API。(参照 DLAutoLayout.h 文件的最底部为可用APIS)
 */
- (void)dl_addAutoLayouts:(void(^)(void))block;

/**
 *  更新布局(只能更新以添加过的约束)
 *  示例：[view dl_updateAutoLayouts:^{
                                     dl_layout_center(self.view,100),
                                     dl_layout_height(50),
                                     dl_layout_widthEqualTo(self.view).multiplier(0.8)
                                     }];
 *  @param block 装载的是DLAutoLayoutFactory对象，可通过 dl_layout_xxx 函数来获取，列如dl_layout_top | dl_layout_left | dl_layout_right | dl_layout_bottom 等等，详情请参照API。(参照 DLAutoLayout.h 文件的最底部为可用APIS)
 */
- (void)dl_updateAutoLayouts:(void(^)(void))block;

- (BOOL)dl_autoLayoutsForSelf:(NSLayoutAttribute)layoutAttribute;

/**
 *  根据子视图获取当前视图适合的高
 *
 *  @param view subview
 *
 *  @return height
 */
- (CGFloat)dl_fittingHeightWithSubview:(UIView *)view;

/**
 *  根据子视图获取当前视图适合的宽
 *
 *  @param view subview
 *
 *  @return width
 */
- (CGFloat)dl_fittingWidthWithSubview:(UIView *)view;

@end

#pragma mark - category UITableView + DLCellAutoHeight

@interface UITableView (DLCellAutoHeight)

/**
 *  cell的高度自适应, 在tableView: cellForRowAtIndexPath: 方法里请用
 [tableView dequeueReusableCellWithIdentifier:cellid];
 方式获取cell
 
 请不要使用
 [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
 会造成野指针错误
 *
 *  @param indexPath indexPath
 *
 *  @return 返回cell.contentView的子视图里 y+height 最大值的数值
 */
- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath;

/**
 *   cell的高度自适应, 在tableView: cellForRowAtIndexPath: 方法里请用
 [tableView dequeueReusableCellWithIdentifier:cellid];
 方式获取cell
 
 请不要使用
 [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
 会造成野指针错误
 *
 *  @param indexPath indexPath
 *  @param block     block
 *
 *  @return 返回block里return view的 y+height
 */
- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath bottomView:(UIView *(^)(__kindof UITableViewCell *cell))block;

/**
 *   cell的高度自适应, 在tableView: cellForRowAtIndexPath: 方法里请用
 [tableView dequeueReusableCellWithIdentifier:cellid];
 方式获取cell
 
 请不要使用
 [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
 会造成野指针错误
 *
 *  @param indexPath indexPath
 *  @param block     block
 *  @param space     space
 *
 *  @return 返回block里return view的 y+height+space
 */
- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath bottomView:(UIView *(^)(__kindof UITableViewCell *cell))block space:(CGFloat)space;;

/**
 *   cell的高度自适应, 在tableView: cellForRowAtIndexPath: 方法里请用
 [tableView dequeueReusableCellWithIdentifier:cellid];
 方式获取cell
 
 请不要使用
 [tableView dequeueReusableCellWithIdentifier:cellid forIndexPath:indexPath];
 会造成野指针错误
 *
 *  @param indexPath indexPath
 *  @param space     space
 *
 *  @return 返回cell.contentView的子视图里 y+height 最大值的数值 并且加上space参数的值
 */
- (CGFloat)dl_cellHeightWithindexPath:(NSIndexPath *)indexPath space:(CGFloat)space;

@end

@interface DLAutoLayoutFactory : NSObject

/**
 *  优先级
 */
@property (copy, nonatomic, readonly) DLAutoLayoutFactory *(^priority)(UILayoutPriority priority);

/**
 *  倍数
 */
@property (copy, nonatomic, readonly) DLAutoLayoutFactory *(^multiplier)(CGFloat multiplier);

@end

//-----------------------------------------------------

#pragma mark - 生产 dl_layout 的C函数

#pragma mark 约束值

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_top(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_left(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_right(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottom(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_width(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_height(CGFloat constant);

extern DLAutoLayoutFactory * dl_layout_edge(UIEdgeInsets insets);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_top(void);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_left(void);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_right(void);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottom(void);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_width(void);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_height(void);

extern DLAutoLayoutFactory * dl_layout_widthGreaterThanOrEqual(CGFloat constant);
extern DLAutoLayoutFactory * dl_layout_heightGreaterThanOrEqual(CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_center(UIView *secondView,CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_center(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_centerX(UIView *secondView,CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_centerX(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_centerY(UIView *secondView,CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_centerY(UIView *secondView);

#pragma mark 等同于参照view的约束

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_topEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_topEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_leftEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_leftEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottomEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottomEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_rightEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_rightEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_widthEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_widthEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_heightEqualTo(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_heightEqualTo(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_widthEqualToHeight(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_widthEqualToHeight(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_heightEqualToWidth(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_heightEqualToWidth(UIView *secondView);

#pragma mark 某一边距参照某一个view来设置

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_topByView(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_topByView(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_leftByView(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_leftByView(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottomByView(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_bottomByView(UIView *secondView);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_rightByView(UIView *secondView, CGFloat constant);

__attribute__((__overloadable__)) extern DLAutoLayoutFactory * dl_layout_rightByView(UIView *secondView);

