#import "UIGestureRecognizer+Add.h"
#import <objc/runtime.h>
#import "DLToolMacro.h"

static const int block_key;

@interface _DLUIGestureRecognizerBlockTarget : NSObject

@property (nonatomic, copy) void (^block)(id sender);

- (id)initWithBlock:(void (^)(id sender))block;
- (void)invoke:(id)sender;

@end

@implementation _DLUIGestureRecognizerBlockTarget

- (id)initWithBlock:(void (^)(id sender))block{
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

- (void)invoke:(id)sender {
    if (_block) _block(sender);
}

@end

@implementation UIGestureRecognizer (Add)

-(instancetype)initWithActionBlock:(void (^)(id sender))block{
    self = [self init];
    [self dl_addActionBlock:block];
    return self;
}

-(void)dl_addActionBlock:(void (^)(id sender))block{
    _DLUIGestureRecognizerBlockTarget *target = [[_DLUIGestureRecognizerBlockTarget alloc] initWithBlock:block];
    [self addTarget:target action:@selector(invoke:)];
    NSMutableArray *targets = [self _dl_allUIGestureRecognizerBlockTargets];
    [targets addObject:target];
}

-(void)dl_removeAllActionBlocks{
    NSMutableArray *targets = [self _dl_allUIGestureRecognizerBlockTargets];
    [targets enumerateObjectsUsingBlock:^(id target, NSUInteger idx, BOOL *stop) {
        [self removeTarget:target action:@selector(invoke:)];
    }];
    [targets removeAllObjects];
}

-(NSMutableArray *)_dl_allUIGestureRecognizerBlockTargets {
    NSMutableArray *targets = objc_getAssociatedObject(self, &block_key);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, &block_key, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end
