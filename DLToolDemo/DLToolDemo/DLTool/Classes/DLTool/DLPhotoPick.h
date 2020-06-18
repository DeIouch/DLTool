/*
 Localized resources can be mixed = YES         调用系统资源使用中文
 Privacy - Photo Library Usage Description      请求使用相册
 Privacy - Camera Usage Description             请求使用相机
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// data可能是image对象，也可能是视频的NSURL

@interface DLPhotoPick : NSObject

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

+(instancetype)shareInstance;

-(instancetype)allowsEditing:(BOOL)allowsEditing;

@property (nonatomic, copy) void(^DLPhotoHelperBlock)(id obj);

@end
