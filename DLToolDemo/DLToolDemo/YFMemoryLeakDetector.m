#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "YFMemoryLeakDetector.h"
#import "Aspects.h"

@interface  YFMemoryLeakDetector()
@end

@implementation  YFMemoryLeakDetector

static YFMemoryLeakDetector * sharedLocalSession = nil;

+ (void)load{
    [[YFMemoryLeakDetector sharedInstance] setup];
}

+(YFMemoryLeakDetector *) sharedInstance{
    @synchronized(self){
        if (sharedLocalSession == nil) {
            sharedLocalSession = [[self alloc] init];
        }
    }
    return  sharedLocalSession;
}


- (void)setup{
    self.loadedViewControllers = [NSMutableDictionary dictionaryWithCapacity: 42];
    self.loadedViews = [NSMutableDictionary dictionaryWithCapacity:42];
    
    /* 控制器循环引用的检测. */
    [UIViewController aspect_hookSelector:@selector(viewDidLoad) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info) {
        NSValue * key = [NSValue valueWithPointer: (__bridge const void * _Nullable)(info.instance)];

        [self.loadedViewControllers setObject:[NSString stringWithFormat:@"%@", info.instance] forKey:key];
    }error:NULL];
    
    [UIViewController aspect_hookSelector:NSSelectorFromString(@"dealloc") withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
        NSValue * key = [NSValue valueWithPointer: (__bridge const void * _Nullable)(info.instance)];

        [self.loadedViewControllers removeObjectForKey: key];
    }error:NULL];
    
    /* 视图循环引用的检测. */
    /* 只捕捉已经从父视图移除,却未释放的视图.以指针区分. */
    [UIView aspect_hookSelector:@selector(willMoveToSuperview:) withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info, UIView * superview){
        /* 过滤以 _ 开头的私有类. */
        NSString * viewClassname = NSStringFromClass(object_getClass(info.instance));
        if ([viewClassname hasPrefix:@"_"]) {
            return;
        }
        
        /* 兼容处理使用了KVO机制监测 delloc 方法的库,如 RAC. */
        if ([viewClassname hasPrefix:@"NSKVONotifying_"]) {
            return;
        }
        
        NSValue * key = [NSValue valueWithPointer: (__bridge const void * _Nullable)(info.instance)];
        
        /* 从父视图移除时,就直接判定为已释放.
         这样做的合理性在于:当视图从父视图移除后,一般是很难再出发循环引用的条件了,所以可适度忽略.
         */
        if (!superview) {
            [self.loadedViews removeObjectForKey: key];
        }
        
        NSMutableDictionary * obj = [self.loadedViews objectForKey: key];
        
        if (obj) { /* 一个 UIView 视图,只记录一次即可.因为一个UIView,最多只被 delloc 一次. */
            return;
        }
        
        [self.loadedViews setObject: [NSString stringWithFormat:@"%@", info.instance] forKey:key];
        
        /* 仅对有效实例进行捕捉.直接捕捉类对象,会引起未知崩溃,尤其涉及到和其他有KVO机制的类库配合使用时. */
        [info.instance aspect_hookSelector:NSSelectorFromString(@"dealloc") withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info){
            [self.loadedViews removeObjectForKey: key];
        }error:NULL];
    }error:NULL];
}
@end
