//
//  UCloudMediaViewController.h
//  UCloudPlayerDemo
//
//  Created by yisanmao on 15/8/24.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UCloudMediaPlayer.h"

typedef NS_ENUM(NSInteger, WebState)
{
    WebSucess,
    WebFailure,
};

@protocol UCloudMediaPlayback;

/**
 *  播放器界面事件代理
 */
@protocol UCloudPlayerUIDelegate<NSObject>

- (void)onClickMediaControl:(id)sender;
- (void)onClickBack:(UIButton*)sender;
- (void)onClickPlay:(id)sender;
- (void)onClickPause:(id)sender;

- (void)durationSliderTouchBegan:(id)delta;
- (void)durationSliderTouchEnded:(id)delta;
- (void)durationSliderValueChanged:(id)delta;

- (void)clickBright:(id)sender;
- (void)clickVolume:(id)sender;
- (void)clickSnaphot:(id)sender;

- (void)selectedDecodeMode:(UCDMediaDecodeMode)decodeMode;
- (void)selectedDefinition:(Definition)definition;
- (void)selectedScalingMode:(MPMovieScalingMode)scalingMode;

- (void)clickFull;
- (BOOL)screenState;
- (void)clickDanmu:(BOOL)show;

@end

@class UCloudMediaPlayer;

@interface UCloudMediaViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *hudView;
@property (nonatomic, weak) id<UCloudMediaPlayback> delegatePlayer;
@property (nonatomic, weak) id<UCloudPlayerUIDelegate> delegateAction;
@property (strong, nonatomic) NSArray* movieInfos;
@property (assign, nonatomic) UrlType urlType;

@property (assign, nonatomic) NSInteger videoQuality;
@property (assign, nonatomic) NSInteger videoGravity;
@property (assign, nonatomic) NSInteger videoCodec;
@property (strong, nonatomic) NSString* videoTitle;
@property (assign, nonatomic) CGPoint center;

- (void)showNoFade;
- (void)showAndFade;
- (void)hide;
- (void)hideMenu;
- (void)stop;

- (void)refreshMediaControl;
- (void)refreshProgressView;
- (void)refreshCenterState;

- (void)setRightPanelHidden:(BOOL)hidden;
- (void)setFullBtnState:(BOOL)hidden;

@end
