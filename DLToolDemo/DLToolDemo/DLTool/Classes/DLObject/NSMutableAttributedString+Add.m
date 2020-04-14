#import "NSMutableAttributedString+Add.h"
#import "DLSafeProtector.h"
#import "DLToolMacro.h"

@implementation NSMutableAttributedString (Add)

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class dClass = NSClassFromString(@"NSConcreteMutableAttributedString");
        Safe_ExchangeMethod(dClass, @selector(initWithString:), @selector(safe_initWithString:));
        Safe_ExchangeMethod(dClass, @selector(initWithString:attributes:), @selector(safe_initWithString:attributes:));
        Safe_ExchangeMethod(dClass, @selector(initWithAttributedString:), @selector(safe_initWithAttributedString:));
        Safe_ExchangeMethod(dClass, @selector(replaceCharactersInRange:withString:), @selector(safe_replaceCharactersInRange:withString:));
        Safe_ExchangeMethod(dClass, @selector(setAttributes:range:), @selector(safe_setAttributes:range:));
        Safe_ExchangeMethod(dClass, @selector(addAttribute:value:range:), @selector(safe_addAttribute:value:range:));
        Safe_ExchangeMethod(dClass, @selector(addAttributes:range:), @selector(addAttributes:range:));
        Safe_ExchangeMethod(dClass, @selector(removeAttribute:range:), @selector(safe_removeAttribute:range:));
        Safe_ExchangeMethod(dClass, @selector(replaceCharactersInRange:withAttributedString:), @selector(safe_replaceCharactersInRange:withAttributedString:));
        Safe_ExchangeMethod(dClass, @selector(insertAttributedString:atIndex:), @selector(safe_insertAttributedString:atIndex:));
        Safe_ExchangeMethod(dClass, @selector(appendAttributedString:), @selector(safe_appendAttributedString:));
        Safe_ExchangeMethod(dClass, @selector(deleteCharactersInRange:), @selector(safe_deleteCharactersInRange:));
        Safe_ExchangeMethod(dClass, @selector(setAttributedString:), @selector(safe_setAttributedString:));
    });
}

- (instancetype)safe_initWithString:(NSString *)str {
    id object = nil;
    @try {
        object = [self safe_initWithString:str];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
        return object;
    }
}

#pragma mark - initWithAttributedString
- (instancetype)safe_initWithAttributedString:(NSAttributedString *)attrStr {
    id object = nil;
    
    @try {
        object = [self safe_initWithAttributedString:attrStr];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
        return object;
    }
}

#pragma mark - initWithString:attributes:
- (instancetype)safe_initWithString:(NSString *)str attributes:(NSDictionary<NSString *,id> *)attrs {
    id object = nil;
    
    @try {
        object = [self safe_initWithString:str attributes:attrs];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
        return object;
    }
}


-(void)safe_replaceCharactersInRange:(NSRange)range withString:(nonnull NSString *)aString
{
    @try {
        [self safe_replaceCharactersInRange:range withString:aString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range
{
    @try {
        [self safe_setAttributes:attrs range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_addAttribute:(NSAttributedStringKey)name value:(id)value range:(NSRange)range
{
    @try {
        [self safe_addAttribute:name value:value range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}
-(void)safe_addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range
{
    @try {
        [self safe_addAttributes:attrs range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_removeAttribute:(NSAttributedStringKey)name range:(NSRange)range
{
    @try {
        [self safe_removeAttribute:name range:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_replaceCharactersInRange:range withAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}


-(void)safe_insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc
{
    @try {
        [self safe_insertAttributedString:attrString atIndex:loc];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}


-(void)safe_appendAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_appendAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_deleteCharactersInRange:(NSRange)range
{
    @try {
        [self safe_deleteCharactersInRange:range];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

-(void)safe_setAttributedString:(NSAttributedString *)attrString
{
    @try {
        [self safe_setAttributedString:attrString];
    }
    @catch (NSException *exception) {
        DLSafeProtectionCrashLog(exception,DLSafeProtectorCrashTypeNSMutableAttributedString);
    }
    @finally {
    }
}

+(instancetype)attribute:(NSString *)text type:(AttributeType)type value:(id)value range:(NSRange)range{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:text];
    NSRange tempRange = range;
    if (range.location + range.length >= text.length) {
        tempRange = NSMakeRange(range.location, text.length - range.location);
    }
    
    NSAttributedStringKey attribute;
    switch (type) {
        case FontSizeAttributeType:
            attribute = NSFontAttributeName;
            break;
            
        case ParagraphStyleAttributeType:
            attribute = NSParagraphStyleAttributeName;
            break;
            
        case ForegroundColorAttributeType:
            attribute = NSForegroundColorAttributeName;
            break;
            
        case BackgroundColorAttributeType:
            attribute = NSBackgroundColorAttributeName;
            break;
            
        case LigatureAttributeType:
            attribute = NSLigatureAttributeName;
            break;
            
        case KernAttributeType:
            attribute = NSKernAttributeName;
            break;
            
        case StrikethroughStyleAttributeType:
            attribute = NSStrikethroughStyleAttributeName;
            break;
            
        case UnderlineStyleType:
            attribute = NSUnderlineStyleAttributeName;
            break;
            
        case StrokeColorAttributeType:
            attribute = NSStrokeColorAttributeName;
            break;
            
        case StrokeWidthAttributeType:
            attribute = NSStrokeWidthAttributeName;
            break;
            
        case ShadowAttributeType:
            attribute = NSShadowAttributeName;
            break;
            
        case TextEffectAttributeType:
            attribute = NSTextEffectAttributeName;
            break;
            
        case AttachmentAttributeType:
            attribute = NSAttachmentAttributeName;
            break;
            
        case LinkAttributeType:
            attribute = NSLinkAttributeName;
            break;
            
        case BaselineOffsetAttributeType:
            attribute = NSBaselineOffsetAttributeName;
            break;
            
        case UnderlineColorAttributeType:
            attribute = NSUnderlineColorAttributeName;
            break;
            
        case StrikethroughColorAttributeType:
            attribute = NSStrikethroughColorAttributeName;
            break;
            
        case ObliquenessAttributeType:
            attribute = NSObliquenessAttributeName;
            break;
            
        case ExpansionAttributeType:
            attribute = NSExpansionAttributeName;
            break;
            
        case WritingDirectionAttributeType:
            attribute = NSWritingDirectionAttributeName;
            break;
            
        case VerticalGlyphFormAttributeType:
            attribute = NSVerticalGlyphFormAttributeName;
            break;
            
        default:
            break;
    }
    [attributedString addAttribute:attribute value:value range:tempRange];
    return attributedString;
}


@end


/*

目前可避免以下方法crash
1.- (instancetype)initWithString:(NSString *)str;
2.- (instancetype)initWithString:(NSString *)str attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;
3.- (instancetype)initWithAttributedString:(NSAttributedString *)attrStr;

4. - (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str;
5.- (void)setAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;

6.- (void)addAttribute:(NSAttributedStringKey)name value:(id)value range:(NSRange)range;
7.- (void)addAttributes:(NSDictionary<NSAttributedStringKey, id> *)attrs range:(NSRange)range;
8.- (void)removeAttribute:(NSAttributedStringKey)name range:(NSRange)range;

9.- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrString;
10.- (void)insertAttributedString:(NSAttributedString *)attrString atIndex:(NSUInteger)loc;
11.- (void)appendAttributedString:(NSAttributedString *)attrString;
12.- (void)deleteCharactersInRange:(NSRange)range;
13.- (void)setAttributedString:(NSAttributedString *)attrString;


*/
