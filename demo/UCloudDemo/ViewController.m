//
//  ViewController.m
//  UCloudPlayerDemo
//
//  Created by yisanmao on 15/8/19.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface ViewController ()
@property (strong, nonatomic) UIButton *btn;
@property (weak, nonatomic) IBOutlet UIButton    *btnLive;
@property (weak, nonatomic) IBOutlet UIButton    *btnVod;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) BOOL barHidden;
@property (assign, nonatomic) NSInteger liveId;
@property (strong, nonatomic) NSString *liveUrlString;
@property (strong, nonatomic) NSString *vodUrlString;

- (IBAction)switchPlayType:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    srand((unsigned)time(NULL));
    _liveId = rand()%10000;
    //直播播放地址为http://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/%@.flv或者 rtmp://publish3.cdn.ucloud.com.cn/ucloud/%@，其中%@为推流的liveID
    _liveUrlString = [NSString stringWithFormat:
//                      @"rtmp://publish3.cdn.ucloud.com.cn/ucloud/%ld", (long)_liveId //ucloudRTMP流地址，配合推流SDK使用 https://github.com/umdk/UCDLive_iOS
                      @"rtmp://live.hkstv.hk.lxdns.com/live/hks" //香港卫视
//                      @"rtmp://v1.one-tv.com/live/mpegts.stream" //亚太第一卫视
//                      @"http://ivi.bupt.edu.cn/hls/cctv6hd.m3u8" //cctv6高清
                      ];
    
    _vodUrlString =
    //点播测试地址范例，urltype设置为UrlTypeAuto或UrlTypeHttp即可
    @"https://mediademo.ufile.ucloud.com.cn/ucloud_promo_140s.mp4";//https播放
//    @"http://mediademo.ufile.ucloud.com.cn/ucloud_promo_140s.mp4";//http播放
//【推荐使用】测试http-flv直播地址范例，因从url上无法判断是直播还是点播，在创建播放器时需要手动设置url类型，demo中可到PlayerManager.m 设置urltype为UrlTypeLive
//    @"http://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/<#streamId#>.flv";
//测试rtmp直播地址范例，urltype设置为UrlTypeAuto或UrlTypeLive即可
//    @"rtmp://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/<#streamId#>";
//测试hls直播地址范例，urltype设置为UrlTypeAuto或UrlTypeLive即可
//    @"http://vlive3.hls.cdn.ucloud.com.cn/ucloud/<#streamId#>/playlist.m3u8";
    
    self.textField.text = _vodUrlString;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudMoviePlayerClickBack object:nil];
    
    [self switchPlayType:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.playerManager)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        [[self navigationController] setNavigationBarHidden:YES];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return self.barHidden;
}

- (IBAction)play:(id)sender
{
//    隐藏导航栏
    self.barHidden = YES;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    NSString *str = self.textField.text;
    
    if (str.length == 0)
    {
        out:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"注意" message:@"URL不可用" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alert show];
            [self.textField becomeFirstResponder];
            return;
        }
    }
    
    str = [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *theMovieURL =[NSURL URLWithString:str];

    if (theMovieURL == nil)
    {
        goto out;
    }
    
    self.btn = sender;
    self.btn.hidden         = YES;
    self.textField.hidden   = YES;
    self.btnVod.hidden      = YES;
    self.btnLive.hidden     = YES;
    
    if ([theMovieURL isFileURL])
    {
        NSLog(@"is file url");
    }
    
    if ([theMovieURL checkResourceIsReachableAndReturnError:nil])
    {
        NSLog(@"error");
    }
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.vc = self;
    self.playerManager = [[PlayerManager alloc] init];
    self.playerManager.view = self.view;
    self.playerManager.viewContorller = self;
    
    float height = 0.f;
    if (PlayPortrait)
    {
        [self.playerManager setSupportAutomaticRotation:NO];
        [self.playerManager setSupportAngleChange:NO];
        height = self.view.frame.size.height/2.f;
    }
    else
    {
        [self.playerManager setSupportAutomaticRotation:YES];
        [self.playerManager setSupportAngleChange:YES];
        height = self.view.frame.size.height;
    }
    
    [self.playerManager setPortraitViewHeight:height];
    [self.playerManager buildMediaPlayer:self.textField.text urlType:_btnLive.selected==YES?UrlTypeLive:UrlTypeHttp];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self.textField isFirstResponder])
    {
        [self.textField resignFirstResponder];
    }
}

- (void)noti:(NSNotification *)noti
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if ([noti.name isEqualToString:UCloudMoviePlayerClickBack])
    {
        self.btn.hidden         = NO;
        self.textField.hidden   = NO;
        self.btnVod.hidden      = NO;
        self.btnLive.hidden     = NO;
        
        /**
         *  一定要置空
         */
        self.playerManager = nil;
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.vc = nil;
        
        self.barHidden = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/**
 *  以下方法必须实现
 */
-(UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.playerManager)
    {
        return self.playerManager.supportInterOrtation;
    }
    else
    {
        /**
         *  这个在播放之外的程序支持的设备方向
         */
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.playerManager rotateEnd];
    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.playerManager rotateBegin:toInterfaceOrientation];
}

- (IBAction)switchPlayType:(id)sender {
    if(sender != _btnLive) {
        _btnVod.selected = YES;
        _btnLive.selected = NO;
        self.textField.text = _vodUrlString;
    }
    else {
        _btnVod.selected = NO;
        _btnLive.selected = YES;
        self.textField.text = _liveUrlString;
    }
}
@end
