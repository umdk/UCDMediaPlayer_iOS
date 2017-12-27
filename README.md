# [UCloud MediaPlayer iOS SDK]()

UCDMediaPlayer 是一个适用于 iOS 的音视频播放器 SDK，基于FFmpeg自主研发音视频媒体播放器，支持 RTMP, HTTP-FLV 和 HLS 直播流媒体播放。更多视频云产品可去[官网](https://docs.ucloud.cn/video/uvideo/index)查看

本文档简要介绍UCDMediaPlayer的功能与简单接入,对于SDK的详细API请查看相关[wiki](https://github.com/umdk/UCDMediaPlayer_iOS/wiki)。

![player1](screenshot/player1.jpeg)
![player2](screenshot/player2.jpeg)

## Demo 体验
![demo](screenshot/vod_download.png)

## 一. 功能特性
- [x] 支持 RTMP、HLS、HTTP-FLV、RTSP 等协议
- [x] 支持speex音频播放
- [x] 支持累积延迟消除(RTMP和HTTP+FLV)，降低观看直播的观众延迟
- [x] 支持H.265/HEVC播放
- [x] 包含armv7、arm64、i386、x86_64指令集
- [x] 支持bitcode
- [x] 支持直播首屏秒开
- [x] 支持直播、点播播放
- [x] 支持软解、硬解切换
- [x] 支持点播多清晰度切换
- [x] 支持画幅调整
- [x] 支持全屏、非全屏切换
- [x] 支持屏幕亮度调节
- [x] 支持音量调节
- [x] 支持播放进度拖拽操作

## 二. 集成介绍
### 2.1 系统要求
* 最低支持iOS版本：iOS 7.0
* 最低支持iPhone型号：iPhone 4
* 支持CPU架构： armv7,arm64(和i386,x86_64模拟器) 

### 2.2 下载集成
```
git clone https://github.com/umdk/UCDMediaPlayer_iOS.git
```

目录结构：  
- demo	: UCDMediaPlayer演示demo，展示本SDK的主要接口使用  
- docs/docset : appleDoc风格接口文档，安装后可在Xcode中直接查看，亦可在Dash APP上查看使用  
- docs/html : appleDoc风格网页版接口文档，可直接点击index.html查看  
- lib/Player : 播放器静态库和相关头文件
- PlayerUI : 播放器UI及其管理器类，用户可自行修改使用

### 2.3 基础集成
#### 2.3.1 导入静态库

将lib文件夹下的Player直接拉到Xcode的工程中；

*Player文件夹中相关文件意义:  

| 类文件 | 描述 |
|---|---|---|
| UCloudMediaPlayer.h | 播放器控制类 |
| UCloudMediaPlayback.h | 播放器通知类 |
| libUCloudMediaPlayer.a | 播放器静态库 |
| UCloudPlayback.h | 播放器播放类 |
| UCloudMediaModule.h | 播放器显示控制类 |

#### 2.3.2 依赖库说明 

 添加libUCloudMediaPlayer.a所需引用的系统 framework,如下: 
 
| framework |
|---|---|
| VideoToolbox.framework |
| CoreMedia.framework |
| MediaPlayer.framework |
| AVFoundation.framework |
| AudioToolbox.framework |
| libz.tbd |

### 2.4播放器接入

#### 2.4.1 引入静态库

播放器包含ffmpeg库，已知在含有ffmpeg的第三方库情况下无法正常运行,可以尝试在编译选项**Other linker Flags**中加入**-force_load**来解决冲突，但不推荐使用。Player文件夹放置的是直播云播放器库，（如果已经有播放器库，可以不添加，自行配置播放器）将Player直接拉进Xcode工程目录中;


*引入**PlayerUI**文件夹，**PlayerUI**是项目中的播放器UI及其管理器类，用户可以自行修改使用。*

#### 2.4.2 集成播放器

##### 2.4.2.1 引入头文件
```
#import "UCloudMediaPlayer.h"
#import "UCloudMediaViewController.h"
#import "PlayerManager.h"
```
##### 2.4.2.2 开始播放直播流
```
self.playerManager = [[PlayerManager alloc] init];
self.playerManager.view = self.view;
self.playerManager.viewContorller = self;
[self.playerManager setPortraitViewHeight: self.view.frame.size.height];
[self.playerManager buildMediaPlayer:self.pathTextField.text];
```
##### 2.4.2.3 关闭播放器
```
[self.playerManager.mediaPlayer.player.view removeFromSuperview];
[self.playerManager.controlVC.view removeFromSuperview];
[self.playerManager.mediaPlayer.player shutdown];
self.playerManager.mediaPlayer = nil;
```
## 三 使用进阶

### 3.1 参数配置
当你要深入理解 SDK 的一些参数及有定制化需求时，可以从高级功能部分中查询阅读。

<code>defaultDecodeMethod</code>
解码方式分软解码和硬解码

<code>UrlType</code> 播放地址类型，区分为本地视频，网络视频，直播视频，使用UrlTypeAuto程序会根据相关规则为你选择播放类型，如果是http-flv直播，请必须设置为UrlTypeLive，hls点播必须设置为UrlTypeHttp;

<code>currentPlaybackTime</code> 当前播放时间点；

<code>duration</code> 视频总时间；

<code>playableDuration</code> 媒体可播放时长，主要用于表示网络媒体已下载视频时长

<code>bufferingProgress</code> 视频缓冲进度；

<code>isPreparedToPlay</code> 是否准备好可以播放

<code>playbackState</code> 媒体播放状态；

<code>loadState</code> 网络媒体加载状态

<code>shouldAutoplay</code> 是否自动播放

## 四 SDK升级历史信息文档变更

| 版本号 | 发布日期 | 说明 |
|---|---|---|
| 1.5.4  | 2017.12.27 | 1、增加音量调节接口，支持音量放大和静音<br/>2、弃用部分API接口改用新命名接口<br/>3、更新播放器内核|
| 1.5.3  | 2017.11.22 | 1、demo增加错误重连逻辑<br/>2、修复demo横竖屏切换时缓冲动画的位置问题<br/>3、UCloudMediaPlayer.h增加dropframeInterval属性<br/>4、本地日志路径改为可设置|
| 1.5.2  | 2017.06.23 | 1、UCloudPlayback.h增加videofps(视频帧率)、downloadSpeed(实时下载速度)属性|
| 1.5.1  | 2017.05.05 | 1、在demo层面加入对demo的友盟统计<br/>2、调整播放器的时的默认参数设置<br/>3、UCloudMediaPlayer.h增加videoToolboxEnabled属性|
| 1.5.0  | 2017.04.18 | 1、调整播放质量采集<br/>2、入本地日志模块，更方便普通用户定位问题，具体API详见UCloudMediaPlayer.h|
| 1.4.1  | 2017.03.17 | 1、增加对speex支持<br/>2、优化内存消耗|
| 1.4.0  | 2017.02.09 | 1、升级播放器解码内核<br/> 2、支持bitcode、动态库 <br/> 3、修复selectDecodeMethod接口问题|
| 1.3.0  | 2016.12.16 | 1、增加对https播放的支持<br/> 2、demo中增加直播、点播类型选择|
| 1.2.5  | 2016.12.08 | 增加delayOptimization、cacheDuration、bufferDuration设置选项|
| 1.2.4  | 2016.09.18 | 增加对FCSubscribe指令播放支持 |
| 1.2.3  | 2016.09.08 | 区分直播与点播的hls播放方式；hls播放流畅度优化 |
| 1.2.2  | 2016.07.29 | 优化弱网下音频播放体验 |
| 1.2.1  | 2016.07.27 | 优化直播追赶策略，使主动丢帧时声音更自然 |
| 1.2.0  | 2016.07.11 | 增加直播延迟丢帧效果，修复弱网情况下音效消失的问题 |
| 1.1.12 | 2016.05.16 | 1、修复鉴权失败时约束更新crash的问题(playerManager.m)；<br/>2、showMediaPlayer方法增加了urltype参数，每次重新播放时必须传入播放类型，以此解决使用单例模式下直播与点播来回切换状态相关没有重置的问题；<br/>3、头文件UCloudMediaPlayer.h中的UrlType枚举UrlTypeUnkown改为UrlTypeAuto |
| 1.1.11 | 2016.05.04 | 更新libUCloudMediaPlayer.a（修改了播放api、优化对蓝牙设备、扬声器、耳机之间的处理）；重新调整了demo初始状态的画幅设置；新增播放器创建方式 |
| 1.1.10 | 2016.04.29 | 修复弱网下偶现播放crash的bug；调整了播放器的初始化方式 |
| 1.1.9  | 2016.04.26 | 修改部分类与变量的命名 |
| 1.1.0  | 2016.02.19 | 播放器UI剥离 |
| 1.0.0  | 2016.01.23 | 优化推流时打开摄像头的流程；增加直播推流的模拟器库版本 |
| 0.9.1  | 2015.10.15 | 完成drm功能开发 |
| 0.9.0  | 2015.09.18 | 基本功能完成，UI编写使用完毕，文档初稿 |

## 五 反馈和建议
  - 主 页：<https://www.ucloud.cn/>
  - issue：[查看已有的 issues 和提交 Bug[推荐]](https://github.com/umdk/UCDMediaPlayer_iOS/issues)
  - 邮 箱：[sdk_spt@ucloud.cn](mailto:sdk_spt@ucloud.cn)
 
### 问题反馈参考模板

| 名称 | 描述 |
|---|---|
| SDK名称 | UCDMediaPlayer_iOS|
| 设备型号 | iphone7 |
| 系统版本 | iOS 10 |
| SDK版本 | v1.5.0 |
| 问题描述 | 描述问题现象 |
| 操作路径 | 经过了什么样的操作出现所述的问题 |
| 附 件 | 文本形式控制台log、crash报告、其他辅助信息（播放界面截屏或其他） |

### 提交工单

提交工单，配置推流域名对应的accesskey: https://accountv2.ucloud.cn/work_ticket

<img src="screenshot/work_ticket.png" width = "75%" height = "75%" alt="work_ticket" />