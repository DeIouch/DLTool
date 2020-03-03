#import "UIScrollView+Add.h"

@implementation UIScrollView (Add)

-(void)dl_scrollToTopAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.y = 0 - self.contentInset.top;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToBottomAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.y = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToLeftAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.x = 0 - self.contentInset.left;
    [self setContentOffset:off animated:animated];
}

-(void)dl_scrollToRightAnimated:(BOOL)animated{
    CGPoint off = self.contentOffset;
    off.x = self.contentSize.width - self.bounds.size.width + self.contentInset.right;
    [self setContentOffset:off animated:animated];
}

@end
