//
//  UCloudMediaViewController.h
//  UCloudPlayerDemo
//
//  Created by yisanmao on 15/8/24.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol UCloudMediaPlayback;

/**
 *  播放器界面事件代理
 */
@protocol UCloudPlayerUIDelegate <NSObject>
- (void)onClickMediaControl:(id)sender;
- (void)onClickBack:(UIButton *)sender;
- (void)onClickPlay:(id)sender;
- (void)onClickPause:(id)sender;
- (void)durationSliderTouchBegan:(id)delta;
- (void)durationSliderTouchEnded:(id)delta;
- (void)durationSliderValueChanged:(id)delta;
- (void)clickBright:(id)sender;
- (void)clickVolume:(id)sender;
- (void)clickShot:(id)sender;
- (void)selectedMenu:(NSInteger)menu choi:(NSInteger)choi;
- (void)clickFull;
@end

@class UCloudMediaPlayer;

@interface UCloudMediaViewController : UIViewController


@property(nonatomic,weak) id<UCloudMediaPlayback> delegatePlayer;
@property(nonatomic, weak) id<UCloudPlayerUIDelegate> delegateAction;
@property(nonatomic) BOOL isPortrait;
@property (strong, nonatomic) NSDictionary *movieInfos;

@property (nonatomic) NSInteger defultQingXiDu;
@property (nonatomic) NSInteger defultHuaFu;
@property (nonatomic) NSInteger defultJieMaQi;
@property (strong, nonatomic) NSString *fileName;
- (void)showNoFade;
- (void)showAndFade;
- (void)hide;
- (void)refreshMediaControl;
- (void)showOrHideMenu;

- (void)stop;
@end
