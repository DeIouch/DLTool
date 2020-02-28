#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, DLEncodingType) {
    DLEncodingTypeMask       = 0xFF, ///< mask of type value
    DLEncodingTypeUnknown    = 0, ///< unknown
    DLEncodingTypeVoid       = 1, ///< void
    DLEncodingTypeBool       = 2, ///< bool
    DLEncodingTypeInt8       = 3, ///< char / BOOL
    DLEncodingTypeUInt8      = 4, ///< unsigned char
    DLEncodingTypeInt16      = 5, ///< short
    DLEncodingTypeUInt16     = 6, ///< unsigned short
    DLEncodingTypeInt32      = 7, ///< int
    DLEncodingTypeUInt32     = 8, ///< unsigned int
    DLEncodingTypeInt64      = 9, ///< long long
    DLEncodingTypeUInt64     = 10, ///< unsigned long long
    DLEncodingTypeFloat      = 11, ///< float
    DLEncodingTypeDouble     = 12, ///< double
    DLEncodingTypeLongDouble = 13, ///< long double
    DLEncodingTypeObject     = 14, ///< id
    DLEncodingTypeClass      = 15, ///< Class
    DLEncodingTypeSEL        = 16, ///< SEL
    DLEncodingTypeBlock      = 17, ///< block
    DLEncodingTypePointer    = 18, ///< void*
    DLEncodingTypeStruct     = 19, ///< struct
    DLEncodingTypeUnion      = 20, ///< union
    DLEncodingTypeCString    = 21, ///< char*
    DLEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    DLEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    DLEncodingTypeQualifierConst  = 1 << 8,  ///< const
    DLEncodingTypeQualifierIn     = 1 << 9,  ///< in
    DLEncodingTypeQualifierInout  = 1 << 10, ///< inout
    DLEncodingTypeQualifierOut    = 1 << 11, ///< out
    DLEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    DLEncodingTypeQualifierByref  = 1 << 13, ///< byref
    DLEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    DLEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    DLEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    DLEncodingTypePropertyCopy         = 1 << 17, ///< copy
    DLEncodingTypePropertyRetain       = 1 << 18, ///< retain
    DLEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    DLEncodingTypePropertyWeak         = 1 << 20, ///< weak
    DLEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    DLEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    DLEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

DLEncodingType DLEncodingGetType(const char *typeEncoding);

@interface DLClassIvarInfo : NSObject
@property (nonatomic, assign, readonly) Ivar ivar;              ///< ivar opaque struct
@property (nonatomic, strong, readonly) NSString *name;         ///< Ivar's name
@property (nonatomic, assign, readonly) ptrdiff_t offset;       ///< Ivar's offset
@property (nonatomic, strong, readonly) NSString *typeEncoding; ///< Ivar's type encoding
@property (nonatomic, assign, readonly) DLEncodingType type;    ///< Ivar's type

- (instancetype)initWithIvar:(Ivar)ivar;
@end

@interface DLClassMethodInfo : NSObject
@property (nonatomic, assign, readonly) Method method;                  ///< method opaque struct
@property (nonatomic, strong, readonly) NSString *name;                 ///< method name
@property (nonatomic, assign, readonly) SEL sel;                        ///< method's selector
@property (nonatomic, assign, readonly) IMP imp;                        ///< method's implementation
@property (nonatomic, strong, readonly) NSString *typeEncoding;         ///< method's parameter and return types
@property (nonatomic, strong, readonly) NSString *returnTypeEncoding;   ///< return value's type
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *argumentTypeEncodings; ///< array of arguments' type

- (instancetype)initWithMethod:(Method)method;
@end

@interface DLClassPropertyInfo : NSObject
@property (nonatomic, assign, readonly) objc_property_t property; ///< property's opaque struct
@property (nonatomic, strong, readonly) NSString *name;           ///< property's name
@property (nonatomic, assign, readonly) DLEncodingType type;      ///< property's type
@property (nonatomic, strong, readonly) NSString *typeEncoding;   ///< property's encoding value
@property (nonatomic, strong, readonly) NSString *ivarName;       ///< property's ivar name
@property (nullable, nonatomic, assign, readonly) Class cls;      ///< may be nil
@property (nullable, nonatomic, strong, readonly) NSArray<NSString *> *protocols; ///< may nil
@property (nonatomic, assign, readonly) SEL getter;               ///< getter (nonnull)
@property (nonatomic, assign, readonly) SEL setter;               ///< setter (nonnull)

- (instancetype)initWithProperty:(objc_property_t)property;
@end

@interface DLClassInfo : NSObject
@property (nonatomic, assign, readonly) Class cls; ///< class object
@property (nullable, nonatomic, assign, readonly) Class superCls; ///< super class object
@property (nullable, nonatomic, assign, readonly) Class metaCls;  ///< class's meta class object
@property (nonatomic, readonly) BOOL isMeta; ///< whether this class is meta class
@property (nonatomic, strong, readonly) NSString *name; ///< class name
@property (nullable, nonatomic, strong, readonly) DLClassInfo *superClassInfo; ///< super class's class info
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, DLClassIvarInfo *> *ivarInfos; ///< ivars
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, DLClassMethodInfo *> *methodInfos; ///< methods
@property (nullable, nonatomic, strong, readonly) NSDictionary<NSString *, DLClassPropertyInfo *> *propertyInfos; ///< properties

- (void)setNeedUpdate;

- (BOOL)needUpdate;

+ (nullable instancetype)classInfoWithClass:(Class)cls;

+ (nullable instancetype)classInfoWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
