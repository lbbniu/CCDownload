#import <Foundation/Foundation.h>

typedef void (^DWErrorBlock)(NSError *error);
typedef void (^DWDownladerFinishBlock)();
typedef void (^DWDownloaderProgressBlock)(float progress, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);
typedef void(^DWDownloaderGetPlayUrlsBlock)(NSDictionary *playUrls);

@interface DWDownloader : NSObject

/**
 * @brief 获取视频下载信息。
 */
@property (copy, nonatomic)DWDownloaderGetPlayUrlsBlock getPlayinfoBlock;
/**
 *  @brief 下载过程中HTTP通信请求超时时间。
 */
@property (assign, nonatomic)NSTimeInterval timeoutSeconds;

/**
 *  @brief 要下载的文件在远程服务器上的字节数。
 */
@property (assign, nonatomic)NSInteger remoteFileSize;

/**
 *  @brief 在该block获取下载进度，可以在block内更新UI，如更新下载进度条。
 */
@property (copy, nonatomic)DWDownloaderProgressBlock progressBlock;

/**
 *  @brief 下载完成时回调该block，可以在block内更新UI，如将视频标记为下载完成。
 */
@property (copy, nonatomic)DWDownladerFinishBlock finishBlock;

/**
 *  @brief 下载失败时回调该block，可以在该block内更新UI，如将视频标记为下载失败。
 */
@property (copy, nonatomic)DWErrorBlock failBlock;

/**
 *  @brief 初始化 DWDownloader
 *
 *  @param userId      用户ID，不能为nil
 *  @param videoId     视频ID，不能为空
 *  @param key         用户秘钥，不能为nil
 *  @param path        下载视频的保存路径，不能为nil
 *
 *  注意：
 *
 *      若你所下载的 videoId 未启用视频加密功能，则保存的文件扩展名[必须]是 mp4，否则无法播放。
 *
 *      若你所下载的 videoId 启用了视频加密功能，则保存的文件扩展名[必须]是 pcm，否则无法播放。
 *
 *  @return 下载对象
 */
- (id)initWithUserId:(NSString *)userId andVideoId:(NSString *)videoId key:(NSString *)key destinationPath:(NSString *)path;

/**
 *  @brief 初始化 DWDownloader
 *
 *  @param userId      用户ID，不能为nil
 *  @param videoId     视频ID，不能为空
 *  @param key         用户秘钥，不能为nil
 *  该初始方法仅为获取视频下载信息使用
 *
 *  @return 下载对象
 */
- (id)initWithUserId:(NSString *)userId andVideoId:(NSString *)videoId key:(NSString *)key;

/**
 *  @brief 开始下载
 */
- (void)start;

/**
 *  @brief 暂停下载
 */
- (void)pause;

/**
 *  @brief 继续下载
 */
- (void)resume;

/**
 *   @brief 获取下载视频信息
 */
- (void)getPlayInfo;

/**
 *   @brief 按下载地址下载视频
 */
- (void)startWithUrlString:(NSString *)urlString;
@end
