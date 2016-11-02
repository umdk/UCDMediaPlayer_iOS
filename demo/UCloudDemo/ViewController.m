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
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic) BOOL barHidden;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudMoviePlayerClickBack object:nil];
    
    self.textField.text =
    //点播测试地址范例，urltype设置为UrlTypeAuto或UrlTypeHttp即可
    @"http://mediademo.ufile.ucloud.com.cn/ucloud_promo_140s.mp4";//未加密
    //【推荐使用】测试http-flv直播地址范例，因从url上无法判断是直播还是点播，在创建播放器时需要手动设置url类型，demo中可到PlayerManager.m 设置urltype为UrlTypeLive
//    @"http://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/streamId.flv";
    //测试rtmp直播地址范例，urltype设置为UrlTypeAuto或UrlTypeLive即可
//    @"rtmp://vlive3.rtmp.cdn.ucloud.com.cn/ucloud/streamId";
    //测试hls直播地址范例，urltype设置为UrlTypeAuto或UrlTypeLive即可
//    @"http://vlive3.hls.cdn.ucloud.com.cn/ucloud/streamId/playlist.m3u8";
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
    self.btn.hidden = YES;
    self.textField.hidden = YES;
    
    if ([theMovieURL isFileURL])
    {
        NSLog(@"is file url");
    }
    
    if ([theMovieURL checkResourceIsReachableAndReturnError:nil])
    {
        NSLog(@"error");
    }
    
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
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
    [self.playerManager buildMediaPlayer:self.textField.text];
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
        self.btn.hidden = NO;
        self.textField.hidden = NO;
        
        /**
         *  一定要置空
         */
        self.playerManager = nil;
        
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
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
    [self.playerManager rotateBegain:toInterfaceOrientation];
}

/*ios8之后 - (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 被弃用(但是还会调用)，可以使用下面的代理
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    UIInterfaceOrientation or = UIInterfaceOrientationUnknown;
    if (size.width > size.height)
    {
        or = UIInterfaceOrientationLandscapeLeft;
    }
    else
    {
        or = UIInterfaceOrientationPortrait;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UCloudViewControllerWillRotate object:@(or)];
   
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UCloudViewControllerDidRotate object:nil];
    }];
}
*/
@end
