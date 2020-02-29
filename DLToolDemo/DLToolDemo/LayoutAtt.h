#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LayoutAtt : NSObject

@property (nonatomic, weak, readonly) UIView *view;

@property (nonatomic, assign, readonly) NSLayoutAttribute layoutAttribute;

@property (nonatomic, weak, readonly) id item;

-(instancetype)initWithView:(UIView *)view item:(id)item layoutAttribute:(NSLayoutAttribute)layoutAttribute;

@end
