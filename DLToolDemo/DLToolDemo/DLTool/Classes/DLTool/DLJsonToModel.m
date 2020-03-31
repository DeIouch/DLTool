#import "DLJsonToModel.h"
#import "NSString+Add.h"
#include <objc/runtime.h>

@interface DLJsonToModel ()
@property (nonatomic, strong) NSMutableArray *classObjects;
@property (nonatomic, strong) NSMutableArray *classNames;
@end

@implementation DLJsonToModel

/// DLModel ?  MJExtension ?

+ (BOOL)dl_createDLModelWithJson:(NSDictionary *)json fileName:(NSString *)fileName extensionName:(NSString *)extensionName fileURL:(NSURL *)url error:(Error)error {
    if (json){
        if (fileName.length < 1)fileName = @"DLTestModel";
        if (extensionName.length < 1)extensionName = @"dl_class";
        if (!url) {
            url = [NSURL URLWithString:@"/Users"];
        }
        return [DLJsonToModel modelWithFileName:fileName extensionName:extensionName json:json fileURL:url error:error];
    }else{
        NSLog(@"/Users error : json为nil!");
        return NO;
    }
}

+ (BOOL)modelWithFileName:(NSString *)fileName extensionName:(NSString *)extensionName json:(NSDictionary *)json fileURL:(NSURL *)url error:(Error)error {
//#warning 此地址为 mac 文件夹地址，地址错误报错为 The folder “XXX.h” doesn’t exist.（暂时仅支持模拟器生成 model 文件，正在完善中。。。）
    if (!TARGET_IPHONE_SIMULATOR) {
        NSLog(@"暂时仅支持模拟器生成 model 文件，正在完善中。。。");
        return NO;
    }else {
        DLJsonToModel *writer = DLJsonToModel.new;
        // 整理出所有存在的类及类型
        [writer willFormat:json withFileName:(NSString *)fileName withExtensionClassName:(NSString *)extensionName];
        // 输出.h
        NSError *errors = nil;
        NSString *hFilename = [NSString stringWithFormat:@"%@.h", fileName];
        NSString *outputHFile = [writer returnHStringWithFileName:fileName];
        [outputHFile writeToFile:[[url URLByAppendingPathComponent:hFilename] absoluteString]
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:&errors];
        if (!errors) {
            // 输出.m
            NSString *mFilename = [NSString stringWithFormat:@"%@.m", fileName];
            NSString *outputMFile = [writer returnMStringWithFileName:fileName withExtensionClassName:(NSString *)extensionName];
            [outputMFile writeToFile:[[url URLByAppendingPathComponent:mFilename] absoluteString]
                          atomically:YES
                            encoding:NSUTF8StringEncoding
                               error:&errors];
            if (errors){
                error(errors);
                return NO;
            }else {
                return YES;
            }
        }else {
            error(errors);
            return NO;
        }
    }
}

#pragma mark - main
/// 格式化数据中所有字典的类型
- (void)willFormat:(NSDictionary *)dict withFileName:(NSString *)fileName withExtensionClassName:(NSString *)extensionName {
    // 先初始化
    self.classNames = [NSMutableArray array];
    self.classObjects = [NSMutableArray array];
    [self formatDataToClassWith:dict withClassName:fileName withExtensionClassName:extensionName];
    NSLog(@"");
}

/// 格式化数据中所有字典的类型
- (void)formatDataToClassWith:(NSDictionary *)dict withClassName:(NSString *)className withExtensionClassName:(NSString *)extensionName {
    // 创建类
    DLClassObject *classObj = DLClassObject.new;
    classObj.className = className;
    // 遍历属性key，确定key值类型
    NSArray *keys = dict.allKeys;
    NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
    for (NSString *key in keys) {
        if ([dict[key] isKindOfClass:[NSArray class]]) {
            // 整理数组并返回一个整理好的字典
            NSDictionary *dicts = [self returnArraysDictionary:dict[key]];
            if (dicts) {
                // 添加这个属性
                NSString *name = [self returnNewName:key withExtensionClassName:extensionName];
                NSString *newName = [NSString stringWithFormat:@"%@%@",DLPropertyTypeArray,name];
                [tempDic setObject:newName forKey:key];
                // 递归
                [self formatDataToClassWith:dicts withClassName:name withExtensionClassName:extensionName];
            }else {
                // 添加这个属性
                NSString *newName = [NSString stringWithFormat:@"%@%@",DLPropertyTypeArray,@"0"];
                [tempDic setObject:newName forKey:key];
            }
        }else if ([dict[key] isKindOfClass:[NSDictionary class]]) {
            // 添加这个属性
            NSString *name = [self returnNewName:key withExtensionClassName:extensionName];
            [tempDic setObject:name forKey:key];
            // 递归
            [self formatDataToClassWith:dict[key] withClassName:name withExtensionClassName:extensionName];
        }else if ([dict[key] isKindOfClass:[NSNull class]]) {
            [tempDic setObject:DLPropertyTypeNull forKey:key];
        }else if ([dict[key] isKindOfClass:[NSString class]]) {
            [tempDic setObject:DLPropertyTypeString forKey:key];
            if ([dict[key] isEqualToString:DLPropertyTypeOther]) {
                [tempDic setObject:DLPropertyTypeOther forKey:key];
            }
        }else {
            NSString *classDecription = [[dict[key] class] description];
            if ([classDecription containsString:@"NSCFBoolean"]) {
                [tempDic setObject:DLPropertyTypeBool forKey:key];
            }
            if ([classDecription containsString:@"NSCFNumber"]) {
                if (strcmp([dict[key] objCType], @encode(long)) == 0) {
                    [tempDic setObject:DLPropertyTypeLong forKey:key];
                }
                if (strcmp([dict[key] objCType], @encode(double)) == 0) {
                    [tempDic setObject:DLPropertyTypeDouble forKey:key];
                }
            }
        }
    }
    // 保存类
    classObj.classPropertys = tempDic;
    [self.classObjects addObject:classObj];
}

#pragma mark custom tools
/// 合并数组中所有字典，并判断在属性相同时，类型是否一致。（只考虑数组中的字典，会扔掉数组中其他元素（正在完善中。。。））
- (NSDictionary *)returnArraysDictionary:(NSArray *)array {
    // 过滤掉不是字典的值
    NSMutableArray *dictArray = [NSMutableArray array];
    NSMutableArray *otherArray = [NSMutableArray array];
    for (id object in array) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [dictArray addObject:object];
        }else {
//#warning 数组中的非字典元素（只考虑数组中的字典，会扔掉数组中其他元素（正在完善中。。。））
            [otherArray addObject:object];
        }
    }
    if (dictArray.count == 0) {
        // 此时数组中没有字典
        return nil;
    }
    // 合并数组中所有字典
    NSMutableDictionary *allDicts = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in dictArray) {
        [allDicts addEntriesFromDictionary:dict];
    }
    // 找到数组中所有字典相同的key
    NSArray *sameKeys = @[];
    if (dictArray.count > 1) {
        for (int i = 0; i < dictArray.count-1; i++) {
            NSDictionary *dic1 = dictArray[i];
            NSDictionary *dic2 = dictArray[i+1];
            sameKeys = [self returnDictionaryTheSameKeyWithA:dic1.allKeys withB:dic2.allKeys];
        }
    }
    // 判断这些key在所有字典中的值的类型是否一致
    for (NSDictionary *dict in dictArray) {
        for (NSString *sameKey in sameKeys) {
            id obja = allDicts[sameKey];
            id objb = dict[sameKey];
            NSString *class1 = [[obja class] description];
            NSString *class2 = [[objb class] description];
            if (![class1 isEqualToString:class2]) {
                [allDicts setObject:DLPropertyTypeOther forKey:sameKey];
            }
        }
    }
    return allDicts;
}

/// 返回数组中所有字典相同的key，需要判断这些相同的key类型是否一致。
- (NSArray *)returnDictionaryTheSameKeyWithA:(NSArray *)a withB:(NSArray *)b {
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF IN %@", b];
    return [a filteredArrayUsingPredicate:pre];
}

/// 返回 object 类型
- (NSString *)returnPropertyType:(id)object {
    if ([object isKindOfClass:[NSNull class]]) {
        return DLPropertyTypeNull;
    }else if ([object isKindOfClass:[NSString class]]) {
        return DLPropertyTypeString;
    }else if ([object isKindOfClass:[NSDictionary class]]) {
        return DLPropertyTypeDictionary;
    }else if ([object isKindOfClass:[NSArray class]]) {
        return DLPropertyTypeArray;
    }else {
        NSString *classDecription = [[object class] description];
        if ([classDecription containsString:@"NSCFBoolean"]) {
            return DLPropertyTypeBool;
        }else if ([classDecription containsString:@"NSCFNumber"]) {
            if (strcmp([object objCType], @encode(long)) == 0) {
                return DLPropertyTypeLong;
            }else if (strcmp([object objCType], @encode(double)) == 0) {
                return DLPropertyTypeDouble;
            }else {
                return DLPropertyTypeOther;
            }
        }else {
            return DLPropertyTypeOther;
        }
    }
}

/// 预防类名重复
- (NSString *)returnNewName:(NSString *)key withExtensionClassName:(NSString *)extensionName{
    NSString *newKey = [NSString stringWithFormat:@"%@_%@",key,extensionName];
    while ([self.classNames containsObject:newKey]) {
        newKey = [NSString stringWithFormat:@"%@_%@",@"z",newKey];
    }
    [self.classNames addObject:newKey];
    return newKey;
}

/// 合并数组并去重
- (NSArray *)arrayA:(NSArray *)a withArrayB:(NSArray *)b {
    NSMutableArray *temp = [a mutableCopy];
    for (id object in b) {
        if (![a containsObject:object]) {
            [temp addObject:object];
        }
    }
    return [temp copy];
}

#pragma mark - .h
/// 返回 .h 文件的内容
- (NSString *)returnHStringWithFileName:(NSString *)fileName {
    // 准备返回 .h
    NSString *string = [NSString stringWithFormat:@"%@",@"#import <Foundation/Foundation.h>"];
    for (DLClassObject *classObj in self.classObjects) {
        NSString *temp = [self hStringWithClassObject:classObj];
        string = [NSString stringWithFormat:@"%@\n\n%@",string,temp];
    }
    
    string = [string stringByReplacingOccurrencesOfString:fileName.dlFormatClassName withString:fileName];
    return string;
}

///  .h文件拼接元素
- (NSString *)hStringWithClassObject:(DLClassObject *)classObj {
    NSString *classString = [NSString stringWithFormat:@"@interface %@ : NSObject",classObj.className.dlFormatClassName];
    NSDictionary *dict = classObj.classPropertys;
    NSArray *keys = dict.allKeys;
    for (NSString *key in keys) {
        id object = dict[key];
        NSString *propertyName = key.dlFormatPropertyName;
        NSString *temp = @"";
        if ([object isKindOfClass:[NSString class]]) {
            if ([object isEqualToString:DLPropertyTypeOther]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,strong) id %@;",propertyName];
            }
            if ([object isEqualToString:DLPropertyTypeString]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,copy  ) NSString *%@;",propertyName];
            }
            if ([object isEqualToString:DLPropertyTypeDouble]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,assign) double %@;",propertyName];
            }
            if ([object isEqualToString:DLPropertyTypeLong]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,assign) NSInteger %@;",propertyName];
            }
            if ([object isEqualToString:DLPropertyTypeBool]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,assign) BOOL %@;",propertyName];
            }
            if ([object isEqualToString:DLPropertyTypeNull]) {
                temp = [NSString stringWithFormat:@"@property (nonatomic,copy  ) NSString *%@;",propertyName];
            }
            if ([self.classNames containsObject:object]) {
                NSString *className = ((NSString *)object).dlFormatClassName;
                temp = [NSString stringWithFormat:@"@property (nonatomic,strong) %@ *%@;",className,propertyName];
            }
            if ([object hasPrefix:DLPropertyTypeArray]) {
                NSString *className = [(NSString *)object substringFromIndex:DLPropertyTypeArray.length];
                if ([className isEqualToString:@"0"]) {
                    temp = [NSString stringWithFormat:@"@property (nonatomic,strong) NSArray *%@;",propertyName];
                }else {
                    temp = [NSString stringWithFormat:@"@property (nonatomic,strong) NSArray<%@ *> *%@;",className.dlFormatClassName,propertyName];
                }
            }
        }
        classString = [NSString stringWithFormat:@"%@\n%@",classString,temp];
    }
    return [NSString stringWithFormat:@"%@\n@end",classString];
}


#pragma mark - .m
/// 返回 .m 文件的内容
- (NSString *)returnMStringWithFileName:(NSString *)fileName withExtensionClassName:(NSString *)extensionName{
    // 准备返回 .m
    NSString *string = [NSString stringWithFormat:@"#import \"%@.h\"",fileName];
    for (DLClassObject *classObj in self.classObjects) {
        NSString *temp = [self mStringWithClassObject:classObj withExtensionClassName:(NSString *)extensionName];
        string = [NSString stringWithFormat:@"%@\n\n%@",string,temp];
    }
    
    string = [string stringByReplacingOccurrencesOfString:fileName.dlFormatClassName withString:fileName];
    return string;
}

///  .m文件拼接类
- (NSString *)mStringWithClassObject:(DLClassObject *)classObj withExtensionClassName:(NSString *)extensionName{
    NSString *stringa;
    NSString *stringc;
    stringa = @"+ (NSDictionary *)modelCustomPropertyMapper {\n    return @{";
    stringc = @"+ (NSDictionary *)modelContainerPropertyGenericClass {\n    return @{";
    NSString *stringb = @"};\n}\n";
    NSString *stringd = @"};\n}\n";
    // 生成 自定义属性名
    NSString *string = @"";
    // 生成 数组中的类
    NSString *strings = @"";
    // 解析
    NSArray *keys = classObj.classPropertys.allKeys;
    for (NSString *key in keys) {
        // 自定义的属性名
        if (![key isEqualToString:key.dlFormatPropertyName]) {
            string = [NSString stringWithFormat:@"%@ @\"%@\" : @\"%@\",",string,key.dlFormatPropertyName,key];
        }
        // 数组中类（泛型）
        id object = classObj.classPropertys[key];
        if ([object hasPrefix:DLPropertyTypeArray]) {
            NSString *className = [(NSString *)object substringFromIndex:DLPropertyTypeArray.length];
            if (![className isEqualToString:@"0"]) {
                strings = [NSString stringWithFormat:@"%@ @\"%@\" : [%@ class],",strings,key.dlFormatPropertyName,className.dlFormatClassName];
            }
        }
    }
    string = string.length > 0 ? [NSString stringWithFormat:@"%@%@%@",stringa,string,stringb] : @"";
    strings = strings.length > 0 ? [NSString stringWithFormat:@"%@%@%@",stringc,strings,stringd] : @"";
    
    NSString *stringe = [NSString stringWithFormat:@"@implementation %@\n",classObj.className.dlFormatClassName];
    return [NSString stringWithFormat:@"%@%@%@@end",stringe,string,strings];
}

+ (double)modelWithSpendTime:(DoSth)doSth {
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    doSth();
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    return end-start;
}

@end

@implementation DLClassObject
@end
