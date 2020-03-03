#import "UIControl+Add.h"
#import <objc/runtime.h>
#import "DLToolMacro.h"

static const int block_key;

@interface _DLUIControlBlockTarget : NSObject

@property (nonatomic, copy) void (^block)(id sender);
@property (nonatomic, assign) UIControlEvents events;

- (id)initWithBlock:(void (^)(id sender))block events:(UIControlEvents)events;
- (void)invoke:(id)sender;

@end

@implementation _DLUIControlBlockTarget

- (id)initWithBlock:(void (^)(id sender))block events:(UIControlEvents)events {
    self = [super init];
    if (self) {
        _block = [block copy];
        _events = events;
    }
    return self;
}

- (void)invoke:(id)sender {
    if (_block) _block(sender);
}

@end

@implementation UIControl (Add)

-(void)dl_removeAllTargets{
    [[self allTargets] enumerateObjectsUsingBlock: ^(id object, BOOL *stop) {
           [self removeTarget:object action:NULL forControlEvents:UIControlEventAllEvents];
       }];
       [[self _dl_allUIControlBlockTargets] removeAllObjects];
}

-(void)dl_setTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents{
    if (!target || !action || !controlEvents) return;
    NSSet *targets = [self allTargets];
    for (id currentTarget in targets) {
        NSArray *actions = [self actionsForTarget:currentTarget forControlEvent:controlEvents];
        for (NSString *currentAction in actions) {
            [self removeTarget:currentTarget action:NSSelectorFromString(currentAction)
                forControlEvents:controlEvents];
        }
    }
    [self addTarget:target action:action forControlEvents:controlEvents];
}

-(void)dl_setBlockForControlEvents:(UIControlEvents)controlEvents block:(void (^)(id sender))block{
    if (!controlEvents) return;
    _DLUIControlBlockTarget *target = [[_DLUIControlBlockTarget alloc]
                                       initWithBlock:block events:controlEvents];
    [self addTarget:target action:@selector(invoke:) forControlEvents:controlEvents];
    NSMutableArray *targets = [self _dl_allUIControlBlockTargets];
    [targets addObject:target];
}

-(void)dl_addBlockForControlEvents:(UIControlEvents)controlEvents block:(void (^)(id sender))block{
    [self dl_removeAllBlocksForControlEvents:UIControlEventAllEvents];
    [self dl_setBlockForControlEvents:controlEvents block:block];
}

-(void)dl_removeAllBlocksForControlEvents:(UIControlEvents)controlEvents{
    NSMutableArray *targets = [self _dl_allUIControlBlockTargets];
    NSMutableArray *removes = [NSMutableArray array];
    for (_DLUIControlBlockTarget *target in targets) {
        if (target.events & controlEvents) {
            UIControlEvents newEvent = target.events & (~controlEvents);
            if (newEvent) {
                [self removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                target.events = newEvent;
                [self addTarget:target action:@selector(invoke:) forControlEvents:target.events];
            } else {
                [self removeTarget:target action:@selector(invoke:) forControlEvents:target.events];
                [removes addObject:target];
            }
        }
    }
    [targets removeObjectsInArray:removes];
}

-(NSMutableArray *)_dl_allUIControlBlockTargets{
    NSMutableArray *targets = objc_getAssociatedObject(self, &block_key);
    if (!targets) {
        targets = [NSMutableArray array];
        objc_setAssociatedObject(self, &block_key, targets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return targets;
}

@end
