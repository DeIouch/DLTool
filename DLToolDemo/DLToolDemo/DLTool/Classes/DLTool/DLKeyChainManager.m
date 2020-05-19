#import "DLKeyChainManager.h"

@implementation DLKeyChainManager

dl_shareInstance_implementation(DLKeyChainManager);

-(BOOL)dl_addKeyChainWithKey:(NSString *)key value:(NSString *)value{
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *secItem = @{
                              (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                              (__bridge id)kSecAttrService : service,
                              (__bridge id)kSecAttrAccount : key,
                              (__bridge id)kSecValueData : valueData,
                              };
    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)secItem, &result);
    if (status == errSecSuccess){
        return true;
    } else {
        return false;
    }
    return false;
}

-(BOOL)dl_deleteKeyChainWithKey:(NSString *)key{
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : service,
                            (__bridge id)kSecAttrAccount : key
                            };
    OSStatus foundExisting =
    SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    if (foundExisting == errSecSuccess){
        OSStatus deleted = SecItemDelete((__bridge CFDictionaryRef)query);
        if (deleted == errSecSuccess){
             NSLog(@"删除成功：%@",key);
            true;
        } else {
            NSLog(@"删除失败");
            false;
        }
    } else {
        NSLog(@"删除失败");
        false;
    }
    return false;
}

-(BOOL)dl_updateKeyChainWithKey:(NSString *)key value:(NSString *)value{
    NSString *keyToSearchFor = key;
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : service,
                            (__bridge id)kSecAttrAccount : keyToSearchFor,
                            };
    OSStatus found = SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                         NULL);
    if (found == errSecSuccess){
        NSData *newData = [value
                           dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *update = @{
                                 (__bridge id)kSecValueData : newData,
                                 (__bridge id)kSecAttrComment : keyToSearchFor,
                                 };
        OSStatus updated = SecItemUpdate((__bridge CFDictionaryRef)query,
                                         (__bridge CFDictionaryRef)update);
        if (updated == errSecSuccess){
            NSLog(@"更新成功.新值是：");
            [self dl_getKeyChainValueWithKey:key];
            return true;
        } else {
            NSLog(@"更新失败");
            return false;
        }
    } else {
        NSLog(@"更新失败");
        return false;
    }
    return true;
}

-(id)dl_getKeyChainValueWithKey:(NSString *)key{
    NSString *keyToSearchFor = key;
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = @{
                            (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService : service,
                            (__bridge id)kSecAttrAccount : keyToSearchFor,
                            (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue,
                            (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll
                            };
    
    CFArrayRef allCfMatches = NULL;
    OSStatus results = SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                           (CFTypeRef *)&allCfMatches);
    if (results == errSecSuccess){
        NSArray *allMatches = (__bridge_transfer NSArray *)allCfMatches;
        for (NSData *itemData in allMatches){
            NSString *value = [[NSString alloc]
                               initWithData:itemData
                               encoding:NSUTF8StringEncoding];
            return value;
        }
    } else {
        return nil;
    }
    return nil;
}

@end
