#import <Foundation/Foundation.h>

/**
 *  分析页面和页面内视图是否有内存泄露的情况.
 */
@interface  YFMemoryLeakDetector: NSObject

#pragma mark - 属性.

/*
  已加载,但尚未正确释放,有内存风险的控制器对象.
 
 以指针地址为key,以对象字符串为值.所以不用担心因为记录本身而引起的内存泄露问题.
 
 必要时,可以使用类似 (UIViewController *)[key pointerValue] 的语法来获取原始的 OC对象来进一步做些过滤操作.
 */
@property (strong, atomic) NSMutableDictionary * loadedViewControllers;

/*
 已加载,但尚未正确释放,有内存风险的视图对象.
 
 以指针地址为key,以对象字符串为值.所以不用担心因为记录本身而引起的内存泄露问题.
 
 必要时,可以使用类似 (UIView *)[key pointerValue] 的语法来获取原始的 OC对象来进一步做些过滤操作.
 */
@property (strong, atomic) NSMutableDictionary * loadedViews; //!< 已加载的视图.



#pragma mark - 单例方法.
+(YFMemoryLeakDetector *) sharedInstance;
@end
