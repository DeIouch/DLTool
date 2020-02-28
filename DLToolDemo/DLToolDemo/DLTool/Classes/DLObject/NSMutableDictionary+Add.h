#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Add)

+(NSMutableDictionary *)dl_dictionaryWithPlistData:(NSData *)plist;

+(NSMutableDictionary *)dl_dictionaryWithPlistString:(NSString *)plist;

-(id)dl_popObjectForKey:(id)aKey;

-(NSDictionary *)dl_popEntriesForKeys:(NSArray *)keys;

@end
