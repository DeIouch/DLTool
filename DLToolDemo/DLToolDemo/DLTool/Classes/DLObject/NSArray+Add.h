#import <Foundation/Foundation.h>

@interface NSArray (Add)

+(NSArray *)dl_arrayWithPlistData:(NSData *)plist;

+(NSArray *)dl_arrayWithPlistString:(NSString *)plist;

-(NSData *)dl_plistData;

-(NSString *)dl_plistString;

-(id)dl_randomObject;

-(NSString *)dl_jsonStringEncoded;

-(NSString *)dl_jsonPrettyStringEncoded;

@end
