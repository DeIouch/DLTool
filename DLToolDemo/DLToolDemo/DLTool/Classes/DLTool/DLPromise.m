#import "DLPromise.h"

typedef id (^Do) (void);

typedef id (^Then) (id obj);

typedef void (^Fail) (id obj);

@interface DLPromise()

@property (readonly) DLPromise *(^then) (Then thenBlock);

@property (readonly) DLPromise *(^fail) (Fail failBlock);

- (void)resolve:(id)value;

- (void)reject:(id)error;

-(id)value;

-(id)error;

-(BOOL)isResolved;

-(BOOL)isRejected;

-(BOOL)isPending;

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation DLPromise{
    id _value;                                      //  回传的值
    id _error;                                      //  错误信息
    BOOL _resolved;                           //  是否已完成
    BOOL _rejected;                           //  是否被拒绝执行
    Do _doBlock;                                //  要执行的block
    Then _thenBlock;                          //  下一步要执行的block
    Fail _failBlock;                              //  错误回调block
    DLPromise *_nextPromise;             //  下一步要执行的操作
    DLPromise *_deferredValue;           //  已经执行的操作
}

-(instancetype)_init{
    self = [super init];
    _value = nil;
    _error = nil;
    _resolved = NO;
    _rejected = NO;
    _nextPromise = nil;
    _deferredValue = nil;
    return self;
}

-(instancetype)_initWithValue:(id)obj{
    self = [super init];
    if ([super init]) {
        _value = nil;
        _error = nil;
        _resolved = NO;
        _rejected = NO;
        _nextPromise = nil;
        _deferredValue = nil;
        [self resolve:obj];
    }
    return self;
}

-(void)resolve:(id)value{
    if ([self isPending]) {
        @try {
            if ([value isKindOfClass:[DLPromise class]]) {
                _deferredValue = (DLPromise *)value;
                _deferredValue.then(^id(id __value){
                    [self resolve:__value];
                    return nil;
                })
                .fail( ^(id __error) {
                    [self reject:__error];
                });
            }else{
                _resolved = YES;
                _value = value;
                if (_nextPromise) {
                    @try {
                        id __value = _thenBlock(value);
                        [_nextPromise resolve:__value];
                    } @catch (NSException *exception) {
                        [_nextPromise reject:exception];
                    }
                }
            }
        } @catch (NSException *exception) {
            [_nextPromise reject:exception];
        }
    }
}

- (void)reject:(id)error{
    if ([self isPending]) {
        _rejected = YES;
        _error = error;
        if (_failBlock) {
            _failBlock(error);
        }else if (_nextPromise) {
            [_nextPromise reject:error];
        }
    }
}

-(DLPromise *(^)(Then))then{
    return ^DLPromise *(Then block){
        [self then:block];
        return self;
    };
}

-(DLPromise *)then:(Then)thenBlock{
    _nextPromise = [[DLPromise alloc]_init];
    if ([self isResolved]) {
        @try {
            [_nextPromise resolve:thenBlock(_value)];
        } @catch (NSException *exception) {
            [_nextPromise reject:exception];
        }
    }else if ([self isRejected]) {
        [_nextPromise reject:_error];
    }else{
        _thenBlock = [thenBlock copy];
    }
    return _nextPromise;
}

-(DLPromise *(^)(Fail))fail{
    return ^DLPromise *(Fail block) {
        [self fail:block];
        return self;
    };
}

-(DLPromise *)fail:(Fail)failBlock{
    if ([self isRejected]) {
        dispatch_async(self.queue, ^{
            failBlock(self->_error);
        });
    }else if ([self isPending]) {
        _failBlock = [failBlock copy];
    }
    return self;
}

+(DLPromise *)sync:(Do)doBlock{
    DLPromise *promise = [[DLPromise alloc]_init];
    promise.queue = dispatch_get_main_queue();
    dispatch_async(promise.queue, ^{
        [promise resolve:doBlock()];
    });
    return promise;
}

+(DLPromise *)async:(id(^)(void))doBlock{
    DLPromise *promise = [[DLPromise alloc]_init];
    promise.queue = dispatch_get_global_queue(0, 0);
    dispatch_async(promise.queue, ^{
        id obj = doBlock();
        [promise resolve:obj];
    });
    return promise;
}

- (id)value {
    return _value;
}

- (id)error {
    return _error;
}

- (BOOL)isResolved {
    return _resolved;
}

- (BOOL)isRejected {
    return _rejected;
}

- (BOOL)isPending {
    return !(_resolved || _rejected);
}

@end
