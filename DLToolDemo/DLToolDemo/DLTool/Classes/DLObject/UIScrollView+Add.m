#import "UIScrollView+Add.h"
#import <objc/runtime.h>
#import "NSObject+Add.h"
#import "DLToolMacro.h"
#import "UIView+Add.h"
@class FootFreshDefaultView;
@class HeadFreshDefaultView;
@class FreshBaseView;
@class CircleRefreshView;

#define ANIMATETIME 0.75
#define FRESHHEIGHT 60
#define LINEWIDTH 2
#define RADIUS 12

static char headFreshKey;
static char footFreshKey;
static FreshBaseView *headFreshDefaultView;
static FreshBaseView *footFreshDefaultView;
static dispatch_semaphore_t semaphore;

@implementation FreshBaseView

-(void)normalRefresh:(CGFloat)rate{};

- (void)readyRefresh{}
- (void)beginRefresh{}
- (void)endRefresh{}

@end

@interface HeadFreshDefaultView : FreshBaseView

@property (nonatomic, strong) NSArray <NSString *>*titleArray;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *label;

-(instancetype)initWithFrame:(CGRect)frame;

@end



@implementation HeadFreshDefaultView{
    BOOL isImageViewUp;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self configBaseView];
    }
    return self;
}

-(void)layoutSubviews{
    CGPoint indicatorcenterPoint = _indicator.center;
    indicatorcenterPoint.y = self.frame.size.height/2 + 8;
    indicatorcenterPoint.x = self.frame.size.width/2 - 50;
    _indicator.center = indicatorcenterPoint;
    CGPoint imageViewcenterPoint = _imageView.center;
    imageViewcenterPoint.y = self.frame.size.height/2 + 8;
    imageViewcenterPoint.x = self.frame.size.width/2 - 50;
    _imageView.center = imageViewcenterPoint;
    CGPoint labelcenterPoint = _label.center;
    labelcenterPoint.y = self.frame.size.height/2 + 8;
    _label.center = labelcenterPoint;
    CGRect rect = _label.frame;
    rect.origin.x = CGRectGetMaxX(_imageView.frame)+10;
    _label.frame = rect;
}

-(void)configBaseView{
    [self addSubview:self.indicator];
    [self addSubview:self.imageView];
    [self addSubview:self.label];
}

-(void)normalRefresh:(CGFloat)rate{
    if (isImageViewUp) {
        [UIView animateWithDuration:0.2 animations:^{
            self.imageView.transform =CGAffineTransformMakeRotation(0);
        }];
        isImageViewUp = NO;
    }
    _label.text = self.titleArray[0];
    _imageView.hidden = NO;
    _indicator.hidden = YES;
    [self.indicator stopAnimating];
}

-(void)readyRefresh{
    if (!isImageViewUp) {
        [UIView animateWithDuration:0.2 animations:^{
            self.imageView.transform = CGAffineTransformMakeRotation(M_PI);
        }];
        isImageViewUp = YES;
    }
    _label.text = self.titleArray[1];
    _imageView.hidden = NO;
    _indicator.hidden = YES;
}

-(void)beginRefresh{
    if (isImageViewUp) {
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.transform =CGAffineTransformIdentity;
        }];
        isImageViewUp = NO;
    }
    _indicator.hidden = NO;
    _imageView.hidden = YES;
    _label.text = self.titleArray[2];
    [self.indicator startAnimating];
}

-(void)endRefresh{
    isImageViewUp = NO;
    _imageView.hidden = NO;
    _label.text = self.titleArray[0];
    [self.indicator stopAnimating];
}

-(NSArray *)titleArray{
    if (!_titleArray) {
        _titleArray = @[@"下拉刷新...",@"松开即可刷新...",@"刷新中..."];
    }
    return _titleArray;
}

-(UIActivityIndicatorView *)indicator{
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicator.color = [[UIColor blackColor]colorWithAlphaComponent:0.5];
        _indicator.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }
    return _indicator;
}

-(UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
        _imageView.image =[UIImage imageNamed:@"common_refresh_arrow"];
        [_imageView sizeToFit];
    }
    return _imageView;
}

-(UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc]init];
        _label.textColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:14];
        _label.text = self.titleArray[0];
        [_label sizeToFit];
    }
    return _label;
}

@end

@interface FootFreshDefaultView : FreshBaseView

@property (nonatomic, strong) NSArray <NSString *>*titleArray;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *label;

-(instancetype)initWithFrame:(CGRect)frame;

@end

@implementation FootFreshDefaultView{
    BOOL isImageViewDown;
}

-(NSArray *)titleArray{
    if (!_titleArray) {
        _titleArray = @[@"上拉加载更多...",@"松手即可加载...",@"加载中..."];
    }
    return _titleArray;
}

-(UIActivityIndicatorView *)indicator{
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicator.color = [[UIColor blackColor]colorWithAlphaComponent:0.5];
        _indicator.transform = CGAffineTransformMakeScale(0.9, 0.9);
    }
    return _indicator;
}

-(UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc]init];
        _imageView.image = [self refreshImageBottom];
        [_imageView sizeToFit];
        _imageView.transform =CGAffineTransformMakeRotation(M_PI);
    }
    return _imageView;
}

-(UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc]init];
        _label.textColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:14];
        _label.text = self.titleArray[0];
        [_label sizeToFit];
    }
    return _label;
}

-(UIImage *)refreshImageBottom{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"refreshmImages.bundle" ofType:nil];
    NSString *placeholdPath = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"common_refresh_arrow@3x.png" ofType:nil];
    return [UIImage imageWithContentsOfFile:placeholdPath];
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self configBaseView];
    }
    return self;
}

-(void)layoutSubviews{
    CGPoint indicatorcenterPoint = _indicator.center;
    indicatorcenterPoint.y = self.frame.size.height/2;
    indicatorcenterPoint.x = self.frame.size.width/2 - 50;
    _indicator.center = indicatorcenterPoint;
    CGPoint imageViewcenterPoint = _imageView.center;
    imageViewcenterPoint.y = self.frame.size.height/2;
    imageViewcenterPoint.x = self.frame.size.width/2 - 50;
    _imageView.center = imageViewcenterPoint;
    CGPoint labelcenterPoint = _label.center;
    labelcenterPoint.y = self.frame.size.height/2;
    _label.center = labelcenterPoint;
    CGRect rect = _label.frame;
    rect.origin.x = CGRectGetMaxX(_imageView.frame)+10;
    _label.frame = rect;
}

-(void)configBaseView{
    [self addSubview:self.indicator];
    [self addSubview:self.imageView];
    [self addSubview:self.label];
}

-(void)normalRefresh:(CGFloat)rate{
    if (isImageViewDown) {
        [UIView animateWithDuration:0.2 animations:^{
            self.imageView.transform =CGAffineTransformMakeRotation(M_PI);;
        }];
        isImageViewDown = NO;
    }
    _label.text = self.titleArray[0];
    _imageView.hidden = NO;
    _indicator.hidden = YES;
    [self.indicator stopAnimating];
}

-(void)readyRefresh{
    if (!isImageViewDown) {
        [UIView animateWithDuration:0.2 animations:^{
            self.imageView.transform = CGAffineTransformMakeRotation(0);
        }];
        isImageViewDown = YES;
    }
    _label.text = self.titleArray[1];
    _imageView.hidden = NO;
    _indicator.hidden = YES;
}

-(void)beginRefresh{
    if (isImageViewDown) {
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.transform =CGAffineTransformMakeRotation(M_PI);
        }];
        isImageViewDown = NO;
    }
    _indicator.hidden = NO;
    _imageView.hidden = YES;
    _label.text = self.titleArray[2];
    [self.indicator startAnimating];
}

-(void)endRefresh{
    isImageViewDown = NO;
    _imageView.hidden = NO;
    _label.text = self.titleArray[0];
    [self.indicator stopAnimating];
}

@end

@interface UIScrollView()

@property (nonatomic, copy) void (^headFreshBlock) (void);

@property (nonatomic, copy) void (^footFreshBlock) (void);

@property (nonatomic, assign) CGFloat scrollViewOriginalInset;

@property (nonatomic, assign) BOOL needHeadFreshBOOL;

@property (nonatomic, assign) BOOL needFootFreshBOOL;

@property (nonatomic, assign) int insetCount;

@property (nonatomic, assign) int tableViewCellCount;

@end

@implementation UIScrollView (Add)

-(void)dl_scrollToTopAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.y = 0 - self.contentInset.top;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToBottomAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.y = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToLeftAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.x = 0 - self.contentInset.left;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToRightAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
    [self setContentOffset:off animated:animated];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headFreshDefaultView = [[HeadFreshDefaultView alloc]initWithFrame:CGRectMake(0, -FRESHHEIGHT, DLWidth, FRESHHEIGHT)];
        headFreshDefaultView.hidden = YES;
        headFreshDefaultView.backgroundColor = [UIColor whiteColor];
        footFreshDefaultView = [[FootFreshDefaultView alloc]initWithFrame:CGRectMake(0, -FRESHHEIGHT, DLWidth, FRESHHEIGHT)];
        footFreshDefaultView.hidden = YES;
        footFreshDefaultView.backgroundColor = [UIColor whiteColor];
        semaphore = dispatch_semaphore_create(1);
    });
}

-(void)headFreshBlock:(void (^)(void))block{
    self.headFreshBlock = block;
    [self addContentOffsetKVO];
    [self addContentSizeKVO];
    [self addSubview:headFreshDefaultView];
}

-(void)footFreshBlock:(void (^)(void))block{
    self.footFreshBlock = block;
    [self addContentOffsetKVO];
    [self addContentSizeKVO];
    [self addSubview:footFreshDefaultView];
}

-(void)addContentSizeKVO{
    [self dl_addObserverBlockForKeyPath:@"contentSize" block:^(id obj, id oldVal, id newVal) {
        if (obj != self) {
            return;
        }
        CGSize size = [((NSValue *)[self valueForKey:@"contentSize"]) CGSizeValue];
        footFreshDefaultView.frame = CGRectMake(0, size.height > self.frame.size.height ? size.height : self.frame.size.height, DLWidth, FRESHHEIGHT);
        if ([self isKindOfClass:UITableView.class]) {
            UITableView *tableView = (UITableView *)self;
            if (tableView.numberOfSections == 1 && [tableView numberOfRowsInSection:0] == 0 && self.tableViewCellCount != 0) {
                self.tableViewCellCount = 0;
                [tableView addSubview:self.emptyView];
                self.emptyView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
                return;
            }else if(self.tableViewCellCount == 0){
                if ([tableView numberOfRowsInSection:0] != 0) {
                    self.tableViewCellCount = 1;                    
                    [self.emptyView removeFromSuperview];
                    return;
                }
                NSInteger number = tableView.numberOfSections;
                for (NSInteger a = 0; a < number; a++) {
                    if ([tableView numberOfRowsInSection:a] > 0) {
                        self.tableViewCellCount = 1;
                        [self.emptyView removeFromSuperview];
                        return;
                    }
                }
            }
        }
    }];
}

-(void)addContentOffsetKVO{
    [self dl_addObserverBlockForKeyPath:@"contentOffset" block:^(id obj, id oldVal, id newVal) {
        if (obj != self) {
            return;
        }
        CGPoint point = [((NSValue *)[self valueForKey:@"contentOffset"]) CGPointValue];
        CGFloat distance = self.frame.size.height>self.contentSize.height?point.y:point.y+self.frame.size.height-self.contentSize.height;
        if (self.insetCount == 5) {
            self.scrollViewOriginalInset = point.y;
        }
        self.insetCount ++;
        if (self.isDragging) {
            if (point.y > 0) {
                if (self.footFreshBlock) {
                    if (!self.needFootFreshBOOL) {
                        if (distance < FRESHHEIGHT) {
                            footFreshDefaultView.hidden = NO;
                            [footFreshDefaultView normalRefresh:0];
                        }else{
                            [footFreshDefaultView beginRefresh];
                            self.needFootFreshBOOL = YES;
                        }
                    }
                }
            }else if (self.scrollViewOriginalInset - point.y > 0) {
                if (self.headFreshBlock) {
                    if (!self.needHeadFreshBOOL) {
                        headFreshDefaultView.hidden = NO;
                        if (self.scrollViewOriginalInset - point.y < FRESHHEIGHT) {
                            [headFreshDefaultView normalRefresh:0];
                        }else{
                            [headFreshDefaultView beginRefresh];
                            self.contentInset = UIEdgeInsetsMake(self.contentInset.top + 40, self.contentInset.left, self.contentInset.bottom, self.contentInset.right);
                            self.needHeadFreshBOOL = YES;
                        }
                    }
                }
            }
        }else{
            if (self.needHeadFreshBOOL) {
                self.needHeadFreshBOOL = NO;
                [headFreshDefaultView readyRefresh];
                self.headFreshBlock();
                [headFreshDefaultView endRefresh];
            }else if (self.needFootFreshBOOL) {
                self.needFootFreshBOOL = NO;
                [footFreshDefaultView readyRefresh];
                self.footFreshBlock();
                [footFreshDefaultView endRefresh];
            }
            headFreshDefaultView.hidden = YES;
            footFreshDefaultView.hidden = YES;
        }
    }];
}

#pragma mark    set get
-(void (^)(void))footFreshBlock{
    return objc_getAssociatedObject(self, &footFreshKey);
}

-(void)setFootFreshBlock:(void (^)(void))footFreshBlock{
    objc_setAssociatedObject(self, &footFreshKey, footFreshBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(void)setHeadFreshBlock:(void (^)(void))headFreshBlock{
    objc_setAssociatedObject(self, &headFreshKey, headFreshBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(void (^)(void))headFreshBlock{
    return objc_getAssociatedObject(self, &headFreshKey);
}

-(CGFloat)scrollViewOriginalInset{
    CGFloat cValue = {999999999};
    NSValue *value = objc_getAssociatedObject(self, @selector(setScrollViewOriginalInset:));
    [value getValue:&cValue];
    return cValue;
}

-(void)setScrollViewOriginalInset:(CGFloat)objc{
    [self willChangeValueForKey:@"scrollViewOriginalInset"];
    NSValue *value = [NSValue value:&objc withObjCType:@encode(CGFloat)];
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"scrollViewOriginalInset"];
}

-(BOOL)needHeadFreshBOOL{
    BOOL cValue = {NO};
    NSValue *value = objc_getAssociatedObject(self, @selector(setNeedHeadFreshBOOL:));
    [value getValue:&cValue];
    return cValue;
}

-(void)setNeedHeadFreshBOOL:(BOOL)needHeadFreshBOOL{
    [self willChangeValueForKey:@"needHeadFreshBOOL"];
    NSValue *value = [NSValue value:&needHeadFreshBOOL withObjCType:@encode(BOOL)];
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"needHeadFreshBOOL"];
}

-(BOOL)needFootFreshBOOL{
    BOOL cValue = {NO};
    NSValue *value = objc_getAssociatedObject(self, @selector(setNeedFootFreshBOOL:));
    [value getValue:&cValue];
    return cValue;
}

-(void)setNeedFootFreshBOOL:(BOOL)needFootFreshBOOL{
    [self willChangeValueForKey:@"needFootFreshBOOL"];
    NSValue *value = [NSValue value:&needFootFreshBOOL withObjCType:@encode(BOOL)];
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"needFootFreshBOOL"];
}

-(int)insetCount{
    int cValue = {0};
    NSValue *value = objc_getAssociatedObject(self, @selector(setInsetCount:));
    [value getValue:&cValue];
    return cValue;
}

-(void)setInsetCount:(int)insetCount{
    [self willChangeValueForKey:@"insetCount"];
    NSValue *value = [NSValue value:&insetCount withObjCType:@encode(int)];
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"insetCount"];
}

-(int)tableViewCellCount{
    int cValue = {1};
    NSValue *value = objc_getAssociatedObject(self, @selector(setTableViewCellCount:));
    [value getValue:&cValue];
    return cValue;
}

-(void)setTableViewCellCount:(int)tableViewCellCount{
    [self willChangeValueForKey:@"tableViewCellCount"];
    NSValue *value = [NSValue value:&tableViewCellCount withObjCType:@encode(int)];
    objc_setAssociatedObject(self, _cmd, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"tableViewCellCount"];
}

+(void)setUpHeadFreshDefaultView:(FreshBaseView *)view{
    headFreshDefaultView = view;
}

+(void)setUpFootFreshDefaultView:(FreshBaseView *)view{
    footFreshDefaultView = view;
}
DLSYNTH_DYNAMIC_PROPERTY_OBJECT(headFreshView, setHeadFreshView, RETAIN_NONATOMIC, FreshBaseView *);

DLSYNTH_DYNAMIC_PROPERTY_OBJECT(footFreshView, setFootFreshView, RETAIN_NONATOMIC, FreshBaseView *);

DLSYNTH_DYNAMIC_PROPERTY_OBJECT(emptyView, setEmptyView, RETAIN_NONATOMIC, UIView *);

@end
