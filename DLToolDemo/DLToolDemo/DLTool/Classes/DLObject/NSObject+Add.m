#import "NSObject+Add.h"
#import <objc/objc.h>
#import <objc/runtime.h>
#import "DLSafeProtector.h"
#import "DLJsonToModel.h"
#import <objc/message.h>
#import "DLClassInfo.h"

#define force_inline __inline__ __attribute__((always_inline))

/// Foundation Class Type
typedef NS_ENUM (NSUInteger, DLEncodingNSType) {
    DLEncodingTypeNSUnknown = 0,
    DLEncodingTypeNSString,
    DLEncodingTypeNSMutableString,
    DLEncodingTypeNSValue,
    DLEncodingTypeNSNumber,
    DLEncodingTypeNSDecimalNumber,
    DLEncodingTypeNSData,
    DLEncodingTypeNSMutableData,
    DLEncodingTypeNSDate,
    DLEncodingTypeNSURL,
    DLEncodingTypeNSArray,
    DLEncodingTypeNSMutableArray,
    DLEncodingTypeNSDictionary,
    DLEncodingTypeNSMutableDictionary,
    DLEncodingTypeNSSet,
    DLEncodingTypeNSMutableSet,
};

/// Get the Foundation class type from property info.
static force_inline DLEncodingNSType DLClassGetNSType(Class cls) {
    if (!cls) return DLEncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return DLEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return DLEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return DLEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return DLEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return DLEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return DLEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return DLEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return DLEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return DLEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return DLEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return DLEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return DLEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return DLEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return DLEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return DLEncodingTypeNSSet;
    return DLEncodingTypeNSUnknown;
}

/// Whether the type is c number.
static force_inline BOOL DLEncodingTypeIsCNumber(DLEncodingType type) {
    switch (type & DLEncodingTypeMask) {
        case DLEncodingTypeBool:
        case DLEncodingTypeInt8:
        case DLEncodingTypeUInt8:
        case DLEncodingTypeInt16:
        case DLEncodingTypeUInt16:
        case DLEncodingTypeInt32:
        case DLEncodingTypeUInt32:
        case DLEncodingTypeInt64:
        case DLEncodingTypeUInt64:
        case DLEncodingTypeFloat:
        case DLEncodingTypeDouble:
        case DLEncodingTypeLongDouble: return YES;
        default: return NO;
    }
}

/// Parse a number value from 'id'.
static force_inline NSNumber *DLNSNumberCreateFromID(__unsafe_unretained id value) {
    static NSCharacterSet *dot;
    static NSDictionary *dic;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
        dic = @{@"TRUE" :   @(YES),
                @"True" :   @(YES),
                @"true" :   @(YES),
                @"FALSE" :  @(NO),
                @"False" :  @(NO),
                @"false" :  @(NO),
                @"YES" :    @(YES),
                @"Yes" :    @(YES),
                @"yes" :    @(YES),
                @"NO" :     @(NO),
                @"No" :     @(NO),
                @"no" :     @(NO),
                @"NIL" :    (id)kCFNull,
                @"Nil" :    (id)kCFNull,
                @"nil" :    (id)kCFNull,
                @"NULL" :   (id)kCFNull,
                @"Null" :   (id)kCFNull,
                @"null" :   (id)kCFNull,
                @"(NULL)" : (id)kCFNull,
                @"(Null)" : (id)kCFNull,
                @"(null)" : (id)kCFNull,
                @"<NULL>" : (id)kCFNull,
                @"<Null>" : (id)kCFNull,
                @"<null>" : (id)kCFNull};
    });
    
    if (!value || value == (id)kCFNull) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSNumber *num = dic[value];
        if (num) {
            if (num == (id)kCFNull) return nil;
            return num;
        }
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            double num = atof(cstring);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        } else {
            const char *cstring = ((NSString *)value).UTF8String;
            if (!cstring) return nil;
            return @(atoll(cstring));
        }
    }
    return nil;
}

/// Parse string to date.
static force_inline NSDate *DLNSDateFromString(__unsafe_unretained NSString *string) {
    typedef NSDate* (^DLNSDateParseBlock)(NSString *string);
    #define kParserNum 34
    static DLNSDateParseBlock blocks[kParserNum + 1] = {0};
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            /*
             2014-01-20  // Google
             */
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter.dateFormat = @"dldl-MM-dd";
            blocks[10] = ^(NSString *string) { return [formatter dateFromString:string]; };
        }
        
        {
            /*
             2014-01-20 12:24:48
             2014-01-20T12:24:48   // Google
             2014-01-20 12:24:48.000
             2014-01-20T12:24:48.000
             */
            NSDateFormatter *formatter1 = [[NSDateFormatter alloc] init];
            formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter1.dateFormat = @"dldl-MM-dd'T'HH:mm:ss";
            
            NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter2.dateFormat = @"dldl-MM-dd HH:mm:ss";

            NSDateFormatter *formatter3 = [[NSDateFormatter alloc] init];
            formatter3.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter3.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter3.dateFormat = @"dldl-MM-dd'T'HH:mm:ss.SSS";

            NSDateFormatter *formatter4 = [[NSDateFormatter alloc] init];
            formatter4.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            formatter4.dateFormat = @"dldl-MM-dd HH:mm:ss.SSS";
            
            blocks[19] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter1 dateFromString:string];
                } else {
                    return [formatter2 dateFromString:string];
                }
            };

            blocks[23] = ^(NSString *string) {
                if ([string characterAtIndex:10] == 'T') {
                    return [formatter3 dateFromString:string];
                } else {
                    return [formatter4 dateFromString:string];
                }
            };
        }
        
        {
            /*
             2014-01-20T12:24:48Z        // Github, Apple
             2014-01-20T12:24:48+0800    // Facebook
             2014-01-20T12:24:48+12:00   // Google
             2014-01-20T12:24:48.000Z
             2014-01-20T12:24:48.000+0800
             2014-01-20T12:24:48.000+12:00
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"dldl-MM-dd'T'HH:mm:ssZ";

            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"dldl-MM-dd'T'HH:mm:ss.SSSZ";

            blocks[20] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[24] = ^(NSString *string) { return [formatter dateFromString:string]?: [formatter2 dateFromString:string]; };
            blocks[25] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[28] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
            blocks[29] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
        
        {
            /*
             Fri Sep 04 00:12:21 +0800 2015 // Weibo, Twitter
             Fri Sep 04 00:12:21.000 +0800 2015
             */
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z dldl";

            NSDateFormatter *formatter2 = [NSDateFormatter new];
            formatter2.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            formatter2.dateFormat = @"EEE MMM dd HH:mm:ss.SSS Z dldl";

            blocks[30] = ^(NSString *string) { return [formatter dateFromString:string]; };
            blocks[34] = ^(NSString *string) { return [formatter2 dateFromString:string]; };
        }
    });
    if (!string) return nil;
    if (string.length > kParserNum) return nil;
    DLNSDateParseBlock parser = blocks[string.length];
    if (!parser) return nil;
    return parser(string);
    #undef kParserNum
}


/// Get the 'NSBlock' class.
static force_inline Class DLNSBlockClass() {
    static Class cls;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void (^block)(void) = ^{};
        cls = ((NSObject *)block).class;
        while (class_getSuperclass(cls) != [NSObject class]) {
            cls = class_getSuperclass(cls);
        }
    });
    return cls; // current is "NSBlock"
}



/**
 Get the ISO date formatter.
 
 ISO8601 format example:
 2010-07-09T16:13:30+12:00
 2011-01-11T11:11:11+0000
 2011-01-26T19:06:43Z
 
 length: 20/24/25
 */
static force_inline NSDateFormatter *DLISODateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"dldl-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}

/// Get the value with key paths from dictionary
/// The dic should be NSDictionary, and the keyPath should not be nil.
static force_inline id DLValueForKeyPath(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *keyPaths) {
    id value = nil;
    for (NSUInteger i = 0, max = keyPaths.count; i < max; i++) {
        value = dic[keyPaths[i]];
        if (i + 1 < max) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                dic = value;
            } else {
                return nil;
            }
        }
    }
    return value;
}

/// Get the value with multi key (or key path) from dictionary
/// The dic should be NSDictionary
static force_inline id DLValueForMultiKeys(__unsafe_unretained NSDictionary *dic, __unsafe_unretained NSArray *multiKeys) {
    id value = nil;
    for (NSString *key in multiKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            value = dic[key];
            if (value) break;
        } else {
            value = DLValueForKeyPath(dic, (NSArray *)key);
            if (value) break;
        }
    }
    return value;
}




/// A property info in object model.
@interface _DLModelPropertyMeta : NSObject {
    @package
    NSString *_name;             ///< property's name
    DLEncodingType _type;        ///< property's type
    DLEncodingNSType _nsType;    ///< property's Foundation type
    BOOL _isCNumber;             ///< is c number type
    Class _cls;                  ///< property's class, or nil
    Class _genericCls;           ///< container's generic class, or nil if threr's no generic class
    SEL _getter;                 ///< getter, or nil if the instances cannot respond
    SEL _setter;                 ///< setter, or nil if the instances cannot respond
    BOOL _isKVCCompatible;       ///< YES if it can access with key-value coding
    BOOL _isStructAvailableForKeyedArchiver; ///< YES if the struct can encoded with keyed archiver/unarchiver
    BOOL _hasCustomClassFromDictionary; ///< class/generic class implements +modelCustomClassForDictionary:
    
    /*
     property->key:       _mappedToKey:key     _mappedToKeyPath:nil            _mappedToKeyArray:nil
     property->keyPath:   _mappedToKey:keyPath _mappedToKeyPath:keyPath(array) _mappedToKeyArray:nil
     property->keys:      _mappedToKey:keys[0] _mappedToKeyPath:nil/keyPath    _mappedToKeyArray:keys(array)
     */
    NSString *_mappedToKey;      ///< the key mapped to
    NSArray *_mappedToKeyPath;   ///< the key path mapped to (nil if the name is not key path)
    NSArray *_mappedToKeyArray;  ///< the key(NSString) or keyPath(NSArray) array (nil if not mapped to multiple keys)
    DLClassPropertyInfo *_info;  ///< property's info
    _DLModelPropertyMeta *_next; ///< next meta if there are multiple properties mapped to the same key.
}
@end

@implementation _DLModelPropertyMeta
+ (instancetype)metaWithClassInfo:(DLClassInfo *)classInfo propertyInfo:(DLClassPropertyInfo *)propertyInfo generic:(Class)generic {
    
    // support pseudo generic class with protocol name
    if (!generic && propertyInfo.protocols) {
        for (NSString *protocol in propertyInfo.protocols) {
            Class cls = objc_getClass(protocol.UTF8String);
            if (cls) {
                generic = cls;
                break;
            }
        }
    }
    
    _DLModelPropertyMeta *meta = [self new];
    meta->_name = propertyInfo.name;
    meta->_type = propertyInfo.type;
    meta->_info = propertyInfo;
    meta->_genericCls = generic;
    
    if ((meta->_type & DLEncodingTypeMask) == DLEncodingTypeObject) {
        meta->_nsType = DLClassGetNSType(propertyInfo.cls);
    } else {
        meta->_isCNumber = DLEncodingTypeIsCNumber(meta->_type);
    }
    if ((meta->_type & DLEncodingTypeMask) == DLEncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
    }
    meta->_cls = propertyInfo.cls;
    
    if (generic) {
        meta->_hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta->_cls && meta->_nsType == DLEncodingTypeNSUnknown) {
        meta->_hasCustomClassFromDictionary = [meta->_cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta->_getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta->_setter = propertyInfo.setter;
        }
    }
    
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation object)
         */
        switch (meta->_type & DLEncodingTypeMask) {
            case DLEncodingTypeBool:
            case DLEncodingTypeInt8:
            case DLEncodingTypeUInt8:
            case DLEncodingTypeInt16:
            case DLEncodingTypeUInt16:
            case DLEncodingTypeInt32:
            case DLEncodingTypeUInt32:
            case DLEncodingTypeInt64:
            case DLEncodingTypeUInt64:
            case DLEncodingTypeFloat:
            case DLEncodingTypeDouble:
            case DLEncodingTypeObject:
            case DLEncodingTypeClass:
            case DLEncodingTypeBlock:
            case DLEncodingTypeStruct:
            case DLEncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default: break;
        }
    }
    
    return meta;
}
@end


/// A class info in object model.
@interface _DLModelMeta : NSObject {
    @package
    DLClassInfo *_classInfo;
    /// Key:mapped key and key path, Value:_DLModelPropertyMeta.
    NSDictionary *_mapper;
    /// Array<_DLModelPropertyMeta>, all property meta of this model.
    NSArray *_allPropertyMetas;
    /// Array<_DLModelPropertyMeta>, property meta which is mapped to a key path.
    NSArray *_keyPathPropertyMetas;
    /// Array<_DLModelPropertyMeta>, property meta which is mapped to multi keys.
    NSArray *_multiKeysPropertyMetas;
    /// The number of mapped key (and key path), same to _mapper.count.
    NSUInteger _keyMappedCount;
    /// Model class type.
    DLEncodingNSType _nsType;
    
    BOOL _hasCustomWillTransformFromDictionary;
    BOOL _hasCustomTransformFromDictionary;
    BOOL _hasCustomTransformToDictionary;
    BOOL _hasCustomClassFromDictionary;
}
@end

@implementation _DLModelMeta
- (instancetype)initWithClass:(Class)cls {
    DLClassInfo *classInfo = [DLClassInfo classInfoWithClass:cls];
    if (!classInfo) return nil;
    self = [super init];
    
    // Get black list
    NSSet *blacklist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyBlacklist)]) {
        NSArray *properties = [(id<DLModel>)cls modelPropertyBlacklist];
        if (properties) {
            blacklist = [NSSet setWithArray:properties];
        }
    }
    
    // Get white list
    NSSet *whitelist = nil;
    if ([cls respondsToSelector:@selector(modelPropertyWhitelist)]) {
        NSArray *properties = [(id<DLModel>)cls modelPropertyWhitelist];
        if (properties) {
            whitelist = [NSSet setWithArray:properties];
        }
    }
    
    // Get container property's generic class
    NSDictionary *genericMapper = nil;
    if ([cls respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
        genericMapper = [(id<DLModel>)cls modelContainerPropertyGenericClass];
        if (genericMapper) {
            NSMutableDictionary *tmp = [NSMutableDictionary new];
            [genericMapper enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isKindOfClass:[NSString class]]) return;
                Class meta = object_getClass(obj);
                if (!meta) return;
                if (class_isMetaClass(meta)) {
                    tmp[key] = obj;
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class cls = NSClassFromString(obj);
                    if (cls) {
                        tmp[key] = cls;
                    }
                }
            }];
            genericMapper = tmp;
        }
    }
    
    // Create all property metas.
    NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
    DLClassInfo *curClassInfo = classInfo;
    while (curClassInfo && curClassInfo.superCls != nil) { // recursive parse super class, but ignore root class (NSObject/NSProxy)
        for (DLClassPropertyInfo *propertyInfo in curClassInfo.propertyInfos.allValues) {
            if (!propertyInfo.name) continue;
            if (blacklist && [blacklist containsObject:propertyInfo.name]) continue;
            if (whitelist && ![whitelist containsObject:propertyInfo.name]) continue;
            _DLModelPropertyMeta *meta = [_DLModelPropertyMeta metaWithClassInfo:classInfo
                                                                    propertyInfo:propertyInfo
                                                                         generic:genericMapper[propertyInfo.name]];
            if (!meta || !meta->_name) continue;
            if (!meta->_getter || !meta->_setter) continue;
            if (allPropertyMetas[meta->_name]) continue;
            allPropertyMetas[meta->_name] = meta;
        }
        curClassInfo = curClassInfo.superClassInfo;
    }
    if (allPropertyMetas.count) _allPropertyMetas = allPropertyMetas.allValues.copy;
    
    // create mapper
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];
    NSMutableArray *multiKeysPropertyMetas = [NSMutableArray new];
    
    if ([cls respondsToSelector:@selector(modelCustomPropertyMapper)]) {
        NSDictionary *customMapper = [(id <DLModel>)cls modelCustomPropertyMapper];
        [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {
            _DLModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
            if (!propertyMeta) return;
            [allPropertyMetas removeObjectForKey:propertyName];
            
            if ([mappedToKey isKindOfClass:[NSString class]]) {
                if (mappedToKey.length == 0) return;
                
                propertyMeta->_mappedToKey = mappedToKey;
                NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                for (NSString *onePath in keyPath) {
                    if (onePath.length == 0) {
                        NSMutableArray *tmp = keyPath.mutableCopy;
                        [tmp removeObject:@""];
                        keyPath = tmp;
                        break;
                    }
                }
                if (keyPath.count > 1) {
                    propertyMeta->_mappedToKeyPath = keyPath;
                    [keyPathPropertyMetas addObject:propertyMeta];
                }
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
                
            } else if ([mappedToKey isKindOfClass:[NSArray class]]) {
                
                NSMutableArray *mappedToKeyArray = [NSMutableArray new];
                for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                    if (![oneKey isKindOfClass:[NSString class]]) continue;
                    if (oneKey.length == 0) continue;
                    
                    NSArray *keyPath = [oneKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        [mappedToKeyArray addObject:keyPath];
                    } else {
                        [mappedToKeyArray addObject:oneKey];
                    }
                    
                    if (!propertyMeta->_mappedToKey) {
                        propertyMeta->_mappedToKey = oneKey;
                        propertyMeta->_mappedToKeyPath = keyPath.count > 1 ? keyPath : nil;
                    }
                }
                if (!propertyMeta->_mappedToKey) return;
                
                propertyMeta->_mappedToKeyArray = mappedToKeyArray;
                [multiKeysPropertyMetas addObject:propertyMeta];
                
                propertyMeta->_next = mapper[mappedToKey] ?: nil;
                mapper[mappedToKey] = propertyMeta;
            }
        }];
    }
    
    [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, _DLModelPropertyMeta *propertyMeta, BOOL *stop) {
        propertyMeta->_mappedToKey = name;
        propertyMeta->_next = mapper[name] ?: nil;
        mapper[name] = propertyMeta;
    }];
    
    if (mapper.count) _mapper = mapper;
    if (keyPathPropertyMetas) _keyPathPropertyMetas = keyPathPropertyMetas;
    if (multiKeysPropertyMetas) _multiKeysPropertyMetas = multiKeysPropertyMetas;
    
    _classInfo = classInfo;
    _keyMappedCount = _allPropertyMetas.count;
    _nsType = DLClassGetNSType(cls);
    _hasCustomWillTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomWillTransformFromDictionary:)]);
    _hasCustomTransformFromDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformFromDictionary:)]);
    _hasCustomTransformToDictionary = ([cls instancesRespondToSelector:@selector(modelCustomTransformToDictionary:)]);
    _hasCustomClassFromDictionary = ([cls respondsToSelector:@selector(modelCustomClassForDictionary:)]);
    
    return self;
}

/// Returns the cached model class meta
+ (instancetype)metaWithClass:(Class)cls {
    if (!cls) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    _DLModelMeta *meta = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!meta || meta->_classInfo.needUpdate) {
        meta = [[_DLModelMeta alloc] initWithClass:cls];
        if (meta) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(meta));
            dispatch_semaphore_signal(lock);
        }
    }
    return meta;
}

@end


/**
 Get number from property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.getter should not be nil.
 @return A number object, or nil if failed.
 */
static force_inline NSNumber *ModelCreateNumberFromProperty(__unsafe_unretained id model,
                                                            __unsafe_unretained _DLModelPropertyMeta *meta) {
    switch (meta->_type & DLEncodingTypeMask) {
        case DLEncodingTypeBool: {
            return @(((bool (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeInt8: {
            return @(((int8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeUInt8: {
            return @(((uint8_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeInt16: {
            return @(((int16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeUInt16: {
            return @(((uint16_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeInt32: {
            return @(((int32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeUInt32: {
            return @(((uint32_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeInt64: {
            return @(((int64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeUInt64: {
            return @(((uint64_t (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter));
        }
        case DLEncodingTypeFloat: {
            float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case DLEncodingTypeDouble: {
            double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        case DLEncodingTypeLongDouble: {
            double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
            if (isnan(num) || isinf(num)) return nil;
            return @(num);
        }
        default: return nil;
    }
}

/**
 Set number to property.
 @discussion Caller should hold strong reference to the parameters before this function returns.
 @param model Should not be nil.
 @param num   Can be nil.
 @param meta  Should not be nil, meta.isCNumber should be YES, meta.setter should not be nil.
 */
static force_inline void ModelSetNumberToProperty(__unsafe_unretained id model,
                                                  __unsafe_unretained NSNumber *num,
                                                  __unsafe_unretained _DLModelPropertyMeta *meta) {
    switch (meta->_type & DLEncodingTypeMask) {
        case DLEncodingTypeBool: {
            ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)model, meta->_setter, num.boolValue);
        } break;
        case DLEncodingTypeInt8: {
            ((void (*)(id, SEL, int8_t))(void *) objc_msgSend)((id)model, meta->_setter, (int8_t)num.charValue);
        } break;
        case DLEncodingTypeUInt8: {
            ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint8_t)num.unsignedCharValue);
        } break;
        case DLEncodingTypeInt16: {
            ((void (*)(id, SEL, int16_t))(void *) objc_msgSend)((id)model, meta->_setter, (int16_t)num.shortValue);
        } break;
        case DLEncodingTypeUInt16: {
            ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint16_t)num.unsignedShortValue);
        } break;
        case DLEncodingTypeInt32: {
            ((void (*)(id, SEL, int32_t))(void *) objc_msgSend)((id)model, meta->_setter, (int32_t)num.intValue);
        }
        case DLEncodingTypeUInt32: {
            ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint32_t)num.unsignedIntValue);
        } break;
        case DLEncodingTypeInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.longLongValue);
            }
        } break;
        case DLEncodingTypeUInt64: {
            if ([num isKindOfClass:[NSDecimalNumber class]]) {
                ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)((id)model, meta->_setter, (int64_t)num.stringValue.longLongValue);
            } else {
                ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)model, meta->_setter, (uint64_t)num.unsignedLongLongValue);
            }
        } break;
        case DLEncodingTypeFloat: {
            float f = num.floatValue;
            if (isnan(f) || isinf(f)) f = 0;
            ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)model, meta->_setter, f);
        } break;
        case DLEncodingTypeDouble: {
            double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)model, meta->_setter, d);
        } break;
        case DLEncodingTypeLongDouble: {
            long double d = num.doubleValue;
            if (isnan(d) || isinf(d)) d = 0;
            ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)model, meta->_setter, (long double)d);
        } // break; commented for code coverage in next line
        default: break;
    }
}

/**
 Set value to model with a property meta.
 
 @discussion Caller should hold strong reference to the parameters before this function returns.
 
 @param model Should not be nil.
 @param value Should not be nil, but can be NSNull.
 @param meta  Should not be nil, and meta->_setter should not be nil.
 */
static void ModelSetValueForProperty(__unsafe_unretained id model,
                                     __unsafe_unretained id value,
                                     __unsafe_unretained _DLModelPropertyMeta *meta) {
    if (meta->_isCNumber) {
        NSNumber *num = DLNSNumberCreateFromID(value);
        ModelSetNumberToProperty(model, num, meta);
        if (num) [num class]; // hold the number
    } else if (meta->_nsType) {
        if (value == (id)kCFNull) {
            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
        } else {
            switch (meta->_nsType) {
                case DLEncodingTypeNSString:
                case DLEncodingTypeNSMutableString: {
                    if ([value isKindOfClass:[NSString class]]) {
                        if (meta->_nsType == DLEncodingTypeNSString) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSString *)value).mutableCopy);
                        }
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == DLEncodingTypeNSString) ?
                                                                       ((NSNumber *)value).stringValue :
                                                                       ((NSNumber *)value).stringValue.mutableCopy);
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSMutableString *string = [[NSMutableString alloc] initWithData:value encoding:NSUTF8StringEncoding];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, string);
                    } else if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == DLEncodingTypeNSString) ?
                                                                       ((NSURL *)value).absoluteString :
                                                                       ((NSURL *)value).absoluteString.mutableCopy);
                    } else if ([value isKindOfClass:[NSAttributedString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                       meta->_setter,
                                                                       (meta->_nsType == DLEncodingTypeNSString) ?
                                                                       ((NSAttributedString *)value).string :
                                                                       ((NSAttributedString *)value).string.mutableCopy);
                    }
                } break;
                    
                case DLEncodingTypeNSValue:
                case DLEncodingTypeNSNumber:
                case DLEncodingTypeNSDecimalNumber: {
                    if (meta->_nsType == DLEncodingTypeNSNumber) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, DLNSNumberCreateFromID(value));
                    } else if (meta->_nsType == DLEncodingTypeNSDecimalNumber) {
                        if ([value isKindOfClass:[NSDecimalNumber class]]) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else if ([value isKindOfClass:[NSNumber class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithDecimal:[((NSNumber *)value) decimalValue]];
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, decNum);
                        } else if ([value isKindOfClass:[NSString class]]) {
                            NSDecimalNumber *decNum = [NSDecimalNumber decimalNumberWithString:value];
                            NSDecimal dec = decNum.decimalValue;
                            if (dec._length == 0 && dec._isNegative) {
                                decNum = nil; // NaN
                            }
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, decNum);
                        }
                    } else { // DLEncodingTypeNSValue
                        if ([value isKindOfClass:[NSValue class]]) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        }
                    }
                } break;
                    
                case DLEncodingTypeNSData:
                case DLEncodingTypeNSMutableData: {
                    if ([value isKindOfClass:[NSData class]]) {
                        if (meta->_nsType == DLEncodingTypeNSData) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                        } else {
                            NSMutableData *data = ((NSData *)value).mutableCopy;
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                        }
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                        if (meta->_nsType == DLEncodingTypeNSMutableData) {
                            data = ((NSData *)data).mutableCopy;
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, data);
                    }
                } break;
                    
                case DLEncodingTypeNSDate: {
                    if ([value isKindOfClass:[NSDate class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, DLNSDateFromString(value));
                    }
                } break;
                    
                case DLEncodingTypeNSURL: {
                    if ([value isKindOfClass:[NSURL class]]) {
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                    } else if ([value isKindOfClass:[NSString class]]) {
                        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                        NSString *str = [value stringByTrimmingCharactersInSet:set];
                        if (str.length == 0) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, nil);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, [[NSURL alloc] initWithString:str]);
                        }
                    }
                } break;
                    
                case DLEncodingTypeNSArray:
                case DLEncodingTypeNSMutableArray: {
                    if (meta->_genericCls) {
                        NSArray *valueArr = nil;
                        if ([value isKindOfClass:[NSArray class]]) valueArr = value;
                        else if ([value isKindOfClass:[NSSet class]]) valueArr = ((NSSet *)value).allObjects;
                        if (valueArr) {
                            NSMutableArray *objectArr = [NSMutableArray new];
                            for (id one in valueArr) {
                                if ([one isKindOfClass:meta->_genericCls]) {
                                    [objectArr addObject:one];
                                } else if ([one isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:one];
                                        if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne dl_modelSetWithDictionary:one];
                                    if (newOne) [objectArr addObject:newOne];
                                }
                            }
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, objectArr);
                        }
                    } else {
                        if ([value isKindOfClass:[NSArray class]]) {
                            if (meta->_nsType == DLEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                               meta->_setter,
                                                                               ((NSArray *)value).mutableCopy);
                            }
                        } else if ([value isKindOfClass:[NSSet class]]) {
                            if (meta->_nsType == DLEncodingTypeNSArray) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, ((NSSet *)value).allObjects);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                               meta->_setter,
                                                                               ((NSSet *)value).allObjects.mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case DLEncodingTypeNSDictionary:
                case DLEncodingTypeNSMutableDictionary: {
                    if ([value isKindOfClass:[NSDictionary class]]) {
                        if (meta->_genericCls) {
                            NSMutableDictionary *dic = [NSMutableDictionary new];
                            [((NSDictionary *)value) enumerateKeysAndObjectsUsingBlock:^(NSString *oneKey, id oneValue, BOOL *stop) {
                                if ([oneValue isKindOfClass:[NSDictionary class]]) {
                                    Class cls = meta->_genericCls;
                                    if (meta->_hasCustomClassFromDictionary) {
                                        cls = [cls modelCustomClassForDictionary:oneValue];
                                        if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                    }
                                    NSObject *newOne = [cls new];
                                    [newOne dl_modelSetWithDictionary:(id)oneValue];
                                    if (newOne) dic[oneKey] = newOne;
                                }
                            }];
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, dic);
                        } else {
                            if (meta->_nsType == DLEncodingTypeNSDictionary) {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, value);
                            } else {
                                ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                               meta->_setter,
                                                                               ((NSDictionary *)value).mutableCopy);
                            }
                        }
                    }
                } break;
                    
                case DLEncodingTypeNSSet:
                case DLEncodingTypeNSMutableSet: {
                    NSSet *valueSet = nil;
                    if ([value isKindOfClass:[NSArray class]]) valueSet = [NSMutableSet setWithArray:value];
                    else if ([value isKindOfClass:[NSSet class]]) valueSet = ((NSSet *)value);
                    
                    if (meta->_genericCls) {
                        NSMutableSet *set = [NSMutableSet new];
                        for (id one in valueSet) {
                            if ([one isKindOfClass:meta->_genericCls]) {
                                [set addObject:one];
                            } else if ([one isKindOfClass:[NSDictionary class]]) {
                                Class cls = meta->_genericCls;
                                if (meta->_hasCustomClassFromDictionary) {
                                    cls = [cls modelCustomClassForDictionary:one];
                                    if (!cls) cls = meta->_genericCls; // for xcode code coverage
                                }
                                NSObject *newOne = [cls new];
                                [newOne dl_modelSetWithDictionary:one];
                                if (newOne) [set addObject:newOne];
                            }
                        }
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, set);
                    } else {
                        if (meta->_nsType == DLEncodingTypeNSSet) {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, valueSet);
                        } else {
                            ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model,
                                                                           meta->_setter,
                                                                           ((NSSet *)valueSet).mutableCopy);
                        }
                    }
                } // break; commented for code coverage in next line
                    
                default: break;
            }
        }
    } else {
        BOOL isNull = (value == (id)kCFNull);
        switch (meta->_type & DLEncodingTypeMask) {
            case DLEncodingTypeObject: {
                if (isNull) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)nil);
                } else if ([value isKindOfClass:meta->_cls] || !meta->_cls) {
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)value);
                } else if ([value isKindOfClass:[NSDictionary class]]) {
                    NSObject *one = nil;
                    if (meta->_getter) {
                        one = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, meta->_getter);
                    }
                    if (one) {
                        [one dl_modelSetWithDictionary:value];
                    } else {
                        Class cls = meta->_cls;
                        if (meta->_hasCustomClassFromDictionary) {
                            cls = [cls modelCustomClassForDictionary:value];
                            if (!cls) cls = meta->_genericCls; // for xcode code coverage
                        }
                        one = [cls new];
                        [one dl_modelSetWithDictionary:value];
                        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)model, meta->_setter, (id)one);
                    }
                }
            } break;
                
            case DLEncodingTypeClass: {
                if (isNull) {
                    ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)NULL);
                } else {
                    Class cls = nil;
                    if ([value isKindOfClass:[NSString class]]) {
                        cls = NSClassFromString(value);
                        if (cls) {
                            ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)cls);
                        }
                    } else {
                        cls = object_getClass(value);
                        if (cls) {
                            if (class_isMetaClass(cls)) {
                                ((void (*)(id, SEL, Class))(void *) objc_msgSend)((id)model, meta->_setter, (Class)value);
                            }
                        }
                    }
                }
            } break;
                
            case  DLEncodingTypeSEL: {
                if (isNull) {
                    ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)NULL);
                } else if ([value isKindOfClass:[NSString class]]) {
                    SEL sel = NSSelectorFromString(value);
                    if (sel) ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)model, meta->_setter, (SEL)sel);
                }
            } break;
                
            case DLEncodingTypeBlock: {
                if (isNull) {
                    ((void (*)(id, SEL, void (^)(void)))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)(void))NULL);
                } else if ([value isKindOfClass:DLNSBlockClass()]) {
                    ((void (*)(id, SEL, void (^)(void)))(void *) objc_msgSend)((id)model, meta->_setter, (void (^)(void))value);
                }
            } break;
                
            case DLEncodingTypeStruct:
            case DLEncodingTypeUnion:
            case DLEncodingTypeCArray: {
                if ([value isKindOfClass:[NSValue class]]) {
                    const char *valueType = ((NSValue *)value).objCType;
                    const char *metaType = meta->_info.typeEncoding.UTF8String;
                    if (valueType && metaType && strcmp(valueType, metaType) == 0) {
                        [model setValue:value forKey:meta->_name];
                    }
                }
            } break;
                
            case DLEncodingTypePointer:
            case DLEncodingTypeCString: {
                if (isNull) {
                    ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, (void *)NULL);
                } else if ([value isKindOfClass:[NSValue class]]) {
                    NSValue *nsValue = value;
                    if (nsValue.objCType && strcmp(nsValue.objCType, "^v") == 0) {
                        ((void (*)(id, SEL, void *))(void *) objc_msgSend)((id)model, meta->_setter, nsValue.pointerValue);
                    }
                }
            } // break; commented for code coverage in next line
                
            default: break;
        }
    }
}


typedef struct {
    void *modelMeta;  ///< _DLModelMeta
    void *model;      ///< id (self)
    void *dictionary; ///< NSDictionary (json)
} ModelSetContext;

/**
 Apply function for dictionary, to set the key-value pair to model.
 
 @param _key     should not be nil, NSString.
 @param _value   should not be nil.
 @param _context _context.modelMeta and _context.model should not be nil.
 */
static void ModelSetWithDictionaryFunction(const void *_key, const void *_value, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained _DLModelMeta *meta = (__bridge _DLModelMeta *)(context->modelMeta);
    __unsafe_unretained _DLModelPropertyMeta *propertyMeta = [meta->_mapper objectForKey:(__bridge id)(_key)];
    __unsafe_unretained id model = (__bridge id)(context->model);
    while (propertyMeta) {
        if (propertyMeta->_setter) {
            ModelSetValueForProperty(model, (__bridge __unsafe_unretained id)_value, propertyMeta);
        }
        propertyMeta = propertyMeta->_next;
    };
}

/**
 Apply function for model property meta, to set dictionary to model.
 
 @param _propertyMeta should not be nil, _DLModelPropertyMeta.
 @param _context      _context.model and _context.dictionary should not be nil.
 */
static void ModelSetWithPropertyMetaArrayFunction(const void *_propertyMeta, void *_context) {
    ModelSetContext *context = _context;
    __unsafe_unretained NSDictionary *dictionary = (__bridge NSDictionary *)(context->dictionary);
    __unsafe_unretained _DLModelPropertyMeta *propertyMeta = (__bridge _DLModelPropertyMeta *)(_propertyMeta);
    if (!propertyMeta->_setter) return;
    id value = nil;
    
    if (propertyMeta->_mappedToKeyArray) {
        value = DLValueForMultiKeys(dictionary, propertyMeta->_mappedToKeyArray);
    } else if (propertyMeta->_mappedToKeyPath) {
        value = DLValueForKeyPath(dictionary, propertyMeta->_mappedToKeyPath);
    } else {
        value = [dictionary objectForKey:propertyMeta->_mappedToKey];
    }
    
    if (value) {
        __unsafe_unretained id model = (__bridge id)(context->model);
        ModelSetValueForProperty(model, value, propertyMeta);
    }
}

/**
 Returns a valid JSON object (NSArray/NSDictionary/NSString/NSNumber/NSNull),
 or nil if an error occurs.
 
 @param model Model, can be nil.
 @return JSON object, nil if an error occurs.
 */
static id ModelToJSONObjectRecursive(NSObject *model) {
    if (!model || model == (id)kCFNull) return model;
    if ([model isKindOfClass:[NSString class]]) return model;
    if ([model isKindOfClass:[NSNumber class]]) return model;
    if ([model isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [((NSDictionary *)model) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) return;
            id jsonObj = ModelToJSONObjectRecursive(obj);
            if (!jsonObj) jsonObj = (id)kCFNull;
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    if ([model isKindOfClass:[NSSet class]]) {
        NSArray *array = ((NSSet *)model).allObjects;
        if ([NSJSONSerialization isValidJSONObject:array]) return array;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in array) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    if ([model isKindOfClass:[NSArray class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in (NSArray *)model) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    if ([model isKindOfClass:[NSURL class]]) return ((NSURL *)model).absoluteString;
    if ([model isKindOfClass:[NSAttributedString class]]) return ((NSAttributedString *)model).string;
    if ([model isKindOfClass:[NSDate class]]) return [DLISODateFormatter() stringFromDate:(id)model];
    if ([model isKindOfClass:[NSData class]]) return nil;
    
    
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:[model class]];
    if (!modelMeta || modelMeta->_keyMappedCount == 0) return nil;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:64];
    __unsafe_unretained NSMutableDictionary *dic = result; // avoid retain and release in block
    [modelMeta->_mapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyMappedKey, _DLModelPropertyMeta *propertyMeta, BOOL *stop) {
        if (!propertyMeta->_getter) return;
        
        id value = nil;
        if (propertyMeta->_isCNumber) {
            value = ModelCreateNumberFromProperty(model, propertyMeta);
        } else if (propertyMeta->_nsType) {
            id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
            value = ModelToJSONObjectRecursive(v);
        } else {
            switch (propertyMeta->_type & DLEncodingTypeMask) {
                case DLEncodingTypeObject: {
                    id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = ModelToJSONObjectRecursive(v);
                    if (value == (id)kCFNull) value = nil;
                } break;
                case DLEncodingTypeClass: {
                    Class v = ((Class (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = v ? NSStringFromClass(v) : nil;
                } break;
                case DLEncodingTypeSEL: {
                    SEL v = ((SEL (*)(id, SEL))(void *) objc_msgSend)((id)model, propertyMeta->_getter);
                    value = v ? NSStringFromSelector(v) : nil;
                } break;
                default: break;
            }
        }
        if (!value) return;
        
        if (propertyMeta->_mappedToKeyPath) {
            NSMutableDictionary *superDic = dic;
            NSMutableDictionary *subDic = nil;
            for (NSUInteger i = 0, max = propertyMeta->_mappedToKeyPath.count; i < max; i++) {
                NSString *key = propertyMeta->_mappedToKeyPath[i];
                if (i + 1 == max) { // end
                    if (!superDic[key]) superDic[key] = value;
                    break;
                }
                
                subDic = superDic[key];
                if (subDic) {
                    if ([subDic isKindOfClass:[NSDictionary class]]) {
                        subDic = subDic.mutableCopy;
                        superDic[key] = subDic;
                    } else {
                        break;
                    }
                } else {
                    subDic = [NSMutableDictionary new];
                    superDic[key] = subDic;
                }
                superDic = subDic;
                subDic = nil;
            }
        } else {
            if (!dic[propertyMeta->_mappedToKey]) {
                dic[propertyMeta->_mappedToKey] = value;
            }
        }
    }];
    
    if (modelMeta->_hasCustomTransformToDictionary) {
        BOOL suc = [((id<DLModel>)model) modelCustomTransformToDictionary:dic];
        if (!suc) return nil;
    }
    return result;
}

/// Add indent to string (exclude first line)
static NSMutableString *ModelDescriptionAddIndent(NSMutableString *desc, NSUInteger indent) {
    for (NSUInteger i = 0, max = desc.length; i < max; i++) {
        unichar c = [desc characterAtIndex:i];
        if (c == '\n') {
            for (NSUInteger j = 0; j < indent; j++) {
                [desc insertString:@"    " atIndex:i + 1];
            }
            i += indent * 4;
            max += indent * 4;
        }
    }
    return desc;
}

/// Generaate a description string
static NSString *ModelDescription(NSObject *model) {
    static const int kDescMaxLength = 100;
    if (!model) return @"<nil>";
    if (model == (id)kCFNull) return @"<null>";
    if (![model isKindOfClass:[NSObject class]]) return [NSString stringWithFormat:@"%@",model];
    
    
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:model.class];
    switch (modelMeta->_nsType) {
        case DLEncodingTypeNSString: case DLEncodingTypeNSMutableString: {
            return [NSString stringWithFormat:@"\"%@\"",model];
        }
        
        case DLEncodingTypeNSValue:
        case DLEncodingTypeNSData: case DLEncodingTypeNSMutableData: {
            NSString *tmp = model.description;
            if (tmp.length > kDescMaxLength) {
                tmp = [tmp substringToIndex:kDescMaxLength];
                tmp = [tmp stringByAppendingString:@"..."];
            }
            return tmp;
        }
            
        case DLEncodingTypeNSNumber:
        case DLEncodingTypeNSDecimalNumber:
        case DLEncodingTypeNSDate:
        case DLEncodingTypeNSURL: {
            return [NSString stringWithFormat:@"%@",model];
        }
            
        case DLEncodingTypeNSSet: case DLEncodingTypeNSMutableSet: {
            model = ((NSSet *)model).allObjects;
        } // no break
            
        case DLEncodingTypeNSArray: case DLEncodingTypeNSMutableArray: {
            NSArray *array = (id)model;
            NSMutableString *desc = [NSMutableString new];
            if (array.count == 0) {
                return [desc stringByAppendingString:@"[]"];
            } else {
                [desc appendFormat:@"[\n"];
                for (NSUInteger i = 0, max = array.count; i < max; i++) {
                    NSObject *obj = array[i];
                    [desc appendString:@"    "];
                    [desc appendString:ModelDescriptionAddIndent(ModelDescription(obj).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
                }
                [desc appendString:@"]"];
                return desc;
            }
        }
        case DLEncodingTypeNSDictionary: case DLEncodingTypeNSMutableDictionary: {
            NSDictionary *dic = (id)model;
            NSMutableString *desc = [NSMutableString new];
            if (dic.count == 0) {
                return [desc stringByAppendingString:@"{}"];
            } else {
                NSArray *keys = dic.allKeys;
                
                [desc appendFormat:@"{\n"];
                for (NSUInteger i = 0, max = keys.count; i < max; i++) {
                    NSString *key = keys[i];
                    NSObject *value = dic[key];
                    [desc appendString:@"    "];
                    [desc appendFormat:@"%@ = %@",key, ModelDescriptionAddIndent(ModelDescription(value).mutableCopy, 1)];
                    [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
                }
                [desc appendString:@"}"];
            }
            return desc;
        }
        
        default: {
            NSMutableString *desc = [NSMutableString new];
            [desc appendFormat:@"<%@: %p>", model.class, model];
            if (modelMeta->_allPropertyMetas.count == 0) return desc;
            
            // sort property names
            NSArray *properties = [modelMeta->_allPropertyMetas
                                   sortedArrayUsingComparator:^NSComparisonResult(_DLModelPropertyMeta *p1, _DLModelPropertyMeta *p2) {
                                       return [p1->_name compare:p2->_name];
                                   }];
            
            [desc appendFormat:@" {\n"];
            for (NSUInteger i = 0, max = properties.count; i < max; i++) {
                _DLModelPropertyMeta *property = properties[i];
                NSString *propertyDesc;
                if (property->_isCNumber) {
                    NSNumber *num = ModelCreateNumberFromProperty(model, property);
                    propertyDesc = num.stringValue;
                } else {
                    switch (property->_type & DLEncodingTypeMask) {
                        case DLEncodingTypeObject: {
                            id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, property->_getter);
                            propertyDesc = ModelDescription(v);
                            if (!propertyDesc) propertyDesc = @"<nil>";
                        } break;
                        case DLEncodingTypeClass: {
                            id v = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, property->_getter);
                            propertyDesc = ((NSObject *)v).description;
                            if (!propertyDesc) propertyDesc = @"<nil>";
                        } break;
                        case DLEncodingTypeSEL: {
                            SEL sel = ((SEL (*)(id, SEL))(void *) objc_msgSend)((id)model, property->_getter);
                            if (sel) propertyDesc = NSStringFromSelector(sel);
                            else propertyDesc = @"<NULL>";
                        } break;
                        case DLEncodingTypeBlock: {
                            id block = ((id (*)(id, SEL))(void *) objc_msgSend)((id)model, property->_getter);
                            propertyDesc = block ? ((NSObject *)block).description : @"<nil>";
                        } break;
                        case DLEncodingTypeCArray: case DLEncodingTypeCString: case DLEncodingTypePointer: {
                            void *pointer = ((void* (*)(id, SEL))(void *) objc_msgSend)((id)model, property->_getter);
                            propertyDesc = [NSString stringWithFormat:@"%p",pointer];
                        } break;
                        case DLEncodingTypeStruct: case DLEncodingTypeUnion: {
                            NSValue *value = [model valueForKey:property->_name];
                            propertyDesc = value ? value.description : @"{unknown}";
                        } break;
                        default: propertyDesc = @"<unknown>";
                    }
                }
                
                propertyDesc = ModelDescriptionAddIndent(propertyDesc.mutableCopy, 1);
                [desc appendFormat:@"    %@ = %@",property->_name, propertyDesc];
                [desc appendString:(i + 1 == max) ? @"\n" : @";\n"];
            }
            [desc appendFormat:@"}"];
            return desc;
        }
    }
}

@interface DLSafeProxy:NSObject
@property (nonatomic,strong) NSException *exception;
@property (nonatomic,weak) id safe_object;
@end
@implementation DLSafeProxy
-(void)safe_crashLog{
}
@end

@interface KVOObserverInfo()

@property (nonatomic,weak) id target;
@property (nonatomic,copy)NSString *targetAddress;
@property (nonatomic,copy)NSString *targetClassName;

@property (nonatomic,weak) id observer;
@property (nonatomic,copy)NSString *observerAddress;
@property (nonatomic,copy)NSString *observerClassName;

@property (nonatomic,copy)NSString *keyPath;
@property (nonatomic,assign) void * context;


@end
@implementation KVOObserverInfo
@end

@interface DLRecursiveLock : NSRecursiveLock
@end
@implementation DLRecursiveLock
-(void)dealloc
{
    DLKVOSafeLog(@"DLRecursiveLock  ---- dealloc -------  %@",self);
}

@end

@interface NSObject()

@property (nonatomic,strong) KVOObserverInfo *safe_willRemoveObserverInfo;

//dealloc时标记有多少没移除，然后手动替他移除，比如有7个 我都替他移除掉，数量还是7，然后用户手动移除时，数量会减少，然后计算最终剩多少就是用户没有移除的，提示用户有没移除的KVO  默认为YES dealloc时改为NO
@property (nonatomic,assign) BOOL safe_notNeedRemoveKeypathFromCrashArray;

@property (nonatomic,strong) DLRecursiveLock *safe_lock;

@end

@implementation NSObject (Add)

static NSMutableSet *KVOSafeSwizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    return swizzledClasses;
}

static NSMutableDictionary *KVOSafeDeallocCrashes() {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *KVOSafeDeallocCrashes = nil;
    dispatch_once(&onceToken, ^{
        KVOSafeDeallocCrashes = [[NSMutableDictionary alloc] init];
    });
    return KVOSafeDeallocCrashes;
}

-(double)getElapsedTime:(void (^)(void))block{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    block();
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    return end-start;
}

-(BOOL)isNSString{
    if ([NSStringFromClass([self class]) isEqualToString:@"NSPlaceholderString"] || [NSStringFromClass([self class]) isEqualToString:@"__NSCFConstantString"] || [NSStringFromClass([self class]) isEqualToString:@"NSTaggedPointerString"] || [NSStringFromClass([self class]) isEqualToString:@"NSPlaceholderMutableString"]) {
        return YES;
    }
    return NO;
}

-(BOOL)isNSArray{
    if ([NSStringFromClass([self class]) isEqualToString:@"__NSPlaceholderArray"] || [NSStringFromClass([self class]) isEqualToString:@"__NSArrayI"] || [NSStringFromClass([self class]) isEqualToString:@"__NSArray0"] || [NSStringFromClass([self class]) isEqualToString:@"__NSArrayM"] || [NSStringFromClass([self class]) isEqualToString:@"__NSCFArray"] || [NSStringFromClass([self class]) isEqualToString:@"__NSSingleObjectArrayI"]) {
        return YES;
    }
    return NO;
}

-(BOOL)isNSDictionary{
    if ([NSStringFromClass([self class]) isEqualToString:@"__NSPlaceholderDictionary"] || [NSStringFromClass([self class]) isEqualToString:@"__NSDictionaryM"] || [NSStringFromClass([self class]) isEqualToString:@"__NSCFDictionary"]) {
        return YES;
    }
    return NO;
}

-(BOOL)ObjectIsNil{
    if (nil == self || [self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return NO;
}

+(void)load
{
     if ([NSStringFromClass([NSObject class]) isEqualToString:@"NSObject"]) {
         static dispatch_once_t onceToken;
         dispatch_once(&onceToken, ^{
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(methodSignatureForSelector:) newSel:@selector(safe_methodSignatureForSelector:)];
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(forwardInvocation:) newSel:@selector(safe_forwardInvocation:)];
             
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(addObserver:forKeyPath:options:context:) newSel:@selector(safe_addObserver:forKeyPath:options:context:)];
             
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(observeValueForKeyPath:ofObject:change:context:) newSel:@selector(safe_observeValueForKeyPath:ofObject:change:context:)];
             
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(removeObserver:forKeyPath:) newSel:@selector(safe_removeObserver:forKeyPath:)];
             
             [self safe_exchangeInstanceMethod:[self class] originalSel:@selector(removeObserver:forKeyPath:context:) newSel:@selector(safe_removeObserver:forKeyPath:context:)];
             
         });
     }else{
         //只有NSObject 能调用openSafeProtector其他类调用没效果
     }
}

- (NSMethodSignature *)safe_methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *ms = [self safe_methodSignatureForSelector:aSelector];
    if ([self respondsToSelector:aSelector] || ms){
        return ms;
    }
    else{
        return [DLSafeProxy instanceMethodSignatureForSelector:@selector(safe_crashLog)];
    }
}

- (void)safe_forwardInvocation:(NSInvocation *)anInvocation{
    @try {
        [self safe_forwardInvocation:anInvocation];
        
    } @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeSelector);
    } @finally {
    }
}

+ (void)dl_createModelWithJson:(NSDictionary *)json fileName:(NSString *)fileName extensionName:(NSString *)extensionName fileURL:(NSURL *)url{
    BOOL isSuccessBOOL = [DLJsonToModel dl_createDLModelWithJson:json fileName:fileName extensionName:extensionName fileURL:url error:^(NSError *error) {
        NSLog(@"%@ 转换失败", fileName);
    }];
    if (isSuccessBOOL) {
        NSLog(@"%@ 转换成功，耗时 %lf", fileName, [DLJsonToModel modelWithSpendTime:nil]);
    }
}

#pragma mark - 交换对象方法
+(void)safe_exchangeInstanceMethod:(Class)dClass originalSel:(SEL)originalSelector newSel:(SEL)newSelector{
    Method originalMethod = class_getInstanceMethod(dClass, originalSelector);
    Method newMethod = class_getInstanceMethod(dClass, newSelector);
    // Method中包含IMP函数指针，通过替换IMP，使SEL调用不同函数实现
    // isAdd 返回值表示是否添加成功
    BOOL isAdd = class_addMethod(dClass, originalSelector,
                                 method_getImplementation(newMethod),
                                 method_getTypeEncoding(newMethod));
    // class_addMethod:如果发现方法已经存在，会失败返回，也可以用来做检查用,我们这里是为了避免源方法没有实现的情况;如果方法没有存在,我们则先尝试添加被替换的方法的实现
    if (isAdd) {
        class_replaceMethod(dClass, newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        // 添加失败：说明源方法已经有实现，直接将两个方法的实现交换即
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

//最后替换的dealloc 会最先调用倒序
-(void)safe_KVOChangeDidDeallocSignal{
    //此处交换dealloc方法是借鉴RAC源码
    Class classToSwizzle=[self class];
    @synchronized (KVOSafeSwizzledClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([KVOSafeSwizzledClasses() containsObject:className]) return;
        
        SEL deallocSelector = sel_registerName("dealloc");
        
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        
        id newDealloc = ^(__unsafe_unretained id self) {
            [self safe_KVODealloc];
            NSString *classAddress=[NSString stringWithFormat:@"%p",self];
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(classToSwizzle)
                };
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
            [NSClassFromString(className) safe_dealloc_crash:classAddress];
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);
            
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        
        [KVOSafeSwizzledClasses() addObject:className];
    }
}


#pragma mark - 被监听的所有keypath 字典
- (NSMutableArray *)safe_downObservedKeyPathArray{
    NSMutableArray *array = objc_getAssociatedObject(self, _cmd);
    if (!array) {
        array = [NSMutableArray new];
        objc_setAssociatedObject(self, _cmd, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

- (void)setSafe_downObservedKeyPathArray:(NSMutableArray *)safe_downObservedKeyPathArray{
    objc_setAssociatedObject(self, @selector(safe_downObservedKeyPathArray), safe_downObservedKeyPathArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 监听了哪些对象数组
- (NSMutableArray *)safe_upObservedArray{
    @synchronized(self){
        NSMutableArray *array = objc_getAssociatedObject(self, _cmd);
        if (!array) {
            array = [NSMutableArray array];
            [self setSafe_upObservedArray:array];
        }
        return array;
    }
}

- (void)setSafe_upObservedArray:(NSMutableArray *)safe_upObservedArray{
    objc_setAssociatedObject(self, @selector(safe_upObservedArray), safe_upObservedArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)setSafe_willRemoveObserverInfo:(KVOObserverInfo *)safe_willRemoveObserverInfo{
    objc_setAssociatedObject(self, @selector(safe_willRemoveObserverInfo), safe_willRemoveObserverInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(KVOObserverInfo *)safe_willRemoveObserverInfo{
    return  objc_getAssociatedObject(self, _cmd);
}

-(void)setSafe_notNeedRemoveKeypathFromCrashArray:(BOOL)safe_notNeedRemoveKeypathFromCrashArray{
    objc_setAssociatedObject(self, @selector(safe_notNeedRemoveKeypathFromCrashArray),@(safe_notNeedRemoveKeypathFromCrashArray), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(BOOL)safe_notNeedRemoveKeypathFromCrashArray{
    return  [objc_getAssociatedObject(self, _cmd) boolValue];
}

-(void)setSafe_lock:(DLRecursiveLock *)safe_lock{
    objc_setAssociatedObject(self, @selector(safe_lock),safe_lock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(DLRecursiveLock *)safe_lock
{
    DLRecursiveLock *myLock=objc_getAssociatedObject(self, _cmd);
    return myLock;
}

-(void)safe_logKVODebugInfoWithText:(NSString*)text observer:(id)observer keyPath:(NSString*)keyPath context:(void*)context
{
    NSString *method;
    if ([text rangeOfString:@"添加"].length>0) {
        method=@" addObserver  ";
    }else{
        method=@"removeObserver";
    }
    NSString *emoji;
    if ([text rangeOfString:@"成功"].length>0) {
        emoji=@"😀😀😀😀😀";
    }else{
        emoji=@"😡😡😡😡😡";
    }

    DLKVOSafeLog(@"\n*******   %@ %@:     ##################\n\t%@(%p)  %@ %@(%p)   keyPath:%@  context:%p\n----------------------------------------",text,emoji,[self class],self,method,[observer class],observer,keyPath,context);
}

-(void)safe_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    @try{
        [self safe_observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }@catch (NSException *exception){
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeKVO);
    }@finally{
        
    }
}

// keyPath为对象的属性，通过keyPath作为Key创建对应对应的一条观察者关键路径：keyPath --> observers-self
- (void)safe_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    if(!observer||!keyPath||([keyPath isKindOfClass:[NSString class]]&&keyPath.length<=0)){
        return ;
    }
    observer.safe_notNeedRemoveKeypathFromCrashArray=YES;
    DLRecursiveLock *lock;
    @synchronized(self){
        lock =self.safe_lock;
        if (lock==nil) {
            lock=[[DLRecursiveLock alloc]init];
            lock.name=[NSString stringWithFormat:@"%@",[self class]];
            self.safe_lock=lock;
        }
    }
    [lock lock];
    
    KVOObserverInfo *info=[self safe_canAddOrRemoveObserverWithKeypathWithObserver:observer keyPath:keyPath context:context haveContext:YES isAdd:YES];
    
    if(info!=nil){
        //如果添加过了直接return
        [self safe_logKVODebugInfoWithText:@"添加失败" observer:observer keyPath:keyPath context:context];
        [lock unlock];
        return;
    }
    @try {
        [self safe_logKVODebugInfoWithText:@"添加成功" observer:observer keyPath:keyPath context:context];
        NSString *targetAddress=[NSString stringWithFormat:@"%p",self];
        NSString *observerAddress=[NSString stringWithFormat:@"%p",observer];
        KVOObserverInfo *info=[KVOObserverInfo new];
        info.target=self;
        info.observer=observer;
        info.keyPath=keyPath;
        info.context=context;
        info.targetAddress=targetAddress;
        info.observerAddress=observerAddress;
        info.targetClassName=NSStringFromClass([self class]);
        info.observerClassName=NSStringFromClass([observer class]);
        @synchronized(self.safe_downObservedKeyPathArray){
            [self.safe_downObservedKeyPathArray addObject:info];
        }
        @synchronized(observer.safe_upObservedArray){
            [observer.safe_upObservedArray addObject:info];
        }
        [self safe_addObserver:observer forKeyPath:keyPath options:options context:context];
        
        //交换dealloc方法
        [observer safe_KVOChangeDidDeallocSignal];
        [self safe_KVOChangeDidDeallocSignal];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeKVO);
    }
    @finally {
//        [self safe_logKVODebugInfoWithText:@"添加结束" observer:observer keyPath:keyPath context:context];
        [lock unlock];
    }
}

//以下两个方法的区别
//带context参数的方法，苹果是倒序遍历数组，然后判断keypath和context是否都相等，如果都相等则移除，如果没有都相等的则崩溃，如果context参数=NULL，也是相同逻辑，判断keypath是否相等，context是否等于NULL，有则移除，没有相等的则崩溃
//不带context，苹果也是倒序遍历数组，然后判断keypath是否相等(不管context是啥)，如果相等则移除，如果没有相等的则崩溃
//移除时不但要把 有哪些对象监听了自己字典移除，还要把observer的监听了哪些人字典移除
- (void)safe_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
    [self safe_allRemoveObserver:observer forKeyPath:keyPath context:nil isContext:NO];
}
- (void)safe_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context{
    [self safe_allRemoveObserver:observer forKeyPath:keyPath context:context isContext:YES];
}

/**
 @param isContext 是否有context
 */
- (void)safe_allRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context isContext:(BOOL)isContext{
    
    if(!observer||!keyPath||([keyPath isKindOfClass:[NSString class]]&&keyPath.length<=0)){
        return ;
    }
    DLRecursiveLock *lock;
    @synchronized(self){
        lock =self.safe_lock;
        if (lock==nil) {
            lock=observer.safe_lock;
            if (lock==nil) {
                lock=[[DLRecursiveLock alloc]init];
                lock.name=[NSString stringWithFormat:@"%@",[observer class]];
                observer.safe_lock=lock;
            }
        }
    }
    
    [lock lock];
    KVOObserverInfo *info=[self safe_canAddOrRemoveObserverWithKeypathWithObserver:observer keyPath:keyPath context:context haveContext:isContext isAdd:NO];
    if (info==nil) {
        // 重复删除观察者或不含有 或者keypath=nil  observer=nil
        NSString *text=@"";
        if (observer.safe_notNeedRemoveKeypathFromCrashArray) {
        }else{
            //observer走完了dealloc，然后去移除，事实上我已经替他移除完了
            text=@"主动";
        }
        [self safe_logKVODebugInfoWithText: [NSString stringWithFormat:@"%@移除失败",text] observer:observer keyPath:keyPath context:context];
        [lock unlock];
        return;
    }
    
    @try {
        if (isContext) {
            NSString *targetAddress=[NSString stringWithFormat:@"%p",self];
            NSString *observerAddress=[NSString stringWithFormat:@"%p",observer];
            //此处是因为remove  keypath context调用的还是remove keypath方法
            KVOObserverInfo *info=[KVOObserverInfo new];
            info.keyPath=keyPath;
            info.context=context;
            info.targetAddress=targetAddress;
            info.observerAddress=observerAddress;
            self.safe_willRemoveObserverInfo=info;
            [self safe_removeObserver:observer forKeyPath:keyPath context:context];
        }else{
            //safe_removeObserver:observer forKeyPath:keyPath context:
            //newContext是上面方法的参数值，因为上面方法底层调用的方法是不带context参数的remove方法
            void *newContext=NULL;
            if(self.safe_willRemoveObserverInfo){
                newContext=self.safe_willRemoveObserverInfo.context;
            }
            [self safe_removeObserver:observer forKeyPath:keyPath];
            [self safe_logKVODebugInfoWithText:@"移除成功" observer:observer keyPath:keyPath context:newContext];
        }
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeKVO);
    }
    @finally {
        if(isContext){
            self.safe_willRemoveObserverInfo=nil;
        }
        [self safe_removeSuccessObserver:observer info:info];
        [lock unlock];
    }
}

-(void)safe_removeSuccessObserver:(NSObject*)observer info:(KVOObserverInfo*)info
{
    //    NSString *key =[NSString stringWithFormat:@"%p",self];
    //哪些对象监听了自己
    NSMutableArray *downArray = self.safe_downObservedKeyPathArray;
    
    //observer监听了哪些对象
    NSMutableArray *upArray = observer.safe_upObservedArray;
    
    if(info){
        @synchronized(downArray){
            if ([downArray containsObject:info]) {
                [downArray removeObject:info];
            }
        }
        @synchronized(upArray){
            if ([upArray containsObject:info]) {
                [upArray removeObject:info];
            }
        }
    }
}

//为什么判断能否移除 而不是直接remove try catch 捕获异常，因为有的类remove keypath两次，try直接就崩溃了
-(KVOObserverInfo*)safe_canAddOrRemoveObserverWithKeypathWithObserver:(NSObject *)observer keyPath:(NSString*)keyPath context:(void*)context haveContext:(BOOL)haveContext isAdd:(BOOL)isAdd
{
    if(observer.safe_notNeedRemoveKeypathFromCrashArray==NO){
        NSString *observerKey=DLFormatterStringFromObject(observer);
        NSMutableDictionary *dic=KVOSafeDeallocCrashes()[observerKey];
        NSMutableArray *array=dic[@"keyPaths"];
        __block NSMutableDictionary *willRemoveDic;
        if(array.count>0){
            [[array copy] enumerateObjectsUsingBlock:^(NSMutableDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([obj[@"targetName"] isEqualToString:NSStringFromClass([self class])]&&[obj[@"targetAddress"] isEqualToString:[NSString stringWithFormat:@"%p",self]]&&[keyPath isEqualToString:obj[@"keyPath"]]){
                    willRemoveDic=obj;
                    *stop=YES;
                }
            }];
            if(willRemoveDic){
                [array removeObject:willRemoveDic];
                if (array.count<=0) {
                    @synchronized(KVOSafeDeallocCrashes()){
                        [KVOSafeDeallocCrashes() removeObjectForKey:observerKey];
                    }
                }
            }
        }
    }
    
    if(haveContext==NO&&self.safe_willRemoveObserverInfo){
        context=self.safe_willRemoveObserverInfo.context;
    }
    if (self.safe_willRemoveObserverInfo) {
        haveContext=YES;
    }
    
    
    //哪些对象监听了自己
    NSMutableArray *downArray = self.safe_downObservedKeyPathArray;
    
    //返回已重复的KVO，或者将要移除的KVO
    __block KVOObserverInfo *info;
    
    //处理添加的逻辑
    if (isAdd) {
        //判断是否完全相等
        [downArray enumerateObjectsUsingBlock:^(KVOObserverInfo *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.observerAddress isEqualToString:[NSString stringWithFormat:@"%p",observer]]&&[obj.keyPath isEqualToString:keyPath]) {
                if(obj.context==context){
                    info=obj;
                    *stop=YES;
                }
            }
        }];
        if (info) {
            return info;
        }
        return nil;
    }
    
    
    //处理移除的逻辑
    [downArray enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(KVOObserverInfo *  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.observerAddress isEqualToString:[NSString stringWithFormat:@"%p",observer]]&&[obj.keyPath isEqualToString:keyPath]) {
            if(haveContext){
                if(obj.context==context){
                    info=obj;
                    *stop=YES;
                }
            }else{
                info=obj;
                *stop=YES;
            }
        }
    }];
    if (info) {
        return info;
    }
    return nil;
    
}

/* 防止此种崩溃所以新创建个NSArray 和 NSMutableDictionary遍历
 Terminating app due to uncaught exception 'NSGenericException', reason: '*** Collection <__NSArrayM: 0x61800024f7b0> was mutated while being enumerated.'
 
 Terminating app due to uncaught exception 'NSGenericException', reason: '*** Collection <__NSDictionaryM: 0x170640de0> was mutated while being enumerated.'
 */
-(void)safe_KVODealloc
{
    DLKVOSafeLog(@"\n******* 🚗🚗🚗🚗🚗  %@(%p)  safe_KVODealloc  🚗🚗🚗🚗🚗\n----------------------------------------",[self class],self);
    if (self.safe_upObservedArray.count>0) {
        @synchronized(KVOSafeDeallocCrashes()){
            NSString *currentKey=DLFormatterStringFromObject(self);
            NSMutableDictionary *crashDic=[NSMutableDictionary dictionary];
            NSMutableArray *array=[NSMutableArray array];
            crashDic[@"keyPaths"]=array;
            crashDic[@"className"]=NSStringFromClass([self class]);
            KVOSafeDeallocCrashes()[currentKey]=crashDic;
            for (KVOObserverInfo *info in self.safe_upObservedArray) {
                NSMutableDictionary *newDic=[NSMutableDictionary dictionary];
                newDic[@"targetName"]=info.targetClassName;
                newDic[@"targetAddress"]=info.targetAddress;
                newDic[@"keyPath"]=info.keyPath;
                newDic[@"context"]=[NSString stringWithFormat:@"%p",info.context];
                [array addObject:newDic];
            }
        }
    }
    
    
    //A->B A先销毁 B的safe_upObservedArray 里的info.target=nil,然后在B dealloc里在remove会导致移除不了，然后系统会报销毁时还持有某keypath的crash
    //A->B B先销毁 此时A remove 但事实上的A的safe_downObservedArray里info.observer=nil  所以B remove里会判断observer是否有值，如果没值则不remove导致没有remove
    
    //监听了哪些人 让那些人移除自己
    NSMutableArray *newUpArray=[[[self.safe_upObservedArray reverseObjectEnumerator]allObjects]mutableCopy];
    
    for (KVOObserverInfo *upInfo in newUpArray) {
        id target=upInfo.target;
        if (target) {
            [target safe_allRemoveObserver:self forKeyPath:upInfo.keyPath context:upInfo.context isContext:upInfo.context!=NULL];
        }else if ([upInfo.targetAddress isEqualToString:[NSString stringWithFormat:@"%p",self]]){
            [self safe_allRemoveObserver:self forKeyPath:upInfo.keyPath context:upInfo.context isContext:upInfo.context!=NULL];
        }
    }
    
    
    //谁监听了自己 移除他们 这块必须处理  不然 A->B   A先销毁了 在B里面调用A remove就无效了，因为A=nil
    NSMutableArray *downNewArray=[[[self.safe_downObservedKeyPathArray reverseObjectEnumerator]allObjects] mutableCopy];
    for (KVOObserverInfo *downInfo in downNewArray) {
        [self safe_allRemoveObserver:downInfo.observer forKeyPath:downInfo.keyPath context:downInfo.context isContext:downInfo.context!=NULL];
    }
    self.safe_notNeedRemoveKeypathFromCrashArray=NO;
}
+(void)safe_dealloc_crash:(NSString*)classAddress
{
    //比如A先释放了然后走到此处，然后地址又被B重新使用了，A又释放了走了safe_KVODealloc方法，KVOSafeDeallocCrashes以地址为key的值又被重新赋值，导致误报(A还监听着B监听的内容)，赋值KVOSafeDeallocCrashes以地址为kay的字典的时候，导致字典被释放其他地方又使用，导致野指针
    @synchronized(KVOSafeDeallocCrashes()){
        NSString *currentKey=[NSString stringWithFormat:@"%@-%@",classAddress,NSStringFromClass(self)];
        NSDictionary *crashDic = KVOSafeDeallocCrashes()[currentKey];
        NSArray *array = [crashDic[@"keyPaths"] copy];
        for (NSMutableDictionary *dic in array) {
            NSString *reason=[NSString stringWithFormat:@"%@:(%@） dealloc时仍然监听着 %@:%@ 的 keyPath of %@ context:%@",crashDic[@"className"],classAddress,dic[@"targetName"],dic[@"targetAddress"],dic[@"keyPath"],dic[@"context"]];
            NSException *exception=[NSException exceptionWithName:@"KVO crash" reason:reason userInfo:nil]; DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeKVO);
        }
        [KVOSafeDeallocCrashes() removeObjectForKey:currentKey];
    }
}

NSString * DLFormatterStringFromObject(id object) {
    return   [NSString stringWithFormat:@"%p-%@",object,NSStringFromClass([object class])];
}

+ (NSDictionary *)_dl_dictionaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

+ (instancetype)dl_modelWithJSON:(id)json {
    NSDictionary *dic = [self _dl_dictionaryWithJSON:json];
    return [self dl_modelWithDictionary:dic];
}

+ (instancetype)dl_modelWithDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary == (id)kCFNull) return nil;
    if (![dictionary isKindOfClass:[NSDictionary class]]) return nil;
    
    Class cls = [self class];
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:cls];
    if (modelMeta->_hasCustomClassFromDictionary) {
        cls = [cls modelCustomClassForDictionary:dictionary] ?: cls;
    }
    
    NSObject *one = [cls new];
    if ([one dl_modelSetWithDictionary:dictionary]) return one;
    return nil;
}

- (BOOL)dl_modelSetWithJSON:(id)json {
    NSDictionary *dic = [NSObject _dl_dictionaryWithJSON:json];
    return [self dl_modelSetWithDictionary:dic];
}

- (BOOL)dl_modelSetWithDictionary:(NSDictionary *)dic {
    if (!dic || dic == (id)kCFNull) return NO;
    if (![dic isKindOfClass:[NSDictionary class]]) return NO;
    

    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:object_getClass(self)];
    if (modelMeta->_keyMappedCount == 0) return NO;
    
    if (modelMeta->_hasCustomWillTransformFromDictionary) {
        dic = [((id<DLModel>)self) modelCustomWillTransformFromDictionary:dic];
        if (![dic isKindOfClass:[NSDictionary class]]) return NO;
    }
    
    ModelSetContext context = {0};
    context.modelMeta = (__bridge void *)(modelMeta);
    context.model = (__bridge void *)(self);
    context.dictionary = (__bridge void *)(dic);
    
    
    if (modelMeta->_keyMappedCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
        CFDictionaryApplyFunction((CFDictionaryRef)dic, ModelSetWithDictionaryFunction, &context);
        if (modelMeta->_keyPathPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_keyPathPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_keyPathPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
        if (modelMeta->_multiKeysPropertyMetas) {
            CFArrayApplyFunction((CFArrayRef)modelMeta->_multiKeysPropertyMetas,
                                 CFRangeMake(0, CFArrayGetCount((CFArrayRef)modelMeta->_multiKeysPropertyMetas)),
                                 ModelSetWithPropertyMetaArrayFunction,
                                 &context);
        }
    } else {
        CFArrayApplyFunction((CFArrayRef)modelMeta->_allPropertyMetas,
                             CFRangeMake(0, modelMeta->_keyMappedCount),
                             ModelSetWithPropertyMetaArrayFunction,
                             &context);
    }
    
    if (modelMeta->_hasCustomTransformFromDictionary) {
        return [((id<DLModel>)self) modelCustomTransformFromDictionary:dic];
    }
    return YES;
}

- (id)dl_modelToJSONObject {
    /*
     Apple said:
     The top level object is an NSArray or NSDictionary.
     All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
     All dictionary keys are instances of NSString.
     Numbers are not NaN or infinity.
     */
    id jsonObject = ModelToJSONObjectRecursive(self);
    if ([jsonObject isKindOfClass:[NSArray class]]) return jsonObject;
    if ([jsonObject isKindOfClass:[NSDictionary class]]) return jsonObject;
    return nil;
}

- (NSData *)dl_modelToJSONData {
    id jsonObject = [self dl_modelToJSONObject];
    if (!jsonObject) return nil;
    return [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:NULL];
}

- (NSString *)dl_modelToJSONString {
    NSData *jsonData = [self dl_modelToJSONData];
    if (jsonData.length == 0) return nil;
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (id)dl_modelCopy{
    if (self == (id)kCFNull) return self;
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self copy];
    
    NSObject *one = [self.class new];
    for (_DLModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_getter || !propertyMeta->_setter) continue;
        
        if (propertyMeta->_isCNumber) {
            switch (propertyMeta->_type & DLEncodingTypeMask) {
                case DLEncodingTypeBool: {
                    bool num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, bool))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeInt8:
                case DLEncodingTypeUInt8: {
                    uint8_t num = ((bool (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint8_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeInt16:
                case DLEncodingTypeUInt16: {
                    uint16_t num = ((uint16_t (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint16_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeInt32:
                case DLEncodingTypeUInt32: {
                    uint32_t num = ((uint32_t (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint32_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeInt64:
                case DLEncodingTypeUInt64: {
                    uint64_t num = ((uint64_t (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, uint64_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeFloat: {
                    float num = ((float (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeDouble: {
                    double num = ((double (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, double))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } break;
                case DLEncodingTypeLongDouble: {
                    long double num = ((long double (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, long double))(void *) objc_msgSend)((id)one, propertyMeta->_setter, num);
                } // break; commented for code coverage in next line
                default: break;
            }
        } else {
            switch (propertyMeta->_type & DLEncodingTypeMask) {
                case DLEncodingTypeObject:
                case DLEncodingTypeClass:
                case DLEncodingTypeBlock: {
                    id value = ((id (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)one, propertyMeta->_setter, value);
                } break;
                case DLEncodingTypeSEL:
                case DLEncodingTypePointer:
                case DLEncodingTypeCString: {
                    size_t value = ((size_t (*)(id, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_getter);
                    ((void (*)(id, SEL, size_t))(void *) objc_msgSend)((id)one, propertyMeta->_setter, value);
                } break;
                case DLEncodingTypeStruct:
                case DLEncodingTypeUnion: {
                    @try {
                        NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                        if (value) {
                            [one setValue:value forKey:propertyMeta->_name];
                        }
                    } @catch (NSException *exception) {}
                } // break; commented for code coverage in next line
                default: break;
            }
        }
    }
    return one;
}

- (void)dl_modelEncodeWithCoder:(NSCoder *)aCoder {
    if (!aCoder) return;
    if (self == (id)kCFNull) {
        [((id<NSCoding>)self)encodeWithCoder:aCoder];
        return;
    }
    
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) {
        [((id<NSCoding>)self)encodeWithCoder:aCoder];
        return;
    }
    
    for (_DLModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_getter) return;
        
        if (propertyMeta->_isCNumber) {
            NSNumber *value = ModelCreateNumberFromProperty(self, propertyMeta);
            if (value) [aCoder encodeObject:value forKey:propertyMeta->_name];
        } else {
            switch (propertyMeta->_type & DLEncodingTypeMask) {
                case DLEncodingTypeObject: {
                    id value = ((id (*)(id, SEL))(void *)objc_msgSend)((id)self, propertyMeta->_getter);
                    if (value && (propertyMeta->_nsType || [value respondsToSelector:@selector(encodeWithCoder:)])) {
                        if ([value isKindOfClass:[NSValue class]]) {
                            if ([value isKindOfClass:[NSNumber class]]) {
                                [aCoder encodeObject:value forKey:propertyMeta->_name];
                            }
                        } else {
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        }
                    }
                } break;
                case DLEncodingTypeSEL: {
                    SEL value = ((SEL (*)(id, SEL))(void *)objc_msgSend)((id)self, propertyMeta->_getter);
                    if (value) {
                        NSString *str = NSStringFromSelector(value);
                        [aCoder encodeObject:str forKey:propertyMeta->_name];
                    }
                } break;
                case DLEncodingTypeStruct:
                case DLEncodingTypeUnion: {
                    if (propertyMeta->_isKVCCompatible && propertyMeta->_isStructAvailableForKeyedArchiver) {
                        @try {
                            NSValue *value = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
                            [aCoder encodeObject:value forKey:propertyMeta->_name];
                        } @catch (NSException *exception) {}
                    }
                } break;
                    
                default:
                    break;
            }
        }
    }
}

- (id)dl_modelInitWithCoder:(NSCoder *)aDecoder {
    if (!aDecoder) return self;
    if (self == (id)kCFNull) return self;
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return self;
    
    for (_DLModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_setter) continue;
        
        if (propertyMeta->_isCNumber) {
            NSNumber *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
            if ([value isKindOfClass:[NSNumber class]]) {
                ModelSetNumberToProperty(self, value, propertyMeta);
                [value class];
            }
        } else {
            DLEncodingType type = propertyMeta->_type & DLEncodingTypeMask;
            switch (type) {
                case DLEncodingTypeObject: {
                    id value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)self, propertyMeta->_setter, value);
                } break;
                case DLEncodingTypeSEL: {
                    NSString *str = [aDecoder decodeObjectForKey:propertyMeta->_name];
                    if ([str isKindOfClass:[NSString class]]) {
                        SEL sel = NSSelectorFromString(str);
                        ((void (*)(id, SEL, SEL))(void *) objc_msgSend)((id)self, propertyMeta->_setter, sel);
                    }
                } break;
                case DLEncodingTypeStruct:
                case DLEncodingTypeUnion: {
                    if (propertyMeta->_isKVCCompatible) {
                        @try {
                            NSValue *value = [aDecoder decodeObjectForKey:propertyMeta->_name];
                            if (value) [self setValue:value forKey:propertyMeta->_name];
                        } @catch (NSException *exception) {}
                    }
                } break;
                    
                default:
                    break;
            }
        }
    }
    return self;
}

- (NSUInteger)dl_modelHash {
    if (self == (id)kCFNull) return [self hash];
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self hash];
    
    NSUInteger value = 0;
    NSUInteger count = 0;
    for (_DLModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_isKVCCompatible) continue;
        value ^= [[self valueForKey:NSStringFromSelector(propertyMeta->_getter)] hash];
        count++;
    }
    if (count == 0) value = (long)((__bridge void *)self);
    return value;
}

- (BOOL)dl_modelIsEqual:(id)model {
    if (self == model) return YES;
    if (![model isMemberOfClass:self.class]) return NO;
    _DLModelMeta *modelMeta = [_DLModelMeta metaWithClass:self.class];
    if (modelMeta->_nsType) return [self isEqual:model];
    if ([self hash] != [model hash]) return NO;
    
    for (_DLModelPropertyMeta *propertyMeta in modelMeta->_allPropertyMetas) {
        if (!propertyMeta->_isKVCCompatible) continue;
        id this = [self valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        id that = [model valueForKey:NSStringFromSelector(propertyMeta->_getter)];
        if (this == that) continue;
        if (this == nil || that == nil) return NO;
        if (![this isEqual:that]) return NO;
    }
    return YES;
}

- (NSString *)dl_modelDescription {
    return ModelDescription(self);
}

@end


/**

A addobserver B  A先dealloc  B未移除keypath的crash捕获不到，B先dealloc，B未移除keypath的crash可以捕获搭配
1、重复添加相同的keyPath观察者，会重复调用 observeValueForKeyPath：...方法

2、crash情况：
   1、移除未注册的观察者 会crash
   2、重复移除观察者 会crash
   3.添加了观察者但是没有实现-observeValueForKeyPath:ofObject:change:context:方法
   4.添加移除keypath=nil;
   5.添加移除observer=nil;
*/
