#import <Foundation/Foundation.h>

@interface NSDictionary (Add)

+(NSDictionary *)dl_dictionaryWithPlistData:(NSData *)plist;

+(NSDictionary *)dl_dictionaryWithPlistString:(NSString *)plist;

-(NSData *)dl_plistData;

-(NSString *)dl_plistString;

-(NSArray *)dl_allKeysSorted;

-(NSArray *)dl_allValuesSortedByKeys;

-(BOOL)dl_containsObjectForKey:(id)key;

-(NSDictionary *)dl_entriesForKeys:(NSArray *)keys;

-(NSString *)dl_jsonStringEncoded;

-(NSString *)dl_jsonPrettyStringEncoded;

+(NSDictionary *)dl_dictionaryWithXML:(id)xml;

-(BOOL)dl_boolValueForKey:(NSString *)key default:(BOOL)def;

-(char)dl_charValueForKey:(NSString *)key default:(char)def;

-(unsigned char)dl_unsignedCharValueForKey:(NSString *)key default:(unsigned char)def;

-(short)dl_shortValueForKey:(NSString *)key default:(short)def;

-(unsigned short)dl_unsignedShortValueForKey:(NSString *)key default:(unsigned short)def;

-(int)dl_intValueForKey:(NSString *)key default:(int)def;

-(unsigned int)dl_unsignedIntValueForKey:(NSString *)key default:(unsigned int)def;

-(long)dl_longValueForKey:(NSString *)key default:(long)def;

-(unsigned long)dl_unsignedLongValueForKey:(NSString *)key default:(unsigned long)def;

-(long long)dl_longLongValueForKey:(NSString *)key default:(long long)def;

-(unsigned long long)dl_unsignedLongLongValueForKey:(NSString *)key default:(unsigned long long)def;

-(float)dl_floatValueForKey:(NSString *)key default:(float)def;

-(double)dl_doubleValueForKey:(NSString *)key default:(double)def;

-(NSInteger)dl_integerValueForKey:(NSString *)key default:(NSInteger)def;

-(NSUInteger)dl_unsignedIntegerValueForKey:(NSString *)key default:(NSUInteger)def;

-(NSNumber *)dl_numberValueForKey:(NSString *)key default:(NSNumber *)def;

-(NSString *)dl_stringValueForKey:(NSString *)key default:(NSString *)def;

+(NSDictionary *)dl_modelDictionaryWithClass:(Class)cls json:(id)json;

@end
