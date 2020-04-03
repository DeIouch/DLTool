#import "NSDictionary+Add.h"
#import "NSObject+Add.h"
#import "DLSafeProtector.h"
#include <objc/runtime.h>
#import "NSString+Add.h"
#import "NSData+Add.h"

@interface _DLXMLDictionaryParser : NSObject <NSXMLParserDelegate>

@end

@implementation _DLXMLDictionaryParser {
    NSMutableDictionary *_root;
    NSMutableArray *_stack;
    NSMutableString *_text;
}

- (instancetype)initWithData:(NSData *)data {
    self = super.init;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser parse];
    return self;
}

- (instancetype)initWithString:(NSString *)xml {
    NSData *data = [xml dataUsingEncoding:NSUTF8StringEncoding];
    return [self initWithData:data];
}

- (NSDictionary *)result {
    return _root;
}

#pragma mark NSXMLParserDelegate

#define XMLText @"_text"
#define XMLName @"_name"
#define XMLPref @"_"

- (void)textEnd {
    _text = _text.dl_stringByTrim.mutableCopy;
    if (_text.length) {
        NSMutableDictionary *top = _stack.lastObject;
        id existing = top[XMLText];
        if ([existing isKindOfClass:[NSArray class]]) {
            [existing addObject:_text];
        } else if (existing) {
            top[XMLText] = [@[existing, _text] mutableCopy];
        } else {
            top[XMLText] = _text;
        }
    }
    _text = nil;
}

- (void)parser:(__unused NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName attributes:(NSDictionary *)attributeDict {
    [self textEnd];
    
    NSMutableDictionary *node = [NSMutableDictionary new];
    if (!_root) node[XMLName] = elementName;
    if (attributeDict.count) [node addEntriesFromDictionary:attributeDict];
    
    if (_root) {
        NSMutableDictionary *top = _stack.lastObject;
        id existing = top[elementName];
        if ([existing isKindOfClass:[NSArray class]]) {
            [existing addObject:node];
        } else if (existing) {
            top[elementName] = [@[existing, node] mutableCopy];
        } else {
            top[elementName] = node;
        }
        [_stack addObject:node];
    } else {
        _root = node;
        _stack = [NSMutableArray arrayWithObject:node];
    }
}

- (void)parser:(__unused NSXMLParser *)parser didEndElement:(__unused NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName {
    [self textEnd];
    
    NSMutableDictionary *top = _stack.lastObject;
    [_stack removeLastObject];
    
    NSMutableDictionary *left = top.mutableCopy;
    [left removeObjectsForKeys:@[XMLText, XMLName]];
    for (NSString *key in left.allKeys) {
        [left removeObjectForKey:key];
        if ([key hasPrefix:XMLPref]) {
            left[[key substringFromIndex:XMLPref.length]] = top[key];
        }
    }
    if (left.count) return;
    
    NSMutableDictionary *children = top.mutableCopy;
    [children removeObjectsForKeys:@[XMLText, XMLName]];
    for (NSString *key in children.allKeys) {
        if ([key hasPrefix:XMLPref]) {
            [children removeObjectForKey:key];
        }
    }
    if (children.count) return;
    
    NSMutableDictionary *topNew = _stack.lastObject;
    NSString *nodeName = top[XMLName];
    if (!nodeName) {
        for (NSString *name in topNew) {
            id object = topNew[name];
            if (object == top) {
                nodeName = name; break;
            } else if ([object isKindOfClass:[NSArray class]] && [object containsObject:top]) {
                nodeName = name; break;
            }
        }
    }
    if (!nodeName) return;
    
    id inner = top[XMLText];
    if ([inner isKindOfClass:[NSArray class]]) {
        inner = [inner componentsJoinedByString:@"\n"];
    }
    if (!inner) return;
    
    id parent = topNew[nodeName];
    if ([parent isKindOfClass:[NSArray class]]) {
        parent[[parent count] - 1] = inner;
    } else {
        topNew[nodeName] = inner;
    }
}

- (void)parser:(__unused NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_text) [_text appendString:string];
    else _text = [NSMutableString stringWithString:string];
}

- (void)parser:(__unused NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    NSString *string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    if (_text) [_text appendString:string];
    else _text = [NSMutableString stringWithString:string];
}

#undef XMLText
#undef XMLName
#undef XMLPref
@end


@implementation NSDictionary (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //NSMutableDictionary和NSDictionary调用下面方法崩溃时的类型都为__NSPlaceholderDictionary
        [self safe_exchangeInstanceMethod:NSClassFromString(@"__NSPlaceholderDictionary") originalSel:@selector(initWithObjects:forKeys:count:) newSel:@selector(safe_initWithObjects:forKeys:count:)];
        [self safe_exchangeInstanceMethod:NSClassFromString(@"__NSPlaceholderDictionary") originalSel:@selector(initWithObjects:forKeys:) newSel:@selector(safe_initWithObjects:forKeys:)];
    });
}

-(instancetype)safe_initWithObjects:(NSArray *)objects forKeys:(NSArray<id<NSCopying>> *)keys
{
    id instance = nil;
    @try {
        instance = [self safe_initWithObjects:objects forKeys:keys];
    }
    @catch (NSException *exception) {
        
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSDictionary);
        
        //处理错误的数据，重新初始化一个字典
        NSUInteger count=MIN(objects.count, keys.count);
        NSMutableArray *newObjects=[NSMutableArray array];
        NSMutableArray *newKeys=[NSMutableArray array];
        for (int i = 0; i < count; i++) {
            if (objects[i] && keys[i]) {
                [newObjects addObject:objects[i]];
                [newKeys addObject:keys[i]];
            }
        }
        instance = [self safe_initWithObjects:newObjects forKeys:newKeys];
    }
    @finally {
        return instance;
    }
}

-(instancetype)safe_initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt
{

    id instance = nil;
    @try {
        instance = [self safe_initWithObjects:objects forKeys:keys count:cnt];
    }
    @catch (NSException *exception) {

        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSDictionary);

        //处理错误的数据，重新初始化一个字典
        NSUInteger index = 0;
        id   newObjects[cnt];
        id   newkeys[cnt];

        for (int i = 0; i < cnt; i++) {
            if (objects[i] && keys[i]) {
                newObjects[index] = objects[i];
                newkeys[index] = keys[i];
                index++;
            }
        }
        instance = [self safe_initWithObjects:newObjects forKeys:newkeys count:index];
    }
    @finally {
        return instance;
    }
}

+(NSDictionary *)dl_dictionaryWithPlistData:(NSData *)plist{
    if (!plist) return nil;
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:plist options:NSPropertyListImmutable format:NULL error:NULL];
    if ([dictionary isKindOfClass:[NSDictionary class]]) return dictionary;
    return nil;
}

+(NSDictionary *)dl_dictionaryWithPlistString:(NSString *)plist{
    if (!plist) return nil;
    NSData* data = [plist dataUsingEncoding:NSUTF8StringEncoding];
    return [self dl_dictionaryWithPlistData:data];
}

-(NSData *)dl_plistData{
    return [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListBinaryFormat_v1_0 options:kNilOptions error:NULL];
}

-(NSString *)dl_plistString{
    NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:self format:NSPropertyListXMLFormat_v1_0 options:kNilOptions error:NULL];
    if (xmlData) return xmlData.dl_utf8String;
    return nil;
}

-(NSArray *)dl_allKeysSorted{
    return [[self allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

-(NSArray *)dl_allValuesSortedByKeys{
    NSArray *sortedKeys = [self dl_allKeysSorted];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (id key in sortedKeys) {
        [arr addObject:self[key]];
    }
    return arr;
}

-(BOOL)dl_containsObjectForKey:(id)key{
    if (!key) return NO;
    return self[key] != nil;
}

-(NSDictionary *)dl_entriesForKeys:(NSArray *)keys{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    for (id key in keys) {
        id value = self[key];
        if (value) dic[key] = value;
    }
    return dic;
}

-(NSString *)dl_jsonStringEncoded{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

-(NSString *)dl_jsonPrettyStringEncoded{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

+(NSDictionary *)dl_dictionaryWithXML:(id)xml{
    _DLXMLDictionaryParser *parser = nil;
    if ([xml isKindOfClass:[NSString class]]) {
        parser = [[_DLXMLDictionaryParser alloc] initWithString:xml];
    } else if ([xml isKindOfClass:[NSData class]]) {
        parser = [[_DLXMLDictionaryParser alloc] initWithData:xml];
    }
    return [parser result];
}

static NSNumber *NSNumberFromID(id value) {
    static NSCharacterSet *dot;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
    });
    if (!value || value == [NSNull null]) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = ((NSString *)value).lowercaseString;
        if ([lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"]) return @(YES);
        if ([lower isEqualToString:@"false"] || [lower isEqualToString:@"no"]) return @(NO);
        if ([lower isEqualToString:@"nil"] || [lower isEqualToString:@"null"]) return nil;
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            return @(((NSString *)value).doubleValue);
        } else {
            return @(((NSString *)value).longLongValue);
        }
    }
    return nil;
}

#define RETURN_VALUE(_type_)                                                     \
if (!key) return def;                                                            \
id value = self[key];                                                            \
if (!value || value == [NSNull null]) return def;                                \
if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value)._type_;   \
if ([value isKindOfClass:[NSString class]]) return NSNumberFromID(value)._type_; \
return def;

-(BOOL)dl_boolValueForKey:(NSString *)key default:(BOOL)def{
    RETURN_VALUE(boolValue);
}

-(char)dl_charValueForKey:(NSString *)key default:(char)def{
    RETURN_VALUE(charValue);
}

-(unsigned char)dl_unsignedCharValueForKey:(NSString *)key default:(unsigned char)def{
    RETURN_VALUE(unsignedCharValue);
}

-(short)dl_shortValueForKey:(NSString *)key default:(short)def{
    RETURN_VALUE(shortValue);
}

-(unsigned short)dl_unsignedShortValueForKey:(NSString *)key default:(unsigned short)def{
    RETURN_VALUE(unsignedShortValue);
}

-(int)dl_intValueForKey:(NSString *)key default:(int)def{
    RETURN_VALUE(intValue);
}

-(unsigned int)dl_unsignedIntValueForKey:(NSString *)key default:(unsigned int)def{
    RETURN_VALUE(unsignedIntValue);
}

-(long)dl_longValueForKey:(NSString *)key default:(long)def{
    RETURN_VALUE(longValue);
}

-(unsigned long)dl_unsignedLongValueForKey:(NSString *)key default:(unsigned long)def{
    RETURN_VALUE(unsignedLongValue);
}

-(long long)dl_longLongValueForKey:(NSString *)key default:(long long)def{
    RETURN_VALUE(longLongValue);
}

-(unsigned long long)dl_unsignedLongLongValueForKey:(NSString *)key default:(unsigned long long)def{
    RETURN_VALUE(unsignedLongLongValue);
}

-(float)dl_floatValueForKey:(NSString *)key default:(float)def{
    RETURN_VALUE(floatValue);
}

-(double)dl_doubleValueForKey:(NSString *)key default:(double)def{
    RETURN_VALUE(doubleValue);
}

-(NSInteger)dl_integerValueForKey:(NSString *)key default:(NSInteger)def{
    RETURN_VALUE(integerValue);
}

-(NSUInteger)dl_unsignedIntegerValueForKey:(NSString *)key default:(NSUInteger)def{
    RETURN_VALUE(unsignedIntegerValue);
}

-(NSNumber *)dl_numberValueForKey:(NSString *)key default:(NSNumber *)def{
    if (!key) return def;
    id value = self[key];
    if (!value || value == [NSNull null]) return def;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) return NSNumberFromID(value);
    return def;
}

-(NSString *)dl_stringValueForKey:(NSString *)key default:(NSString *)def{
    if (!key) return def;
    id value = self[key];
    if (!value || value == [NSNull null]) return def;
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value).description;
    return def;
}

@end

// 类继承关系
// __NSDictionaryI              继承于 NSDictionary
// __NSSingleEntryDictionaryI   继承于 NSDictionary
// __NSDictionary0              继承于 NSDictionary
// __NSFrozenDictionaryM        继承于 NSDictionary
// __NSDictionaryM              继承于 NSMutableDictionary
// __NSCFDictionary             继承于 NSMutableDictionary
// NSMutableDictionary          继承于 NSDictionary
// NSDictionary                 继承于 NSObject


/*
 大概和NSArray类似  也是iOS8之前都是__NSDictionaryI，如果是json转过来的对象为__NSCFDictionary，其他的参考NSArray
 
 __NSSingleEntryDictionaryI
 @{@"key":@"value"} 此种形式创建而且仅一个可以为__NSSingleEntryDictionaryI
 __NSDictionaryM
 NSMutableDictionary创建都为__NSDictionaryM
 __NSDictionary0
 除__NSDictionaryM外 不管什么方式创建0个key都为__NSDictionary0
 __NSDictionaryI
 @{@"key":@"value",@"key2",@"value2"}此种方式创建多于1个key，或者initWith创建都是__NSDictionaryI
 */

/*
 特殊类型
1. __NSCFDictionary 以下情况生成
 沙盒即使存储的是可变的得到的也是不可变的，当然还有其他情况得到这种类型的字典
 [[NSUserDefaults standardUserDefaults] setObject:[NSMutableDictionary dictionary] forKey:@"name"];
 NSMutableDictionary *dict=[[NSUserDefaults standardUserDefaults] objectForKey:@"name"];
 
2.__NSFrozenDictionaryM  以下情况生成
 
 NSMutableDictionary *dict=[[NSMutableDictionary dictionary] copy];
 [dict setObject:@"fsd" forKey:value];
 
*/
 
/*
    目前可避免以下crash  NSDictionary和NSMutableDictionary 调用 objectForKey： key为nil不会崩溃
 
 1.+ (instancetype)dictionaryWithObjects:(const ObjectType _Nonnull [_Nullable])objects forKeys:(const KeyType <NSCopying> _Nonnull [_Nullable])keys count:(NSUInteger)cnt会调用2中的方法
 2.- (instancetype)initWithObjects:(const ObjectType _Nonnull [_Nullable])objects forKeys:(const KeyType _Nonnull [_Nullable])keys count:(NSUInteger)cnt;
 3. @{@"key1":@"value1",@"key2":@"value2"}也会调用2中的方法
 4. - (instancetype)initWithObjects:(NSArray<ObjectType> *)objects forKeys:(NSArray<KeyType <NSCopying>> *)keys;
 */
