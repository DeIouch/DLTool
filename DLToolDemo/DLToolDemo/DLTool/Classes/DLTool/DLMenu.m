#import "DLMenu.h"
#import <UIKit/UIKit.h>
#import "UIView+Add.h"
#import "UIView+Layout.h"

@interface DLMenuCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation DLMenuCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if ([super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.titleLabel = [UILabel dl_view:^(UILabel *label) {
            label.dl_backView(self.contentView).dl_backColor(@"FFFFFF").dl_alignment(NSTextAlignmentCenter).dl_fontSize(16).dl_textColor(@"000000");
        }];
        self.titleLabel.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 60, 40);
    }
    return self;
}

@end

@interface DLMenuView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *array;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *backview;

@property (nonatomic, copy) void (^selectMenuBlock) (NSInteger target);

@end

@implementation DLMenuView

-(instancetype)init{
    if ([super init]) {
        self.backgroundColor = [[UIColor colorWithRed:16/255.0 green:16/255.0 blue:16/255.0 alpha:1] colorWithAlphaComponent:0.6];
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
        [window addSubview:self];
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        self.backview = [UIView dl_view:^(UIView *view) {
            view.dl_backView(self).dl_backColor(@"FFFFFF");
        }];
        
        self.backview.dl_layout(DL_Left | DL_Right).equal(self).offset(20).dl_layout(DL_CenterX).equal(self).dl_layout(DL_Top).equal_to(self).offset(0);
        
//        [self.backview dl_AutoLayout:^(DLConstraintMaker *make) {
//            make.left.equal(self).offset(20);
//            make.right.equal(self).offset(-20);
//            make.top.equal(self).to(DLAttributeBottom).offset(0);
//            make.centerX.equal(self);
//        }];
        
        self.tableView = [[UITableView alloc]init];
        [self.backview addSubview:self.tableView];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor whiteColor];
        
        self.tableView.dl_layout(DL_Left | DL_Right | DL_Bottom | DL_Top).offset(0);
        
//        [self.tableView dl_AutoLayout:^(DLConstraintMaker *make) {
//            make.left.offset(0);
//            make.right.offset(0);
//            make.top.offset(0);
//            make.bottom.offset(0);
//        }];
    }
    return self;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self menuHidden];
}

-(void)menuHidden{
    [UIView animateWithDuration:0.15 animations:^{
//        [self.backview dl_AutoLayout:^(DLConstraintMaker *make) {
//            make.bottom.remove();
//            make.top.equal(self).to(DLAttributeBottom).offset(0);
//        }];
        
        self.backview.dl_remove_layout(DL_Bottom).dl_layout(DL_Top).equal_to(self).offset(0);
        
        [self layoutIfNeeded];
        [self dl_viewHidden:0.2];
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 40;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DLMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DLMenuCell"];
    if (!cell) {
        cell = [[DLMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DLMenuCell"];
    }
    cell.titleLabel.text = self.array[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row != (self.array.count - 1)) {
        if (self.selectMenuBlock) {
            self.selectMenuBlock(indexPath.row);
        }
    }
    [self menuHidden];
}
@end


@interface DLMenu()

@property (nonatomic, strong) DLMenuView *menuView;

@property (nonatomic, strong) NSMutableArray *array;

@end

@implementation DLMenu

+(DLMenu *)createDLMenuWithTitleArray:(NSMutableArray *)array selectBlock:(void(^)(NSInteger target))block{
    DLMenu *dlMenu = [DLMenu shareInstance];
    NSMutableArray *tempArray = [[NSMutableArray alloc]initWithArray:array];
    [tempArray addObject:@"取消"];
    dlMenu.menuView.array = tempArray;
    if (tempArray.count * 40 > [UIScreen mainScreen].bounds.size.height * 0.5) {
        dlMenu.menuView.tableView.scrollEnabled = YES;
    }else{
        dlMenu.menuView.tableView.scrollEnabled = NO;
    }
    [UIView animateWithDuration:0.2 animations:^{
//        [dlMenu.menuView.backview dl_AutoLayout:^(DLConstraintMaker *make) {
//            make.top.remove();
//            make.bottom.offset(-10);
//            make.height.offset(tempArray.count * 40 > [UIScreen mainScreen].bounds.size.height * 0.5 ? [UIScreen mainScreen].bounds.size.height * 0.5 : tempArray.count * 40);
//        }];
        
        dlMenu.menuView.dl_remove_layout(DL_Top).dl_layout(DL_Bottom).offset(10).dl_layout(DL_Height).offset(tempArray.count * 40 > [UIScreen mainScreen].bounds.size.height * 0.5 ? [UIScreen mainScreen].bounds.size.height * 0.5 : tempArray.count * 40);
        [dlMenu.menuView layoutIfNeeded];
    }];
    
    [dlMenu.menuView.tableView reloadData];
    dlMenu.menuView.selectMenuBlock = block;
    [dlMenu.menuView dl_viewShow];
    dlMenu.menuView.backview.dl_allCorner(5);
    return dlMenu;
}

static DLMenu *menu = nil;
+(DLMenu *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menu = [[DLMenu alloc] _init];
        [menu.menuView layoutIfNeeded];
    });
    return menu;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menu = [super allocWithZone:zone];
    });
    return menu;
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return menu;
}

- (instancetype)mutableCopyWithZone:(nullable NSZone *)zone {
    return [self copyWithZone:zone];
}

-(DLMenuView *)menuView{
    if (!_menuView) {
        _menuView = [[DLMenuView alloc]init];
    }
    return _menuView;
}

-(instancetype)_init{
    self = [super init];
    return self;
}

@end
