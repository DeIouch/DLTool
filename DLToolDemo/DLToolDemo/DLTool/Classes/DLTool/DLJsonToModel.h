


#import <Foundation/Foundation.h>

#define DLJsonToModelDeprecated(instead) __attribute__((deprecated(instead)))
typedef void(^Error)(NSError *error);
typedef void(^DoSth)(void);

static NSString *const DLPropertyTypeString = @"dlMonsterNSString";
static NSString *const DLPropertyTypeArray = @"dlMonsterNSArray";
static NSString *const DLPropertyTypeDictionary = @"dlMonsterNSDictionary";
static NSString *const DLPropertyTypeDouble = @"dlMonsterDouble";
static NSString *const DLPropertyTypeLong = @"dlMonsterNSInteger";
static NSString *const DLPropertyTypeBool = @"dlMonsterBOOL";
static NSString *const DLPropertyTypeNull = @"dlMonsterNull";
static NSString *const DLPropertyTypeOther = @"dlMonsterOther";

@interface DLClassObject : NSObject
@property (nonatomic,copy  ) NSString *className;
@property (nonatomic,strong) NSDictionary *classPropertys;
@end


@interface DLJsonToModel : NSObject

/**
 生成 DLModel‘s model 调用方法
 
 @param json 请求到的json，传入类型默认是（NSDictionary *）json
 @param fileName 生成文件的文件名
 @param extensionName 为预防自动生成的类名重复。例Authors类后加后缀->AuthorsClass，不会污染数据
 @param url 生成文件存放的路径
 @param error 生成文件发生错误
 @return 是否成功生成文件
 */
/// 生成 DLModel‘s model 调用方法
+ (BOOL)dl_createDLModelWithJson:(NSDictionary *)json fileName:(NSString *)fileName extensionName:(NSString *)extensionName fileURL:(NSURL *)url error:(Error)error;

/**
 计算代码耗时

 @param doSth 代码块
 @return 耗时
 */
/// 计算代码耗时
+ (double)modelWithSpendTime:(DoSth)doSth;

#pragma mark -

/// 返回 .h 文件的内容
- (NSString *)returnHStringWithFileName:(NSString *)fileName;

/// 返回 .m 文件的内容
- (NSString *)returnMStringWithFileName:(NSString *)fileName withExtensionClassName:(NSString *)extensionName;

/// 格式化数据中所有字典的类型
- (void)willFormat:(NSDictionary *)dict withFileName:(NSString *)fileName withExtensionClassName:(NSString *)extensionName;


@end
