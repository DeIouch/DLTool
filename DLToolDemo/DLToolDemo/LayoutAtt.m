#import "LayoutAtt.h"

@implementation LayoutAtt

-(instancetype)initWithView:(UIView *)view item:(id)item layoutAttribute:(NSLayoutAttribute)layoutAttribute{
    if (![super init]) {
        return nil;
    }
    _view = view;
    _item = item;
    _layoutAttribute = layoutAttribute;
    return self;
}

@end
