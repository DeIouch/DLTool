#import <Foundation/Foundation.h>

@interface NSData (Add)

-(NSString *)dl_md2String;

-(NSData *)dl_md2Data;

-(NSString *)dl_md4String;

-(NSData *)dl_md4Data;

-(NSString *)dl_md5String;

-(NSData *)dl_md5Data;

-(NSString *)dl_sha1String;

-(NSData *)dl_sha1Data;

-(NSString *)dl_sha224String;

-(NSData *)dl_sha224Data;

-(NSString *)dl_sha256String;

-(NSData *)dl_sha256Data;

-(NSString *)dl_sha384String;

-(NSData *)dl_sha384Data;

-(NSString *)dl_sha512String;

-(NSData *)dl_sha512Data;

-(NSString *)dl_hmacMD5StringWithKey:(NSString *)key;

-(NSData *)dl_hmacMD5DataWithKey:(NSData *)key;

-(NSString *)dl_hmacSHA1StringWithKey:(NSString *)key;

-(NSData *)dl_hmacSHA1DataWithKey:(NSData *)key;

-(NSString *)dl_hmacSHA224StringWithKey:(NSString *)key;

-(NSData *)dl_hmacSHA224DataWithKey:(NSData *)key;

-(NSString *)dl_hmacSHA256StringWithKey:(NSString *)key;

-(NSData *)dl_hmacSHA256DataWithKey:(NSData *)key;

-(NSString *)dl_hmacSHA384StringWithKey:(NSString *)key;

-(NSData *)dl_hmacSHA384DataWithKey:(NSData *)key;

-(NSString *)dl_hmacSHA512StringWithKey:(NSString *)key;

-(NSData *)dl_hmacSHA512DataWithKey:(NSData *)key;

-(NSString *)dl_crc32String;

-(uint32_t)dl_crc32;

-(NSData *)dl_aes256EncryptWithKey:(NSData *)key iv:(NSData *)iv;

-(NSData *)dl_aes256DecryptWithkey:(NSData *)key iv:(NSData *)iv;

-(NSString *)dl_utf8String;

-(NSString *)dl_hexString;

+(NSData *)dl_dataWithHexString:(NSString *)hexSt;

-(NSString *)dl_base64EncodedString;

+(NSData *)dl_dataWithBase64EncodedString:(NSString *)base64EncodedString;

-(id)dl_jsonValueDecoded;

-(NSData *)dl_gzipInflate;

-(NSData *)dl_gzipDeflate;

-(NSData *)dl_zlibInflate;

-(NSData *)dl_zlibDeflate;

+(NSData *)dl_dataNamed:(NSString *)name;

@end
