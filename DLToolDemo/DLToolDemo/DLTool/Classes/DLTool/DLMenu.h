//  选择菜单

#import <Foundation/Foundation.h>

@interface DLMenu : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+(DLMenu *)createDLMenuWithTitleArray:(NSArray *)array selectBlock:(void(^)(NSInteger target))block;

@end
