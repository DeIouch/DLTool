//
//  TestView.h
//  DLToolDemo
//
//  Created by tanqiu on 2020/4/13.
//  Copyright © 2020 戴青. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestView : UIView

@property (nonatomic, copy) void (^actionBlock)(void);
@end
