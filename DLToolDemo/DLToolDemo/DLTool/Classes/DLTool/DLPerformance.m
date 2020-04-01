//
//  DLPerformance.m
//  DLToolDemo
//
//  Created by tanqiu on 2020/3/20.
//  Copyright © 2020 戴青. All rights reserved.
//

#import "DLPerformance.h"
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <QuartzCore/QuartzCore.h>

@interface DLMarginLabel : UILabel

@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end

@implementation DLMarginLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsMake(0.0f, 5.0f, 0.0f, 5.0f);
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width += self.edgeInsets.left + self.edgeInsets.right;
    size.height += self.edgeInsets.top + self.edgeInsets.bottom;
    return size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    sizeThatFits.width += self.edgeInsets.left + self.edgeInsets.right;
    sizeThatFits.height += self.edgeInsets.top + self.edgeInsets.bottom;
    return sizeThatFits;
}

@end

@interface DLWindows : UIView

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, strong) DLMarginLabel *monitoringTextLabel;

@property (nonatomic) int screenUpdatesCount;

@property (nonatomic) CFTimeInterval screenUpdatesBeginTime;

@property (nonatomic) CFTimeInterval averageScreenUpdatesTime;

@end

@implementation DLWindows

-(instancetype)init{
    if ([super init]) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        self.monitoringTextLabel = [[DLMarginLabel alloc] init];
        [self.monitoringTextLabel setTextAlignment:NSTextAlignmentCenter];
        [self.monitoringTextLabel setNumberOfLines:2];
        [self.monitoringTextLabel setBackgroundColor:[UIColor blackColor]];
        [self.monitoringTextLabel setTextColor:[UIColor whiteColor]];
        [self.monitoringTextLabel setClipsToBounds:YES];
        [self.monitoringTextLabel setFont:[UIFont systemFontOfSize:8.0f]];
        [self.monitoringTextLabel.layer setBorderWidth:1.0f];
        [self.monitoringTextLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
        [self.monitoringTextLabel.layer setCornerRadius:5.0f];
        [self addSubview:self.monitoringTextLabel];
        self.frame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 20.0f);
        UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
         window.windowLevel = UIWindowLevelStatusBar + 1;
        [window addSubview:self];
    }
    return self;
}

//获取当前任务所占用内存
-(double)usedMemory{
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte / 1024.0 / 1024.0;
}

- (void)displayLinkAction:(CADisplayLink *)displayLink {
    if (self.screenUpdatesBeginTime == 0.0f) {
        self.screenUpdatesBeginTime = displayLink.timestamp;
    } else {
        self.screenUpdatesCount += 1;
        CFTimeInterval screenUpdatesTime = displayLink.timestamp - self.screenUpdatesBeginTime;
        if (screenUpdatesTime >= 1.0) {
            self.screenUpdatesBeginTime = displayLink.timestamp;
            [self takeReadings:self.screenUpdatesCount / screenUpdatesTime];
        }
    }
}

- (void)takeReadings:(int)fps {
    self.screenUpdatesCount = 0;
    float cpu = [self cpuUsage];
    self.screenUpdatesCount = 0;
    self.screenUpdatesBeginTime = 0.0f;
    [self updateMonitoringLabelWithFPS:fps CPU:cpu];
}

- (void)updateMonitoringLabelWithFPS:(int)fpsValue CPU:(float)cpuValue {
    NSString *monitoringString = [NSString stringWithFormat:@"FPS : %d CPU : %.1f%% \n内存 : %0.1lfM", fpsValue, cpuValue, [self usedMemory]];
    [self.monitoringTextLabel setText:monitoringString];
    [self layoutTextLabel];
}

- (void)layoutTextLabel {
    CGFloat windowWidth = CGRectGetWidth(self.bounds);
    CGFloat windowHeight = CGRectGetHeight(self.bounds);
    CGSize labelSize = [self.monitoringTextLabel sizeThatFits:CGSizeMake(windowWidth, windowHeight)];
    [self.monitoringTextLabel setFrame:CGRectMake((windowWidth - labelSize.width) / 2.0f, (windowHeight - labelSize.height) / 2.0f, labelSize.width, labelSize.height)];
}

- (float)cpuUsage {
    kern_return_t kern;
    thread_array_t threadList;
    mach_msg_type_number_t threadCount;
    thread_info_data_t threadInfo;
    mach_msg_type_number_t threadInfoCount;
    thread_basic_info_t threadBasicInfo;
    uint32_t threadStatistic = 0;
    kern = task_threads(mach_task_self(), &threadList, &threadCount);
    if (kern != KERN_SUCCESS) {
        return -1;
    }
    if (threadCount > 0) {
        threadStatistic += threadCount;
    }
    float totalUsageOfCPU = 0;
    for (int i = 0; i < threadCount; i++) {
        threadInfoCount = THREAD_INFO_MAX;
        kern = thread_info(threadList[i], THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount);
        if (kern != KERN_SUCCESS) {
            return -1;
        }
        threadBasicInfo = (thread_basic_info_t)threadInfo;
        if (!(threadBasicInfo -> flags & TH_FLAGS_IDLE)) {
            totalUsageOfCPU = totalUsageOfCPU + threadBasicInfo -> cpu_usage / (float)TH_USAGE_SCALE * 100.0f;
        }
    }
    kern = vm_deallocate(mach_task_self(), (vm_offset_t)threadList, threadCount * sizeof(thread_t));
    return totalUsageOfCPU;
}


@end

@interface DLPerformance()

@property (nonatomic, strong) DLWindows *window;

@end

@implementation DLPerformance

static DLPerformance *performance= nil;

+(instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        performance = [[DLPerformance alloc]init];
        performance.window = [[DLWindows alloc]init];
    });
    return performance;
}

+(void)openMonitoring{
    [DLPerformance shareInstance];
}

@end
