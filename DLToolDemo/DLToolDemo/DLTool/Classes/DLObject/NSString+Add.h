#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>

@interface NSString (Add)

-(NSString *)md5;
-(NSString *)sha1;
-(NSString *)base64;

-(NSString *(^)(NSString *str))addString;

-(BOOL)StringIsEmpty;

// 随机生成字符串(由大小写字母、数字组成)
+(NSString *)random:(int)len;

-(NSString *)dl_stringByTrim;

+(NSString *)dl_stringWithUUID;

/** 邮箱验证 */
- (BOOL)dl_isValidEmail;

/** 手机号码验证 */
- (BOOL)dl_isValidPhoneNum;

/** 车牌号验证 */
- (BOOL)dl_isValidCarNo;

/** 网址验证 */
- (BOOL)dl_isValidUrl;

/** 邮政编码 */
- (BOOL)dl_isValidPostalcode;

/** 纯汉字 */
- (BOOL)dl_isValidChinese;

/**
 @brief     是否符合IP格式，xxx.xxx.xxx.xxx
 */
-(BOOL)dl_isValidIP;

/**
 @brief     是否符合最小长度、最长长度，是否包含中文,数字，字母，其他字符，首字母是否可以为数字
 @param     minLenth 账号最小长度
 @param     maxLenth 账号最长长度
 @param     containChinese 是否包含中文
 @param     containDigtal   包含数字
 @param     containLetter   包含字母
 @param     containOtherCharacter   其他字符
 @param     firstCannotBeDigtal 首字母不能为数字
 @return    正则验证成功返回YES, 否则返回NO
 */
- (BOOL)dl_isValidWithMinLenth:(NSInteger)minLenth
                   maxLenth:(NSInteger)maxLenth
             containChinese:(BOOL)containChinese
              containDigtal:(BOOL)containDigtal
              containLetter:(BOOL)containLetter
      containOtherCharacter:(NSString *)containOtherCharacter
        firstCannotBeDigtal:(BOOL)firstCannotBeDigtal;

/** 去掉两端空格和换行符 */
-(NSString *)dl_stringByTrimmingBlank;

/** 工商税号 */
-(BOOL)dl_isValidTaxNo;

// 随机生成字符串(由大小写字母组成)
+(NSString *)randomNoNumber:(int)len;

-(NSString *(^)(void))test:(NSString *(^)(void))test text:(NSString *)text;

@end
