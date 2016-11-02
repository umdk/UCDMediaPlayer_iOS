//
//  UCloudMediaPlayer.h
//

#import <Foundation/Foundation.h>
#import "UCloudMediaPlayback.h"

/*!
 *  解码器
 */
typedef NS_ENUM(NSInteger, DecodeMethod) {
    /*!
     *  软解码
     */
    DecodeMethodSoft,
    /*!
     *  硬解码
     */
    DecodeMethodHard,
};

/*!
 *  清晰度
 */
typedef NS_ENUM(NSInteger, Definition) {
    
    /// 蓝光
    Definition_fhd,
    /// 超清
    Definition_shd,
    /// 高清
    Definition_hd,
    /// 标清
    Definition_sd,
};

/*!
 *  错误码
 */
typedef NS_ENUM(NSInteger, ErrorNum)
{
    ErrorNumShowViewIsNull = 1000,
    ErrorNumUrlIsNull,
    ErrorNumSaveShotError,
    ErrorNumUrlIsWrong,
    ErrorNumdrm,
    
    ErrorNumCgiLostPars = 40021,
    ErrorNumCgiRequest = 40022,
    ErrorNumCgiAuthFail = 40023,
    ErrorNumCgiMovieCannotFound = 40024, /// 不会构建videoview
    ErrorNumCgiDomainError = 40025,
    ErrorNumCgiServerError = 40026,
    ErrorNumCgiTimeOut = 40027,
};

/*!
 *  url类型值
 */
typedef NS_ENUM(NSInteger, UrlType)
{
    /// 自动，程序会根据相关规则为你选择播放类型，如果是http-flv直播，请必须设置为UrlTypeLive
    UrlTypeAuto   = 0,
    ///本地视频
    UrlTypeLocal  = 1,
    ///网络视频(非直播)
    UrlTypeHttp   = 2,
    ///直播
    UrlTypeLive   = 3,
};

typedef void(^UCloudMediaCompletionBlock)(NSInteger defaultNum, NSArray *data);

@interface UCloudMediaPlayer : NSObject

/**
 *  画面填充方式
 */
@property (assign, nonatomic) MPMovieScalingMode    defaultScalingMode;

/**
 *  默认的解码方式
 */
@property (assign, nonatomic) DecodeMethod           defaultDecodeMethod;

/**
 *  播放地址
 */
@property (strong, nonatomic) NSURL                 *url;

/**
 *  视频类型（直播、点播）
 */
@property (assign, nonatomic) UrlType               urlType;

/**
 *  向服务器发送FCSubscribe命令,一般填写streamID，比如播放地址为rtmp://xxx.com/app/id,此处填写id
 */
@property (strong, nonatomic) NSString              *rtmpSubscribe;

/**
 *  播放器控制器
 */
@property (strong, nonatomic) id<UCloudMediaPlayback> player;

/**
 *  初始化mediaPlayer
 *
 *  @return UCloudMediaPlayer
 */
+ (instancetype)ucloudMediaPlayer;

/**
 *  配置播放view
 *
 *  @param url   播放url
 *  @param urltype 播放类型
 *  @param frame playerView视图大小，默认传入CGRectNull
 *  @param view  player
 *  @param block 初始化完成
 */
- (void)showMediaPlayer:(NSString *)url urltype:(UrlType)urltype frame:(CGRect)frame view:(UIView *)view completion:(UCloudMediaCompletionBlock)block;

/**
 *  配置播放view
 *
 *  @param view  父view
 *  @param block 回掉清晰度信息
 */
- (void)showInview:(UIView *)view definition:(void(^)(NSInteger defaultNum, NSArray *data))block;

/**
 *  切换解码方式
 *
 *  @param decode 切换后的解码方式
 */
- (void)selectDecodeMethod:(DecodeMethod)decode;

/**
 *  切换清晰度
 *
 *  @param definition 切换后的清晰度
 */
- (void)selectDefinition:(Definition)definition;

/**
 *  刷新视图
 */
- (void)refreshView;

/**
 * 获取SDK版本号
 */
-(NSString*)getSDKVersion;

@end
