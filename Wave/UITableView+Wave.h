//
//  UITableView+Wave.h
//  TableViewWaveDemo
//
//  Created by jason on 14-4-23.
//  Copyright (c) 2014年 taobao All rights reserved.
//

#import <UIKit/UIKit.h>

#define kBOUNCE_DISTANCE  2

typedef NS_ENUM(NSInteger,WaveAnimation) {
    LeftToRightWaveAnimation = -1,
    RightToLeftWaveAnimation = 1
};


@interface UITableView (Wave)

- (void)reloadDataAnimateWithWave:(WaveAnimation)animation;


@end
