//
//  UCloudMediaViewController.m
//  UCloudPlayerDemo
//
//  Created by yisanmao on 15/8/24.
//  Copyright (c) 2015年 yisanmao. All rights reserved.
//

#import "UCloudMediaViewController.h"
#import "UCloudMediaPlayback.h"
#import "UCloudProgressView.h"
#import "UCloudBrightnessView.h"

typedef NS_ENUM(NSInteger, GesDirection)
{
    Dir_H,
    Dir_V_L,
    Dir_V_R,
};


#define UISCREEN_WIDTH      MIN(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)
#define UISCREEN_HEIGHT     MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)

@interface UCloudMediaViewController ()<UITableViewDataSource, UITableViewDelegate>


@property(nonatomic,strong) IBOutlet UIView *overlayPanel;
@property(nonatomic,strong) IBOutlet UIView *topPanel;
@property(nonatomic,strong) IBOutlet UIView *bottomPanel;
@property (weak, nonatomic) IBOutlet UIView *rightPanel;

@property(nonatomic,strong) IBOutlet UIButton *playButton;
@property(nonatomic,strong) IBOutlet UIButton *pauseButton;

@property(nonatomic,strong) IBOutlet UILabel *currentTimeLabel;
@property(nonatomic,strong) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;

@property (weak, nonatomic) IBOutlet UIButton *centerPlanBtn;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UITableView *resultTabelView;
@property (weak, nonatomic) IBOutlet UITableView *choiceTabelView;
@property (weak, nonatomic) IBOutlet UCloudProgressView *progressPanel;

@property (strong, nonatomic) NSDictionary *choices;
@property (strong, nonatomic) NSArray *choi;
@property (nonatomic) GesDirection direc;
@property (nonatomic) CGFloat voiceNormal;
@property (nonatomic) CGFloat progressViewNormal;
@property (nonatomic) CGFloat brightNomal;
@property (strong, nonatomic)UCloudBrightnessView *brightnessView;
@property (nonatomic,strong) UCloudProgressView *progressView;

@property (nonatomic) NSInteger selectedChoices;
@property (strong, nonatomic) NSMutableDictionary *selectedResults;
@property (strong, nonatomic) UILabel *waterMarkLabel;
@end

@implementation UCloudMediaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self refreshMediaControl];
    [self buildData];
    [self buildGes];
    [self buildUI];
    self.isPortrait = NO;
    self.choiceTabelView.dataSource = self;
    self.choiceTabelView.delegate = self;
    self.choiceTabelView.tableFooterView = [[UIView alloc] init];
    
    self.resultTabelView.dataSource = self;
    self.resultTabelView.delegate = self;
    self.resultTabelView.tableFooterView = [[UIView alloc] init];
    
    //暂时不加水印
//    [self waterMark];
}

- (void)buildData
{
    NSArray *infos = [self.movieInfos objectForKey:@"multi_rate_info"];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:infos.count];
    for (NSDictionary *dic in infos)
    {
        NSString *type = [dic objectForKey:@"type"];
        NSString *key = nil;
        if ([type isEqualToString:@"fhd"])
        {
            key = @"蓝光";
        }
        else if ([type isEqualToString:@"shd"])
        {
            key = @"超清";
        }
        else if ([type isEqualToString:@"hd"])
        {
            key = @"高清";
        }
        else if ([type isEqualToString:@"sd"])
        {
            key = @"标清";
        }
        [arr addObject:key];
    }
    
    self.choi = @[@"清晰度", @"画幅", @"解码器"];
    self.choices = @{@"清晰度":arr, @"画幅":@[@"自动",@"原始",@"全屏"], @"解码器":@[@"硬解",@"软解"]};
    self.selectedResults = [NSMutableDictionary dictionaryWithDictionary:@{@"0":@(self.defultQingXiDu), @"1":@(self.defultHuaFu), @"2":@(self.defultJieMaQi)}];
}

- (void)buildGes
{
    UIPanGestureRecognizer *ges = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self.view addGestureRecognizer:ges];
}

- (void)pan:(UIPanGestureRecognizer *)ges
{
    CGFloat delta = 0.f;
    if (ges.state == UIGestureRecognizerStateBegan)
    {
        self.progressViewNormal = self.progressView.progress;
        self.voiceNormal = [MPMusicPlayerController systemMusicPlayer].volume;
        self.brightNomal = [UIScreen mainScreen].brightness;
        
        if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(durationSliderTouchBegan:)])
        {
            [self.delegateAction durationSliderTouchBegan:nil];
        }
        
        CGPoint point = [ges translationInView:self.view];
        if (fabs(point.x) < fabs(point.y))
        {
            point = [ges locationInView:self.view];
            //竖直   音量或者亮度
            if (point.x < self.view.frame.size.width/2.0)
            {
                //左侧
                self.direc = Dir_V_L;
            }
            else
            {
                //右侧
                self.direc = Dir_V_R;
                if (!self.brightnessView)
                {
                    self.brightnessView = [[UCloudBrightnessView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
                    self.brightnessView.center = self.view.center;
                    [self.view addSubview:self.brightnessView];
                    [self.brightnessView setProgress:[UIScreen mainScreen].brightness*10];
                }
                self.brightnessView.alpha = 1.0f;
            }
        }
        else
        {
            //水平   进度
            self.direc = Dir_H;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
        }
    }
    else if (ges.state == UIGestureRecognizerStateChanged)
    {
        CGPoint p = [ges translationInView:self.view];
        if (self.direc == Dir_H)
        {
            delta = p.x/self.view.frame.size.width*2;
        }
        else
        {
            delta = -p.y/self.view.frame.size.height*2;
        }
        
        switch (self.direc)
        {
            case Dir_H:
            {
                if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(durationSliderValueChanged:)])
                {
                    [self.delegateAction durationSliderValueChanged:@(delta)];
                }
                CGFloat value = self.progressViewNormal + delta;
                if (value >= 0 && value <= 1)
                {
                    self.progressView.progress = value;
                }
                
            }break;
            case Dir_V_R:
            {
                [self.brightnessView setProgress:(self.brightNomal + delta)*10];
                
                [UIScreen mainScreen].brightness = self.brightNomal + delta;
            }break;
            case Dir_V_L:
            {
                [MPMusicPlayerController systemMusicPlayer].volume = self.voiceNormal + delta;
            }break;
            default:
                break;
        }
    }
    else if (ges.state == UIGestureRecognizerStateCancelled || ges.state == UIGestureRecognizerStateEnded || ges.state == UIGestureRecognizerStateFailed)
    {
        [UIView animateWithDuration:0.5f animations:^{
            self.brightnessView.alpha = 0.f;
        }];
        [self.delegatePlayer play];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
        if (!self.overlayPanel.hidden)
        {
            [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
        }
        
        if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(durationSliderTouchEnded:)])
        {
            [self.delegateAction durationSliderTouchEnded:@(self.progressView.progress - self.progressViewNormal)];
        }
    }
}

#pragma mark - table
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count;
    if (tableView == self.choiceTabelView)
    {
        count = self.choi.count;
    }
    else
    {
        NSString *key = [self.choi objectAtIndex:self.selectedChoices];
        count = [[self.choices objectForKey:key] count];
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.choiceTabelView)
    {
        static NSString *cellId1 = @"Cell1";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId1];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId1];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = [self.choi objectAtIndex:indexPath.row];
        
        if (self.selectedChoices == indexPath.row)
        {
            cell.textLabel.textColor = [UIColor colorWithRed:64.f/255.f green:116.f/255.f blue:225.f/255.f alpha:1.f];
        }
        else
        {
            cell.textLabel.textColor = [UIColor whiteColor];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
    else
    {
        static NSString *cellId1 = @"Cell2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId1];
        if (!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId1];
        }
        
        NSString *key = [self.choi objectAtIndex:self.selectedChoices];
        NSArray *data = [self.choices objectForKey:key];
        cell.textLabel.text = [data objectAtIndex:indexPath.row];
        
        if ([self tableviewSelectedRow:tableView].row == indexPath.row)
        {
            cell.textLabel.textColor = [UIColor colorWithRed:64.f/255.f green:116.f/255.f blue:225.f/255.f alpha:1.f];
        }
        else
        {
            cell.textLabel.textColor = [UIColor whiteColor];
        }
        
        cell.backgroundColor = [UIColor clearColor];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.choiceTabelView)
    {
        self.resultLabel.text = [self.choi objectAtIndex:indexPath.row];
        [self.resultTabelView reloadData];
    }
}

- (NSIndexPath *)tableviewSelectedRow:(UITableView *)tableView
{
    if (tableView == self.choiceTabelView)
    {
        return [NSIndexPath indexPathForRow:self.selectedChoices inSection:0];
    }
    else
    {
        NSInteger sele = [[self.selectedResults objectForKey:[NSString stringWithFormat:@"%@", @(self.selectedChoices)]] integerValue];
        return [NSIndexPath indexPathForRow:sele inSection:0];
    }
}

#pragma mark - show or hide
- (void)viewDidLayoutSubviews
{
    if (!self.progressView)
    {
        CGRect frame = CGRectMake(0, self.view.frame.size.height - 44 - self.progressPanel.frame.size.height, self.view.frame.size.width, self.progressPanel.frame.size.height);
        self.progressView = [[UCloudProgressView alloc] initWithFrame:frame];
        self.progressView.progress = 0.0;
        self.progressView.noColor = [UIColor clearColor];
        self.progressView.borderWidth = 0.8f;
        self.progressView.prsColor = [UIColor colorWithRed:64.f/255.f green:116.f/255.f blue:225.f/255.f alpha:1.f];
        self.progressView.backgroundColor = [UIColor blackColor];
        [self.overlayPanel addSubview:self.progressView];
        
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
        if (!self.overlayPanel.hidden)
        {
            [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
        }
    }
}
- (void)buildUI
{
//    UIView *view = [self.delegatePlayer.view superview];
//    self.view.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    //菜单，开始不显示
    self.rightPanel.transform = CGAffineTransformMakeTranslation(self.rightPanel.frame.size.width, 0);
    self.centerPlanBtn.hidden = YES;
    self.playButton.hidden = YES;
    
    UITapGestureRecognizer *pan = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickMediaControl:)];
    [self.view addGestureRecognizer:pan];
}

- (void)showNoFade
{
    self.overlayPanel.hidden = NO;
    [self cancelDelayedHide];
    [self refreshMediaControl];
}

- (void)showAndFade
{
    [self showNoFade];
    [self performSelector:@selector(hide) withObject:nil afterDelay:5];
}

- (void)hide
{
    self.overlayPanel.hidden = !self.overlayPanel.hidden;
    [self cancelDelayedHide];
}

- (void)cancelDelayedHide
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
}

- (void)refreshMediaControl
{
    NSTimeInterval duration = self.delegatePlayer.duration;
    NSTimeInterval position = self.delegatePlayer.currentPlaybackTime;
    
    NSInteger intDuration = duration;
    NSInteger intPosition = position;
    
    if (intPosition > 0 &&   intPosition <= intDuration)
    {
        self.currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
        self.totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
        
        CGFloat value = position/(float)duration;
        if (value >= 0 && value <= 1 && self.progressView.progress != value)
        {
            self.progressView.progress = value;
        }
    }
    else
    {
        self.totalDurationLabel.text = @"--:--";
        self.currentTimeLabel.text = @"00:00";
        self.progressView.progress = 0.0f;
    }
    
    if ([self.delegatePlayer isPlaying])
    {
        self.centerPlanBtn.hidden = YES;
        self.playButton.hidden = YES;
        self.pauseButton.hidden = NO;
    }
    else
    {
        self.centerPlanBtn.hidden = NO;
        self.pauseButton.hidden = YES;
        self.playButton.hidden = NO;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    if (!self.overlayPanel.hidden)
    {
        [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
    }
}

- (void)showOrHideMenu
{
    __weak UCloudMediaViewController *weakSelf = self;
    if (CGAffineTransformEqualToTransform(self.rightPanel.transform, CGAffineTransformMakeTranslation(self.rightPanel.frame.size.width, 0)))
    {
        [UIView animateWithDuration:0.5f animations:^{
            weakSelf.rightPanel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
    else
    {
        [UIView animateWithDuration:0.5f animations:^{
            weakSelf.rightPanel.transform = CGAffineTransformMakeTranslation(weakSelf.rightPanel.frame.size.width, 0);
        } completion:^(BOOL finished) {
            
        }];
    }
}

#pragma mark IBAction
- (void)onClickMediaControl:(UITapGestureRecognizer *)sender
{
    CGPoint p = [sender locationInView:self.view];
    
    BOOL contain =  CGRectContainsPoint(self.rightPanel.frame, p);
    
    if (p.x > self.view.frame.size.width*2/3 && !contain)
    {
        self.overlayPanel.hidden = YES;
        [self cancelDelayedHide];
        [self showOrHideMenu];
    }
    else if (!contain)
    {
        self.rightPanel.transform = CGAffineTransformMakeTranslation(self.rightPanel.frame.size.width, 0);
        [self showAndFade];
    }
    
    else
    {
        CGPoint new = [self.choiceTabelView convertPoint:p fromView:self.view];
        NSIndexPath *indexPath = [self.choiceTabelView indexPathForRowAtPoint:new];
        if (indexPath == nil)
        {
            new  = [self.resultTabelView convertPoint:p fromView:self.view];
            indexPath = [self.resultTabelView indexPathForRowAtPoint:new];
            if (indexPath)
            {
                [self.selectedResults setObject:@(indexPath.row) forKey:[NSString stringWithFormat:@"%@", @(self.selectedChoices)]];
                
                if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(selectedMenu:choi:)])
                {
                    NSInteger one = self.selectedChoices;
                    NSInteger two = [self tableviewSelectedRow:self.resultTabelView].row;
                    [self.delegateAction selectedMenu:one choi:two];
                    [self showOrHideMenu];
                }
                [self.resultTabelView reloadData];
            }
        }
        else
        {
            self.selectedChoices = indexPath.row;
            self.resultLabel.text = [self.choi objectAtIndex:indexPath.row];
            [self.resultTabelView reloadData];
            [self.choiceTabelView reloadData];
        }
    }
    
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(onClickMediaControl:)])
    {
        [self.delegateAction onClickMediaControl:sender];
    }
}

- (IBAction)onClickBack:(UIButton *)sender
{
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(onClickBack:)])
    {
        [self.delegateAction onClickBack:sender];
    }
}

- (IBAction)onClickPlay:(id)sender
{
    self.centerPlanBtn.hidden = YES;
    self.playButton.hidden = YES;
    self.pauseButton.hidden = NO;
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(onClickPlay:)] && sender != nil)
    {
        [self.delegateAction onClickPlay:sender];
    }
}

- (IBAction)onClickPause:(id)sender
{
    self.centerPlanBtn.hidden = NO;
    self.pauseButton.hidden = YES;
    self.playButton.hidden = NO;
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(onClickPause:)] && sender != nil)
    {
        [self.delegateAction onClickPause:sender];
    }
}

- (IBAction)clickBright:(id)sender
{
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(clickBright:)])
    {
        [self.delegateAction clickBright:sender];
    }
}

- (IBAction)clickVolume:(id)sender
{
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(clickVolume:)])
    {
        [self.delegateAction clickVolume:sender];
    }
}

- (IBAction)clickFull:(UIButton *)sender
{
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(clickFull)])
    {
        [self.delegateAction clickFull];
    }
    [self forceRotation];
}

- (IBAction)clickShot:(id)sender
{
    if (self.delegateAction && [self.delegateAction respondsToSelector:@selector(clickShot:)])
    {
        [self.delegateAction clickShot:sender];
    }
}

#pragma mark - 旋转屏幕
- (void)forceRotation
{
    [self.progressView removeFromSuperview];
    self.progressView = nil;
    if (self.isPortrait) {
        self.isPortrait = NO;
        [self ForceLandscapeLeft];
    } else {
        self.isPortrait = YES;
        [self ForcePortrait];
    }
    self.progressView.frame = self.progressPanel.frame;
}

// 强制左横屏
- (void)ForceLandscapeLeft
{
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView animateWithDuration:duration animations:^{
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
        self.view.transform = CGAffineTransformIdentity;
        UIView *view = self.view.superview;
        [self.view removeFromSuperview];
        self.view.frame = CGRectMake(0, 0,view.frame.size.width, view.frame.size.height);
        [view addSubview:self.view];
    }];
}

// 强制竖屏
- (void)ForcePortrait
{
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView animateWithDuration:duration animations:^{
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        self.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
        UIView *views = self.view.superview;
        [self.view removeFromSuperview];
        self.view.frame = CGRectMake(0, 0,UISCREEN_WIDTH, UISCREEN_WIDTH);
        [views addSubview:self.view];
    }];
}

#pragma mark - 水印
- (void)waterMark
{
    if (!self.waterMarkLabel)
    {
        UILabel *label = [[UILabel alloc] init];
        label.text = @"UCloud";
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        [label sizeToFit];
        self.waterMarkLabel = label;
        [self.view addSubview:label];
    }
    
    
    //1.创建核心动画
    CAKeyframeAnimation *keyAnima=[CAKeyframeAnimation animation];
    //平移
    keyAnima.keyPath=@"position";
    //1.1告诉系统要执行什么动画
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(self.waterMarkLabel.frame.size.width/2.f, self.waterMarkLabel.frame.size.height/2.f, self.overlayPanel.frame.size.width - self.waterMarkLabel.frame.size.width, self.overlayPanel.frame.size.height - self.waterMarkLabel.frame.size.height)];
    
    
    //    CGPoint one = self.waterMarkLabel.center;
    //    CGPoint two = CGPointMake(self.overlayPanel.frame.size.width-self.overlayPanel.frame.size.width/2.f, self.waterMarkLabel.center.y);
    //    CGPoint three = CGPointMake(two.x, self.overlayPanel.frame.size.height-self.overlayPanel.frame.size.height/2.f);
    //    CGPoint four = CGPointMake(one.x, three.y);
    //
    //    CGFloat deltaOne = fabs(two.x - one.x);
    //    CGFloat deltaTwo = fabs(three.y - two.y);
    //    CGFloat deltaThree = fabs(four.x - three.x);
    //    CGFloat deltaFour = fabs(one.y - four.y);
    //    CGFloat all = deltaOne + deltaTwo + deltaThree +deltaFour;
    //
    //    CGFloat timeOne = 0;
    //    CGFloat timeTwo = deltaOne/all *5.f;
    //    CGFloat timeThree = deltaTwo/all *5.f;
    //    CGFloat timeFour = deltaThree/all *5.f;
    //
    //    keyAnima.values = @[[NSValue valueWithCGPoint:one],[NSValue valueWithCGPoint:two], [NSValue valueWithCGPoint:three], [NSValue valueWithCGPoint:four]];
    //    keyAnima.keyTimes = @[@(timeOne), @(timeTwo), @(timeThree), @(timeFour)];
    
    keyAnima.path=path.CGPath;
    keyAnima.delegate = self;
    //1.4设置动画执行的时间
    keyAnima.duration=5.0;
    //1.5设置动画的节奏
    keyAnima.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    //2.添加核心动画
    [self.waterMarkLabel.layer addAnimation:keyAnima forKey:@"wendingding"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self waterMark];
}

#pragma mark - stop
- (void)stop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    [self onClickPause:nil];
}
@end
