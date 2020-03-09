#import "UIScrollView+AddAdd.h"
#import <objc/runtime.h>
#import "NSObject+Add.h"
#import "DLToolMacro.h"
#import "UIScrollView+Add.h"
@class FootFreshDefaultView;
@class HeadFreshDefaultView;
@class FreshBaseView;

static char headFreshKey;
static char footFreshKey;
static UIView *headFreshDefaultView;
static UIView *footFreshDefaultView;

@implementation FreshBaseView

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
        _titleArray = @[@"下拉可以刷新...",@"松开即可刷新...",@"刷新中..."];
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

-(instancetype)init;

@end

@implementation FootFreshDefaultView

-(instancetype)init{
    if ([super init]) {
        
    }
    return self;
}

@end




@interface UIScrollView()

@property (nonatomic, copy) void (^headFreshBlock) (void);

@property (nonatomic, copy) void (^footFreshBlock) (void);

@property (nonatomic, assign) CGFloat scrollViewOriginalInset;

@property (nonatomic, assign) BOOL needHeadFreshBOOL;

@property (nonatomic, assign) BOOL needFootFreshBOOL;

@end

@implementation UIScrollView (AddAdd)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        headFreshDefaultView = [[HeadFreshDefaultView alloc]initWithFrame:CGRectMake(0, 0, 0, 60)];
        footFreshDefaultView = [[FootFreshDefaultView alloc]initWithFrame:CGRectMake(0, 0, 0, 60)];
    });
}

-(void)headFreshBlock:(void (^)(void))block{
    self.headFreshBlock = block;
    if (!block) {
        return;
    }
    if (!self.needHeadFreshBOOL && !self.needFootFreshBOOL) {
        [self addContentOffsetKVO];
    }
}

-(void)addContentOffsetKVO{
    [self dl_addObserverBlockForKeyPath:@"contentOffset" block:^(id obj, id oldVal, id newVal) {
        if (obj != self) {
            return;
        }
        if (self.isDragging) {
            CGPoint point = [((NSValue *)[self valueForKey:@"contentOffset"]) CGPointValue];
            CGFloat distance = self.frame.size.height>self.contentSize.height?point.y:point.y+self.frame.size.height-self.contentSize.height;
            if (self.scrollViewOriginalInset == 999999999 && point.y == distance) {
                self.scrollViewOriginalInset = distance;
                return;
            }
            if (point.y > 0) {
                if (self.needFootFreshBOOL) {
                    return;
                }
                if (distance > 60) {
                    self.needFootFreshBOOL = YES;
                    self.footFreshBlock();
                }
            }else if (self.scrollViewOriginalInset - point.y > 60) {
                if (self.needHeadFreshBOOL) {
                    return;
                }
                
                
                
                
                self.needHeadFreshBOOL = YES;
                self.headFreshBlock();
            }
        }else{
            self.needFootFreshBOOL = NO;
            self.needHeadFreshBOOL = NO;
        }
    }];
}

-(void)footFreshBlock:(void (^)(void))block{
    self.footFreshBlock = block;
    if (!block) {
        return;
    }
    if (!self.needHeadFreshBOOL && !self.needFootFreshBOOL) {
        [self addContentOffsetKVO];
    }
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

+(void)setUpHeadFreshDefaultView:(FreshBaseView *)view{
    headFreshDefaultView = view;
}

+(void)setUpFootFreshDefaultView:(FreshBaseView *)view{
    footFreshDefaultView = view;
}
DLSYNTH_DYNAMIC_PROPERTY_OBJECT(headFreshView, setHeadFreshView, RETAIN_NONATOMIC, FreshBaseView *);

DLSYNTH_DYNAMIC_PROPERTY_OBJECT(footFreshView, setFootFreshView, RETAIN_NONATOMIC, FreshBaseView *);

@end
