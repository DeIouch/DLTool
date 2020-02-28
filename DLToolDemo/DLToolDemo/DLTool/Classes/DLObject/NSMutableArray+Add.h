#import <Foundation/Foundation.h>

@interface NSMutableArray (Add)

+(NSMutableArray *)dl_arrayWithPlistData:(NSData *)plist;

+(NSMutableArray *)dl_arrayWithPlistString:(NSString *)plist;

-(void)dl_shuffle;

@end


