#import "DLSQLManager.h"
#import <sqlite3.h>
#import "NSObject+Add.h"
#import <objc/runtime.h>

#define DLDBCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject


#pragma mark    ----------   缓存模型语句   ----------
@interface DLCache : NSCache

+(instancetype)shareInstance;

@end

@implementation DLCache

static DLCache *dl_cache = nil;

+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dl_cache = [[DLCache alloc]init];
    });
    return dl_cache;
}

@end


@interface DLModelAnalysis : NSObject

 // 获取模型对应的数据库表名
+(NSString *)tableName:(Class)cls targetId:(NSString *)targetId;

// 获取临时表名
+(NSString *)tmpTableName:(Class)cls targetId:(NSString *)targetId;


// 获取类所有成员变量的类型以及名称组成的字典 例如 int stuId --> { stuId : int }
+(NSDictionary *)classIvarNameAndTypeDic:(Class)cls;

 // 将模型的所有成员变量的类型以及名称转换成sql语句可用的字符串 例如 int a ； int b； --> a i，b i
+(NSString *)sqlColumnNamesAndTypesStr:(Class)cls;

// 返回模型的所有成员变量
+(NSArray *)allIvarNames:(Class)cls;

// 格式化模型的value或将数据库内的数据转换到模型对应的类型的值，我们的口号：一切不是数据库支持格式的数据，通通都转成字符串
+(id)formatModelValue:(id)value type:(NSString *)type isEncode:(BOOL)isEncode;

// 模型转字典
+(NSDictionary *)dictWithModel:(id)model;

// 字典转模型
+(id)model:(Class)cls Dict:(NSDictionary *)dict;

// 字典转字符串
+(NSString *)stringWithDict:(id)dict;

// 字符串转字典
+(id)dictWithString:(NSString *)str type:(NSString *)type;

// 数组转字典
+(NSString *)stringWithArray:(id)array;

// 字符串转数组
+(id)arrayWithString:(NSString *)str type:(NSString *)type;

@end

@implementation DLModelAnalysis

+(NSString *)tableName:(Class)cls targetId:(NSString *)targetId{
    if (!targetId) targetId = @"";
    return [NSString stringWithFormat:@"%@%@",NSStringFromClass(cls),targetId];
}

+(NSString *)tmpTableName:(Class)cls targetId:(NSString *)targetId{
    if (!targetId) targetId = @"";
    return [NSString stringWithFormat:@"%@_tmp",[self tableName:cls targetId:targetId]];
}

+(NSDictionary *)classIvarNameAndTypeDic:(Class)cls{
    NSDictionary *cacheIvarNameAndTypeDic = [[DLCache shareInstance] objectForKey:NSStringFromClass(cls)];
    if (cacheIvarNameAndTypeDic) {
        return cacheIvarNameAndTypeDic;
    }
    unsigned int outCount = 0;
    Ivar *varList = class_copyIvarList(cls, &outCount);
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    NSArray *ignoreNames = nil;
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = varList[i];
        // 1.获取成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        // 忽略字段
        if ([ignoreNames containsObject:ivarName]) {
            continue;
        }
        // 2.获取成员变量类型 @\"
        NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        [nameTypeDic setValue:type forKey:ivarName];
    }
    [[DLCache shareInstance] setObject:nameTypeDic forKey:NSStringFromClass(cls)];
    return nameTypeDic;
}

+(NSDictionary *)classIvarNameAndSqlTypeDic:(Class)cls{
    // 获取模型的所有成员变量
    NSMutableDictionary *classDict = [[self classIvarNameAndTypeDic:cls] mutableCopy];
    [classDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        // 对应的数据库的类型重新赋值
        classDict[key] = [self getSqlType:obj];
    }];
    return classDict;
}

+(NSString*)getSqlType:(NSString*)type{
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]|
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]) {
        return @"integer";
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return @"real";
    }else{
        return @"text";
    }
}

+(NSString *)sqlColumnNamesAndTypesStr:(Class)cls{
    // 缓存
    NSDictionary *sqlDict = [[self classIvarNameAndSqlTypeDic:cls] mutableCopy];
    NSMutableArray *nameTypeArr = [NSMutableArray array];
    [sqlDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        [nameTypeArr addObject:[NSString stringWithFormat:@"%@ %@",key,obj]];
    }];
    return [nameTypeArr componentsJoinedByString:@","];
}

+(NSArray *)allIvarNames:(Class)cls{
    NSDictionary *dict = [self classIvarNameAndTypeDic:cls];
    NSArray *names = dict.allKeys;
    // 排序
    names = [names sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return names;
}

+ (id)formatModelValue:(id)value type:(NSString *)type isEncode:(BOOL)isEncode{
    if (isEncode && value == nil) { // 只有对象才能为nil，基本数据类型没值时为0
        return @"";
    }
    if (!isEncode && [value isKindOfClass:[NSString class]] && [value isEqualToString:@""]) {
        return [NSClassFromString(type) new];
    }
    if([type isEqualToString:@"i"]||[type isEqualToString:@"I"]||
       [type isEqualToString:@"s"]||[type isEqualToString:@"S"]||
       [type isEqualToString:@"q"]||[type isEqualToString:@"Q"]||
       [type isEqualToString:@"b"]||[type isEqualToString:@"B"]||
       [type isEqualToString:@"c"]||[type isEqualToString:@"C"]||
       [type isEqualToString:@"l"]||[type isEqualToString:@"L"]||
       [value isKindOfClass:[NSNumber class]]) {
        return value;
    }else if([type isEqualToString:@"f"]||[type isEqualToString:@"F"]||
             [type isEqualToString:@"d"]||[type isEqualToString:@"D"]){
        return value;
    }else if ([type containsString:@"NSData"]) {
        if (isEncode) {
            return [value base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else {
            return [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }
    }else if ([type isEqualToString:@"UIImage"]) {
        if (isEncode) {
            NSData* data = UIImageJPEGRepresentation(value, 1);
            return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }else {
            return [UIImage imageWithData:[[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters]];
        }
    } else if ([type containsString:@"String"]) {
        if ([type containsString:@"AttributedString"]) {
            if (isEncode) {
                NSData *data = [[NSKeyedArchiver archivedDataWithRootObject:value] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
                return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }else {
                NSData* data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
                return [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }
        }
        return value;
    }else if ([type containsString:@"Dictionary"] && [type containsString:@"NS"]) {
        if (isEncode) {
            return [self stringWithDict:value];
        }else {
            return [self dictWithString:value type:type];
        }
    }else if (([type containsString:@"Array"] || [type containsString:@"Set"]) && [type containsString:@"NS"] ) {
        if (isEncode) {
            return [self stringWithArray:value];
        }else {
            return [self arrayWithString:value type:type];
        }
    }else if ([type containsString:@"UIColor"]){
        if(isEncode){
            CGFloat r, g, b, a;
            [value getRed:&r green:&g blue:&b alpha:&a];
            return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
        }else{
            NSArray<NSString*>* arr = [value componentsSeparatedByString:@","];
            return [UIColor colorWithRed:arr[0].floatValue green:arr[1].floatValue blue:arr[2].floatValue alpha:arr[3].floatValue];
        }
    }else if ([type containsString:@"NSURL"]){
        if(isEncode){
            return [value absoluteString];
        }else{
            return [NSURL URLWithString:value];
        }
    }else if ([type containsString:@"NSRange"]){
        if(isEncode){
            return NSStringFromRange([value rangeValue]);
        }else{
            return [NSValue valueWithRange:NSRangeFromString(value)];
        }
    }else { // 当模型处理
        if (isEncode) {  // 模型转json字符串
            NSDictionary *modelDict = [self dictWithModel:value];
            return [self stringWithDict:modelDict];
        }else {  // 字符串转模型
            NSDictionary *dict = [self dictWithString:value type:type];
            return [self model:NSClassFromString(type) Dict:dict];
        }
    }
    return @"";
}

+ (NSString *)stringWithDate:(NSDate *)date {
    NSDateFormatter* formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:date];
}

+ (NSDate *)dateWithString:(NSString *)str {
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSDate *date = [formatter dateFromString:str];
    return date;
}

// 数组转字符串
+ (NSString *)stringWithArray:(id)array {
    if ([NSJSONSerialization isValidJSONObject:array]) {
        // array -> Data
        NSData *data = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        NSMutableArray *arrayM = [NSMutableArray array];
        for (id value in array) {
            
            id result = [self formatModelValue:value type:NSStringFromClass([value class]) isEncode:YES];
            NSDictionary *dict = @{NSStringFromClass([value class]) : result};
            [arrayM addObject:dict];
        }
        return [[self stringWithArray:arrayM] stringByAppendingString:@"DLCustom"];
    }
}

// 字典转字符串
+ (NSString *)stringWithDict:(NSDictionary *)dict {
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        // dict -> data
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        // data -> NSString
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }else {
        NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
        for (NSString *key in dict.allKeys) {
            id value = dict[key];
            id result = [self formatModelValue:value type:NSStringFromClass([value class]) isEncode:YES];
            NSDictionary *valueDict = @{NSStringFromClass([value class]) : result};
            [dictM setValue:valueDict forKey:key];
        }
        return [[self stringWithDict:dictM] stringByAppendingString:@"DLCustom"];
    }
}

// 字符串转数组(还原)
+ (id)arrayWithString:(NSString *)str type:(NSString *)type{
    if ([str hasSuffix:@"DLCustom"]) {
        NSUInteger length = @"DLCustom".length;
        str = [str substringToIndex:str.length - length];
        NSJSONReadingOptions options = kNilOptions; // 是否可变
        if ([type containsString:@"Mutable"] || [type containsString:@"NSArrayM"]) {
            options = NSJSONReadingMutableContainers;
        }
        NSMutableArray *resultArr = [NSMutableArray array];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        id result = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
        id value;
        for (NSDictionary *dict in result) {
            value = [self formatModelValue:dict.allValues.firstObject type:dict.allKeys.firstObject isEncode:NO];
            [resultArr addObject:value];
        }
        if (options == kNilOptions) {
            resultArr = [resultArr copy]; // 不可变数组
        }
        return resultArr;
    }else {
        return [self formatJsonArrayAndJsonDict:str type:type];
    }
    
}
// 字符串转字典(还原)
+ (id)dictWithString:(NSString *)str type:(NSString *)type {
    if ([str hasSuffix:@"DLCustom"]) {
        NSUInteger length = @"DLCustom".length;
        str = [str substringToIndex:str.length - length];
        NSJSONReadingOptions options = kNilOptions; // 是否可变
        if ([type containsString:@"Mutable"] || [type containsString:@"NSDictionaryM"]) {
            options = NSJSONReadingMutableContainers;
        }
        NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        id resultDict = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
        for (NSString *key in [resultDict allKeys]) {
            NSDictionary *valueDict = [resultDict valueForKey:key];
            id value = valueDict.allValues.firstObject;
            NSString *type = valueDict.allKeys.firstObject;
            id resultValue = [self formatModelValue:value type:type isEncode:NO];
            [dictM setValue:resultValue forKey:key];
        }
        return dictM;
    }else {
        return [self formatJsonArrayAndJsonDict:str type:type];
    }
}

// json数组和json字典可直接转换
+ (id)formatJsonArrayAndJsonDict:(NSString *)str type:(NSString *)type {
    NSJSONReadingOptions options = kNilOptions;
    if ([type containsString:@"Mutable"] || [type containsString:@"NSArrayM"] || [type containsString:@"NSDictionaryM"]) {
        options = NSJSONReadingMutableContainers;
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    id result = [NSJSONSerialization JSONObjectWithData:data options:options error:nil];
    return result;
}

#pragma mark - 模型转字典
+ (NSDictionary *)dictWithModel:(id)model {
    // 获取类的所有成员变量的名称与类型
    NSDictionary *nameTypeDict = [DLModelAnalysis classIvarNameAndTypeDic:[model class]];
    // 获取模型所有成员变量
    NSArray *allIvarNames = nameTypeDict.allKeys;
    NSMutableDictionary *allIvarValues = [NSMutableDictionary dictionary];
    // 获取所有成员变量对应的值
    for (NSString *ivarName in allIvarNames) {
        id value = [model valueForKeyPath:ivarName];
        NSString *type = nameTypeDict[ivarName];
        value = [DLModelAnalysis formatModelValue:value type:type isEncode:YES];
        allIvarValues[ivarName] = value;
    }
    return allIvarValues;
}

#pragma mark - 字典转模型
+ (id)model:(Class)cls Dict:(NSDictionary *)dict {
    id model = [cls new];
    // 获取所有属性名
    NSArray *ivarNames = [DLModelAnalysis allIvarNames:cls];
    // 获取所有属性名和类型的字典 {ivarName : type}
    NSDictionary *nameTypeDict = [DLModelAnalysis classIvarNameAndTypeDic:cls];
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id value = obj;
        // 判断数据库查询到的key 在当前模型中是否存在，存在才赋值
        if ([ivarNames containsObject:key]) {
            
            NSString *type = nameTypeDict[key];
            
            value = [DLModelAnalysis formatModelValue:value type:type isEncode:NO];
            if (value == nil) {
                value = @(0);
            }
            [model setValue:value forKeyPath:key];
        }
    }];
    return model;
}

@end

@interface DLDatabase : NSObject

+(BOOL)openDB:(NSString *)uid;

+(void)closeDB;

+(BOOL)execSQL:(NSString *)sql uid:(NSString *)uid;

// 查询语句
+(NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid;

// 执行多个sql语句
+(BOOL)execSqls:(NSArray <NSString *>*)sqls uid:(NSString *)uid;

#pragma mark - 事务
// 开始事务
+(void)beginTransaction:(NSString *)uid;

// 提交事务
+(void)commitTransaction:(NSString *)uid;

// 回滚事务
+(void)rollBackTransaction:(NSString *)uid;

@end

@implementation DLDatabase

static sqlite3 *dl_database = nil;

static NSTimeInterval _startBusyRetryTime; // 第一次重试的时间

// 返回0 则不重试操作数据库，返回非0 将不断尝试操作数据库
static int DLDBBusyCallBack(void *f, int count) {
    // count为回调这个函数的次数
    if (count == 0) {
        _startBusyRetryTime = [NSDate timeIntervalSinceReferenceDate];
        return 1;
    }
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - _startBusyRetryTime;
    if (delta < 2) { //如果本次尝试操作距离第一次尝试操作 小于2秒 （最多尝试操作数据库2秒钟）
        int actualSleepInMilliseconds = sqlite3_sleep(100); // 休眠100毫秒
        if (actualSleepInMilliseconds != 100) {
            NSLog(@"⚠️警告:请求休眠100毫秒，但是实际休眠%d毫秒,Maybe SQLite wasn't built with HAVE_USLEEP=1?",actualSleepInMilliseconds);
        }
        return 1;
    }
    // 反复尝试操作超过2秒，返回0不再尝试操作数据库
    return 0;
}


+(BOOL)openDB:(NSString *)uid{
    NSString *dbName = @"dlDB.sqlite";
    if (uid.length != 0) {
        dbName = [NSString stringWithFormat:@"%@.sqlite", uid];
    }
    NSString *dbPath = [DLDBCachePath stringByAppendingPathComponent:dbName];
    int result = sqlite3_open(dbPath.UTF8String, &dl_database);
    if (result != SQLITE_OK) {
        NSLog(@"打开数据库失败! : %d",result);
        return NO;
    }
    sqlite3_busy_handler(dl_database, &DLDBBusyCallBack, (void *)(dl_database));
    return YES;
}

+(void)closeDB{
    if (dl_database) {
        sqlite3_close(dl_database);
        dl_database = nil;
    }
}

+(BOOL)execSQL:(NSString *)sql uid:(NSString *)uid{
    if (!dl_database) {
        if (![self openDB:uid]) {
            return NO;
        }
    }
    char *errmsg = nil;
    int result = sqlite3_exec(dl_database, sql.UTF8String, nil, nil, &errmsg);
    if (result != SQLITE_OK) {
        NSLog(@"exec SQL(%@) error : %s",sql,errmsg);
        sqlite3_free(errmsg);
        return NO;
    }
    return YES;
}

// 执行多个sql语句
+(BOOL)execSqls:(NSArray <NSString *>*)sqls uid:(NSString *)uid {
    // 事务控制所有语句必须返回成功，才算执行成功
    [self beginTransaction:uid];
    
    for (NSString *sql in sqls) {
        BOOL result = [self execSQL:sql uid:uid];
        if (result == NO) {
            [self rollBackTransaction:uid];
            return NO;
        }
    }
    [self commitTransaction:uid];
    return YES;
}

// 查询
+(NSMutableArray <NSMutableDictionary *>*)querySql:(NSString *)sql uid:(NSString *)uid {
    // 1、打开数据库
    if (!dl_database) {
        if (![self openDB:uid]) {
            return nil;
        }
    }
    
    // 2、预执行语句
    sqlite3_stmt *ppStmt     = 0x00; //伴随指针
    if (sqlite3_prepare_v2(dl_database, sql.UTF8String, -1, &ppStmt, nil) != SQLITE_OK) {
        NSLog(@"查询准备语句编译失败");
        return nil;
    }
    // 3、绑定数据，因为我们的sql语句中不带有？用来赋值，所以不需要进行绑定
    // 4、执行遍历查询
    NSMutableArray *rowDicArray = [NSMutableArray array];
    while (sqlite3_step(ppStmt) == SQLITE_ROW) { // SQLITE_ROW表示还有下一条数据
        // 获取有多少列(也就是一条数据有多少个字段)
        int columnCount = sqlite3_column_count(ppStmt);
        // 存储一条数据的所有字段名与值 的字典
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionary];
        // 遍历数据库一条数据所有字段
        for (int i = 0; i < columnCount; i++) {
            // 获取字段名
            NSString *columnName = [NSString stringWithUTF8String:sqlite3_column_name(ppStmt, i)];
            // 获取字段名对应的类型
            int type = sqlite3_column_type(ppStmt, i);
            // 获取对应的值
            id value = nil;
            switch (type) {
                case SQLITE_INTEGER:
                    value = @(sqlite3_column_int(ppStmt, i));
                    break;
                case SQLITE_FLOAT:
                    value = @(sqlite3_column_double(ppStmt, i));
                    
                    break;
                case SQLITE_BLOB: // 二进制
                    value = CFBridgingRelease(sqlite3_column_blob(ppStmt, i));
                    break;
                case SQLITE_NULL:
                    value = @"";
                    break;
                case SQLITE3_TEXT:
                    value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(ppStmt, i)];
                    break;
                    
                default:
                    break;
            }
            [rowDict setValue:value forKey:columnName];
        }
        [rowDicArray addObject:rowDict];
    }
    // 5、重制（省略）
    // 6、释放资源，关闭数据库
    sqlite3_finalize(ppStmt);
    
    return rowDicArray;
}

#pragma mark - 事务
+ (void)beginTransaction:(NSString *)uid {
    [self execSQL:@"BEGIN TRANSACTION" uid:uid];
}

+ (void)commitTransaction:(NSString *)uid {
     [self execSQL:@"COMMIT TRANSACTION" uid:uid];
}

+ (void)rollBackTransaction:(NSString *)uid {
     [self execSQL:@"ROLLBACK TRANSACTION" uid:uid];
}

@end

@interface DLSqliteTableTool : NSObject

// 表格是否存在
+(BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid;

// 获取数据库表格的所有字段
+(NSArray *)allTableColumnNames:(NSString *)tableName uid:(NSString *)uid;

// 数据库表是否需要更新
+(BOOL)isTableNeedUpdate:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

@end

@implementation DLSqliteTableTool

+(BOOL)isTableExists:(NSString *)tableName uid:(NSString *)uid{
    // 去sqlite_master这个表里面去查询创建此索引的sql语句
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'",tableName];
    NSMutableArray *resultArray = [DLDatabase querySql:queryCreateSqlStr uid:uid];
    return resultArray.count > 0;
}

// 获取表的所有字段名，排序后返回
+(NSArray *)allTableColumnNames:(NSString *)tableName uid:(NSString *)uid {
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'",tableName];
    NSArray *dictArr = [DLDatabase querySql:queryCreateSqlStr uid:uid];
    NSMutableDictionary *dict = dictArr.firstObject;
    NSString *createSql = dict[@"sql"];
    if (createSql.length == 0) {
        return nil;
    }
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    createSql = [createSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    NSString *nameTypeStr = [createSql componentsSeparatedByString:@"("][1];
    NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *nameType in nameTypeArray) {
        // 去掉主键
        if ([nameType containsString:@"primary"]) {
            continue;
        }
        // 压缩掉字符串里面的 @“ ”  只压缩两端的
        NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        // age integer
        NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
        [names addObject:name];
    }
    [names sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2){
        return [obj1 compare:obj2];
    }];
    return names;
}

// 数据库表是否需要更新
+(BOOL)isTableNeedUpdate:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId{
    NSArray *modelNames = [DLModelAnalysis allIvarNames:cls];
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSArray *tableNames = [self allTableColumnNames:tableName uid:uid];
    return ![modelNames isEqualToArray:tableNames];
}

@end

@interface DLSQLManager ()

@property (nonatomic,strong)dispatch_semaphore_t dsema;

@end

@implementation DLSQLManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.dsema = dispatch_semaphore_create(1);
    }
    return self;
}

static DLSQLManager * sqlManager = nil;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sqlManager = [[DLSQLManager alloc] init];
    });
    return sqlManager;
}

#pragma mark - 创建数据库表格
// 不需要自己调用
+ (BOOL)createSQLTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {
    // 创建数据库表的语句
    // create table if not exists 表名(字段1 字段1类型（约束）,字段2 字段2类型（约束）....., primary key(字段))
    // 获取数据库表名
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        return NO;
    }
    // 获取主键
    NSString *primaryKey = [cls primaryKey];
    if (!primaryKey) {
        NSLog(@"你需要指定一个主键来创建数据库表");
        return NO;
    }
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))",tableName,[DLModelAnalysis sqlColumnNamesAndTypesStr:cls],primaryKey];
    // 执行语句
    BOOL result = [DLDatabase execSQL:createTableSql uid:uid];
    // 关闭数据库
//    [CWDatabase closeDB];
    return result;
}


#pragma mark - 插入或者更新数据

#pragma mark 简易方法

/**
简易方法!向数据库单个插入或者更新数据.

@param model 需要保存或者更新的模型
@return 插入或者更新数据是否成功，成功返回YES 失败返回NO
*/
+(BOOL)insertOrUpdateModel:(id)model {
    return [self insertOrUpdateModels:@[model] uid:nil targetId:nil];
}

/**
简易方法!向数据库批量插入或者更新数据.

@param modelsArray 模型的数组，数组内的模型必须是同一类型，否则会失败
@return 插入或者更新数据是否成功，成功返回YES 失败返回NO。（事务控制，必须全部插入成功才返回YES，有一条失败则返回NO）
*/
+(BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray {
    return [self insertOrUpdateModels:modelsArray uid:nil targetId:nil];
}

#pragma mark 完整方法
/**
向数据库单个插入或者更新数据

@param model       需要保存或者更新的模型
@param uid         userId，可为nil，作用看前一个方法（批量插入数据）的解释
@param targetId    目标id，可为nil，作用看前一个方法（批量插入数据）的解释
@return            插入或者更新数据是否成功，成功返回YES 失败返回NO
*/
+ (BOOL)insertOrUpdateModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    return [self insertOrUpdateModels:@[model] uid:uid targetId:targetId];
}

/**
向数据库批量插入或者更新数据
--方法内部会根据所传模型的主键值来判断数据库内是否存在数据；
--如果数据库对应表格内存在主键一样的数据，方法内部会进行更新操作，将原有的模型的数据更新为最新的模型的数据。
--如果数据库对应表格内不存在主键一样的数据，方法内将会直接执行插入数据库操作

@param modelsArray     模型的数组，数组内的模型必须是同一类型，否则会失败
@param uid             userId，主要用于数据库的名称，可为nil，当为nil时我们会默认将数据库名称设置为CWDB，不同的uid对应不同的数据              库，比如账号张三登陆，创建的数据库则为张三，李四登陆创建的数据库则为李四
@param targetId        目标id，可为nil，主要用于分辨数据库表名，方法内部创建数据库表时根据模型的类型className来创建对应的数据库表，但是有的场景并不适合仅用className为表名，比如聊天记录，和张三聊天希望是和张三聊天对应的一个表，和李四聊天就对应另一个表，带上目标ID我们就能将要保存的数据分别给张三、李四对应的表内存储，查询数据的时候会按照targetId找到对应的表格进行查询，如果你不需要同个模型分别建多张表格，传nil即可
@return                插入或者更新数据是否成功，成功返回YES 失败返回NO。（事务控制，必须全部插入成功才返回YES，有一条失败则返回NO）
*/
+ (BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    id modelF = modelsArray.firstObject;
    // 获取表名
    Class cls = [modelF class];
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    
    // 判断数据库是否存在对应的表，不存在则创建
    if (![DLSqliteTableTool isTableExists:tableName uid:uid]) {
        BOOL r = [self createSQLTable:cls uid:uid targetId:targetId];
        if (!r) {
            dispatch_semaphore_signal([[self shareInstance] dsema]);
            return NO;
        }
    }else { // 如果表格存在，则检测表格是否需要更新
        // 1、检查缓存，表格是否更新过,不考虑动态添加属性的情况下，只要更新更高一次即可
        if (!targetId) targetId = @"";
        NSString *cacheKey = [NSString stringWithFormat:@"%@%@CWUpdated",NSStringFromClass(cls),targetId];
        BOOL updated = [[[DLCache shareInstance] objectForKey:cacheKey] boolValue]; // 表格是否更新过
        if (!updated) { // 2、如果表格没有更新过,检测是否需要更新
            if ([DLSqliteTableTool isTableNeedUpdate:cls uid:uid targetId:targetId] ) {
                dispatch_semaphore_signal([[self shareInstance] dsema]);
                // 2.1、表格需要更新,则进行更新操作
                BOOL result = [self updateTable:cls uid:uid targetId:targetId];
                dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
                if (!result) {
                    // 2.2、更新失败，设置缓存为未更新
                    [[DLCache shareInstance] setObject:@(NO) forKey:cacheKey];
                    NSLog(@"更新数据库表结构失败!插入或更新数据失败!");
                    dispatch_semaphore_signal([[self shareInstance] dsema]);
                    return NO;
                }
                // 2.3、更新成功，设置缓存为已更新
                [[DLCache shareInstance] setObject:@(YES) forKey:cacheKey];
            }else {
                // 3、表格不需要更新,设置缓存为已更新
                [[DLCache shareInstance] setObject:@(YES) forKey:cacheKey];
            }
        }
    }
    
    // 根据主键，判断数据库内是否存在记录
    // 判断对象是否返回主键信息
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    // 获取主键
    NSString *primaryKey = [cls primaryKey];
    if (!primaryKey) {
        NSLog(@"你需要指定一个主键来创建数据库表");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    [DLDatabase beginTransaction:uid];
    for (id model in modelsArray) {
        @autoreleasepool {
        // 模型中的主键的值
        id primaryValue = [model valueForKeyPath:primaryKey];
        //  查询语句：  NSString *checkSql = @"select * from 表名 where 主键 = '主键值' ";
        NSString * checkSql = [NSString stringWithFormat:@"select * from %@ where %@ = '%@'",tableName,primaryKey,primaryValue];
        
        // 执行查询语句,获取结果
        NSArray *result = [DLDatabase querySql:checkSql uid:uid];
        // 获取类的所有成员变量的名称与类型
        NSDictionary *nameTypeDict = [DLModelAnalysis classIvarNameAndTypeDic:cls];
        // 获取所有成员变量的名称，也就是sql语句字段名称
        NSArray *allIvarNames = nameTypeDict.allKeys;
        // 获取所有成员变量对应的值
        NSMutableArray *allIvarValues = [NSMutableArray array];
        for (NSString *ivarName in allIvarNames) {
            @autoreleasepool {
                // 获取对应的值,暂时不考虑自定义模型和oc模型的情况
                id value = [model valueForKeyPath:ivarName];
                
                NSString *type = nameTypeDict[ivarName];
                //        NSLog(@"type: %@ , value : %@ , valueClass : %@ , ivarName : %@",type,value,[value class],ivarName);
                
                value = [DLModelAnalysis formatModelValue:value type:type isEncode:YES];
                
                [allIvarValues addObject:value];
            }
        }
        // 字段1=字段1值 allIvarNames[i]=allIvarValues[i]
        NSMutableArray *ivarNameValueArray = [NSMutableArray array];
        //    NSInteger count = allIvarNames.count;
        
        [allIvarNames enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *name = obj;
            id value = allIvarValues[idx];
            NSString *ivarNameValue = [NSString stringWithFormat:@"%@='%@'",name,value];
            [ivarNameValueArray addObject:ivarNameValue];
        }];
        
        NSString *execSql = @"";
        if (result.count > 0) { // 表内存在记录，更新
            // update 表名 set 字段1='字段1值'，字段2='字段2的值'...where 主键 = '主键值'
            execSql = [NSString stringWithFormat:@"update %@ set %@ where %@ = '%@'",tableName,[ivarNameValueArray componentsJoinedByString:@","],primaryKey,primaryValue];
        }else { // 表内不存在记录，插入
            // insert into 表名(字段1，字段2，字段3) values ('值1'，'值2'，'值3')
            execSql = [NSString stringWithFormat:@"insert into %@(%@) values('%@')",tableName,[allIvarNames componentsJoinedByString:@","],[allIvarValues componentsJoinedByString:@"','"]];
        }
        // 执行数据库
        BOOL ret = [DLDatabase execSQL:execSql uid:uid];
        if (ret == NO) {
            [DLDatabase rollBackTransaction:uid];
            dispatch_semaphore_signal([[self shareInstance] dsema]);
            return NO;
        }
        }
    }
    // 提交事务
    [DLDatabase commitTransaction:uid];
    // 关闭数据库
    [DLDatabase closeDB];
    
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return YES;
}

#pragma mark - 查询数据

#pragma mark 简易方法

// 查询所有数据
/**
简易方法!查询数据库所有数据.

@param cls 模型的类型 [obj class]
@return  查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryAllModels:(Class)cls {
    return [self queryAllModels:cls uid:nil targetId:nil];
}

/**
简易方法!根据单个条件查询数据.
比如我想查找数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age大于10

@param cls             模型的类型
@param name            条件字段名称
@param relation        字段与值的关系，大于、小于、等于......
@param value           字段的值
@return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value {
    return [self queryModels:cls name:name relation:relation value:value uid:nil targetId:nil];
}

/**
简易方法!根据多个条件与查询(and必须所有条件都满足才能查询到 or 满足其中一个条件就都查询得到)
比如我想查找数据库内Student模型的 age大于10岁，并且 height小于等于100厘米的小朋友：
第一个参数传 @[@"age",@"height"]
第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
第三个参数传 @[@(10),@(100)]
第四个参数传 YES，如果 age>10 和 height<=100 只要满足其中一个就行 就传NO

@param cls             模型的类型
@param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
@param relations       字段与值的关系数组
@param values          字段的值数组
@param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
@return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd {
    return [self queryModels:cls columnNames:columnNames relations:relations values:values isAnd:isAnd uid:nil targetId:nil];
}

#pragma mark 完整方法

/**
查询对应uid的数据库内对应targetId表内的所有数据

@param cls         模型的类型 [obj class]
@param uid         userId,可为nil，保存数据时传的啥，这里就传啥，（使用简易方法保存的数据传nil即可）
@param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
@return            查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId {
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
    NSArray <NSDictionary *>*results = [DLDatabase querySql:sql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return [self parseResults:results withClass:cls];
}

/**
自己传sql语句查询
写sql语句时，表名为插入数据时的 模型类型的字符串+targetId
比如：插入一个 Student模型时 targetId为张三，那么这个表名为 Student张三，在自己写sql语句时表名通过这个规则写
提供写法：[NSString stringWithFormat:@"%@%@",NSStringFromClass([student class]),targetId] 这样就返回了正确的表名

@param cls     模型的类型，返回的数据内的元素为该类型的模型，请与保存数据时的模型类型对应
@param sql     sql语句，如 select * from 表名 where xx = xx or/and cc = cc ...
@param uid     userId,可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@return        查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryModels:(Class)cls Sql:(NSString *)sql uid:(NSString *)uid {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSArray <NSDictionary *>*results = [DLDatabase querySql:sql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return [self parseResults:results withClass:cls];
}

/**
根据单个条件查询数据
比如我想查找数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age大于10

@param cls             模型的类型
@param name            条件字段名称
@param relation        字段与值的关系，大于、小于、等于......
@param value           字段的值
@param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@param targetId        targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
@return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId {
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ %@ '%@'", tableName,name,self.CWDBNameToValueRelationTypeDic[@(relation)],value];
    NSArray <NSDictionary *>*results = [DLDatabase querySql:sql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return [self parseResults:results withClass:cls];
}

/**
根据多个条件与查询(and必须所有条件都满足才能查询到 or 满足其中一个条件就都查询得到)
比如我想查找数据库内Student模型的 age大于10岁，并且 height小于等于100厘米的小朋友：
第一个参数传 @[@"age",@"height"]
第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
第三个参数传 @[@(10),@(100)]
第四个参数传 YES，如果 age>10 和 height<=100 只要满足其中一个就行 就传NO

@param cls             模型的类型
@param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
@param relations       字段与值的关系数组
@param values          字段的值数组
@param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
@param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@param targetId        目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
@return                查询到的结果数组，数组内元素为第一个参数cls类型的模型
*/
+(NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    if (!(columnNames.count == relations.count && relations.count == values.count)) {
        NSLog(@"columnNames、relations、values元素个数请保持一致!");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return nil;
    }
    
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *appendStr = isAnd ? @"and" : @"or" ;
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select * from %@ where",tableName];
    for (int i = 0; i < columnNames.count; i++) {
        NSString *columnName = columnNames[i];
        NSString *relation = self.CWDBNameToValueRelationTypeDic[relations[i]];
        id value = values[i];
        NSString *nameValueStr = [NSString stringWithFormat:@" %@ %@ '%@' ",columnName,relation,value];
        [sql appendString:nameValueStr];
        if (i != columnNames.count - 1) {
            [sql appendString:appendStr];
        }
    }
    
    NSArray <NSDictionary *>*results = [DLDatabase querySql:sql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return [self parseResults:results withClass:cls];
}

// 解析数组                             {字段名称 : 值}
+(NSArray *)parseResults:(NSArray <NSDictionary *>*)results withClass:(Class)cls  {
    NSMutableArray *models = [NSMutableArray array];
    // {字段名称 : 值}
    for (NSDictionary *dict in results) {
        id model = [DLModelAnalysis model:cls Dict:dict];
        [models addObject:model];
    }
    return models;
}

#pragma mark - 删除数据

#pragma mark 简易方法

/**
简易方法!删除指定模型.
会根据model的主键值来删除对应的数据，模型不一定要完全一样，删除的数据只和主键相关

@param model 要删除的模型
@return 删除是否成功
*/
+(BOOL)deleteModel:(id)model{
    return [self deleteModel:model uid:nil targetId:nil];
}

/**
简易方法!删除数据库表中所有数据.

@param cls 模型类型
@param isKeep 是否保留表，传YES表保留只删除表内所有数据，传NO直接将表销毁
@return 删除是否成功
*/
+(BOOL)deleteTableAllData:(Class)cls isKeepTable:(BOOL)isKeep {
    return [self deleteTableAllData:cls uid:nil targetId:nil isKeepTable:isKeep];
}

/**
简易方法!根据单个条件删除数据库内数据.

比如我想删除数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age>10

@param cls             模型的类型
@param name            条件字段名称
@param relation        字段与值的关系，大于、小于、等于......
@param value           字段的值
@return                删除是否成功
*/
+(BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value {
    return [self deleteModels:cls columnName:name relation:relation value:value uid:nil targetId:nil];
}

/**
简易方法!根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)
比如我想删除数据库内Student模型的age大于10岁并且height小于等于100厘米的所有小朋友：
第一个参数传 @[@"age",@"height"]
第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
第三个参数传 @[@(10),@(100)]
第四个参数传 YES；  如果age>10和height<=100只要满足其中一个就删除就传NO

@param cls             模型的类型
@param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
@param relations       字段与值的关系数组
@param values          字段的值数组
@param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
@return                删除是否成功
*/
+(BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd {
    return [self deleteModels:cls columnNames:columnNames relations:relations values:values isAnd:isAnd uid:nil targetId:nil];
}

#pragma mark 完整方法

/**
删除数据库表中所有数据

@param cls         模型类型
@param uid         userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥（使用简易方法保存的数据传nil即可）
@param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
@param isKeep      是否保留表，传YES表保留只删除表内所有数据，传NO直接将表销毁
@return            删除是否成功
*/
+(BOOL)deleteTableAllData:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId isKeepTable:(BOOL)isKeep {
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *deleteSql ;
    if (isKeep) {
        deleteSql = [NSString stringWithFormat:@"delete from %@",tableName];
    }else {
        deleteSql = [NSString stringWithFormat:@"drop table if exists %@",tableName];
    }
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    // 执行数据库
    BOOL result = [DLDatabase execSQL:deleteSql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return result;
}

// 根据模型的主键来删除
/**
删除指定模型,会根据model的主键值来删除对应的数据，模型不一定要完全一样，输出的数据只和主键相关

@param model       要删除的模型
@param uid         用户id，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@param targetId    目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
@return            删除是否成功
*/
+ (BOOL)deleteModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    Class cls = [model class];
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    NSString *primaryKey = [cls primaryKey];
    id primaryValue = [model valueForKeyPath:primaryKey];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'",tableName,primaryKey,primaryValue];
    
    // 执行数据库
    BOOL result = [DLDatabase execSQL:deleteSql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

/**
自己传sql语句删除
写sql语句时，表名为插入数据时的 模型类型的字符串+targetId
比如：插入一个 Student模型时 targetId为张三，那么这个表名为 Student张三，在自己写sql语句时表名通过这个规则写
提供写法：[NSString stringWithFormat:@"%@%@",NSStringFromClass([student class]),targetId] 这样就返回了正确的表名

@param deleteSql   执行的sql语句
@param uid         用户id，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@return            删除是否成功
*/
+ (BOOL)deleteModelWithSql:(NSString *)deleteSql uid:(NSString *)uid{
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    
    BOOL result = [DLDatabase execSQL:deleteSql uid:uid];
    
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return result;
}

/**
根据单个条件删除数据库内数据

比如我想删除数据库内Student模型的 age 大于 10岁的所有数据：第一个参数name传age，第二个参数relation传CWDBRelationTypeMore，第三个参数传值@(10)，连着读就是，age>10

@param cls             模型的类型
@param name            条件字段名称
@param relation        字段与值的关系，大于、小于、等于......
@param value           字段的值
@param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
@param targetId        targetId 目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
@return                删除是否成功
*/
+ (BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId {
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *deleteSql = [NSString stringWithFormat:@"delete from %@ where %@ %@ '%@'",tableName,name,self.CWDBNameToValueRelationTypeDic[@(relation)],value];
    BOOL result = [DLDatabase execSQL:deleteSql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    return result;
}


// 根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)

/**
 根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)
 比如我想删除数据库内Student模型的age大于10岁并且height小于等于100厘米的所有小朋友：
 第一个参数传 @[@"age",@"height"]
 第二个参数传 @[@(CWDBRelationTypeMore),@(CWDBRelationTypeLessEqual)]
 第三个参数传 @[@(10),@(100)]
 第四个参数传 YES；  如果age>10和height<=100只要满足其中一个就删除就传NO
 
 @param cls             模型的类型
 @param columnNames     条件字段名称组成的数组  columnNames、relations、values数组元素的个数必须相等
 @param relations       字段与值的关系数组
 @param values          字段的值数组
 @param isAnd           各个条件之前是否需要全部满足还是只要满足其中的一个条件，YES对应and NO对应or
 @param uid             userId，可为nil，数据库名称是以uid命名，保存数据时传的啥，这里就传啥
 @param targetId        目标ID，可为nil，与数据库表名相关，保存数据时传的啥，这里就传啥
 @return                删除是否成功
 */
+ (BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId {
    
    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);

    if (!(columnNames.count == relations.count && relations.count == values.count)) {
        NSLog(@"columnNames、relations、values元素个数请保持一致!");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }
    
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];
    NSString *appendStr = isAnd ? @"and" : @"or" ;

    NSMutableString *deleteSql = [NSMutableString stringWithFormat:@"delete from %@ where",tableName];
    
    [columnNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *columnName = obj;
        NSString *relation = self.CWDBNameToValueRelationTypeDic[relations[idx]];
        id value = values[idx];
        NSString *nameValueStr = [NSString stringWithFormat:@" %@ %@ '%@' ",columnName,relation,value];
        [deleteSql appendString:nameValueStr];
        if (idx != columnNames.count - 1) {
            [deleteSql appendString:appendStr];
        }
    }];
    
    BOOL result = [DLDatabase execSQL:deleteSql uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);
    
    return result;
}

//+(NSString *)primaryKey{
//    return @"id";
//}

#pragma mark - 更新数据库表结构、数据迁移
// 更新表并迁移数据
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId{

    dispatch_semaphore_wait([[self shareInstance] dsema], DISPATCH_TIME_FOREVER);
    // 1.创建一个拥有正确结构的临时表
    // 1.1 获取表格名称
    NSString *tmpTableName = [DLModelAnalysis tmpTableName:cls targetId:targetId];
    NSString *tableName = [DLModelAnalysis tableName:cls targetId:targetId];

    // 类方法可以直接响应 对象方法[cls new] responds...
    if (![cls respondsToSelector:@selector(primaryKey)]) {
        NSLog(@"如果想要操作这个模型，必须要实现+ (NSString *)primaryKey;这个方法，来告诉我主键信息");
        dispatch_semaphore_signal([[self shareInstance] dsema]);
        return NO;
    }

    // 保存所有需要执行的sql语句
    NSMutableArray *execSqls = [NSMutableArray array];

    NSString *primaryKey = [cls primaryKey];
    // 1.2 获取一个模型里面所有的字段，以及类型
    NSString *createTableSql = [NSString stringWithFormat:@"create table if not exists %@(%@, primary key(%@))",tmpTableName,[DLModelAnalysis sqlColumnNamesAndTypesStr:cls],primaryKey];

    [execSqls addObject:createTableSql];

    // 2.根据主键插入数据
    //--insert into cwstu_tmp(stuNum) select stuNum from CWStu;
    NSString *inserPrimaryKeyData = [NSString stringWithFormat:@"insert into %@(%@) select %@ from %@",tmpTableName,primaryKey,primaryKey,tableName];

    [execSqls addObject:inserPrimaryKeyData];

    // 3.根据主键，把所有的数据插入到怕新表里面去
    NSArray *oldNames = [DLSqliteTableTool allTableColumnNames:tableName uid:uid];
    NSArray *newNames = [DLModelAnalysis allIvarNames:cls];

    // 4.获取更名字典
    NSDictionary *newNameToOldNameDic = @{};
//    if ([cls respondsToSelector:@selector(newNameToOldNameDic)]) {
//        newNameToOldNameDic = [cls newNameToOldNameDic];
//    }

    for (NSString *columnName in newNames) {
        NSString *oldName = columnName;
        // 找映射的旧的字段名称
        if ([newNameToOldNameDic[columnName] length] != 0) {
            if ([oldNames containsObject:newNameToOldNameDic[columnName]]) {
                oldName = newNameToOldNameDic[columnName];
            }
        }
        // 如果老表包含了新的列名，应该从老表更新到临时表格里面
        if ((![oldNames containsObject:columnName] && [columnName isEqualToString:oldName]) ) {
            continue;
        }
        // --update cwstu_tmp set name = (select name from cwstu where cwstu_tmp.stuNum = cwstu.stuNum);
        NSString *updateSql = [NSString stringWithFormat:@"update %@ set %@ = (select %@ from %@ where %@.%@ = %@.%@)",tmpTableName,columnName,oldName,tableName,tmpTableName,primaryKey,tableName,primaryKey];

        [execSqls addObject:updateSql];

    }

    NSString *deleteOldTable = [NSString stringWithFormat:@"drop table if exists %@",tableName];
    [execSqls addObject:deleteOldTable];

    NSString *renameTableName = [NSString stringWithFormat:@"alter table %@ rename to %@",tmpTableName,tableName];
    [execSqls addObject:renameTableName];

    BOOL result = [DLDatabase execSqls:execSqls uid:uid];
    [DLDatabase closeDB];
    dispatch_semaphore_signal([[self shareInstance] dsema]);

    return result;
}

#pragma mark - 枚举与字符串的映射关系
+ (NSDictionary *)CWDBNameToValueRelationTypeDic {
    return @{@(DLSQLRelationTypeGreat):@">",
             @(DLSQLRelationTypeLess):@"<",
             @(DLSQLRelationTypeEqual):@"=",
             @(DLSQLRelationTypeGreatEqual):@">=",
             @(DLSQLRelationTypeLessEqual):@"<="
             };
}


@end
