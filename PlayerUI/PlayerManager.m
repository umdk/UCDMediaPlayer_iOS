//
//  PlayerManager.m
//  UCloudMediaRecorderDemo
//
//  Created by yisanmao on 16/1/4.
//  Copyright © 2016年 zmw. All rights reserved.
//

#import "PlayerManager.h"
#import "ViewController.h"
#import "JGProgressHUD.h"
#import "UCloudReachability.h"

#define UISCREEN_WIDTH      MIN([UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height)
#define UISCREEN_HEIGHT     MAX([UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height)

@interface PlayerManager()<UCloudPlayerUIDelegate>

@property (strong, nonatomic) UIImageView* imgView;
@property (strong, nonatomic) NSArray *contrants;
@property (strong, nonatomic) JGProgressHUD *jgHud;
@property (assign, nonatomic) BOOL     bFirstConn;
@property (assign, nonatomic) BOOL     bReconnceting;
@property (nonatomic, assign) NSInteger retryConnectNumber;
@property (assign, nonatomic) UCloudNetworkStatus networkStatus;
@property (nonatomic, strong) UCloudReachability* netReachability;//网络状况监测

@end

@implementation PlayerManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addNotification];
        self.bFirstConn = YES;
        self.retryConnectNumber = 0;
        self.networkStatus = UCloudNotReachable;
        _netReachability = [UCloudReachability reachabilityWithHostName:@"www.apple.com"];
        [_netReachability  startNotifier];
    }
    return self;
}

- (void)buildMediaPlayer:(NSString *)path urlType:(UrlType)urlType
{
    __weak PlayerManager *weakSelf = self;
    //多个实例播放器模式
    //_mediaPlayer = [[UCloudMediaPlayer alloc] init];
    //单例模式
    self.mediaPlayer = [UCloudMediaPlayer ucloudMediaPlayer];
    
    if (urlType == UrlTypeLive) {
        if ([path.pathExtension hasSuffix:@"m3u8"]) {
            //HLS如果对累积延时没要求，建议把setCachedDuration设置为0(即关闭消除累积延时功能)，这样播放过程中卡顿率会更低
            [_mediaPlayer setCachedDuration:0];
            [_mediaPlayer setBufferDuration:5000];
        }
        else {
            [_mediaPlayer setCachedDuration:2000];
            [_mediaPlayer setBufferDuration:2000];
        }
    }
    
    [_mediaPlayer showMediaPlayer:path urltype:urlType frame:CGRectNull view:self.view completion:^(NSInteger defaultNum, NSArray *data) {
        if (weakSelf.mediaPlayer) {
            [weakSelf buildMediaControl:defaultNum data:data];
            [weakSelf configurePlayer];
        }
    }];
}

/**
 设置控制器
 
 @param defaultNum 清晰度或者错误码
 @param data 所有清晰度或空
 */
- (void)buildMediaControl:(NSInteger)defaultNum data:(NSArray *)data
{
    //Add player controller
    UCloudMediaViewController *vc = [[UCloudMediaViewController alloc] initWithNibName:@"UCloudMediaViewController" bundle:nil];
    self.controlVC = vc;
    self.controlVC.delegateAction = self;
    self.controlVC.delegatePlayer = _mediaPlayer.player;
    self.controlVC.center = self.view.center;
    self.controlVC.center = CGPointMake(100, 100);
    
    // get player infos
    self.controlVC.videoQuality = defaultNum;
    if (_mediaPlayer.defaultDecodeMethod == DecodeMethodHard) {
        self.controlVC.videoCodec = 0;
    } else if (_mediaPlayer.defaultDecodeMethod == DecodeMethodSoft) {
        self.controlVC.videoCodec = 1;
    }
    self.controlVC.urlType = _mediaPlayer.urlType;
    
    self.controlVC.videoGravity = 0;
    _mediaPlayer.player.scalingMode = MPMovieScalingModeAspectFit;
    
    self.controlVC.videoTitle = @"Test";
    self.controlVC.movieInfos = data;
    if (_mediaPlayer.urlType != UrlTypeLive) {
        self.controlVC.view.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    }
    
    self.view.backgroundColor = [UIColor blackColor];
    // add mask view 添加logo图
    [self showMaskView];
    [self.view addSubview:self.controlVC.view];
}

- (void)configurePlayer
{
    //点播默认是横屏播放，直播进来默认是竖屏播放
    if (_mediaPlayer.urlType == UrlTypeLive)
    {
        self.isFullscreen = YES;
    }
    [self clickFull];
    
    self.isPortrait = NO;
    
    self.controlVC.view.autoresizingMask = UIViewAutoresizingNone;
    
    
    NSMutableArray *cons = [NSMutableArray array];
    self.equalArray = [NSMutableArray array];
    self.exchangeArray = [NSMutableArray array];
    
    //当返回defaultNum为ErrorNumCgiMovieCannotFound时，并没有创建出videoView
    if (_mediaPlayer.player) {
        [self addConstraintForView:_mediaPlayer.player.view
                            inView:self.view
                        constraint:cons
                             equal:self.equalArray
                          exchange:self.exchangeArray];
    }
    
    if (self.imgView) {
        [self addImgViewConstraints:self.imgView];
    }

    
    self.playerContraints = cons;
    self.vcBottomConstraint = [self addConstraintForView:self.controlVC.view inView:self.view constraint:nil];
    
    if (_mediaPlayer.urlType == UrlTypeLive)
    {
        //生成新的ijksdlView默认旋转角度
        [[NSNotificationCenter defaultCenter] postNotificationName:UCloudPlayerVideoChangeRotationNotification object:@(0)];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"view" object:nil];
}

- (void)reConfigurePlayer:(CGFloat)current
{
    float height = self.playerHeightContraint.constant;
    float centerX = self.playerCenterXContraint.constant;
    [self.view removeConstraints:@[self.playerCenterXContraint, self.playerHeightContraint]];
    
    self.controlVC.delegatePlayer = _mediaPlayer.player;
    
    _mediaPlayer.player.view.frame = self.controlVC.view.bounds;
    [self.view addSubview:_mediaPlayer.player.view];
    
    
    NSMutableArray *cons = [NSMutableArray array];
    self.equalArray = [NSMutableArray array];
    self.exchangeArray = [NSMutableArray array];
    [self addConstraintForView:_mediaPlayer.player.view inView:self.view constraint:cons equal:self.equalArray exchange:self.exchangeArray];
    self.playerHeightContraint.constant = height;
    self.playerCenterXContraint.constant = centerX;
    self.playerContraints = cons;
    
    if (_mediaPlayer.urlType == UrlTypeLive)
    {
        //生成新的ijksdlView默认旋转角度
        [[NSNotificationCenter defaultCenter] postNotificationName:UCloudPlayerVideoChangeRotationNotification object:@(0)];
    }
    
    self.isPrepared = NO;
    
    [self.view bringSubviewToFront:self.controlVC.view];
    [self.controlVC setRightPanelHidden:YES];
}

- (void)addConstraintForView:(UIView *)subView inView:(UIView *)view constraint:(NSMutableArray *)contraints equal:(NSMutableArray *)equalArray exchange:(NSMutableArray *)exchangeArray
{
    //使用Auto Layout约束，禁止将Autoresizing Mask转换为约束
    [subView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // center subView horizontally in view
    NSLayoutConstraint *contraint1 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeCenterX
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeCenterX
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // center subView vertically in view
    NSLayoutConstraint *contraint2 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeCenterY
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeCenterY
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // width subView equal width view
    NSLayoutConstraint *contraint3 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // height subView equal height view
    NSLayoutConstraint *contraint4 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeHeight
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    //width subView equal view height
    NSLayoutConstraint *contraint5 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeHeight
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // height subview equal view width
    NSLayoutConstraint *contraint6 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    NSArray *array = [NSArray arrayWithObjects:contraint1, contraint2, contraint3, contraint4, contraint5, contraint6, nil];
    
    if (contraints)
    {
        [contraints removeAllObjects];
        [contraints addObjectsFromArray:array];
    }
    if (equalArray)
    {
        [equalArray removeAllObjects];
        [equalArray addObjectsFromArray:@[contraint3, contraint4]];
    }
    if (exchangeArray)
    {
        [exchangeArray removeAllObjects];
        [exchangeArray addObjectsFromArray:@[contraint5, contraint6]];
    }
    
    //把约束添加到父视图上
    [view addConstraints:array];
    
    self.contrants = @[ contraint5,contraint6];
    [view removeConstraints:self.contrants];
    
    self.playerCenterXContraint = contraint2;
    self.playerHeightContraint = contraint4;
}

- (NSLayoutConstraint *)addConstraintForView:(UIView *)subView inView:(UIView *)view constraint:(NSMutableArray *)contraints
{
    //使用Auto Layout约束，禁止将Autoresizing Mask转换为约束
    [subView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // align subView and view to top
    NSLayoutConstraint *contraint1 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // align subView and view to left
    NSLayoutConstraint *contraint2 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeLeft
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // align subView and view to bottom
    NSLayoutConstraint *contraint3 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:-0.0];
    //子view的右边缘离父view的右边缘40个像素
    // align subView and view to right
    NSLayoutConstraint *contraint4 = [NSLayoutConstraint constraintWithItem:subView
                                                                  attribute:NSLayoutAttributeRight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1.0
                                                                   constant:-0.0];
    //把约束添加到父视图上
    NSArray *array = [NSArray arrayWithObjects:contraint1, contraint2, contraint3, contraint4, nil];
    
    if (contraints)
    {
        [contraints addObjectsFromArray:array];
    }
    [view addConstraints:array];
    
    return contraint3;
}

- (void)addImgViewConstraints:(UIView *)imgView
{
    //使用Auto Layout约束，禁止将Autoresizing Mask转换为约束
    [imgView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSLayoutConstraint *contraint3 = [NSLayoutConstraint constraintWithItem:imgView
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1.0
                                                                   constant:0.0];
    
    // height subView equal height view
    NSLayoutConstraint *contraint4 = [NSLayoutConstraint constraintWithItem:imgView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.view
                                                                  attribute:NSLayoutAttributeHeight
                                                                 multiplier:1.0
                                                                   constant:0.0];
    [self.view addConstraint:contraint3];
    [self.view addConstraint:contraint4];
}

#pragma mark - 屏幕旋转
- (void)awakeSupportInterOrtation:(UIViewController *)showVC completion:(void(^)(void))block
{
    UIViewController *vc = [[UIViewController alloc] init];
    void(^completion)(void) = ^() {
        [showVC dismissViewControllerAnimated:NO completion:nil];
        
        if (block)
        {
            block();
        }
    };
    
    // This check is needed if you need to support iOS version older than 7.0
    BOOL canUseTransitionCoordinator = [showVC respondsToSelector:@selector(transitionCoordinator)];
    BOOL animated = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0)
    {
        animated = NO;
    }
    else
    {
        animated = YES;
    }
    if (canUseTransitionCoordinator)
    {
        [showVC presentViewController:vc animated:animated completion:nil];
        [showVC.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            completion();
        }];
    }
    else
    {
        [showVC presentViewController:vc animated:NO completion:completion];
    }
}
//屏幕方向改变
-(void)deviceOrientationChanged:(UIInterfaceOrientation)interfaceOrientation
{
    [self.controlVC setRightPanelHidden:YES];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        self.view.transform = CGAffineTransformIdentity;
    }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        {
            [self turnToPortraint:^{
                
            }];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            [self turnToLeft:^{
                
            }];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:
        {
            [self turnToRight:^{
                
            }];
        }
            break;
        default:
            break;
    }
    
    BOOL shouldChangeFrame = NO;
    if ((UIInterfaceOrientationIsLandscape(interfaceOrientation) && UIInterfaceOrientationIsPortrait(self.currentOrientation)) || (UIInterfaceOrientationIsPortrait(interfaceOrientation) && UIInterfaceOrientationIsLandscape(self.currentOrientation)))
    {
        shouldChangeFrame = YES;
    }
    
    //调整缓冲提示的位置
    if (shouldChangeFrame)
    {
//        [self.controlVC.view.window changeFrame:interfaceOrientation];
    }
    
    if (_jgHud) {
        CGRect bounds = _jgHud.targetView.bounds;
        _jgHud.targetView.bounds = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetHeight(bounds), CGRectGetWidth(bounds));
    }
    
    if (_imgView) {
        _imgView.frame = _mediaPlayer.player.view.frame;
    }

    
    //重绘画面
    [_mediaPlayer refreshView];
}

- (void)rotateBegin:(UIInterfaceOrientation)noti
{
    [self deviceOrientationChanged:noti];
}

- (void)rotateEnd
{
    //重绘画面
    [_mediaPlayer refreshView];
    [self.controlVC setRightPanelHidden:NO];
    
    [self.controlVC refreshProgressView];
}

-(void)turnToPortraint:(void(^)(void))block
{
    _playerHeightContraint.constant = -[self getContraintConstant];
    _playerCenterXContraint.constant = -[self getContraintConstant]/2.f;
    
    
    _vcBottomConstraint.constant = -[self getContraintConstant];
    _danmuBottomContraint.constant = -[self getContraintConstant];
    [_mediaPlayer refreshView];
    self.isFullscreen = NO;
    
    [self.controlVC hideMenu];
    if (block)
    {
        block();
    }
}

-(void)turnToLeft:(void(^)(void))block
{
    self.playerCenterXContraint.constant = 0.0;
    self.playerHeightContraint.constant = 0.0;
    
    
    self.vcBottomConstraint.constant = -0.0;
    self.danmuBottomContraint.constant = -0.0;
    [_mediaPlayer refreshView];
    self.isFullscreen = YES;
    if (block)
    {
        block();
    }
}

-(void)turnToRight:(void(^)(void))block
{
    self.playerCenterXContraint.constant = 0.0;
    self.playerHeightContraint.constant = 0.0;
    
    self.vcBottomConstraint.constant = -0.0;
    self.danmuBottomContraint.constant = -0.0;
    [_mediaPlayer refreshView];
    self.isFullscreen = YES;
    if (block)
    {
        block();
    }
}

-(float)getContraintConstant
{
    float delta = UISCREEN_HEIGHT - self.portraitViewHeight;
    
    if (delta < 0)
    {
        delta = 0;
    }
    else if (delta >= UISCREEN_HEIGHT)
    {
        delta = UISCREEN_HEIGHT - UISCREEN_WIDTH;
    }
    return delta;
}

-(UIInterfaceOrientationMask)supportInterOrtation
{
    if (self.supportAutomaticRotation)
    {
        return _supportInterOrtation;
    }
    else
    {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)setSupportAutomaticRotation:(BOOL)supportAutomaticRotation
{
    _supportAutomaticRotation = supportAutomaticRotation;
    if (_supportAutomaticRotation)
    {
        [self.controlVC setFullBtnState:NO];
    }
    else
    {
        [self.controlVC setFullBtnState:YES];
    }
}

#pragma mark - save pic
- (void)saveImageToPhotos:(UIImage*)savedImage
{
    UIImageWriteToSavedPhotosAlbum(savedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}
- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"保存图片结果提示"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
}
static bool showing = NO;
#pragma mark - loading view
- (void)showLoadingView
{
    if (!showing)
    {
        showing = YES;
        
        _jgHud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        _jgHud.textLabel.text = @"加载中";
        [_jgHud showInView:self.controlVC.hudView];
    }
}

- (void)hideLoadingView
{
    showing = NO;
    [_jgHud dismissAnimated:YES];
}

#pragma mark - notification
- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:UCloudReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerFirstVideoFrameRenderedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudMoviePlayerSeekCompleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerPlaybackDidFinishNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerBufferingUpdateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateEnd) name:UCloudViewControllerDidRotate object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateBegin:) name:UCloudViewControllerWillRotate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerVideoChangeRotationNotification object:nil];
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlaybackIsPreparedToPlayDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerFirstVideoFrameRenderedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudMoviePlayerSeekCompleted object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerPlaybackDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerBufferingUpdateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudViewControllerDidRotate object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudViewControllerWillRotate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerVideoChangeRotationNotification object:nil];
}

- (void)dealloc
{
    [self removeNotification];
}

- (void)noti:(NSNotification *)noti
{
//    NSLog(@"%@", noti.name);
    if ([noti.name isEqualToString:UCloudPlaybackIsPreparedToPlayDidChangeNotification])
    {
        [self.controlVC refreshMediaControl];
        self.retryConnectNumber = 0;
        if (self.current != 0)
        {
            [_mediaPlayer.player setCurrentPlaybackTime:self.current];
            self.current = 0;
        }
    }
    else if([noti.name isEqualToString:UCloudPlayerFirstVideoFrameRenderedNotification])
    {
        if (self.imgView && self.imgView.superview) {
            [self.imgView removeFromSuperview];
        }
    
    }
    else if ([noti.name isEqualToString:UCloudPlayerLoadStateDidChangeNotification])
    {
        if ([_mediaPlayer.player loadState] == MPMovieLoadStateStalled)
        {
            //网速不好，开始缓冲
            [self showLoadingView];
        }
        else if ([_mediaPlayer.player loadState] == (MPMovieLoadStatePlayable|MPMovieLoadStatePlaythroughOK))
        {
            //缓冲完毕
            [self hideLoadingView];
        }
    }
    else if ([noti.name isEqualToString:UCloudMoviePlayerSeekCompleted])
    {
        
    }
    else if ([noti.name isEqualToString:UCloudPlayerPlaybackStateDidChangeNotification])
    {
        NSLog(@"backState:%ld", (long)[_mediaPlayer.player playbackState]);
        if (!self.isPrepared)
        {
            self.isPrepared = YES;
            [_mediaPlayer.player play];
            
            if (![_mediaPlayer.player isPlaying])
            {
                [self.controlVC refreshCenterState];
            }
        }
    }
    else if ([noti.name isEqualToString:UCloudPlayerPlaybackDidFinishNotification])
    {
        MPMovieFinishReason reson = [[noti.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
        SubErrorCode subErrorCode = 0;
        id erroVaule =  [noti.userInfo objectForKey:@"error"];
        if (erroVaule &&([erroVaule isKindOfClass:[NSString class]]|| [erroVaule isKindOfClass:[NSNumber class]])) {
           subErrorCode =  [erroVaule integerValue];
        } 
       
        if (reson == MPMovieFinishReasonPlaybackEnded)
        {
            [self.controlVC stop];
        }
        else if (reson == MPMovieFinishReasonPlaybackError)
        {
            self.current = _mediaPlayer.player.currentPlaybackTime;
            NSLog(@"player manager finish reason playback error! subErrorCode:%ld",(long)subErrorCode);
            JGProgressHUD *erroHud = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            erroHud.textLabel.text = @"加载中";
            [erroHud showInView:self.view];
            [erroHud dismissAfterDelay:2.0f animated:YES];
            if (self.retryConnectNumber++ < _mediaPlayer.maxReconCount) {
                [self playerReconnect];
                return;
            }
            
            UIAlertView* retryAlert = [[UIAlertView alloc] initWithTitle:@"重连失败" message:@"" delegate:self cancelButtonTitle:@"知道了"   otherButtonTitles: nil, nil];
            retryAlert.message = @"视频播放错误";
            [retryAlert show];
            
        }
        
        self.view.backgroundColor = [UIColor whiteColor];
    }
    else if ([noti.name isEqualToString:UCloudPlayerVideoChangeRotationNotification]&& self.supportAngleChange)
    {
        if (!_mediaPlayer.player.view) {
            return;
        }

        NSInteger rotation = [noti.object integerValue];
        _mediaPlayer.player.view.transform = CGAffineTransformIdentity;
        float height = self.playerHeightContraint.constant;
        
        switch (rotation)
        {
            case 0:
            {
                [self.view removeConstraints:self.exchangeArray];
                [self.view addConstraints:self.equalArray];
                
                self.playerHeightContraint.constant=_portraitViewHeight;
                _mediaPlayer.player.view.transform = CGAffineTransformIdentity;
                self.imgView.transform = CGAffineTransformIdentity;
            }
                break;
            case 90:
            {
                [self.view removeConstraints:self.equalArray];
                [self.view addConstraints:self.exchangeArray];
                
                self.playerHeightContraint = [self.exchangeArray lastObject];
                _mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
                self.imgView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            }
                break;
            case 180:
            {
                [self.view removeConstraints:self.exchangeArray];
                [self.view addConstraints:self.equalArray];
                
                self.playerHeightContraint = [self.equalArray firstObject];
                _mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-M_PI);
                self.imgView.transform = CGAffineTransformMakeRotation(-M_PI);
            }
                break;
            case 270:
            {
                [self.view removeConstraints:self.equalArray];
                [self.view addConstraints:self.exchangeArray];
                
                self.playerHeightContraint = [self.exchangeArray lastObject];
                _mediaPlayer.player.view.transform = CGAffineTransformMakeRotation(-(M_PI+M_PI_2));
                self.imgView.transform = CGAffineTransformMakeRotation(-(M_PI+M_PI_2));
            }
                break;
            default:
                break;
        }
        self.playerHeightContraint.constant = height;
        [_mediaPlayer.player.view updateConstraintsIfNeeded];
    }
}


#pragma mark-networkStateChange
- (void)networkStateChange
{
    UCloudNetworkStatus status = [_netReachability currentReachabilityStatus];
   
    if( status == UCloudNotReachable ||
        status == self.networkStatus ){
        self.networkStatus = status;
        return;
    }
    self.networkStatus = status;
    if (_mediaPlayer.bReconEnable &&
        !self.bFirstConn)
    {
        /*正在播的过程中网络切换，APP第一启动时获得网络状态变化，不进入重连逻辑*/
        [self playerReconnect];
    }
    self.bFirstConn = NO;
    
}

#pragma mark-reconnect
- (void) playerReconnect
{
    
    if (_bReconnceting) {
        return;
    }

//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UCloudPlayerPlaybackDidFinishNotification object:nil];
    _bReconnceting = YES;
    [self selectedDecodeMethod:_mediaPlayer.defaultDecodeMethod];
//    [[NSNotificationobsCenter defaultCenter] addObserver:self selector:@selector(noti:) name:UCloudPlayerPlaybackDidFinishNotification object:nil];
}

#pragma mark - mediaControl delegate
- (void)onClickMediaControl:(id)sender
{
    
}

- (void)onClickBack:(UIButton *)sender
{
    
    self.bFirstConn = YES;
    [_mediaPlayer.player.view removeFromSuperview];
    [self.controlVC.view removeFromSuperview];
    [self.imgView removeFromSuperview];
    [_mediaPlayer.player shutdown];

    _mediaPlayer.player = nil;
    _mediaPlayer = nil;
    self.imgView = nil;
    
    {
        self.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        [self awakeSupportInterOrtation:self.viewContorller completion:^{
            self.supportInterOrtation = UIInterfaceOrientationMaskAllButUpsideDown;
            [self.view setBackgroundColor:[UIColor whiteColor]];
        }];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UCloudMoviePlayerClickBack object:self];
}

- (void)onClickPlay:(id)sender
{
    [_mediaPlayer.player play];
}

- (void)onClickPause:(id)sender
{
    [_mediaPlayer.player pause];
}

- (void)durationSliderTouchBegan:(id)delta
{
    //        [self.player pause];
}

- (void)durationSliderTouchEnded:(id)delta
{
    CGFloat del = _mediaPlayer.player.duration * [delta floatValue];
    del = _mediaPlayer.player.currentPlaybackTime + del;
    [_mediaPlayer.player setCurrentPlaybackTime:floor(del)];
    [_mediaPlayer.player prepareToPlay];
}

- (void)durationSliderValueChanged:(id)delta
{
    
}

- (void)clickBright:(id)sender
{
    
}

- (void)clickVolume:(id)sender
{
    
}

- (void)clickSnaphot:(id)sender
{
    self.current = [_mediaPlayer.player currentPlaybackTime];
    UIImage *image = [_mediaPlayer.player thumbnailImageAtCurrentTime];
    [self saveImageToPhotos:image];
}

// 获取视频最后一帧画面
- (void)showLastVideoFrame
{
    if (self.imgView && self.imgView.superview) {
        [self.imgView removeFromSuperview];
    }
    
    self.imgView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.imgView.image =  [_mediaPlayer.player thumbnailImageAtCurrentTime];
    
    if (self.imgView) {
        
        [UIView animateWithDuration:0.3 animations:^{
            
            [self.view addSubview:self.imgView];;
        }];
        
    }

}

- (void)showMaskView
{
    self.imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo-6"]];
    self.imgView.frame = self.view.frame;
    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imgView];
}

- (void)selectedDecodeMethod:(DecodeMethod)decodeMethod
{
   
    if (_mediaPlayer.urlType != UrlTypeLive) {
        [self showLastVideoFrame];
        self.current = [_mediaPlayer.player currentPlaybackTime];
    }
    
    [_mediaPlayer selectDecodeMethod:decodeMethod];
    [self reConfigurePlayer:0];
}

- (void)selectedDefinition:(Definition)definition
{
    [self showLastVideoFrame];
    self.current = [_mediaPlayer.player currentPlaybackTime];
    [_mediaPlayer selectDefinition:definition];
    [self reConfigurePlayer:0];
    [_mediaPlayer.player setCurrentPlaybackTime:self.current];
}

- (void)selectedScalingMode:(MPMovieScalingMode)scalingMode
{
    _mediaPlayer.player.scalingMode = scalingMode;
    [self reConfigurePlayer:0];
}

- (void)clickFull
{
    [_mediaPlayer.player pause];
    
    if(!self.isFullscreen)
    {
        UIDeviceOrientation deviceOr = [UIDevice currentDevice].orientation;
        if (deviceOr == UIInterfaceOrientationLandscapeRight)
        {
            self.supportInterOrtation = UIInterfaceOrientationMaskLandscapeRight;
            [self awakeSupportInterOrtation:self.viewContorller completion:^() {
                
                [self turnToRight:^{
                    self.supportInterOrtation = UIInterfaceOrientationMaskAllButUpsideDown;
                    [_mediaPlayer.player play];
                    self.currentOrientation = UIInterfaceOrientationLandscapeRight;
                    //重绘画面
                    [_mediaPlayer refreshView];
                }];
            }];
        }
        else
        {
            self.supportInterOrtation = UIInterfaceOrientationMaskLandscapeLeft;
            [self awakeSupportInterOrtation:self.viewContorller completion:^() {
                [self turnToLeft:^{
                    self.supportInterOrtation = UIInterfaceOrientationMaskAllButUpsideDown;
                    [_mediaPlayer.player play];
                    self.currentOrientation = UIInterfaceOrientationLandscapeLeft;
                    //重绘画面
                    [_mediaPlayer refreshView];
                }];
            }];
        }
    }
    else
    {
        self.supportInterOrtation = UIInterfaceOrientationMaskPortrait;
        [self awakeSupportInterOrtation:self.viewContorller completion:^() {
            [self turnToPortraint:^{
                self.supportInterOrtation = UIInterfaceOrientationMaskAllButUpsideDown;
                [_mediaPlayer.player play];
                
                //重绘画面
                [_mediaPlayer refreshView];
            }];
            
        }];
    }
}

- (void)clickDanmu:(BOOL)show
{
    
}

- (void)selectedMenu:(NSInteger)menu choi:(NSInteger)choi
{
//    NSLog(@"menu:%ld__choi:%ld", (long)menu, (long)choi);
}

- (BOOL)screenState
{
    return self.isFullscreen;
}


@end
