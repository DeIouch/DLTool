#import "UIImageView+DLWeb.h"
#import "DLToolMacro.h"
#import "DLDownloderOperationManager.h"

static char const urlStringKey;

@implementation UIImageView (DLWeb)

-(void)setUrlString:(NSString *)urlString{
    objc_setAssociatedObject(self, &urlStringKey, urlString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)urlString{
    return objc_getAssociatedObject(self, &urlStringKey);
}

-(void)dl_setWebImage:(NSString *)urlStr{
    if (!urlStr) {
        return;
    }
    if (![urlStr isEqualToString:self.urlString]) {
        [DLDownloderOperationManager cancelOperation:urlStr];
        self.urlString = urlStr;
        [DLDownloderOperationManager downloadWithURLString:urlStr withImageView:self];
    }
}

@end
