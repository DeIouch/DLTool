//  自动生成带解析的model文件，只支持模拟器生成


#import <Foundation/Foundation.h>

//  model保存地址
#define SvaeModelFileUrl @"/Users/tanqiu/Desktop/"

//  内嵌model的后缀名
#define SvaeModelExtensionName @"_ModelClass"

//  model保留字段，在这里面的字段，首字母自动大写
#define ModelReservedWordArray @[@"id", @"abstract", @"case", @"catch", @"class", @"def", @"do", @"else", @"extends", @"false", @"final", @"finally", @"for", @"forSome", @"if", @"implicit", @"import", @"lazy", @"match", @"new", @"null", @"object", @"override", @"package", @"private", @"protected", @"return", @"sealed", @"super", @"this", @"throw", @"trait", @"try", @"true", @"type", @"val", @"var", @"while", @"with", @"yield", @"_", @":", @"=", @"=>", @"<-", @"<:", @"<%", @">:", @"#", @"@"]


@interface DLJsonToModel : NSObject

+(BOOL)dl_createModelWithDic:(NSDictionary *)dic modelName:(NSString *)modelName;

@end
