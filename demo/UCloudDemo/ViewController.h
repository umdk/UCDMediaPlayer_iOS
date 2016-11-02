//
//  ViewController.h
//  UCloudPlayerDemo
//
//  Created by yisanmao on 15/8/19.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerManager.h"

#define PlayPortrait  0


@interface ViewController : UIViewController
@property (strong, nonatomic) PlayerManager *playerManager;
@end

