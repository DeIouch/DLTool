#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>

@interface NSString (Add)

- (NSString *)md5;
- (NSString *)sha1;
- (NSString *)base64;

-(NSString *(^)(NSString *str))addString;

-(BOOL)StringIsEmpty;

// 随机生成字符串(由大小写字母、数字组成)
+(NSString *)random:(int)len;

-(NSString *)dl_stringByTrim;

// 随机生成字符串(由大小写字母组成)
+(NSString *)randomNoNumber:(int)len;

/// 返回标准的类名
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *dlFormatClassName;

/// 返回标准的属性名
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *dlFormatPropertyName;

@end
