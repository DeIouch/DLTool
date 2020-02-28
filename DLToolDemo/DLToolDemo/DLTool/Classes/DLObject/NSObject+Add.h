#import <Foundation/Foundation.h>

@interface KVOObserverInfo:NSObject

@end

@interface NSObject (Add)

-(BOOL)isNSString;

-(BOOL)isNSArray;

-(BOOL)isNSDictionary;

-(BOOL)ObjectIsNil;

+ (void)dl_createModelWithJson:(NSDictionary *)json fileName:(NSString *)fileName extensionName:(NSString *)extensionName fileURL:(NSURL *)url;

+(void)safe_exchangeInstanceMethod:(Class)dClass originalSel:(SEL)originalSelector newSel:(SEL)newSelector;

+(instancetype)dl_modelWithJSON:(id)json;

+(instancetype)dl_modelWithDictionary:(NSDictionary *)dictionary;

-(BOOL)dl_modelSetWithJSON:(id)json;

-(BOOL)dl_modelSetWithDictionary:(NSDictionary *)dic;

-(id)dl_modelToJSONObject;

-(NSData *)dl_modelToJSONData;

-(NSString *)dl_modelToJSONString;

-(id)dl_modelCopy;

-(void)dl_modelEncodeWithCoder:(NSCoder *)aCoder;

-(id)dl_modelInitWithCoder:(NSCoder *)aDecoder;

-(NSUInteger)dl_modelHash;

-(BOOL)dl_modelIsEqual:(id)model;

-(NSString *)dl_modelDescription;

@end

@protocol DLModel <NSObject>
@optional

+(NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

+(NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

+(Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

+(NSArray<NSString *> *)modelPropertyBlacklist;

+(NSArray<NSString *> *)modelPropertyWhitelist;

-(NSDictionary *)modelCustomWillTransformFromDictionary:(NSDictionary *)dic;

-(BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

-(BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;

@end
