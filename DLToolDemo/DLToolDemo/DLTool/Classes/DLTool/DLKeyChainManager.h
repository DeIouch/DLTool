#import <Foundation/Foundation.h>
#import "DLToolMacro.h"

@interface DLKeyChainManager : NSObject

dl_shareInstance(DLKeyChainManager);

-(BOOL)dl_addKeyChainWithKey:(NSString *)key value:(NSString *)value;
-(BOOL)dl_updateKeyChainWithKey:(NSString *)key value:(NSString *)value;
-(BOOL)dl_deleteKeyChainWithKey:(NSString *)key;
-(id)dl_getKeyChainValueWithKey:(NSString *)key;

@end
