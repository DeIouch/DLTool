#import <UIKit/UIKit.h>

@interface DLLayout : NSObject

@property (nonatomic, weak) UIView *firstView;

@property (nonatomic, weak) id item;

@property (nonatomic, weak) UIView *secondView;

@property (nonatomic, assign) CGFloat constant;

@property (nonatomic, assign) CGFloat multiplied;

@property (nonatomic, assign) NSLayoutAttribute firstAttribute;

@property (nonatomic, assign) NSLayoutAttribute secondAttribute;

@property (nonatomic, assign) NSLayoutRelation layoutRelation;

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, strong) NSLayoutConstraint *constraint;

-(DLLayout *(^)(UIView *view))equal;

-(DLLayout *(^)(CGFloat constant))offset;

@property (nonatomic, assign) BOOL hasInstall;

@property (nonatomic, assign) BOOL needInstall;

@property (nonatomic, assign) BOOL needDelete;

@end

@interface DLLayoutMark : NSObject

@property (nonatomic, assign) BOOL needInstall;

@property (nonatomic, strong) DLLayout *leftConstraint;

@property (nonatomic, strong) DLLayout *rightConstraint;

@property (nonatomic, strong) DLLayout *topConstraint;

@property (nonatomic, strong) DLLayout *bottomConstraint;


-(DLLayoutMark *(^)(UIView *view))equal;

-(DLLayoutMark *(^)(CGFloat constant))offset;

-(DLLayoutMark *(^)(CGFloat constant))multipliedBy;

@property (nonatomic, strong) NSMutableArray *array;

-(void)install;

@end

@interface UIView (Layout)

@property (nonatomic, strong) DLLayoutMark *mark;

-(UIView *(^)(UIView *view))left;

-(UIView *(^)(UIView *view))right;

-(UIView *(^)(UIView *view))top;

-(UIView *(^)(UIView *view))bottom;

-(UIView *(^)(UIView *view))leftTo;

-(UIView *(^)(UIView *view))rightTo;

-(UIView *(^)(UIView *view))topTo;

-(UIView *(^)(UIView *view))bottomTo;

//-(UIView *)left;
//
//-(UIView *)right;
//
//-(UIView *)top;
//
//-(UIView *)bottom;
//
//-(UIView *)leftTo;
//
//-(UIView *)rightTo;
//
//-(UIView *)topTo;
//
//-(UIView *)bottomTo;



-(UIView *(^)(CGFloat constant))offset;

-(UIView *(^)(UIView *view))equal;

-(UIView *(^)(CGFloat constant))multipliedBy;

-(UIView *(^)(void))layout_install;

@end



