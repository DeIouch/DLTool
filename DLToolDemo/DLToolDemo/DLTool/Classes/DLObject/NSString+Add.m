#import "NSString+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>

@implementation NSString (Add)

static const char TTAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
- (NSString *)md5{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr,
          (CC_LONG)[self length], result);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", result[i]];
    }
    return output;
}

+(NSString *)dl_stringWithUUID{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (__bridge_transfer NSString *)string;
}

- (NSString *)sha1{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
     CC_SHA1(cStr, (CC_LONG)[self length], result);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", result[i]];
    }
    
    return output;
}

- (NSString *)base64{
    const char *cStr = [self UTF8String];
    if ([self length] == 0)
        return @"";
    
    char *characters = malloc((([self length] + 2) / 3) * 4);
    if (characters == NULL)
        return nil;
    
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (i < [self length]) {
        char buffer[3] = {0,0,0};
        short bufferLength = 0;
        
        while (bufferLength < 3 && i < [self length])
            buffer[bufferLength++] = ((char *)cStr)[i++];
        characters[length++] = TTAlphabet[(buffer[0] & 0xFC) >> 2];
        characters[length++] = TTAlphabet[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        
        if (bufferLength > 1) {
            characters[length++] = TTAlphabet[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        } else {
            characters[length++] = '=';
        }
        
        if (bufferLength > 2) {
            characters[length++] = TTAlphabet[buffer[2] & 0x3F];
        } else {
            characters[length++] = '=';
        }
    }
    return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

-(NSString *(^) (NSString *str))addString{
    return ^(NSString *str){
        return [self stringByAppendingString:str];
    };
}

-(BOOL)StringIsEmpty{
    if (self.length == 0 || [self ObjectIsNil]) {
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)dl_isValidateWithRegex:(NSString *)regex
{
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [pre evaluateWithObject:self];
}

/* 邮箱验证 MODIFIED BY HELENSONG */
- (BOOL)dl_isValidEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

/* 手机号码验证 MODIFIED BY HELENSONG */
- (BOOL)dl_isValidPhoneNum{
    //手机号以13， 14，15，17，18，19开头，八个 \d 数字字符
    NSString *phoneRegex = @"^(13[0-9]|14[5-9]|15[012356789]|166|17[0-8]|18[0-9]|19[0-9])[0-9]{8}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:self];
}

/* 车牌号验证 MODIFIED BY HELENSONG */
-(BOOL)dl_isValidCarNo{
    NSString *carRegex = @"^[A-Za-z]{1}[A-Za-z_0-9]{5}$";
    NSPredicate *carTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",carRegex];
    return [carTest evaluateWithObject:self];
}

/** 网址验证 */
-(BOOL)dl_isValidUrl{
    NSString *regex = @"^((http)|(https))+:[^\\s]+\\.[^\\s]*$";
    return [self dl_isValidateWithRegex:regex];
}

/** 邮政编码 */
-(BOOL)dl_isValidPostalcode{
    NSString *phoneRegex = @"^[0-8]\\d{5}(?!\\d)$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:self];
}

/** 纯汉字 */
- (BOOL)dl_isValidChinese{
    NSString *phoneRegex = @"^[\u4e00-\u9fa5]+$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",phoneRegex];
    return [phoneTest evaluateWithObject:self];
}

- (BOOL)dl_isValidIP{
    NSString *regex = [NSString stringWithFormat:@"^(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})$"];
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    BOOL rc = [pre evaluateWithObject:self];
    if (rc) {
        NSArray *componds = [self componentsSeparatedByString:@","];
        BOOL v = YES;
        for (NSString *s in componds) {
            if (s.integerValue > 255) {
                v = NO;
                break;
            }
        }
        return v;
    }
    return NO;
}

- (BOOL)dl_isValidWithMinLenth:(NSInteger)minLenth
                   maxLenth:(NSInteger)maxLenth
             containChinese:(BOOL)containChinese
              containDigtal:(BOOL)containDigtal
              containLetter:(BOOL)containLetter
      containOtherCharacter:(NSString *)containOtherCharacter
        firstCannotBeDigtal:(BOOL)firstCannotBeDigtal;
{
    BOOL rc = YES;
    if (firstCannotBeDigtal) {
        NSString *regex = @"^[0-9]+.*";
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
        rc = [pre evaluateWithObject:self];
        if (rc) {
            return NO;
        }
    }
    NSString *hanzi = containChinese ? @"\u4e00-\u9fa5" : @"";
    NSString *digtalRegex = containDigtal ? @"0-9" : @"";
    NSString *containOtherCharacterRegex = containOtherCharacter ? containOtherCharacter : @"";
    NSString *characterRegex = [NSString stringWithFormat:@"[%@A-Za-z%@%@]", hanzi, digtalRegex, containOtherCharacterRegex];
    NSString *regex = [NSString stringWithFormat:@"%@{%@,%@}", characterRegex, @(minLenth), @(maxLenth)];
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pre evaluateWithObject:self];
}

/** 去掉两端空格和换行符 */
-(NSString *)dl_stringByTrimmingBlank{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/** 工商税号 */
- (BOOL)dl_isValidTaxNo
{
    NSString *emailRegex = @"[0-9]\\d{13}([0-9]|X)$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        Class NSPlaceholderStringClass=NSClassFromString(@"NSPlaceholderString");
        
        //initWithString:
        [self safe_exchangeInstanceMethod:NSPlaceholderStringClass originalSel:@selector(initWithString:) newSel:@selector(safe_initWithString:)];
         
         Class dClass=NSClassFromString(@"__NSCFConstantString");
         Class dClass2=NSClassFromString(@"NSTaggedPointerString");
         [self safe_changeAllMethod:dClass];
         [self safe_changeAllMethod:dClass2];
        
    });
}

+(void)safe_changeAllMethod:(Class)dClass
{
    //hasPrefix
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(hasPrefix:) newSel:@selector(safe_hasPrefix:)];
    
    //hasSuffix
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(hasSuffix:) newSel:@selector(safe_hasSuffix:)];
    
    //substringFromIndex
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(substringFromIndex:) newSel:@selector(safe_substringFromIndex:)];
    
    //substringToIndex
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(substringToIndex:) newSel:@selector(safe_substringToIndex:)];
    
    //substringWithRange
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(substringWithRange:) newSel:@selector(safe_substringWithRange:)];
    
    //characterAtIndex
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(characterAtIndex:) newSel:@selector(safe_characterAtIndex:)];
    
    //stringByReplacingOccurrencesOfString:withString:options:range:
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(stringByReplacingOccurrencesOfString:withString:options:range:) newSel:@selector(safe_stringByReplacingOccurrencesOfString:withString:options:range:)];
    
    //stringByReplacingCharactersInRange:withString:
    [self safe_exchangeInstanceMethod:dClass originalSel:@selector(stringByReplacingCharactersInRange:withString:) newSel:@selector(safe_stringByReplacingCharactersInRange:withString:)];
}

-(instancetype)safe_initWithString:(NSString *)aString
{
    id instance = nil;
    @try {
        instance = [self safe_initWithString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
    }
    @finally {
        return instance;
    }
}

-(BOOL)safe_hasPrefix:(NSString *)str
{
    BOOL has = NO;
    @try {
        has = [self safe_hasPrefix:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
    }
    @finally {
        return has;
    }
}

-(BOOL)safe_hasSuffix:(NSString *)str
{
    BOOL has = NO;
    @try {
        has = [self safe_hasSuffix:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
    }
    @finally {
        return has;
    }
}

- (NSString *)safe_substringFromIndex:(NSUInteger)from {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringFromIndex:from];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (NSString *)safe_substringToIndex:(NSUInteger)index {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringToIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (NSString *)safe_substringWithRange:(NSRange)range {
    NSString *subString = nil;
    @try {
        subString = [self safe_substringWithRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
        subString = nil;
    }
    @finally {
        return subString;
    }
}

- (unichar)safe_characterAtIndex:(NSUInteger)index {
    unichar characteristic;
    @try {
        characteristic = [self safe_characterAtIndex:index];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
    }
    @finally {
        return characteristic;
    }
}

- (NSString *)safe_stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange {
    NSString *newStr = nil;
    @try {
        newStr = [self safe_stringByReplacingOccurrencesOfString:target withString:replacement options:options range:searchRange];
    }
    @catch (NSException *exception) {
       DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
        newStr = nil;
    }
    @finally {
        return newStr;
    }
}

- (NSString *)safe_stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement {
    NSString *newStr = nil;
    @try {
        newStr = [self safe_stringByReplacingCharactersInRange:range withString:replacement];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSStirng);
        newStr = nil;
    }
    @finally {
        return newStr;
    }
}

- (NSString *)uncapitalizeFirstCharacter
{
    if (self.length == 0) {
        return @"";
    } else if (self.length == 1) {
        return self.lowercaseString;
    }
    NSString *lowercase = self.lowercaseString;
    NSString *firstLetter = [lowercase substringToIndex:1];
    NSString *restOfString = [self substringFromIndex:1];
    return [NSString stringWithFormat:@"%@%@", firstLetter, restOfString];
}

+(NSString *)random:(int)len{
    char ch[len];
    for (int index=0; index<len; index++) {
        int num = arc4random_uniform(75)+48;
        if (num>57 && num<65) { num = num%57+48; }
        else if (num>90 && num<97) { num = num%90+65; }
        ch[index] = num;
    }
    return [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
}

-(NSString *)dl_stringByTrim{
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [self stringByTrimmingCharactersInSet:set];
}

// 随机生成字符串(由大小写字母组成)
+(NSString *)randomNoNumber:(int)len{
    char ch[len];
    for (int index=0; index<len; index++) {
        int num = arc4random_uniform(58)+65;
        if (num>90 && num<97) { num = num%90+65; }
        ch[index] = num;
    }
    return [[NSString alloc] initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
}

- (NSString *)uppercaseCamelcaseString {
    NSCharacterSet *nonAlphanumericCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"].invertedSet;
    NSMutableArray *components = [NSMutableArray arrayWithArray:[self componentsSeparatedByCharactersInSet:nonAlphanumericCharacterSet]];
    NSUInteger componentCount = components.count;
    
    for (NSUInteger i = 0; i < componentCount; ++i) {
        components[i] = [components[i] capitalizedString];
    }
    
    return [components componentsJoinedByString:@""];
}


@end

/*
initWithString导致的crash
 如果是[NSString alloc]initWithString 类为NSPlaceholderString
 如果是[NSMutableString alloc]initWithString 类为NSPlaceholderMutableString
 
 __NSCFString
 非常量 或者 [NSMutableString stringWithFormat:@"fs"];
 [[NSMutableString alloc]initWithString:@"fs"];
 [NSString stringWithFormat:]大于7字节
 
 __NSCFConstantString
 @"fdsfsds"
 [[NSString alloc]initWithString:@"fs"];
 
 NSTaggedPointerString [NSString stringWithFormat:@"fs"]形式创建 当字节小于7时是NSTaggedPointerString 大于7字节时是__NSCFString
 @"123456"0xa003635343332316  当字节大于7填满时并不会立即变成__NSCFString，而是采用一种压缩算法，当压缩之后大于7字节时才会变成__NSCFString ( @"1234567"为 0xa373635343332317 没有压缩， @"12345678"为 0xa007a87dcaecc2a8 开始压缩了）//第一位为a代表是字符串  b为NSNumber,当为NSNumber时最后一位表示(long 3 float为4，Int为2，double为5）
 */


/*
   1. initWithString
   2. hasPrefix
   3. hasSuffix
   4. substringFromIndex:(NSUInteger)from
   5. substringToIndex:(NSUInteger)to {
   6. substringWithRange:(NSRange)range {
   7. characterAtIndex:(NSUInteger)index
   8. stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement 实际上调用的是9方法
   9. stringByReplacingOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange
   10. stringByReplacingCharactersInRange:(NSRange)range withString:(NSString *)replacement
 
 */
