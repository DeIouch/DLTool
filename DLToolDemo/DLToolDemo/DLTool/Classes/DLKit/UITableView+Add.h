#import <UIKit/UIKit.h>

//      UITableView高度自适应，不需要设置cell自适应高度

@interface UITableView (Add)

-(void)setCellHeight:(UITableViewCell *)cell WithIndex:(NSIndexPath *)index;

-(CGFloat)getCellHeightWithIndex:(NSIndexPath *)index;

@end
