#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DLToolMacro.h"

@interface KVOObserverInfo:NSObject

@end

@interface NSObject (Add)

-(BOOL)isNSString;

-(BOOL)isNSArray;

-(BOOL)isNSDictionary;

-(BOOL)ObjectIsNil;

/// 获取代码块执行时间
/// @param block 代码块
-(double)getElapsedTime:(void (^)(void))block;

-(void)dl_addObserverBlockForKeyPath:(NSString*)keyPath block:(void (^)(id obj, id oldVal, id newVal))block;

-(void)dl_removeObserverBlocksForKeyPath:(NSString*)keyPath;

- (void)dl_removeObserverBlocks;

-(void)startTiming;

-(void)endTiming;

@end
