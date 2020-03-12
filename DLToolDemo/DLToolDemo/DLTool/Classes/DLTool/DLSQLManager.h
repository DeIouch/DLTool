#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DLSQLRelationType) {
    DLSQLRelationTypeGreat = 0,       // 大于 >
    DLSQLRelationTypeLess,            // 小于 <
    DLSQLRelationTypeEqual,           // 等于 =
    DLSQLRelationTypeGreatEqual,      // 大于等于 >=
    DLSQLRelationTypeLessEqual        // 小于等于 <=
};

@interface DLSQLManager : NSObject

//  设置主键（model中必须实现）
+(NSString *)primaryKey;

#pragma mark - 插入或更新数据

// 向数据库单个插入或者更新数据.
+(BOOL)insertOrUpdateModel:(id)model;

// 向数据库批量插入或者更新数据
+(BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray;

#pragma mark 完整方法
// 向数据库批量插入或者更新数据
+(BOOL)insertOrUpdateModels:(NSArray<id> *)modelsArray uid:(NSString *)uid targetId:(NSString *)targetId;

// 插入单个模型
+(BOOL)insertOrUpdateModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;

#pragma mark - 数据查询
// 查询数据库所有数据
+(NSArray *)queryAllModels:(Class)cls;

// 根据单个条件查询数据
+(NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value;

// 根据多个条件与查询
+(NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd;

#pragma mark 完整方法
// 查询对应uid的数据库内对应targetId表内的所有数据
+(NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId;

// 根据sql语句查询
+(NSArray *)queryModels:(Class)cls Sql:(NSString *)sql uid:(NSString *)uid;

// 根据单个条件查询
+(NSArray *)queryModels:(Class)cls name:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId;

// 根据多个条件查询
+(NSArray *)queryModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId;


#pragma mark -数据删除
// 删除指定模型
+(BOOL)deleteModel:(id)model;

//删除数据表所有数据
+(BOOL)deleteTableAllData:(Class)cls isKeepTable:(BOOL)isKeep;

// 根据单个条件删除
+(BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value;

// 根据多个条件删除
+(BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd;

// 删除数据库表中所有数据
// isKeep：是否把表一起删除
+(BOOL)deleteTableAllData:(Class)cls uid:(NSString *)uid targetId:(NSString *)targetId isKeepTable:(BOOL)isKeep;

// 根据模型的主键来删除删除指定模型
+(BOOL)deleteModel:(id)model uid:(NSString *)uid targetId:(NSString *)targetId;

// 自己写sql语句删除
+(BOOL)deleteModelWithSql:(NSString *)deleteSql uid:(NSString *)uid;

// 根据单个条件删除数据库内数据
+(BOOL)deleteModels:(Class)cls columnName:(NSString *)name relation:(DLSQLRelationType)relation value:(id)value uid:(NSString *)uid targetId:(NSString *)targetId;

// 根据多个条件删除(and删除满足所有条件的数据 or 删除满足其中任何一个条件的数据)
+(BOOL)deleteModels:(Class)cls columnNames:(NSArray <NSString *>*)columnNames relations:(NSArray <NSNumber *>*)relations values:(NSArray *)values isAnd:(BOOL)isAnd uid:(NSString *)uid targetId:(NSString *)targetId;

@end
