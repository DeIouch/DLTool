#import "UITableView+Add.h"
#import "DLToolMacro.h"

static char const tableViewHeightDicKey;

@interface UITableView ()

@property (nonatomic, strong) NSMutableDictionary *heightDic;

@end

@implementation UITableView (Add)

+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Safe_ExchangeMethod([self class], @selector(reloadData), @selector(dl_reloadData));
    });
}

-(void)dl_reloadData{
    [self.heightDic removeAllObjects];
    [self dl_reloadData];
}

-(void)setHeightDic:(NSMutableDictionary *)heightDic{
    objc_setAssociatedObject(self, &tableViewHeightDicKey, heightDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSMutableDictionary *)heightDic{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &tableViewHeightDicKey);
    if (!dic) {
        dic = [[NSMutableDictionary alloc]init];
        objc_setAssociatedObject(self, &tableViewHeightDicKey, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dic;
}

-(void)setCellHeight:(UITableViewCell *)cell WithIndex:(NSIndexPath *)index;{
    if ([[self.heightDic objectForKey:index] floatValue] == 0) {
        [self.heightDic setObject:@([cell systemLayoutSizeFittingSize:CGSizeMake(self.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height) forKey:index];
    }
}

-(CGFloat)getCellHeightWithIndex:(NSIndexPath *)index{
    CGFloat height = [[self.heightDic objectForKey:index] floatValue];
    return height > 0 ? height : UITableViewAutomaticDimension;
}

@end
