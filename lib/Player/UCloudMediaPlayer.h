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
    ErrorNumShowViewIsNull      = 1000,
    ErrorNumUrlIsNull,
    ErrorNumSaveShotError,
    ErrorNumUrlIsWrong,
    ErrorNumdrm,
    
    ErrorNumCgiLostPars         = 40021,
    ErrorNumCgiRequest          = 40022,
    ErrorNumCgiAuthFail         = 40023,
    ErrorNumCgiMovieCannotFound = 40024, /// 不会构建videoview
    ErrorNumCgiDomainError      = 40025,
    ErrorNumCgiServerError      = 40026,
    ErrorNumCgiTimeOut          = 40027,
};

/*!
 *  播放错误时的子错误码
 */
typedef NS_ENUM(NSInteger, SubErrorCode)
{
    ///默认错误
    SubErrorCodeDefault = 0,
    ///准备播放超时
    SubErrorCodePrepareTimeout = 6,
    ///获取音频或视频帧超时
    SubErrorCodeAVFrameTimeout = 7,
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
 * 适用于rtmp直播协议，向服务器发送FCSubscribe命令,一般填写streamID，比如播放地址为rtmp://xxx.com/app/id,此处填写id
 */
@property (strong, nonatomic) NSString              *rtmpSubscribe;

/*!
 @property cachedDuration
 @abstract 丢帧策略缓存时长阀值，适用于直播，单位 ms，建议范围:0-5000，默认为3000。
 @discussion 当 cachedDuration > 0，播放器会触发追帧策略，缩短播放延时。cachedDuration <= 0 不启用。
 */
@property (assign, nonatomic) NSInteger             cachedDuration;

/*!
 @property bufferDuration
 @abstract 卡顿时的缓存时长，适用于直播，单位 ms，建议范围：1000-6000，默认为3000。
 @discussion 当播放器发生卡顿开始缓存时，缓冲视频数据时长为bufferDuration。该值越大卡顿缓冲时间越长，但是后续卡顿率会所有降低。当bufferDuration设置为0时，播放器将不发生缓冲，有数据则即刻播放，对网络比较敏感，容易发生卡顿，如果对延时要求不高的可以适当设置cachedDuration缓存一定量的音视频数据
 */
@property (assign, nonatomic) NSInteger             bufferDuration;

/*!
 @property prepareTimeout
 @abstract 暂时适用于直播，播放准备完成超时时间设置，单位 ms，默认10000，推荐范围5000-150000，超时会收到UCloudPlayerPlaybackDidFinishNotification消息
 */
@property (assign, nonatomic) NSInteger             prepareTimeout;

/*!
 @property getAVFrameTimeout
 @abstract 暂时适用于直播，获取音频或视频帧超时设置，单位 ms，默认10000，推荐范围5000-150000，超时会收到UCloudPlayerPlaybackDidFinishNotification消息
 */
@property (assign, nonatomic) NSInteger             getAVFrameTimeout;
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
 * 获取播放器SDK版本号
 */
-(NSString*)getSDKVersion;

/**
 *  刷新视图
 */
- (void)refreshView;

@end
