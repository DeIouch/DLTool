#import "UIControl+Add.h"
#import <objc/runtime.h>
#import "DLToolMacro.h"

static char const tapBlockDic_Key;

NSString* p_dl_event(UIControlEvents controlEvents) {
    NSString *controlEventsString;
#define controlEventsToString(value) case value : controlEventsString = @#value; break;
    switch (controlEvents) {
            controlEventsToString(UIControlEventTouchDownRepeat)
            controlEventsToString(UIControlEventTouchDragInside)
            controlEventsToString(UIControlEventTouchDragOutside)
            controlEventsToString(UIControlEventTouchDragEnter)
            controlEventsToString(UIControlEventTouchDragExit)
            controlEventsToString(UIControlEventTouchUpInside)
            controlEventsToString(UIControlEventTouchUpOutside)
            controlEventsToString(UIControlEventTouchCancel)
            controlEventsToString(UIControlEventValueChanged)
            controlEventsToString(UIControlEventPrimaryActionTriggered)
            controlEventsToString(UIControlEventEditingDidBegin)
            controlEventsToString(UIControlEventEditingChanged)
            controlEventsToString(UIControlEventEditingDidEnd)
            controlEventsToString(UIControlEventEditingDidEndOnExit)
            controlEventsToString(UIControlEventAllTouchEvents)
            controlEventsToString(UIControlEventAllEditingEvents)
            controlEventsToString(UIControlEventApplicationReserved)
            controlEventsToString(UIControlEventSystemReserved)
            controlEventsToString(UIControlEventAllEvents)
        default:
            controlEventsToString(UIControlEventTouchDown)
    }
#undef controlEventsToString
    return controlEventsString;
}

@interface UIControl ()

@property (nonatomic, strong) NSMutableDictionary *tapBlockDic;

@property (nonatomic, readonly) UIViewController *vc;

@end

@implementation UIControl (Add)

-(UIViewController *)vc{
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

-(NSMutableDictionary *)tapBlockDic{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &tapBlockDic_Key);
    if (!dic) {
        dic = [[NSMutableDictionary alloc]init];
        [self setTapBlockDic:dic];
    }
    return dic;
}

-(void)setTapBlockDic:(NSMutableDictionary *)tapBlockDic{
    objc_setAssociatedObject(self, &tapBlockDic_Key, tapBlockDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)addClick:(UIControlEvents)controlEvents block:(void (^)(id vc))action{
    if (!action || !controlEvents) return;
    NSSet *targets = [self allTargets];
    for (id currentTarget in targets) {
        NSArray *actions = [self actionsForTarget:currentTarget forControlEvent:controlEvents];
        for (NSString *currentAction in actions) {
            [self removeTarget:currentTarget action:NSSelectorFromString(currentAction)
                forControlEvents:controlEvents];
        }
    }
    [self.tapBlockDic setObject:action forKey:[p_dl_event(controlEvents) stringByReplacingOccurrencesOfString:@"UIControlEvent" withString:@""]];
    [self addTarget:self action:NSSelectorFromString([p_dl_event(controlEvents) stringByReplacingOccurrencesOfString:@"UIControlEvent" withString:@""]) forControlEvents:controlEvents];
}

-(void)actionRun:(NSString *)runKey{
    void(^action)(id vc) = self.tapBlockDic[runKey];
    if (action) {
        action(self.vc);
    }
}

-(void)TouchDownRepeat{
    [self actionRun:@"TouchDownRepeat"];
}

-(void)TouchDragInside{
    [self actionRun:@"TouchDragInside"];
}

-(void)TouchDragOutside{
    [self actionRun:@"TouchDragOutside"];
}

-(void)TouchDragEnter{
    [self actionRun:@"TouchDragEnter"];
}

-(void)TouchDragExit{
    [self actionRun:@"TouchDragExit"];
}

-(void)TouchUpInside{
    [self actionRun:@"TouchUpInside"];
}

-(void)TouchUpOutside{
    [self actionRun:@"TouchUpOutside"];
}

-(void)TouchCancel{
    [self actionRun:@"TouchCancel"];
}

-(void)ValueChanged{
    [self actionRun:@"ValueChanged"];
}

-(void)PrimaryActionTriggered{
    [self actionRun:@"PrimaryActionTriggered"];
}

-(void)EditingDidBegin{
    [self actionRun:@"EditingDidBegin"];
}

-(void)EditingChanged{
    [self actionRun:@"EditingChanged"];
}

-(void)EditingDidEnd{
    [self actionRun:@"EditingDidEnd"];
}

-(void)EditingDidEndOnExit{
    [self actionRun:@"EditingDidEndOnExit"];
}

-(void)AllTouchEvents{
    [self actionRun:@"AllTouchEvents"];
}

-(void)AllEditingEvents{
    [self actionRun:@"AllEditingEvents"];
}

-(void)ApplicationReserved{
    [self actionRun:@"ApplicationReserved"];
}

-(void)SystemReserved{
    [self actionRun:@"SystemReserved"];
}

-(void)AllEvents{
    [self actionRun:@"AllEvents"];
}

-(void)TouchDown{
    [self actionRun:@"TouchDown"];
}

@end
