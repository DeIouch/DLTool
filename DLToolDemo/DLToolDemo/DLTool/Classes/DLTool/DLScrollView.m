#import "DLScrollView.h"
#import "UIView+Add.h"
#import "DLTimer.h"
#import "DLToolMacro.h"

//获取ScrollView的X值偏移量
#define contentOffSet_x self.scrollView.contentOffset.x
//获取ScrollView的宽度
#define frame_width self.scrollView.frame.size.width
//获取ScrollView的contentSize宽度
#define contentSize_x self.scrollView.contentSize.width

@interface DLScrollView()<UIScrollViewDelegate>

//轮播图片名字的数组
@property(strong,nonatomic) NSArray *imageArr;

@property (nonatomic, strong) UIPageControl *pageVC;

//自定义视图的数组
@property(strong,nonatomic) NSArray *viewArr;

//轮播的ScrollView
@property(strong,nonatomic) UIScrollView *scrollView;

@property(nonatomic, copy) void (^clickBlock) (NSInteger index);

@property (nonatomic, strong) NSString *timer;

@property (nonatomic, assign) BOOL isLoop;

@end

@implementation DLScrollView

+(DLScrollView *)scrollWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ImageArr:(NSArray *)imageNameArray AndImageClickBlock:(void (^)(NSInteger index))clickBlock{
    return [[DLScrollView alloc]initWithFrame:frame loop:isLoop loopSecond:second ImageArr:imageNameArray AndImageClickBlock:[clickBlock copy]];
}

-(instancetype)initWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ImageArr:(NSArray *)imageNameArray AndImageClickBlock:(void (^)(NSInteger index))clickBlock{
    if (self = [self initWithFrame:frame]) {
        self.scrollView.contentSize = CGSizeMake((imageNameArray.count+2)*frame.size.width,0);
        self.imageArr = imageNameArray;
        self.clickBlock = clickBlock;
        self.isLoop = isLoop;
        if (imageNameArray.count > 1) {
            self.pageVC.numberOfPages = imageNameArray.count;
        }
        if (isLoop && imageNameArray.count > 1) {
            @dl_weakify;
            self.timer = [DLTimer doTask:^{
                @dl_strongify;
                CGPoint currentConOffSet=self.scrollView.contentOffset;
                currentConOffSet.x+=frame_width;
                [UIView animateWithDuration:0.5 animations:^{
                    self.scrollView.contentOffset=currentConOffSet;
                }completion:^(BOOL finished) {
                    [self updataWhenFirstOrLast];
                }];
            } start:second interval:second repeats:YES async:NO];
        }
    }
    return self;
}

-(void)cancelLoop{
    [DLTimer cancelTask:self.timer];
}

+(DLScrollView *)scrollWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ViewArr:(NSArray *)customViewArr AndClickBlock:(void (^)(NSInteger index))clickBlock{
    return [[DLScrollView alloc]initWithFrame:frame loop:isLoop loopSecond:second ViewArr:customViewArr AndClickBlock:[clickBlock copy]];
}

-(instancetype)initWithFrame:(CGRect)frame loop:(BOOL)isLoop loopSecond:(NSInteger)second ViewArr:(NSArray *)customViewArr AndClickBlock:(void (^)(NSInteger index))clickBlock{
    if (self=[self initWithFrame:frame]) {
        self.scrollView.contentSize = CGSizeMake((customViewArr.count+2)*frame.size.width,0);
        self.viewArr=customViewArr;
        self.clickBlock=clickBlock;
        self.isLoop = isLoop;
        if (customViewArr.count > 1) {
            self.pageVC.numberOfPages=customViewArr.count;
        }
        if (isLoop && customViewArr.count > 1) {
            @dl_weakify;
            self.timer = [DLTimer doTask:^{
                @dl_strongify;
                CGPoint currentConOffSet=self.scrollView.contentOffset;
                currentConOffSet.x+=frame_width;
                [UIView animateWithDuration:0.5 animations:^{
                    self.scrollView.contentOffset=currentConOffSet;
                }completion:^(BOOL finished) {
                    [self updataWhenFirstOrLast];
                }];
                NSLog(@"1111");
            } start:second interval:second repeats:YES async:NO];
        }
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if(self=[super initWithFrame:frame]){
        self.scrollView=[[UIScrollView alloc]init];
        self.scrollView.delegate=self;
        self.scrollView.pagingEnabled=YES;
        self.scrollView.frame=self.bounds;
        self.scrollView.contentOffset=CGPointMake(frame.size.width, 0);
        self.scrollView.showsHorizontalScrollIndicator=NO;
        [self addSubview:self.scrollView];
    }
    return self;
}

-(UIPageControl *)pageVC{
    if (!_pageVC) {
        _pageVC = [[UIPageControl alloc]init];
        _pageVC.frame=CGRectMake(0,self.frame.size.height-30, self.frame.size.width, 30);
        [self addSubview:_pageVC];
    }
    return _pageVC;
}

#pragma mark 结束滚动代理
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self updataWhenFirstOrLast];
}

#pragma mark-=====================轮播页码改变=====================
#pragma mark 更新PageControl
-(void)updataPageControl{
    NSInteger index=(contentOffSet_x-frame_width)/frame_width;
    _pageVC.currentPage=index;
}

#pragma mark 重写图片名字的数组
-(void)setImageArr:(NSArray *)imageArr{
    _imageArr=imageArr;
    [self addImageToScrollView];
}

#pragma mark 重写自定义视图的数组
-(void)setViewArr:(NSArray *)viewArr{
    _viewArr=viewArr;
    [self addCustomViewToScrollView];
}

#pragma mark 根据自定义视图添加到ScrollView
-(void)addCustomViewToScrollView{
    NSMutableArray *imgMArr=[NSMutableArray arrayWithArray:self.viewArr];
    UIView *lastView=[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:[self.viewArr lastObject]]];
    [self imageCopy:[self.viewArr lastObject] To:lastView];
    [imgMArr insertObject:lastView atIndex:0];
    UIView *firstView=[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:[self.viewArr firstObject]]];
    [self imageCopy:[self.viewArr firstObject] To:firstView];
    [imgMArr addObject:firstView];
    NSInteger tag=-1;
    for (UIView *customView in imgMArr) {
        customView.frame=CGRectMake(self.frame.size.width*(tag+1), 0, self.frame.size.width, self.frame.size.height);
        customView.tag=tag;
        tag++;
        @dl_weakify;
        [customView addClickAction:^(UIView *view) {
            @dl_strongify;
            if(self.clickBlock){
                self.clickBlock(view.tag);
            }
        }];
        [self.scrollView addSubview:customView];
    }
}

#pragma mark 根据图片名添加图片到ScrollView
-(void)addImageToScrollView{
    NSMutableArray *imgMArr=[NSMutableArray arrayWithArray:self.imageArr];
    [imgMArr insertObject:[self.imageArr lastObject] atIndex:0];
    [imgMArr addObject:[self.imageArr firstObject]];
    NSInteger tag=-1;
    for (NSString *name in imgMArr) {
        UIImageView *imgView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:name]];
        if(imgView.image ==nil){
            imgView.dl_urlImageString(name);
            
        }
        imgView.frame=CGRectMake(self.frame.size.width*(tag+1), 0, self.frame.size.width, self.frame.size.height);
        imgView.tag=tag;
        tag++;
        @dl_weakify;
        [imgView addClickAction:^(UIView *view) {
            @dl_strongify;
            if(self.clickBlock){
                self.clickBlock(view.tag);
            }
        }];
        [self.scrollView addSubview:imgView];
    }
    _pageVC.numberOfPages=self.imageArr.count;
}

#pragma mark 递归图片
-(void)imageCopy:(id)obj To:(id)obj2{
    if([obj isKindOfClass:[UIImageView class]]){
        ((UIImageView *)obj2).image=((UIImageView *)obj).image;
    }
    if([obj isKindOfClass:[UIView class]]){
        UIView *view=(UIView *)obj;
        UIView *view2=(UIView *)obj2;
        for(int i=0;i<view.subviews.count;i++){
            [self imageCopy:view.subviews[i] To:view2.subviews[i]];
        }
    }
}

#pragma mark 判断是否第一或者最后一个图片,改变坐标
-(void)updataWhenFirstOrLast{
    if(contentOffSet_x>=contentSize_x-frame_width){
        self.scrollView.contentOffset=CGPointMake(frame_width, 0);
    }
    else if (contentOffSet_x<=0){
        self.scrollView.contentOffset=CGPointMake(contentSize_x-2*frame_width, 0);
    }
    [self updataPageControl];
}

@end
