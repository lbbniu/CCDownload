#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>

#import "DWCustomPlayerViewController.h"
#import "DWOfflineViewController.h"
#import "DWGestureButton.h"
#import "DWPlayerMenuView.h"
#import "DWTableView.h"
#import "DWTools.h"
#import "DWMediaSubtitle.h"
#import "Reachability.h"

enum {
    DWPlayerScreenSizeModeFill=1,
    DWPlayerScreenSizeMode100,
    DWPlayerScreenSizeMode75,
    DWPlayerScreenSizeMode50
};
typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,
    DirectionUpOrDown,
    DirectionNone
};

typedef NSInteger DWPLayerScreenSizeMode;

@interface DWCustomPlayerViewController () <UIGestureRecognizerDelegate,DWGestureViewDelegate,UIAlertViewDelegate>
{
    NSMutableArray *_signArray;
}
@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) UILabel *tipLabel;
@property (assign, nonatomic) NSInteger tipHiddenSeconds;

@property (assign, nonatomic) Direction direction;
@property (assign, nonatomic) CGPoint startPoint;
@property (assign, nonatomic) CGFloat startVB;
@property (assign, nonatomic) CGFloat startVideoRate;
@property (strong, nonatomic) MPVolumeView *volumeView;//控制音量的view
@property (strong, nonatomic) UISlider* volumeViewSlider;//控制音量
@property (assign, nonatomic) CGFloat currentRate;//当期视频播放的进度

@property (strong, nonatomic)UIView *headerView;
@property (strong, nonatomic)UIView *footerView;
@property (strong, nonatomic)DWGestureView *overlayView;
@property (strong, nonatomic)UIView *videoBackgroundView;
@property (strong, nonatomic)UITapGestureRecognizer *signelTap;
@property (strong, nonatomic)UILabel *videoStatusLabel;
@property (strong, nonatomic)UIButton *lockButton;
@property (assign, nonatomic)BOOL isLock;
@property (strong, nonatomic)UIButton *BigPauseButton;

@property (strong, nonatomic)UIButton *backButton;
@property (strong, nonatomic)UIButton *screenSizeButton;
@property (assign, nonatomic)NSInteger currentScreenSizeStatus;
@property (strong, nonatomic)UIButton *downloadButton;
@property (strong, nonatomic)UIButton *menuButton;
@property (strong, nonatomic)UIButton *subtitleButton;
@property (assign, nonatomic)NSInteger currentSubtitleStatus;
@property (strong, nonatomic)DWTableView *subtitleTable;
@property (strong, nonatomic)UILabel *movieSubtitleLabel;
@property (strong, nonatomic)DWMediaSubtitle *mediaSubtitle;
@property (strong, nonatomic)UIView *menuView;
@property (strong, nonatomic)UIView *restView;
@property (strong, nonatomic)UITapGestureRecognizer *restviewTap;
@property (strong, nonatomic)UILabel *subtitleLabel;
@property (strong, nonatomic)UISwitch *subtitelSwitch;
@property (strong, nonatomic)UILabel *screenSizeLabel;
@property (strong, nonatomic)UIButton *screenSizeFull;
@property (strong, nonatomic)UIButton *screenSize100;
@property (strong, nonatomic)UIButton *screenSize75;
@property (strong, nonatomic)UIButton *screenSize50;

@property (strong, nonatomic)UIButton *switchScrBtn;
@property (assign, nonatomic)BOOL isFullscreen;
@property (strong, nonatomic)UIButton *selectvideoButton;
@property (strong, nonatomic)DWTableView *selectvideoTable;
@property (strong, nonatomic)UIButton *qualityButton;
@property (assign, nonatomic)NSInteger currentQualityStatus;
@property (strong, nonatomic)DWTableView *qualityTable;
@property (strong, nonatomic)NSArray *qualityDescription;
@property (strong, nonatomic)NSString *currentQuality;
@property (assign, nonatomic)BOOL isSwitchquality;
@property (assign, nonatomic)NSTimeInterval switchTime;
@property (strong, nonatomic)UIButton *playbackButton;
@property (assign, nonatomic)BOOL pausebuttonClick;
@property (strong, nonatomic)UIButton *playbackrateButton;
@property(nonatomic) float currentPlaybackRate;
@property (strong, nonatomic)UIButton *lastButton;
@property (strong, nonatomic)UIButton *nextButton;
@property (strong, nonatomic)UISlider *durationSlider;
@property (strong, nonatomic)UILabel *currentPlaybackTimeLabel;
@property (strong, nonatomic)UILabel *durationLabel;

@property (strong, nonatomic)DWMoviePlayerController  *player;
@property (strong, nonatomic)NSDictionary *playUrls;
@property (strong, nonatomic)NSDictionary *currentPlayUrl;
@property (assign, nonatomic)NSTimeInterval historyPlaybackTime;

@property (strong, nonatomic)NSTimer *timer;
@property (assign, nonatomic)BOOL hiddenAll;
@property (assign, nonatomic)NSInteger hiddenDelaySeconds;
@property(nonatomic,strong)NSDictionary *playPosition;

@property (strong, nonatomic)DWAdInfo *adInfo;
@property (strong, nonatomic)NSString *type;
@property (assign, nonatomic)int adNum;
@property (strong, nonatomic)NSString *materialUrl;
@property (strong, nonatomic)NSString *clickUrl;
@property (strong, nonatomic)UIView *adView;
@property (strong, nonatomic)UIImageView *materialView;
@property (strong, nonatomic)UIImage *materialImg;
@property (retain, nonatomic)UILabel *timeLabel;
@property (assign, nonatomic)NSInteger secondsCountDown;
@property (strong, nonatomic)NSTimer *countDownTimer;
@property (assign, nonatomic)BOOL adPlay;

@property (nonatomic) Reachability *internetReachability;

@end

@implementation DWCustomPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _qualityDescription = @[@"普通", @"清晰", @"高清"];
        
        _player = [[DWMoviePlayerController alloc] initWithUserId:DWACCOUNT_USERID key:DWACCOUNT_APIKEY];
        
        _currentQuality = [_qualityDescription objectAtIndex:0];
    
        [self addObserverForMPMoviePlayController];
        [self addTimer];
    }
    return self;
}

# pragma mark - 页面视图

- (void)viewDidLoad
{
    [super viewDidLoad];
    _signArray = [NSMutableArray new];
    for (int i=0; i<4; i++) {
        [_signArray addObject:@"0"];
    }
 
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    if ([_internetReachability currentReachabilityStatus] == ReachableViaWWAN) {
        self.alert = [[UIAlertView alloc]initWithTitle:@"当前为移动网络，是否继续播放？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [self.alert show];
    }
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
    self.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
    // 加载播放器 必须第一个加载
    [self loadPlayer];
    // 初始化播放器覆盖视图，它作为所有空间的父视图。
    self.overlayView = [[DWGestureView alloc] initWithFrame:self.view.bounds];
    self.overlayView.touchDelegate = self;
    // 初始化子视图
    [self loadFooterView];
    [self loadHeaderView];
    self.videoStatusLabel = [[UILabel alloc] init];
    self.tipLabel = [[UILabel alloc]init];
    [self onDeviceOrientationChange];
    
    self.signelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSignelTap:)];
    self.signelTap.numberOfTapsRequired = 1;
    self.signelTap.delegate = self;
    [self.overlayView addGestureRecognizer:self.signelTap];

    if (self.videoId) {
        if (_playMode) {
            // 获取广告信息
            _type = @"1";
            [self startRequestAdInfo];
        }
        else{
            [self loadPlayUrls];
        }
        
    } else if (self.videoLocalPath) {
        // 播放本地视频
        [self playLocalVideo];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"没有可以播放的视频"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
    // 10 秒后隐藏所有窗口·
    self.hiddenDelaySeconds = 10;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
}
- (void)appWillEnterForegroundNotification{
    if (self.player.playbackState == MPMoviePlaybackStatePaused) {
        [self.player play];
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    logdebug(@"stop movie");
    [self.player cancelRequestPlayInfo];
    if (!_adPlay) {
        [self saveNsUserDefaults];
    }
    self.player.currentPlaybackTime = self.player.duration;
    [self.player stop];
    self.secondsCountDown = -1;
    self.player.contentURL = nil;
    self.player = nil;
    [self removeAllObserver];
    [self removeTimer];
    
    // 显示 状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    // 显示 navigationController
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

# pragma mark 处理网络状态改变

- (void)networkStateChange
{
    NetworkStatus status = [_internetReachability currentReachabilityStatus];
    switch (status) {
        case NotReachable:
            NSLog(@"没有网络");
            [self loadTipLabelview];
            self.tipLabel.text = @"当前无任何网络";
            self.tipHiddenSeconds = 2;
            break;
            
        case ReachableViaWiFi:
            NSLog(@"Wi-Fi");
            [self loadTipLabelview];
            self.tipLabel.text = @"切换到wi-fi网络";
            self.tipHiddenSeconds = 2;
            break;
            
        case ReachableViaWWAN:
            NSLog(@"运营商网络");
            {
                [self.player pause];
                self.alert = [[UIAlertView alloc]initWithTitle:@"当前为移动网络，是否继续播放？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                [self.alert show];
            }
            break;
            
        default:
            break;
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.player stop];
        self.player.contentURL = nil;
        self.player = nil;
        [self removeAllObserver];
        [self removeTimer];
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (buttonIndex == 1) {
        [self.player play];
    }
}

# pragma mark - 广告层
-(void)loadAdview
{
    [_adView removeFromSuperview];
    _adView = [[UIView alloc]init];
    _adView.frame = self.overlayView.frame;
    _adView.backgroundColor = [UIColor clearColor];
    
    [_materialView removeFromSuperview];
    _materialView = [[UIImageView alloc]init];
    
    UIButton *backBtn = [[UIButton alloc]init];
    backBtn.frame = CGRectMake(_adView.bounds.origin.x+10, 20, 35, 35);
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[UIImage imageNamed:@"player-back-button.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_adView addSubview:backBtn];
    
    UIButton *scrBtn = [[UIButton alloc]init];
    scrBtn.frame = CGRectMake(_adView.bounds.size.width - 40, _adView.bounds.size.height - 40, 30, 30);
    scrBtn.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    scrBtn.selected = self.switchScrBtn.selected;
    [scrBtn setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateNormal];
    [scrBtn setImage:[UIImage imageNamed:@"nonfullscreen.png"] forState:UIControlStateSelected];
    [scrBtn addTarget:self action:@selector(switchScreenAction:)
     forControlEvents:UIControlEventTouchUpInside];
    [_adView addSubview:scrBtn];
    
    UIButton *detailBtn = [[UIButton alloc]init];
    detailBtn.frame = CGRectMake(_adView.bounds.size.width - 120, _adView.bounds.size.height - 40, 70, 30);
    [detailBtn setTitle:@"了解详情" forState:UIControlStateNormal];
    detailBtn.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    detailBtn.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    [detailBtn addTarget:self action:@selector(detailBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    _timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(_adView.bounds.size.width - 117, 20, 30, 30)];
    _timeLabel.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.adjustsFontSizeToFitWidth = YES;
    _timeLabel.textAlignment = UITextAlignmentCenter;
    
    UIButton *closeBtn = [[UIButton alloc]init];
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    [closeBtn addTarget:self action:@selector(closeBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *playBtn = [[UIButton alloc]init];
    playBtn.frame = CGRectMake(_adView.bounds.origin.x + 10, _adView.bounds.size.height - 40, 30, 30);
    playBtn.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    [playBtn setImage:[UIImage imageNamed:@"player-playbutton"] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(playbackButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([[_materialUrl lowercaseString] rangeOfString:@".mp4"].location == NSNotFound) {
        //片头图片保证旋转时刷新frame
        if (self.isFullscreen) {
            _materialView.center = _overlayView.center;
            _materialView.frame = _overlayView.frame;
            _materialView.backgroundColor = [UIColor clearColor];
            _materialView.transform = CGAffineTransformMakeScale(0.6, 0.6);
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *img = [DWTools imageCompressForSize:_materialImg targetSize:_materialView.layer.preferredFrameSize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_materialView setImage:img];
                });
            });
        }
        else{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *img = [DWTools imageCompressForSize:_materialImg targetSize:self.adView.layer.preferredFrameSize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.adView.layer.contents = (id)img.CGImage;
                });
            });
        }
    }
    if ([_type isEqualToString:@"2"]) {
        if (!_isFullscreen) {
            _materialView.center = _overlayView.center;
            _materialView.frame = CGRectMake(0, 58, _overlayView.frame.size.width, _overlayView.frame.size.height - 122);
            closeBtn.frame = CGRectMake(_materialView.bounds.size.width - 30, 0, 30, 30);
            _materialView.backgroundColor = [UIColor clearColor];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                UIImage *img = [DWTools imageCompressForSize:_materialImg targetSize:_materialView.layer.preferredFrameSize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_materialView setImage:img];
                });
            });
        }
        _materialView.userInteractionEnabled=YES;
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(detailBtn:)];
        [_materialView addGestureRecognizer:singleTap];
        [_overlayView addSubview:_materialView];
        [closeBtn setBackgroundImage:[UIImage imageNamed:@"close@3x"] forState:UIControlStateNormal];
        if (_isFullscreen) {
            closeBtn.frame = CGRectMake(_materialView.bounds.size.width - 45, 5, 40, 40);
        }
        [_materialView addSubview:closeBtn];
    }
    
    if ([_type isEqualToString:@"1"]) {
        //片头广告显示倒计时和了解详情
        [self.player.view addSubview:_adView];
        [_adView addSubview:_timeLabel];
        [_adView addSubview:detailBtn];
        if (self.isFullscreen) {
            [_adView setBackgroundColor:[UIColor clearColor]];
            [_adView addSubview:_materialView];
        }
        [_adView addSubview:_materialView];
        if (_adInfo.canSkip) {
            //只有可以跳过的广告才显示关闭按钮
            [closeBtn setTitle:@"关闭广告" forState:UIControlStateNormal];
            closeBtn.titleLabel.font = [UIFont systemFontOfSize: 14.0];
            closeBtn.frame = CGRectMake(_adView.bounds.size.width - 80, 20, 70, 30);
            [_adView addSubview:closeBtn];
        }
        else{
            //不显示关闭按钮时 倒计时框位置改变
            _timeLabel.frame = CGRectMake(_adView.bounds.size.width - 45, 20, 25, 25);
        }
    }
    if (_adInfo.canClick) {
        //可以点击广告画面进行跳转时
        UITapGestureRecognizer *TapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(detailBtn:)];
        [self.adView addGestureRecognizer:TapGesture];
    }
}

-(void)playAdmovie
{
    _materialUrl = [[_adInfo.ad objectAtIndex:_adNum] objectForKey:@"material"];
    _clickUrl = [[_adInfo.ad objectAtIndex:_adNum] objectForKey:@"clickurl"];
    _adPlay = YES;
    NSRange range;
    NSString *lowMateurl = [_materialUrl lowercaseString];
    range = [lowMateurl rangeOfString:@".mp4"];
    if (range.location == NSNotFound) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 处理耗时操作的代码块...
            _materialImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:_materialUrl]]];
            //通知主线程刷新
            dispatch_async(dispatch_get_main_queue(), ^{
                self.adView.layer.contents = (id)_materialImg.CGImage;
            });
        });
    }else{
        self.player.contentURL = [NSURL URLWithString:_materialUrl];
        [self.player play];
    }
}
-(void)detailBtn:(UIButton *)button
{//点击进入详情
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_clickUrl]];
}
-(void)closeBtn:(UIButton *)button
{//关闭广告按钮
    [_countDownTimer invalidate];
    _countDownTimer = nil;
    _adPlay = NO;
    if ([_type isEqualToString:@"1"]) {
        [self.adView setHidden:YES];
        [self.overlayView setHidden:NO];
        self.player.contentURL = nil;
        [self loadPlayUrls];
    }
    else{
        [_materialView setHidden:YES];
    }
}
- (void)addcountdownTimer
{//广告倒计时
    _secondsCountDown = _adInfo.time;
    _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeFireMethod) userInfo:nil repeats:YES];
    [self loadAdview];
    [self.overlayView setHidden:YES];
}

- (void)timeFireMethod
{
    _timeLabel.text = [NSString stringWithFormat:@"%lds",(long)_secondsCountDown];
    _secondsCountDown--;
    if(_secondsCountDown==-1){
        [_countDownTimer invalidate];
        _countDownTimer = nil;
        self.player.contentURL = nil;
        _adPlay = NO;
        [self loadPlayUrls];
        NSLog(@"计时器销毁");
        [self.adView setHidden:YES];
        [self.overlayView setHidden:NO];
    }
}
- (void)startRequestAdInfo
{
    _adInfo = [[DWAdInfo alloc]initWithUserId:DWACCOUNT_USERID andVideoId:self.videoId type:_type];
    [_adInfo start];
    if ([_type isEqualToString:@"2"]) {
        //暂停广告
        __weak DWCustomPlayerViewController *blockslf = self;
        _adInfo.finishBlock = ^(NSDictionary *response){
            _materialUrl = [[_adInfo.ad objectAtIndex:0] objectForKey:@"material"];
            _clickUrl = [[_adInfo.ad objectAtIndex:0] objectForKey:@"clickurl"];
            blockslf.materialImg = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:blockslf.materialUrl]]];
            [blockslf.materialView setHidden:NO];
            [blockslf loadAdview];
        };
    }
    if ([_type isEqualToString:@"1"]) {
        //片头广告
        __weak DWCustomPlayerViewController *blockself = self;
        _adInfo.finishBlock = ^(NSDictionary *response){
            [blockself addcountdownTimer];
            _adNum = 0;
            [blockself playAdmovie];
        };
    }
}

# pragma mark - 加载播放器
- (void)loadPlayer
{
    self.videoBackgroundView = [[UIView alloc] init];
    self.videoBackgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.videoBackgroundView];
}

# pragma mark - headerView
- (void)loadHeaderView
{
    self.headerView = [[UIView alloc]init];
    
    self.headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    
    [self.overlayView addSubview:self.headerView];
    logdebug(@"headerView frame: %@", NSStringFromCGRect(self.headerView.frame));
    
    // 返回按钮及视频标题
    self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //下载按钮
    self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //菜单按钮
    self.menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
}
# pragma mark 下载
-(void)loadDownloadButton
{
    CGRect frame = CGRectZero;
    frame.size.width = 40;
    frame.size.height = 40;
    frame.origin.x = self.headerView.frame.size.width - 100;
    frame.origin.y = self.backButton.frame.origin.y;
    self.downloadButton.frame = frame;
    
    self.downloadButton.backgroundColor = [UIColor clearColor];
    [self.downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.downloadButton setImage:[UIImage imageNamed:@"download_ic"] forState:UIControlStateNormal];
    [self.downloadButton addTarget:self action:@selector(downloadButtonAction:)
              forControlEvents:UIControlEventTouchUpInside];
    self.downloadButton.showsTouchWhenHighlighted = YES;
    [self.overlayView addSubview:self.downloadButton];
}
-(void)downloadButtonAction:(UIButton *)button
{
        DWOfflineViewController *offline = [[DWOfflineViewController alloc]init];
        offline.videoId = self.videoId;
        [offline loadDownloadItems];
        [offline addTask];
    if (DWAPPDELEGATE.isDownloaded) {
        [self loadTipLabelview];
        self.tipLabel.text = @"该视频已经下载过";
        self.tipHiddenSeconds = 2;
    }
}

# pragma mark 菜单 ...
-(void)loadMenuButton
{
    CGRect frame = CGRectZero;
    frame.size.width = 40;
    frame.size.height = 40;
    frame.origin.x = self.headerView.frame.size.width - 50;
    frame.origin.y = self.backButton.frame.origin.y;
    self.menuButton.frame = frame;
    
    self.menuButton.backgroundColor = [UIColor clearColor];
    [self.menuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.menuButton setImage:[UIImage imageNamed:@"more_ic"] forState:UIControlStateNormal];
    [self.menuButton addTarget:self action:@selector(menuButtonAction:)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.menuButton];
    self.menuButton.hidden = self.backButton.hidden;
    
}
-(void)menuButtonAction:(UIButton *)button
{
    CGRect frame = CGRectZero;
    frame.origin.x = self.overlayView.frame.size.width * 1 / 2;
    frame.origin.y = 0;
    frame.size.width = self.overlayView.frame.size.width / 2;
    frame.size.height = self.overlayView.frame.size.height;
    self.menuView = [[UIView alloc]initWithFrame:frame];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5];
    [self.overlayView addSubview:self.menuView];
    
    self.restView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.overlayView.frame.size.width * 1 / 2, self.overlayView.frame.size.height)];
    self.restView.backgroundColor = [UIColor clearColor];
    [self.overlayView addSubview:self.restView];
    self.restviewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRestviewTap:)];
    self.restviewTap.numberOfTapsRequired = 1;
    self.restviewTap.delegate = self;
    [self.restView addGestureRecognizer:self.restviewTap];

    [self hiddenAllView];
    [self loadSubtitleView];
    [self loadScreenSizeView];
    [self.overlayView removeGestureRecognizer:self.signelTap];
}
-(void)handleRestviewTap:(UIGestureRecognizer*)gestureRecognizer{
    [self.restView removeFromSuperview];
    [self.menuView removeFromSuperview];
    [self showBasicViews];
    [self.overlayView addGestureRecognizer:self.signelTap];

}

# pragma mark 返回按钮及视频标题
- (void)loadBackButton
{
    CGRect frame;
    frame.origin.x = 16;
    frame.origin.y = self.headerView.frame.origin.y + 4;
    frame.size.width = 100;
    frame.size.height = 30;
    self.backButton.frame = frame;
    
    self.backButton.backgroundColor = [UIColor clearColor];
    [self.backButton setTitle:@"  视频标题" forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.backButton setImage:[UIImage imageNamed:@"player-back-button"] forState:UIControlStateNormal];
    self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.backButton addTarget:self action:@selector(backButtonAction:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.backButton];
}

- (void)backButtonAction:(UIButton *)button
{
    if (self.isFullscreen == YES) {
        [self SmallScreenFrameChanges];
        self.isFullscreen = NO;
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

# pragma mark 字幕
-(void)loadSubtitleView
{
    CGRect frame = CGRectZero;
    frame.origin.x = 30;
    frame.origin.y = 30;
    frame.size.width = 50;
    frame.size.height = 30;
    self.subtitleLabel = [[UILabel alloc]initWithFrame:frame];
    self.subtitleLabel.text = @"字幕:";
    self.subtitleLabel.font = [UIFont systemFontOfSize:14];
    self.subtitleLabel.textColor = [UIColor whiteColor];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.menuView addSubview:self.subtitleLabel];
    
    frame.origin.x = self.subtitleLabel.frame.origin.x + 50 + 50;
    self.subtitelSwitch = [[UISwitch alloc]initWithFrame:frame];
    if (self.movieSubtitleLabel) {
        [self.subtitelSwitch setOn:!self.movieSubtitleLabel.hidden];
    }
    [self.subtitelSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.menuView addSubview:self.subtitelSwitch];
    [self.subtitelSwitch setOnTintColor:[UIColor orangeColor]];
    [self.subtitelSwitch setThumbTintColor:[UIColor whiteColor]];
    [self.subtitelSwitch setTintColor:[UIColor grayColor]];
    
}
-(void)switchChanged:(UISwitch *)subtitelSwitch
{
    if (self.subtitelSwitch.on == YES) {
        if (!self.movieSubtitleLabel) {
            [self loadMovieSubtitle];
        }
        self.movieSubtitleLabel.hidden = NO;
    }
    else{
        self.movieSubtitleLabel.hidden = YES;
    }
}
- (BOOL)loadMovieSubtitle
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"example.utf8" ofType:@"srt"];
    self.mediaSubtitle = [[DWMediaSubtitle alloc] initWithSRTPath:path];
    if (![self.mediaSubtitle parse]) {
        loginfo(@"path parse failed: %@", [self.mediaSubtitle.error localizedDescription]);
        return NO;
    }
    if (self.isFullscreen) {
        self.movieSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, self.overlayView.frame.size.height * 3 / 5, self.overlayView.frame.size.width - 200, 40)];
    }
    else{
        self.movieSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.overlayView.frame.size.height * 3 / 5, self.overlayView.frame.size.width - 20, 40)];
    }
    self.movieSubtitleLabel.font = [UIFont systemFontOfSize:16];
    self.movieSubtitleLabel.textAlignment = UITextAlignmentCenter;
    self.movieSubtitleLabel.textColor = [UIColor whiteColor];
    self.movieSubtitleLabel.backgroundColor = [UIColor clearColor];
    [self.overlayView addSubview:self.movieSubtitleLabel];
    
    return YES;
}

#pragma mark 画面尺寸
-(void)loadScreenSizeView
{
    CGRect frame = CGRectZero;
    frame.origin.x = 10;
    frame.origin.y = 80;
    frame.size.width = 70;
    frame.size.height = 30;
    self.screenSizeLabel = [[UILabel alloc]initWithFrame:frame];
    self.screenSizeLabel.text =@"画面尺寸:";
    self.screenSizeLabel.font = [UIFont systemFontOfSize:14];
    self.screenSizeLabel.textColor = [UIColor whiteColor];
    self.screenSizeLabel.textAlignment = NSTextAlignmentCenter;
    [self.menuView addSubview:self.screenSizeLabel];
    
    frame.origin.x = self.screenSizeLabel.frame.origin.x + 70;
    self.screenSizeFull = [[UIButton alloc]initWithFrame:frame];
    [self.screenSizeFull setTitle:@"满屏" forState:UIControlStateNormal];
    self.screenSizeFull.titleLabel.font = [UIFont systemFontOfSize:14];
    self.screenSizeFull.tag = 100;
    if ([_signArray[_screenSizeFull.tag-100] isEqualToString:@"1"]) {
        [self.screenSizeFull setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    }else{
        [self.screenSizeFull setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.screenSizeFull addTarget:self action:@selector(screenSizeChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:self.screenSizeFull];
    
    frame.origin.x = self.screenSizeFull.frame.origin.x + 50;
    self.screenSize100 = [[UIButton alloc]initWithFrame:frame];
    [self.screenSize100 setTitle:@"100%" forState:UIControlStateNormal];
    self.screenSize100.titleLabel.font = [UIFont systemFontOfSize:14];
    self.screenSize100.tag = 101;
    if ([_signArray[_screenSize100.tag-100] isEqualToString:@"1"]) {
        [self.screenSize100 setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    }else{
        [self.screenSize100 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.screenSize100 addTarget:self action:@selector(screenSizeChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:self.screenSize100];
    
    frame.origin.x = self.screenSize100.frame.origin.x + 50;
    self.screenSize75 = [[UIButton alloc]initWithFrame:frame];
    [self.screenSize75 setTitle:@"75%" forState:UIControlStateNormal];
    self.screenSize75.titleLabel.font = [UIFont systemFontOfSize:14];
    self.screenSize75.tag = 102;
    if ([_signArray[_screenSize75.tag-100] isEqualToString:@"1"]) {
        [self.screenSize75 setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    }else{
        [self.screenSize75 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.screenSize75 addTarget:self action:@selector(screenSizeChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:self.screenSize75];
    
    frame.origin.x = self.screenSize75.frame.origin.x + 50;
    self.screenSize50 = [[UIButton alloc]initWithFrame:frame];
    [self.screenSize50 setTitle:@"50%" forState:UIControlStateNormal];
    self.screenSize50.titleLabel.font = [UIFont systemFontOfSize:14];
    self.screenSize50.tag = 103;
    if ([_signArray[_screenSize50.tag-100] isEqualToString:@"1"]) {
        [self.screenSize50 setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    }else{
        [self.screenSize50 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    [self.screenSize50 addTarget:self action:@selector(screenSizeChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuView addSubview:self.screenSize50];

}
-(void)screenSizeChange:(UIButton *)btn
{
    for (int i=0; i<4; i++) {
        if (i==btn.tag-100) {
            _signArray[btn.tag - 100] = @"1";
        }else{
            _signArray[i] = @"0";
        }
    }
    [btn setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    if (btn.tag == 100) {
        [self switchScreenSizeMode:DWPlayerScreenSizeModeFill];
        [self.screenSize50 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize75 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize100 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    if (btn.tag == 101) {
        [self switchScreenSizeMode:DWPlayerScreenSizeMode100];
        [self.screenSizeFull setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize75 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize50 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    }
    if (btn.tag == 102) {
        [self switchScreenSizeMode:DWPlayerScreenSizeMode75];
        [self.screenSize50 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize100 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSizeFull setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    }
    if (btn.tag == 103) {
        [self switchScreenSizeMode:DWPlayerScreenSizeMode50];
        [self.screenSize100 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSize75 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.screenSizeFull setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}
- (void)switchScreenSizeMode:(DWPLayerScreenSizeMode)screenSizeMode
{
    switch (screenSizeMode) {
        case DWPlayerScreenSizeModeFill:
            self.player.view.frame = self.videoBackgroundView.bounds;
            self.player.scalingMode = MPMovieScalingModeFill;
            break;

        case DWPlayerScreenSizeMode100:
            self.player.view.frame = self.videoBackgroundView.bounds;
            self.player.scalingMode = MPMovieScalingModeAspectFit;
            break;

        case DWPlayerScreenSizeMode75:
            self.player.scalingMode = MPMovieScalingModeAspectFit;

            self.player.view.frame = [self getScreentSizeWithRefrenceFrame:self.videoBackgroundView.bounds andScaling:0.75f];
            break;

        case DWPlayerScreenSizeMode50:
            self.player.scalingMode = MPMovieScalingModeAspectFit;

            self.player.view.frame = [self getScreentSizeWithRefrenceFrame:self.videoBackgroundView.bounds andScaling:0.5f];
            break;
            
        default:
            break;
    }
}
- (CGRect)getScreentSizeWithRefrenceFrame:(CGRect)frame andScaling:(float)scaling
{
    if (scaling == 1) {
        return frame;
    }
    
    NSInteger n = 1/(1 - scaling);
    frame.origin.x += roundf(frame.size.width/n/2);
    frame.origin.y += roundf(frame.size.height/n/2);
    frame.size.width -= roundf(frame.size.width/n);
    frame.size.height -= roundf(frame.size.height/n);
    
    return frame;
}
# pragma mark - footerView

- (void)loadFooterView
{
    self.footerView = [[UIView alloc]init];
    self.footerView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.2];
    [self.overlayView addSubview:self.footerView];
    logdebug(@"footerView: %@", NSStringFromCGRect(self.footerView.frame));

    // 播放按钮
    self.playbackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.lastButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // 当前播放时间
    self.currentPlaybackTimeLabel = [[UILabel alloc] init];

    // 画面尺寸
    self.screenSizeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];

    // 视频总时间
    self.durationLabel = [[UILabel alloc] init];

    // 时间滑动条
    self.durationSlider = [[UISlider alloc] init];
    [self durationSlidersetting];
    
    //切换屏幕按钮
    self.switchScrBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //倍速按钮
    self.playbackrateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //清晰度按钮
    self.qualityButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //选集按钮
    self.selectvideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
}
# pragma mark 屏幕翻转
-(void)loadSwitchScrBtn
{
    CGRect frame;
    if (_isFullscreen == NO) {
        frame.origin.x = self.footerView.frame.size.width - 35;
        frame.origin.y = self.footerView.frame.origin.y;
        frame.size.width = 38;
        frame.size.height = 38;
    }
    else{
        frame.origin.x = self.footerView.frame.size.width - 35;
        frame.origin.y = self.footerView.frame.origin.y;
        frame.size.width = 40;
        frame.size.height = 40;
    }
    
    
    self.switchScrBtn.frame = frame;
    self.switchScrBtn.backgroundColor = [UIColor clearColor];
    self.switchScrBtn.showsTouchWhenHighlighted = YES;
    [self.switchScrBtn setImage:[UIImage imageNamed:@"fullscreen.png"] forState:UIControlStateNormal];
    [self.switchScrBtn setImage:[UIImage imageNamed:@"nonfullscreen.png"] forState:UIControlStateSelected];
    [self.switchScrBtn addTarget:self action:@selector(switchScreenAction:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.switchScrBtn];
    logdebug(@"self.switchScrBtn.frame: %@", NSStringFromCGRect(self.switchScrBtn.frame));
   
}

-(void)switchScreenAction:(UIButton *)button
{
    self.switchScrBtn.selected = !self.switchScrBtn.selected;
    
    if (self.switchScrBtn.selected == YES) {
        [self FullScreenFrameChanges];
        if (_adPlay && _playMode) {
            [self loadAdview];
        }
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
        self.isFullscreen = YES;
        NSLog(@"点击按钮 to Full");
    }
    else{
        [self SmallScreenFrameChanges];
        if (_adPlay && _playMode) {
            [self loadAdview];
        }
        self.isFullscreen = NO;
        NSLog(@"点击按钮 to Small");
    }
}

-(void)SmallScreenFrameChanges{
    self.isFullscreen = NO;
    
    [self.videoBackgroundView removeFromSuperview];
    [self.overlayView removeFromSuperview];
    [self.player.view removeFromSuperview];
    [self.menuView removeFromSuperview];
    [self.restView removeFromSuperview];
    [self.lockButton removeFromSuperview];
    [self.BigPauseButton removeFromSuperview];
    [self.movieSubtitleLabel removeFromSuperview];
    
    self.view.transform = CGAffineTransformIdentity;
    self.overlayView.transform =CGAffineTransformIdentity;
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    CGRect frame = self.view.frame;
    
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height/2 - 50);
    
    [self.view addSubview:self.overlayView];
    
    self.videoBackgroundView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height/2 - 50);
    self.videoBackgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.videoBackgroundView];
    
    self.player.scalingMode = MPMovieScalingModeAspectFit;
    self.player.controlStyle = MPMovieControlStyleNone;
    self.player.view.backgroundColor = [UIColor clearColor];
    self.player.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height/2 - 50);
    [self.videoBackgroundView addSubview:self.player.view];
    
    [self.view bringSubviewToFront:self.overlayView];
    
    self.headerView.frame = CGRectMake(0, 0, self.overlayView.frame.size.width, 38);
    self.footerView.frame = CGRectMake(0, self.overlayView.frame.size.height - 38, self.overlayView.frame.size.width, 38);
    self.switchScrBtn.selected = NO;
    [self volumeView];
    [self headerViewframe];
    [self footerViewframe];
    [self loadVideoStatusLabel];
    if (self.subtitelSwitch.on == YES) {
        [self loadMovieSubtitle];
    }
    if (_pausebuttonClick) {
        [self loadBigPauseButton];
    }
    [self showBasicViews];
    self.hiddenDelaySeconds = 10;
}

-(void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [self FullScreenFrameChanges];
    if (_adPlay && _playMode) {
        [self loadAdview];
    }
}

-(void)FullScreenFrameChanges{
    self.isFullscreen = YES;
    
    [self.videoBackgroundView removeFromSuperview];
    [self.overlayView removeFromSuperview];
    [self.player.view removeFromSuperview];
    [self.BigPauseButton removeFromSuperview];
    [self.movieSubtitleLabel removeFromSuperview];
    self.view.transform = CGAffineTransformIdentity;
    self.overlayView.transform = CGAffineTransformIdentity;
    
    CGFloat max = MAX(self.view.frame.size.width, self.view.frame.size.height);
    CGFloat min = MIN(self.view.frame.size.width, self.view.frame.size.height);
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.frame = CGRectMake(0, 0, max, min);
    [self.view addSubview:self.overlayView];
    
    self.videoBackgroundView.backgroundColor = [UIColor blackColor];
    self.videoBackgroundView.frame = CGRectMake(0, 0, max, min);
    [self.view addSubview:self.videoBackgroundView];
    
    self.player.scalingMode = MPMovieScalingModeAspectFit;
    self.player.controlStyle = MPMovieControlStyleNone;
    self.player.view.backgroundColor = [UIColor clearColor];
    self.player.view.frame = CGRectMake(0, 0, max, min);
    [self.videoBackgroundView addSubview:self.player.view];
    
    self.headerView.frame = CGRectMake(0, 0, self.overlayView.frame.size.width, 38);
    self.footerView.frame = CGRectMake(0, self.overlayView.frame.size.height - 60, self.overlayView.frame.size.width, 60);
    self.switchScrBtn.selected = YES;
    [self volumeView];
    [self headerViewframe];
    [self footerViewframe];
    [self loadLockButton];
    [self loadVideoStatusLabel];
    if (_pausebuttonClick) {
        [self loadBigPauseButton];
    }
    if (self.subtitelSwitch.on == YES) {
        [self loadMovieSubtitle];
    }
    [self.view bringSubviewToFront:self.overlayView];
    [self showBasicViews];
    self.hiddenDelaySeconds = 10;
}
-(void)footerViewframe
{
    [self loadPlaybackButton];
    [self loadCurrentPlaybackTimeLabel];
    [self loadPlaybackSlider];
    [self loadDurationLabel];
    [self loadSwitchScrBtn];
    if (self.isFullscreen == YES) {
        [self loadLastButton];
        [self loadNextButton];
        [self loadQualityView];
        [self loadPlaybackRateButton];
        [self loadSelectvideoButton];
    }
}

-(void)headerViewframe
{
    [self loadBackButton];
    [self loadDownloadButton];
    [self loadMenuButton];
}
//隐藏状态栏
- (BOOL)prefersStatusBarHidden{
    return YES;
}
/**
 *  旋转屏幕通知
 */

- (void)onDeviceOrientationChange{
    if (self.player==nil){
        return;
    }

    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationUnknown:{
            NSLog(@"旋转方向未知");
            [self SmallScreenFrameChanges];
        }
            break;
        case UIInterfaceOrientationPortrait:{
            NSLog(@"第0个旋转方向---电池栏在上");
            [self SmallScreenFrameChanges];
            if (_adPlay && _playMode) {
                [self loadAdview];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            NSLog(@"第2个旋转方向---电池栏在左");
            if (self.isFullscreen == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            NSLog(@"第1个旋转方向---电池栏在右");
            if (self.isFullscreen == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        }
            break;
        default:
            //设备平躺条件下进入播放界面
            if (self.isFullscreen == NO) {
                [self SmallScreenFrameChanges];
            }
            break;
    }
}

# pragma mark 选集

-(void)loadSelectvideoButton
{
    CGRect frame = CGRectZero;
    frame.size.width = 50;
    frame.size.height = 30;
    frame.origin.x = self.qualityButton.frame.origin.x + 30 + 50;
    frame.origin.y = self.qualityButton.frame.origin.y;
    self.selectvideoButton.frame = frame;
    
    self.selectvideoButton.backgroundColor = [UIColor clearColor];
    [self.selectvideoButton setTitle:@"选集" forState:UIControlStateNormal];
    [self.selectvideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.selectvideoButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.selectvideoButton addTarget:self action:@selector(selectvideoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.selectvideoButton.hidden = self.qualityButton.hidden;
    [self.overlayView addSubview:self.selectvideoButton];
}

-(void)selectvideoButtonAction:(UIButton *)button
{
    CGRect frame = CGRectZero;
    frame.origin.x = self.overlayView.frame.size.width * 1 / 2;
    frame.origin.y = 0;
    frame.size.width = self.overlayView.frame.size.width / 2;
    frame.size.height = self.overlayView.frame.size.height;
    self.menuView = [[UIView alloc]initWithFrame:frame];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5];
    [self.overlayView addSubview:self.menuView];
    
    self.restView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.overlayView.frame.size.width * 1 / 2, self.overlayView.frame.size.height)];
    self.restView.backgroundColor = [UIColor clearColor];
    [self.overlayView addSubview:self.restView];
    self.restviewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRestviewTap:)];
    self.restviewTap.numberOfTapsRequired = 1;
    self.restviewTap.delegate = self;
    [self.restView addGestureRecognizer:self.restviewTap];
    
    [self hiddenAllView];
    [self.overlayView removeGestureRecognizer:self.signelTap];

    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.width = self.menuView.frame.size.width;
    frame.size.height = self.menuView.frame.size.height;
    self.selectvideoTable = [[DWTableView alloc]initWithFrame:frame style:UITableViewStylePlain];
    self.selectvideoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.selectvideoTable.rowHeight = self.overlayView.frame.size.height / 4;
    self.selectvideoTable.backgroundColor = [UIColor clearColor];
    [self.selectvideoTable resetDelegate];
    self.selectvideoTable.scrollEnabled = YES;
    [self.menuView addSubview:self.selectvideoTable];
    
    __weak DWCustomPlayerViewController *blockSelf = self;
    self.selectvideoTable.tableViewNumberOfRowsInSection = ^NSInteger(UITableView *tableView, NSInteger section) {
                return blockSelf.videos.count;
            };

    self.selectvideoTable.tableViewCellForRowAtIndexPath = ^UITableViewCell*(UITableView *tableView, NSIndexPath *indexPath){
        static NSString *cellId = @"selectvideoTableCellId";
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
            cell.imageView.image = [UIImage imageNamed:@"cc-placeholder"];
            cell.textLabel.text = [blockSelf.videos objectAtIndex:indexPath.row];
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellEditingStyleNone;
            if (blockSelf.indexpath == indexPath.row) {
                cell.textLabel.textColor = [UIColor orangeColor];
            }
        }
        return cell;
    };
    self.selectvideoTable.tableViewDidSelectRowAtIndexPath = ^void(UITableView *tableView, NSIndexPath *indexPath){
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        // 更新表格文字颜色，已选中行为橙色，为选中行为白色。
        UITableViewCell *cell = [blockSelf.selectvideoTable cellForRowAtIndexPath:indexPath];
        NSArray *cells = [blockSelf.selectvideoTable visibleCells];
        for (UITableViewCell *cl in cells) {
            if (cl == cell) {
                cl.textLabel.textColor = [UIColor orangeColor];
            } else {
                cl.textLabel.textColor = [UIColor whiteColor];
            }
        }
        blockSelf.pausebuttonClick = NO;
        [blockSelf.BigPauseButton removeFromSuperview];
        blockSelf.videoId = cell.textLabel.text;
        blockSelf.indexpath = indexPath.row;
        [blockSelf loadPlayUrls];
        
    };
}


# pragma mark 播放按钮
- (void)loadPlaybackButton
{
    CGRect frame = CGRectZero;
    if (self.isFullscreen == NO) {
        frame.origin.x = self.footerView.frame.origin.x + 5;
        frame.origin.y = self.footerView.frame.origin.y + self.footerView.frame.size.height / 2 - 15;
    }else{
        frame.origin.x = self.footerView.frame.size.width/4 - 15;
        frame.origin.y = self.footerView.frame.origin.y + (self.footerView.frame.size.height/4)*3 - 15;
        if (self.videoLocalPath) {
            frame.origin.x = self.footerView.frame.size.width/10;
            frame.origin.y = self.footerView.frame.origin.y + (self.footerView.frame.size.height/4)*3 - 15;
        }
    }
    
    frame.size.width = 30;
    frame.size.height = 30;
    self.playbackButton.frame = frame;

    [self.playbackButton setImage:[UIImage imageNamed:@"player-pausebutton"] forState:UIControlStateNormal];
    [self.playbackButton addTarget:self action:@selector(playbackButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.playbackButton];
}

- (void)playbackButtonAction:(UIButton *)button
{
    self.hiddenDelaySeconds = 10;
    
    if (!self.playUrls || self.playUrls.count == 0) {
        [self loadPlayUrls];
        return;
    }
    
    UIImage *image = nil;
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        // 暂停播放
        self.pausebuttonClick = YES;
        image = [UIImage imageNamed:@"player-playbutton"];
        [self.player pause];
        [self loadBigPauseButton];
        if (_playMode) {
            _type = @"2";
            [self startRequestAdInfo];
            _adPlay = YES;
            }
    } else {
        // 继续播放
        self.pausebuttonClick = NO;
        self.BigPauseButton.hidden = YES;
        image = [UIImage imageNamed:@"player-pausebutton"];
        [self.player play];
        [self.materialView setHidden:YES];
        _adPlay = NO;
    }
    [self.playbackButton setImage:image forState:UIControlStateNormal];
}

-(void)loadLastButton
{
    CGRect frame = CGRectZero;
    frame.origin.x = self.playbackButton.frame.origin.x - 50;
    frame.origin.y = self.footerView.frame.origin.y + (self.footerView.frame.size.height/4)*3 - 15;
    frame.size.width = 30;
    frame.size.height = 30;
    self.lastButton.frame = frame;
    
    [self.lastButton setImage:[UIImage imageNamed:@"last-button"] forState:UIControlStateNormal];
    [self.lastButton addTarget:self action:@selector(lastButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.lastButton];
    
}
-(void)lastButtonAction:(UIButton *)button
{
    if (self.indexpath == 0) {
        self.indexpath = self.videos.count;
    }
    self.videoId = self.videos[self.indexpath - 1];
    [self loadPlayUrls];
    self.indexpath --;
    [self.BigPauseButton removeFromSuperview];
}

-(void)loadNextButton
{
    CGRect frame = CGRectZero;
    frame.origin.x = self.playbackButton.frame.origin.x + 50;
    frame.origin.y = self.footerView.frame.origin.y + (self.footerView.frame.size.height/4)*3 - 15;
    frame.size.width = 30;
    frame.size.height = 30;
    self.nextButton.frame = frame;
 
    [self.nextButton setImage:[UIImage imageNamed:@"next-button"] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.nextButton];
    
}
-(void)nextButtonAction:(UIButton *)button
{
    if (self.indexpath == self.videos.count - 1) {
        self.indexpath = -1;
    }
    self.videoId = self.videos[self.indexpath + 1];
    [self loadPlayUrls];
    self.indexpath ++;
    [self.BigPauseButton removeFromSuperview];
}

# pragma mark 倍速
-(void)loadPlaybackRateButton
{
    CGRect frame = CGRectZero;
    if (self.videoId) {
        frame.size.width = 50;
        frame.size.height = 30;
        frame.origin.x = self.qualityButton.frame.origin.x - 30 - 50;
        frame.origin.y = self.qualityButton.frame.origin.y;
    }
    else{
        frame.size.width = 50;
        frame.size.height = 30;
        frame.origin.x = self.footerView.frame.size.width/4 + self.footerView.frame.size.width/2 + 5 + 50;
        frame.origin.y = self.playbackButton.frame.origin.y;
    }
    self.playbackrateButton.frame = frame;

    self.playbackrateButton.backgroundColor = [UIColor clearColor];
    self.playbackrateButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.playbackrateButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.playbackrateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if (self.player.playbackState == MPMoviePlaybackStatePlaying) {
        self.player.currentPlaybackRate = 1.0;
    }
    [self.playbackrateButton setTitle:@"倍速x1.0" forState:UIControlStateNormal];
    self.playbackrateButton.tag = 101;
    [self.playbackrateButton addTarget:self action:@selector(playbackrateButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.playbackrateButton];
}

-(void)playbackrateButtonAction:(UIButton *)button
{
    if (self.playbackrateButton.tag % 4 == 0) {
        self.player.currentPlaybackRate = 1.0;
        [self.playbackrateButton setTitle:@"倍速x1.0" forState:UIControlStateNormal];
    }
    if (self.playbackrateButton.tag % 4 == 1) {
        self.player.currentPlaybackRate = 1.5;
        [self.playbackrateButton setTitle:@"倍速x1.5" forState:UIControlStateNormal];
    }
    if (self.playbackrateButton.tag % 4 == 2) {
        self.player.currentPlaybackRate = 2.0;
        [self.playbackrateButton setTitle:@"倍速x2.0" forState:UIControlStateNormal];
    }
    if (self.playbackrateButton.tag % 4 == 3) {
        self.player.currentPlaybackRate = 0.5;
        [self.playbackrateButton setTitle:@"倍速x0.5" forState:UIControlStateNormal];
    }
    self.playbackrateButton.tag ++;
}

# pragma mark 清晰度
- (void)loadQualityView
{
    if (self.qualityButton == nil) {
        self.qualityButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }
    CGRect frame = CGRectZero;
    frame.origin.x =self.playbackButton.frame.origin.x + self.footerView.frame.size.width/2 - 10;
    frame.origin.y = self.playbackButton.frame.origin.y;
    frame.size.width = 50;
    frame.size.height = 30;
    self.qualityButton.frame = frame;
    
    self.qualityButton.backgroundColor = [UIColor clearColor];
    [self.qualityButton setTitle:self.currentQuality forState:UIControlStateNormal];
    self.qualityButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.qualityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.qualityButton addTarget:self action:@selector(qualityButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.qualityButton.tag = 103;
    [self.overlayView addSubview:self.qualityButton];
}

- (void)reloadQualityView
{
    if (self.isFullscreen == YES) {
        [self loadQualityView];
    }
}

- (void)qualityButtonAction:(UIButton *)button
{
    if (self.qualityButton.tag % self.qualityDescription.count == 0) {
        [self switchQuality:0];
        [self.qualityButton setTitle:@"清晰" forState:UIControlStateNormal];
    }
    if (self.qualityButton.tag % self.qualityDescription.count == 1) {
        [self switchQuality:1];
        [self.qualityButton setTitle:@"高清" forState:UIControlStateNormal];
    }
    if (self.qualityButton.tag % self.qualityDescription.count == 2) {
        [self switchQuality:2];
        [self.qualityButton setTitle:@"超清" forState:UIControlStateNormal];
    }
    self.qualityButton.tag ++;
    if (self.qualityDescription.count > 1) {
        [self.BigPauseButton removeFromSuperview];
    }
}

- (void)switchQuality:(NSInteger)index
{
    self.switchTime = self.player.currentPlaybackTime;
    NSInteger currentQualityIndex =  [[self.playUrls objectForKey:@"qualities"] indexOfObject:self.currentPlayUrl];
    
    NSDictionary *currentUrl = [[self.playUrls objectForKey:@"qualities"] objectAtIndex:0];
    self.player.sourceURL = [NSURL URLWithString:[currentUrl objectForKey:@"playurl"]];
    
    logdebug(@"index: %ld %ld", (long)index, (long)currentQualityIndex);
    if (index == currentQualityIndex) {
        //不需要切换
        logdebug(@"current quality: %ld %@", (long)currentQualityIndex, self.currentPlayUrl);
        return;
    }
    loginfo(@"switch %@ -> %@", self.currentPlayUrl, [[self.playUrls objectForKey:@"qualities"] objectAtIndex:index]);
    self.isSwitchquality = YES;
    self.currentPlayUrl = [[self.playUrls objectForKey:@"qualities"] objectAtIndex:index];
    self.player.contentURL = [NSURL URLWithString:[self.currentPlayUrl objectForKey:@"playurl"]];
    [self.player swith_quality];
    
    [self resetPlayer];
}

# pragma mark 当前播放时间
- (void)loadCurrentPlaybackTimeLabel
{//视频当前播放时间
    CGRect frame = CGRectZero;
    if (self.isFullscreen == NO) {
        frame.origin.x = self.playbackButton.frame.origin.x + self.playbackButton.frame.size.width + 5;
        frame.origin.y = self.playbackButton.frame.origin.y + 5;
    }
    else{
        frame.origin.x = 10;
        frame.origin.y = self.footerView.frame.origin.y + 9;
    }
    frame.size.width = 40;
    frame.size.height = 20;
    
    self.currentPlaybackTimeLabel.frame = frame;
    self.currentPlaybackTimeLabel.text = @"00:00:00";
    self.currentPlaybackTimeLabel.textColor = [UIColor whiteColor];
    self.currentPlaybackTimeLabel.font = [UIFont systemFontOfSize:8];
    self.currentPlaybackTimeLabel.backgroundColor = [UIColor clearColor];
    [self.overlayView addSubview:self.currentPlaybackTimeLabel];
    logdebug(@"currentPlaybackTimeLabel frame: %@", NSStringFromCGRect(self.currentPlaybackTimeLabel.frame));
}

# pragma mark 视频总时间
- (void)loadDurationLabel
{//视频总时间label
    CGRect frame = CGRectZero;
    if (self.isFullscreen == NO) {
        frame.origin.x = self.durationSlider.frame.origin.x + self.durationSlider.frame.size.width + 5;
        frame.origin.y = self.playbackButton.frame.origin.y + 5;
    }else{
        frame.origin.x = self.footerView.frame.size.width - 50 - 40;
        frame.origin.y = self.footerView.frame.origin.y + 9;
    }
    frame.size.width = 40;
    frame.size.height = 20;

    self.durationLabel.frame = frame;
    self.durationLabel.text = @"00:00:00";
    self.durationLabel.textColor = [UIColor whiteColor];
    self.durationLabel.backgroundColor = [UIColor clearColor];
    self.durationLabel.font = [UIFont systemFontOfSize:8];
    
    [self.overlayView addSubview:self.durationLabel];
}

# pragma mark 时间滑动条
- (void)loadPlaybackSlider
{
    CGRect frame = CGRectZero;
    if (self.isFullscreen == NO) {
        frame.origin.x = self.currentPlaybackTimeLabel.frame.origin.x + self.currentPlaybackTimeLabel.frame.size.width ;
        frame.origin.y = self.playbackButton.frame.origin.y;
    }else{
        frame.origin.x = self.footerView.frame.origin.x + 10 + 10 + 40;
        frame.origin.y = self.footerView.frame.origin.y + 4;
    }
    frame.size.width = self.footerView.frame.size.width - 60 - 100;
    frame.size.height = 30;
    
    self.durationSlider.frame =frame;
    
    [self.overlayView addSubview:self.durationSlider];
    logdebug(@"self.durationSlider.frame: %@", NSStringFromCGRect(self.durationSlider.frame));
    
}
-(void)durationSlidersetting
{
    self.durationSlider.minimumValue = 0.0f;
    self.durationSlider.maximumValue = 1.0f;
    self.durationSlider.value = 0.0f;
    self.durationSlider.continuous = NO;
    [self.durationSlider setMaximumTrackImage:[UIImage imageNamed:@"player-slider-inactive"]
                                     forState:UIControlStateNormal];
    [self.durationSlider setMinimumTrackImage:[UIImage imageNamed:@"slider"]
                                     forState:UIControlStateNormal];
    [self.durationSlider setThumbImage:[UIImage imageNamed:@"player-slider-handle"]
                              forState:UIControlStateNormal];
    [self.durationSlider addTarget:self action:@selector(durationSliderMoving:) forControlEvents:UIControlEventValueChanged];
    [self.durationSlider addTarget:self action:@selector(durationSliderDone:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)durationSliderMoving:(UISlider *)slider
{
    logdebug(@"self.durationSlider.value: %ld", (long)slider.value);
    
    self.player.seekStartTime = self.player.currentPlaybackTime;
    self.player.currentPlaybackTime = slider.value;
    self.currentPlaybackTimeLabel.text = [DWTools formatSecondsToString:self.player.currentPlaybackTime];
    self.historyPlaybackTime = self.player.currentPlaybackTime;
}
- (void)durationSliderDone:(UISlider *)slider
{
    logdebug(@"slider touch");
    
    self.currentPlaybackTimeLabel.text = [DWTools formatSecondsToString:self.player.currentPlaybackTime];
    self.historyPlaybackTime = self.player.currentPlaybackTime;
    
    if (self.player.playbackState == MPMoviePlaybackStatePaused) {
        self.player.playaction = @"unbuffereddrag";
    }
    else{
        self.player.playaction = @"buffereddrag";
    }
        [self.player drag_action];
    
        [self.player play_action];
}
# pragma mark - 其它控件

# pragma mark 屏幕锁
-(void)loadLockButton
{
    if (!self.lockButton) {
        self.lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    CGRect frame = CGRectZero;
    frame.origin.x = 20;
    frame.origin.y = self.overlayView.frame.size.height/2 - 20;
    frame.size.width = 40;
    frame.size.height = 40;

    self.lockButton.frame = frame;
    self.lockButton.backgroundColor = [UIColor clearColor];
    [self.lockButton setImage:[UIImage imageNamed:@"unlock_ic"] forState:UIControlStateNormal];
    [self.lockButton setImage:[UIImage imageNamed:@"lock_ic"] forState:UIControlStateSelected];
    [self.lockButton addTarget:self action:@selector(lockScreenAction:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.overlayView addSubview:self.lockButton];
    
}
-(void)lockScreenAction:(UIButton *)button
{
    self.lockButton.selected = !self.lockButton.selected;
    
    if (self.lockButton.selected == YES) {
        self.isLock = YES;
        [self hiddenAllView];
        [self loadTipLabelview];
        self.tipLabel.text = @"屏幕已锁定";
        self.tipHiddenSeconds = 2;
    }
    else{
        [self showBasicViews];
        self.isLock = NO;
        [self loadTipLabelview];
        self.tipLabel.text = @"屏幕已解锁";
        self.tipHiddenSeconds = 2;
    }
}

# pragma mark 播放状态提示
- (void)loadVideoStatusLabel
{
    CGRect frame = CGRectZero;
    frame.size.height = 40;
    frame.size.width = 100;
    frame.origin.x = self.overlayView.frame.size.width/2 - frame.size.width/2;
    frame.origin.y = self.overlayView.frame.size.height/2 - frame.size.height/2;
    
    self.videoStatusLabel.frame = frame;
    if (self.pausebuttonClick) {
        self.videoStatusLabel.text = @"暂停";
    }else{
        self.videoStatusLabel.text = @"正在加载";
    }
    self.videoStatusLabel.textAlignment = UITextAlignmentCenter;
    self.videoStatusLabel.textColor = [UIColor whiteColor];
    self.videoStatusLabel.backgroundColor = [UIColor clearColor];
    self.videoStatusLabel.font = [UIFont systemFontOfSize:16];
    [self.overlayView addSubview:self.videoStatusLabel];
}
-(void)loadBigPauseButton
{
    CGRect frame = CGRectZero;
    frame.size.height = 100;
    frame.size.width = 100;
    frame.origin.x = self.overlayView.frame.size.width/2 - frame.size.width/2;
    frame.origin.y = self.overlayView.frame.size.height/2 - frame.size.height/2;
    if (!self.BigPauseButton) {
        self.BigPauseButton = [[UIButton alloc]init];
    }
    self.BigPauseButton.frame = frame;
    [self.BigPauseButton setImage:[UIImage imageNamed:@"big_stop_ic"] forState:UIControlStateNormal];
    [self.BigPauseButton addTarget:self action:@selector(playbackButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.BigPauseButton.hidden = NO;
    [self.overlayView addSubview:self.BigPauseButton];
}
-(void)loadTipLabelview
{
    CGRect frame = CGRectZero;
    frame.size.height = 40;
    frame.size.width = 100;
    frame.origin.x = self.overlayView.frame.size.width/2 - frame.size.width/2;
    frame.origin.y = self.overlayView.frame.size.height/2 - frame.size.height/2 + 30;

    self.tipLabel.frame = frame;
    self.tipLabel.textAlignment = UITextAlignmentCenter;
    self.tipLabel.adjustsFontSizeToFitWidth = YES;
    self.tipLabel.textColor = [UIColor whiteColor];
    self.tipLabel.backgroundColor = [UIColor clearColor];
    self.tipLabel.hidden = NO;
    [self.overlayView addSubview:self.tipLabel];
}
#pragma mark - 控件隐藏 & 显示
- (void)hiddenAllView
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.backButton.hidden = YES;
    self.downloadButton.hidden = YES;
    self.menuButton.hidden = YES;
    self.subtitleButton.hidden = YES;
    self.qualityButton.hidden = YES;
    self.playbackrateButton.hidden = YES;
    self.screenSizeButton.hidden = YES;
    self.selectvideoButton.hidden = YES;
    self.playbackButton.hidden = YES;
    self.lastButton.hidden = YES;
    self.nextButton.hidden = YES;
    self.currentPlaybackTimeLabel.hidden = YES;
    self.durationLabel.hidden = YES;
    self.durationSlider.hidden = YES;
    self.switchScrBtn.hidden = YES;
    self.headerView.hidden = YES;
    self.footerView.hidden = YES;
    self.hiddenAll = YES;
    if (!self.isLock) {
        self.lockButton.hidden = YES;
    }
}

- (void)showBasicViews
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.backButton.hidden = NO;
    self.downloadButton.hidden = NO;
    self.menuButton.hidden = NO;
    self.subtitleButton.hidden = NO;
    self.qualityButton.hidden = NO;
    self.playbackrateButton.hidden = NO;
    self.screenSizeButton.hidden = NO;
    self.playbackButton.hidden = NO;
    self.selectvideoButton.hidden = NO;
    self.lastButton.hidden = NO;
    self.nextButton.hidden = NO;
    self.currentPlaybackTimeLabel.hidden = NO;
    self.durationLabel.hidden = NO;
    self.durationSlider.hidden = NO;
    self.switchScrBtn.hidden = NO;
    self.lockButton.hidden = NO;
    self.headerView.hidden = NO;
    self.footerView.hidden = NO;
    self.hiddenAll = NO;
    if (!self.isFullscreen) {
        self.menuButton.hidden = YES;
        self.nextButton.hidden = YES;
        self.lastButton.hidden = YES;
        self.selectvideoButton.hidden = YES;
        self.lockButton.hidden = YES;
    }
    if (self.videoLocalPath) {
        self.downloadButton.hidden = YES;
        self.qualityButton.hidden = YES;
        self.selectvideoButton.hidden = YES;
        self.lastButton.hidden = YES;
        self.nextButton.hidden = YES;
    }
}

# pragma mark - 手势识别 UIGestureRecognizerDelegate

-(void)handleSignelTap:(UIGestureRecognizer*)gestureRecognizer
{
    if (!self.isLock) {
        if (self.hiddenAll) {
            [self showBasicViews];
            self.hiddenDelaySeconds = 10;
            
        } else {
            [self hiddenAllView];
            self.hiddenDelaySeconds = 0;
        }
    }
    else{
        if (self.lockButton.hidden) {
            self.lockButton.hidden = NO;
            self.hiddenDelaySeconds = 10;
        }
        else{
            self.lockButton.hidden = YES;
            self.hiddenDelaySeconds = 0;
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == self.signelTap) {
        if ([touch.view isKindOfClass:[UIButton class]]) {
            return NO;
        }
        if ([touch.view isKindOfClass:[DWTableView class]]) {
            return NO;
        }
        if ([touch.view isKindOfClass:[UISlider class]]) {
            return NO;
        }
        if ([touch.view isKindOfClass:[UIImageView class]]) {
            return NO;
        }
        if ([touch.view isKindOfClass:[UITableView class]]) {
            return NO;
        }
        if ([touch.view isKindOfClass:[UITableViewCell class]]) {
            return NO;
        }
        // UITableViewCellContentView => UITableViewCell
        if([touch.view.superview isKindOfClass:[UITableViewCell class]]) {
            return NO;
        }
        // UITableViewCellContentView => UITableViewCellScrollView => UITableViewCell
        if([touch.view.superview.superview isKindOfClass:[UITableViewCell class]]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark 手势调节
- (void)touchesBeganWithPoint:(CGPoint)point {
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是亮度，右边是音量
    if (self.startPoint.x <= self.overlayView.frame.size.width / 2.0) {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    } else {
        //音/量
        self.startVB = self.volumeViewSlider.value;
    }
    //方向置为无
    self.direction = DirectionNone;
    //记录当前视频播放的进度
    self.startVideoRate = self.player.currentPlaybackTime / self.player.duration;
}

- (void)touchesEndWithPoint:(CGPoint)point {
    if (self.direction == DirectionLeftOrRight) {
        self.player.currentPlaybackTime = self.currentRate * self.player.duration;
    }
}

- (void)touchesMoveWithPoint:(CGPoint)point {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    //分析出用户滑动的方向
    if (self.direction == DirectionNone) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = DirectionLeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = DirectionUpOrDown;
        }
    }
    
    if (self.direction == DirectionNone) {
        return;
    } else if (self.direction == DirectionUpOrDown) {
        //音量和亮度
        if (self.startPoint.x <= self.overlayView.frame.size.width / 2.0) {
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
            }
        } else {
            //音量
            if (panPoint.y < 0) {
                //增大音量
                [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }
            } else {
                //减少音量
                [self.volumeViewSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
        }
    } else if (self.direction == DirectionLeftOrRight ) {
        //进度
        CGFloat rate = self.startVideoRate + (panPoint.x / 30.0 / 80.0);
        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        self.currentRate = rate;
    }
}
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

# pragma mark - 播放视频
- (void)loadPlayUrls
{
    self.player.videoId = self.videoId;
    self.player.timeoutSeconds = 10;
    
    __weak DWCustomPlayerViewController *blockSelf = self;
    self.player.failBlock = ^(NSError *error) {
        loginfo(@"error: %@", [error localizedDescription]);
        blockSelf.videoStatusLabel.hidden = NO;
        blockSelf.videoStatusLabel.text = @"加载失败";
    };
    
    self.player.getPlayUrlsBlock = ^(NSDictionary *playUrls) {
        // [必须]判断 status 的状态，不为"0"说明该视频不可播放，可能正处于转码、审核等状态。
        NSNumber *status = [playUrls objectForKey:@"status"];
       
            if (status == nil || [status integerValue] != 0) {
                NSString *message = [NSString stringWithFormat:@"%@ %@:%@",
                                     blockSelf.videoId,
                                     [playUrls objectForKey:@"status"],
                                     [playUrls objectForKey:@"statusinfo"]];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
        blockSelf.playUrls = playUrls;
        
        [blockSelf resetViewContent];
    };
    [self.player startRequestPlayInfo];
}

# pragma mark - 根据播放url更新涉及的视图

- (void)resetViewContent
{
    // 获取默认清晰度播放url
    NSNumber *defaultquality = [self.playUrls objectForKey:@"defaultquality"];
    
    for (NSDictionary *playurl in [self.playUrls objectForKey:@"qualities"]) {
        if (defaultquality == [playurl objectForKey:@"quality"]) {
            self.currentPlayUrl = playurl;
            break;
        }
    }
    
    if (!self.currentPlayUrl) {
        self.currentPlayUrl = [[self.playUrls objectForKey:@"qualities"] objectAtIndex:0];
    }
    loginfo(@"currentPlayUrl: %@", self.currentPlayUrl);
    
    if (self.videoId) {
        [self resetQualityView];
    }
    [self.player prepareToPlay];

    [self.player play];
    
    self.player.shouldAutoplay = YES;
    logdebug(@"play url: %@", self.player.originalContentURL);
}

- (void)resetQualityView
{
    self.qualityDescription = [self.playUrls objectForKey:@"qualityDescription"];
    
    // 设置当前清晰度
    NSNumber *defaultquality = [self.playUrls objectForKey:@"defaultquality"];
    
    for (NSDictionary *playurl in [self.playUrls objectForKey:@"qualities"]) {
        if (defaultquality == [playurl objectForKey:@"quality"]) {
            self.currentQuality = [playurl objectForKey:@"desp"];
            break;
        }
    }
    // 由于每个视频的清晰度种类不同，所以这里需要重新加载
    [self reloadQualityView];
}

- (void)resetPlayer
{
    self.videoStatusLabel.hidden = NO;
    self.videoStatusLabel.text = @"正在加载";
    [self.player prepareToPlay];
    [self.player play];
    logdebug(@"play url: %@", self.player.originalContentURL);
}

# pragma mark - 播放本地文件
- (void)playLocalVideo
{
    self.playUrls = [NSDictionary dictionaryWithObject:self.videoLocalPath forKey:@"playurl"];
    self.player.contentURL = [[NSURL alloc] initFileURLWithPath:self.videoLocalPath];
    
    [self.player prepareToPlay];
    [self.player play];
    logdebug(@"play url: %@", self.player.originalContentURL);
}

# pragma mark - MPMoviePlayController Notifications
- (void)addObserverForMPMoviePlayController
{
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // MPMovieDurationAvailableNotification
    [notificationCenter addObserver:self selector:@selector(moviePlayerDurationAvailable) name:MPMovieDurationAvailableNotification object:self.player];
    
    // MPMovieNaturalSizeAvailableNotification
    
    // MPMoviePlayerLoadStateDidChangeNotification
    [notificationCenter addObserver:self selector:@selector(moviePlayerLoadStateDidChange) name:MPMoviePlayerLoadStateDidChangeNotification object:self.player];
    
    // MPMoviePlayerPlaybackDidFinishNotification
    [notificationCenter addObserver:self selector:@selector(moviePlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.player];
    
    // MPMoviePlayerPlaybackStateDidChangeNotification
    [notificationCenter addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.player];
    
    // MPMoviePlayerReadyForDisplayDidChangeNotification
}

- (void)moviePlayerDurationAvailable
{
    self.durationLabel.text = [DWTools formatSecondsToString:self.player.duration];
    self.currentPlaybackTimeLabel.text = [DWTools formatSecondsToString:0];
	self.durationSlider.minimumValue = 0.0;
    self.durationSlider.maximumValue = self.player.duration;
    logdebug(@"seconds %f maximumValue %f %@", self.player.duration, self.durationSlider.maximumValue, self.durationLabel.text);
}

- (void)moviePlayerLoadStateDidChange
{
    switch (self.player.loadState) {
        case MPMovieLoadStatePlayable:
            // 可播放
            logdebug(@"%@ playable", self.player.originalContentURL);
            self.videoStatusLabel.hidden = YES;
            if (_videoId) {
                if (self.player.playNum < 2) {
                    [self.player first_load];
                    self.player.playNum ++;
                    if (!_adPlay && !_isSwitchquality) {
                        [self readNSUserDefaults];
                    }
                }
                if (_isSwitchquality) {
                    self.player.currentPlaybackTime = self.switchTime;
                }
            }
            break;
            
        case MPMovieLoadStatePlaythroughOK:
            // 状态为缓冲几乎完成，可以连续播放
            logdebug(@"%@ PlaythroughOK", self.player.originalContentURL);
            self.videoStatusLabel.hidden = YES;
            if (_videoId) {
                if (self.player.playNum < 2) {
                    [self.player first_load];
                    self.player.playNum ++;
                    if (!_adPlay && !_isSwitchquality) {
                        [self readNSUserDefaults];
                    }
                }
                if (_isSwitchquality) {
                    self.player.currentPlaybackTime = self.switchTime;
                }
            }
            break;
            
        default:
            break;
    }
}

- (void)moviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    logdebug(@"accessLog %@", self.player.accessLog);
    logdebug(@"errorLog %@", self.player.errorLog);
    NSNumber *n = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    switch ([n intValue]) {
        case MPMovieFinishReasonPlaybackEnded:
        {
            logdebug(@"PlaybackEnded");
            self.videoStatusLabel.hidden = YES;
            if (_adPlay && _playMode) {
                //处理片头广告视频轮播逻辑
                if (_adInfo.ad.count == 1) {
                    self.player.contentURL = [NSURL URLWithString:_materialUrl];
                    [self.player play];
                }
                if (_adInfo.ad.count > 1) {
                    if (_adNum <= _adInfo.ad.count - 2) {
                        _adNum ++;
                        [self playAdmovie];
                    }
                    else{
                        _adNum = 0;
                        [self playAdmovie];
                    }
                }
            }
            else {
                //进度记忆清零
                if (self.videoId) {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:_videoId];
                }else if (self.videoLocalPath)
                {
                    [[NSUserDefaults standardUserDefaults]removeObjectForKey:_videoLocalPath];
                }
                [[NSUserDefaults standardUserDefaults]synchronize];
                
                [self nextButtonAction:self.nextButton];
            }
            break;
        }
        case MPMovieFinishReasonPlaybackError:
            logdebug(@"PlaybackError");
            self.videoStatusLabel.hidden = NO;
            self.videoStatusLabel.text = @"加载失败";
            break;
        case MPMovieFinishReasonUserExited:
            logdebug(@"ReasonUserExited");
            break;
        default:
            break;
    }
}

- (void)moviePlayerPlaybackStateDidChange
{
    logdebug(@"playbackState: %ld", (long)self.player.playbackState);
    
    switch ([self.player playbackState]) {
        case MPMoviePlaybackStateStopped:
        {   logdebug(@"movie stopped");
            [self.playbackButton setImage:[UIImage imageNamed:@"player-playbutton"] forState:UIControlStateNormal];
            break;
        }
        case MPMoviePlaybackStatePlaying:
        {
            [self.playbackButton setImage:[UIImage imageNamed:@"player-pausebutton"] forState:UIControlStateNormal];
            logdebug(@"movie playing");
            self.videoStatusLabel.hidden = YES;
            self.player.playaction = @"buffereddrag";
            if (_videoId) {
                if (self.player.playNum >1 && self.player.isReplay == NO) {
                    [self.player replay];
                }
            }
            break;
        }
        case MPMoviePlaybackStatePaused:
        {
            [self.playbackButton setImage:[UIImage imageNamed:@"player-playbutton"] forState:UIControlStateNormal];
            logdebug(@"movie paused");
            self.videoStatusLabel.hidden = NO;
            self.player.action++;
            self.player.playaction = @"unbuffereddrag";
            if (_videoId) {
                if (self.player.playableDuration < 5 && self.player.playNum >1 && self.player.sourceURL==nil) {
                    [self.player playlog];
                    
                    if (self.player.action == 1 || self.player.action == 3) {
                        [self.player playlog_php];
                    }
                }
            }
            if (self.pausebuttonClick) {
                self.videoStatusLabel.hidden = YES;
            }
            else{
                self.videoStatusLabel.text = @"正在加载";
            }
            break;
        }
        case MPMoviePlaybackStateSeekingForward:
            logdebug(@"movie seekingForward");
            self.videoStatusLabel.hidden = YES;
            break;
            
        case MPMoviePlaybackStateSeekingBackward:
            logdebug(@"movie seekingBackward");
            self.videoStatusLabel.hidden = YES;
            break;
            
        default:
            break;
    }
}

# pragma mark - 记录播放位置

-(void)saveNsUserDefaults
{
    //记录退出时播放信息
    NSTimeInterval time = self.player.currentPlaybackTime;
    long long dTime = [[NSNumber numberWithDouble:time] longLongValue];
    NSString *curTime = [NSString stringWithFormat:@"%llu",dTime];
    self.playPosition = [NSDictionary dictionaryWithObjectsAndKeys:
                         curTime,@"playbackTime",
                         nil];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (self.videoId) {
        //在线视频
        [userDefaults setObject:self.playPosition forKey:_videoId];
        
    } else if (self.videoLocalPath) {
        //本地视频
        [userDefaults setObject:self.playPosition forKey:_videoLocalPath];
    }
    //同步到磁盘
    [userDefaults synchronize];
}
-(void)readNSUserDefaults
{
    NSUserDefaults *userDefaultes = [NSUserDefaults standardUserDefaults];
    if (self.videoId) {
        NSDictionary *playPosition = [userDefaultes dictionaryForKey:_videoId];
        self.player.currentPlaybackTime = [[playPosition valueForKey:@"playbackTime"] floatValue];

    }else if (self.videoLocalPath){
        NSDictionary *playPosition = [userDefaultes dictionaryForKey:_videoLocalPath];
        self.player.currentPlaybackTime = [[playPosition valueForKey:@"playbackTime"] floatValue];
    }
}

# pragma mark - timer
- (void)addTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
}

- (void)removeTimer
{
    [self.timer invalidate];
}

- (void)timerHandler
{
    self.currentPlaybackTimeLabel.text = [DWTools formatSecondsToString:self.player.currentPlaybackTime];
    self.durationLabel.text = [DWTools formatSecondsToString:self.player.duration];
    self.durationSlider.value = self.player.currentPlaybackTime;
    self.historyPlaybackTime = self.player.currentPlaybackTime;
    if (!self.tipLabel.hidden) {
        self.tipHiddenSeconds --;
        if (self.tipHiddenSeconds == 0) {
            self.tipLabel.hidden = YES;
        }
    }
    
    if (!self.hiddenAll) {
        if (self.hiddenDelaySeconds > 0) {
            if (self.hiddenDelaySeconds == 1) {
                [self hiddenAllView];
            }
            self.hiddenDelaySeconds--;
        }
    }
    self.movieSubtitleLabel.text = [self.mediaSubtitle searchWithTime:self.player.currentPlaybackTime];
}

- (void)removeAllObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
