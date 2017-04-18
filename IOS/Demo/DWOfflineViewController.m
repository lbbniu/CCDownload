#import "DWOfflineViewController.h"
#import "DWDownloadItem.h"
#import "DWCustomPlayerViewController.h"
#import "DWDownloader.h"
#import "DWTableView.h"

#define DWDownloadingItemPlistFilename @"downloadingItems.plist"
#define DWDownloadFinishItemPlistFilename @"downloadFinishItems.plist"

@interface DWOfflineViewController ()

@property (strong, nonatomic)DWTableView *downloadFinishTableView;
@property (strong, nonatomic)DWTableView *downloadingTableView;
@property (strong, nonatomic)UISegmentedControl *segmentedControl;
@property (strong, nonatomic)DWDownloadItems *downloadFinishItems;
@property (strong, nonatomic)DWDownloadItems *downloadingItems;
@property (strong,nonatomic)DWDownloader *downloader;

/**
 *  定时器用来处理处于wait的任务。
 */
@property (strong, nonatomic)NSTimer *timer;

@end

@implementation DWOfflineViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"离线";
        
        [self addTimer];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadDownloadItems];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(loadDownloadItems) name:@"loadDownloadItems" object:nil];
    
    NSArray *titles = @[@"已完成", @"下载中"];
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:titles];
    
    self.segmentedControl.frame = CGRectMake(self.view.frame.size.width/2 - 150, 69, 300, 44);
    
    // 初始界面为："下载完成"
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl addTarget:self action:@selector(segmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.segmentedControl];
    logdebug(@"self.view.frame: %@ self.segmentedControl.frame: %@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.segmentedControl.frame));
    
    // 加载下载中tableView 和 下载已完成tableView
    [self loadTableView];
    
    self.downloadFinishTableView.hidden = NO;
    self.downloadingTableView.hidden = YES;
    
    [self addTask];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self removeTimer];
    //判断如果下载中列表没有视频的话 删除缓存目录防止缓存文件占内存
    if ([_downloadingItems.items count] == 0) {
        NSString *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        NSString *tmpPath = [NSString stringWithFormat:@"%@/flvs", pathDocuments];
        NSString *tmpPlist = [NSString stringWithFormat:@"%@/tmp.plist", pathDocuments];
//        NSString *path1 = [pathDocuments stringByAppendingPathComponent:DWDownloadingItemPlistFilename];
//        NSString *path2 = [pathDocuments stringByAppendingPathComponent:DWDownloadFinishItemPlistFilename];
        [[NSFileManager defaultManager]removeItemAtPath:tmpPath error:NULL];
        [[NSFileManager defaultManager]removeItemAtPath:tmpPlist error:NULL];
//        [[NSFileManager defaultManager]removeItemAtPath:path1 error:NULL];
//        [[NSFileManager defaultManager]removeItemAtPath:path2 error:NULL];
        NSArray *paths = [[NSFileManager defaultManager] subpathsAtPath:NSTemporaryDirectory()];
        for (NSString *filePath in paths)
        {
            if ([filePath rangeOfString:@"CFNetworkDownload"].length>0)
            {
                NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filePath];
                //tmp中的文件随时有可能给删除,移动到安全目录下防止被删除
                [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
            }
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"loadDownloadItems" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

# pragma mark - tableView

- (void)loadDownloadFinishTableView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.y = self.segmentedControl.frame.origin.y + self.segmentedControl.frame.size.height + 10;
    if (!IsIOS7) {
        frame.size.height = frame.size.height - self.segmentedControl.frame.size.height - 10 - 20 - 44;
        
    } else {
        frame.size.height = frame.size.height - frame.origin.y;
    }
    self.downloadFinishTableView = [[DWTableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.downloadFinishTableView.rowHeight = 80.0f;
    self.downloadFinishTableView.hidden = YES;
    logdebug(@"self.downloadFinishTableView.frame: %@", NSStringFromCGRect(self.downloadFinishTableView.frame));
    
    __weak DWOfflineViewController *blockSelf = self;
    
    self.downloadFinishTableView.tableViewNumberOfRowsInSection = ^NSInteger(UITableView *tableView, NSInteger section) {
        return blockSelf.downloadFinishItems.items.count;
    };
    
    self.downloadFinishTableView.tableViewCellForRowAtIndexPath = ^UITableViewCell*(UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *cellId = @"DWOfflineViewControllerCellId";
        
        DWDownloadItem *item = blockSelf.downloadFinishItems.items[indexPath.row];
        
        DWOfflineTableViewCell *cell = (DWOfflineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
        if(cell == nil){
            cell = [[DWOfflineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId downloadFinish:YES];
            // 为 DWUploadTableViewCell 的 statusButton 绑定方法
        }
        
        [cell.statusButton addTarget:blockSelf action:@selector(videoDownloadFinishStatusButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.statusButton.tag = indexPath.row;
        [cell setupCell:item];
        
        return cell;
    };
    
    self.downloadFinishTableView.numberOfSectionsInTableView = ^NSInteger(UITableView *tableView){
        return 1;
    };
    
    self.downloadFinishTableView.tableViewCanEditRowAtIndexPath = ^BOOL(UITableView *tableView, NSIndexPath *indexPath) {
        return YES;
    };
    
    self.downloadFinishTableView.tableViewCommitEditingStyleforRowAtIndexPath = ^(UITableView * tableView, UITableViewCellEditingStyle editingStyle, NSIndexPath *indexPath) {
        
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            DWDownloadItem *item = blockSelf.downloadFinishItems.items[indexPath.row];
            if (item.downloader) {
                [item.downloader pause];
            }
            loginfo(@"deleted item: %@", item);
            [blockSelf.downloadFinishItems removeObjectAtIndex:indexPath.row];
            [tableView reloadData];
        }
    };
    
    [self.downloadFinishTableView resetDelegate];
    [self.view addSubview:self.downloadFinishTableView];
}

- (void)loadDownloadingTableView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.y = self.segmentedControl.frame.origin.y + self.segmentedControl.frame.size.height + 10;
    if (!IsIOS7) {
        frame.size.height = frame.size.height - self.segmentedControl.frame.size.height - 10 - 20 - 44;
    } else {
        frame.size.height = frame.size.height - frame.origin.y;
    }
    self.downloadingTableView = [[DWTableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.downloadingTableView.rowHeight = 80.0f;
    self.downloadingTableView.hidden = YES;
    
    __weak DWOfflineViewController *blockSelf = self;
    
    self.downloadingTableView.tableViewNumberOfRowsInSection = ^NSInteger(UITableView *tableView, NSInteger section) {
        return blockSelf.downloadingItems.items.count;
    };
    
    self.downloadingTableView.tableViewCellForRowAtIndexPath = ^UITableViewCell*(UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *cellId = @"DWOfflineViewControllerCellId";
        
        DWDownloadItem *item = blockSelf.downloadingItems.items[indexPath.row];
        
        DWOfflineTableViewCell *cell = (DWOfflineTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
        if(cell == nil){
            cell = [[DWOfflineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
            // 为 DWUploadTableViewCell 的 statusButton 绑定方法
        }
        
        cell.statusButton.tag = indexPath.row;
        [cell.statusButton addTarget:blockSelf action:@selector(videoDownloadingStatusButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell setupCell:item];
        
        // 重置 downloader 的block块。
        if (item.downloader) {
            [blockSelf setDownloaderBlocksWithItem:item andCell:cell];
        }
        
        return cell;
    };
    
    self.downloadingTableView.numberOfSectionsInTableView = ^NSInteger(UITableView *tableView){
        return 1;
    };
    
    self.downloadingTableView.tableViewCanEditRowAtIndexPath = ^BOOL(UITableView *tableView, NSIndexPath *indexPath) {
        return YES;
    };
    
    self.downloadingTableView.tableViewCommitEditingStyleforRowAtIndexPath = ^(UITableView * tableView, UITableViewCellEditingStyle editingStyle, NSIndexPath *indexPath) {
        
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            DWDownloadItem *item = blockSelf.downloadingItems.items[indexPath.row];
            if (item.downloader) {
                [item.downloader pause];
            }
            logdebug(@"deleted item: %@", item);
            [blockSelf.downloadingItems removeObjectAtIndex:indexPath.row];
            [tableView reloadData];
        }
    };
    
    [self.downloadingTableView resetDelegate];
    [self.view addSubview:self.downloadingTableView];
}

- (void)loadTableView
{
    [self loadDownloadingTableView];
    [self loadDownloadFinishTableView];
}

# pragma mark - processer

- (void)loadDownloadItems
{
    self.downloadingItems = DWAPPDELEGATE.downloadingItems;
    self.downloadFinishItems = DWAPPDELEGATE.downloadFinishItems;
}

- (void)addTask
{
    
    if (!self.videoId) {
        return;
    }
    DWDownloadItem *item = nil;
    
    // 判断是否"下载完成"列表中
    for (item in self.downloadFinishItems.items) {
        if (!self.definition) {
            if ([item.videoId isEqualToString:self.videoId] && !item.definition) {
                self.segmentedControl.selectedSegmentIndex = 0;
                self.downloadFinishTableView.hidden = NO;
                self.downloadingTableView.hidden = YES;
                DWAPPDELEGATE.isDownloaded = YES;
                return;
            }
        } else {
            if ([item.videoId isEqualToString:self.videoId] && [item.definition isEqualToString:self.definition]) {
                self.segmentedControl.selectedSegmentIndex = 0;
                self.downloadFinishTableView.hidden = NO;
                self.downloadingTableView.hidden = YES;
                return;
            }
        }
    }
    
    self.segmentedControl.selectedSegmentIndex = 1;
    self.downloadFinishTableView.hidden = YES;
    self.downloadingTableView.hidden = NO;
    
    // 判断是否"正在下载"列表中
    for (item in self.downloadingItems.items) {
        if (!self.definition) {
            if ([item.videoId isEqualToString:self.videoId] && !item.definition) {
                DWAPPDELEGATE.isDownloaded = YES;
                return;
            }
        } else {
            if ([item.videoId isEqualToString:self.videoId] && [item.definition isEqualToString:self.definition]) {
                return;
            }
        }
    }
    
    item = [[DWDownloadItem alloc] init];
    item.videoId = self.videoId;
    item.videoDownloadStatus = DWDownloadStatusWait;
    
    if(self.definition) {
        item.definition = self.definition;
    }
    [self.downloadingItems.items addObject:item];
    [self.downloadingTableView reloadData];
    
    // 清空数据
    self.videoId = nil;
    self.definition = nil;
    DWAPPDELEGATE.isDownloaded = NO;
}

- (void)segmentedControlAction:(UISegmentedControl *)segment
{
    logdebug(@"%ld 被点击", (long)[segment selectedSegmentIndex]);
    if ([segment selectedSegmentIndex] == 0) { //已下载
        self.downloadFinishTableView.hidden = NO;
        self.downloadingTableView.hidden = YES;
        
    } else { // 下载中
        self.downloadFinishTableView.hidden = YES;
        self.downloadingTableView.hidden = NO;
    }
}

# pragma mark - download

- (void)videoDownloadFinishStatusButtonAction:(UIButton *)button
{
    NSInteger indexPath = button.tag;
    DWDownloadItem *item = [self.downloadFinishItems.items objectAtIndex:indexPath];
    
    DWCustomPlayerViewController *player = [[DWCustomPlayerViewController alloc] init];
    player.videoLocalPath = item.videoPath;
    
    player.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:player animated:NO];
}

- (void)videoDownloadingStatusButtonAction:(UIButton *)button
{
    DWOfflineTableViewCell *cell = nil;
    DWCustomPlayerViewController *player = nil;
    
    NSInteger indexPath = button.tag;
    NSIndexPath *index = [NSIndexPath indexPathForRow:indexPath inSection:0];
    cell = (DWOfflineTableViewCell *)[self.downloadingTableView cellForRowAtIndexPath:index];
    DWDownloadItem *item = [self.downloadingItems.items objectAtIndex:indexPath];
    
    switch (item.videoDownloadStatus) {
        case DWDownloadStatusWait:
            // 状态转为 开始下载
            [self videoDownloadStartWithItem:item andCell:cell];
            break;
            
        case DWDownloadStatusStart:
            // 状态转为 暂停下载
            [self videoDownloadPauseWithItem:item andCell:cell];
            break;
            
        case DWDownloadStatusDownloading:
            // 状态转为 暂停下载
            [self videoDownloadPauseWithItem:item andCell:cell];
            break;
            
        case DWDownloadStatusPause:
            // 状态转为 开始下载
            [self videoDownloadResumeWithItem:item andCell:cell];
            break;
            
        case DWDownloadStatusFail:
            // 状态转为 重新开始
            [self videoDownloadStartWithItem:item andCell:cell];
            break;
            
        case DWDownloadStatusFinish:
            // 播放本地视频
            player = [[DWCustomPlayerViewController alloc] init];
            player.videoLocalPath = item.videoPath;
            
            player.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:player animated:NO];
            
            break;
            
        default:
            break;
    }
}

- (void)setDownloaderBlocksWithItem:(DWDownloadItem *)item andCell:(DWOfflineTableViewCell *)cell
{
    DWDownloader *downloader = item.downloader;
    
    downloader.progressBlock = ^(float progress, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        item.videoDownloadedSize = totalBytesWritten;
        item.videoFileSize = totalBytesExpectedToWrite;
        item.videoDownloadProgress = (float)item.videoDownloadedSize/item.videoFileSize;
        NSLog(@"totalBytesWritten==%ld,totalBytesExpectedToWrite==%ld",(long)totalBytesWritten,(long)totalBytesExpectedToWrite);

        [cell updateCellProgress:item];
    };
    
    downloader.failBlock = ^(NSError *error) {
        item.videoDownloadStatus = DWDownloadStatusFail;
        [cell updateDownloadStatus:item];
        
        logerror(@"download fail %@", [error localizedDescription]);
        logerror(@"download fail %@", item);
    };
    
    downloader.finishBlock = ^() {
        item.videoDownloadStatus = DWDownloadStatusFinish;
        [cell updateDownloadStatus:item];
        [self.downloadingItems.items removeObject:item];
        [self.downloadFinishItems.items insertObject:item atIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.downloadingTableView reloadData];
            [self.downloadFinishTableView reloadData];
        });
        
        logdebug(@"download finish %@", item);
    };
}

- (void)videoDownloadStartWithItem:(DWDownloadItem *)item andCell:(DWOfflineTableViewCell *)cell
{
    // 更新下载状态
    item.videoDownloadStatus  = DWDownloadStatusStart;
    [cell updateDownloadStatus:item];
    
    // 开始下载
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    
    // DEMO_REPLACE_CODE_OFFLINE_EXTENSION_{
    /* 注意：
     若你所下载的 videoId 未启用视频加密功能，则保存的文件扩展名[必须]是 mp4，否则无法播放。
     若你所下载的 videoId 启用了视频加密功能，则保存的文件扩展名[必须]是 pcm，否则无法播放。
    */
    
    NSString *videoPath;
    
    if (!item.definition) {
        videoPath = [NSString stringWithFormat:@"%@/%@.mp4", documentDirectory, item.videoId];
    } else {
        videoPath = [NSString stringWithFormat:@"%@/%@-%@.mp4", documentDirectory, item.videoId, item.definition];
    }
    
    item.videoPath = videoPath;
    DWDownloader *downloader = [[DWDownloader alloc] initWithUserId:DWACCOUNT_USERID
                                                         andVideoId:item.videoId
                                                                key:DWACCOUNT_APIKEY
                                                     destinationPath:item.videoPath];
    item.downloader = downloader;
    item.videoDownloadStatus  = DWDownloadStatusDownloading;
    [cell updateDownloadStatus:item];
    
    downloader.timeoutSeconds = 20;
    
    [self setDownloaderBlocksWithItem:item andCell:cell];
    
    if (self.playUrl) {
        [downloader startWithUrlString:self.playUrl];
    } else {
        [downloader start];
    }
    
}

- (void)videoDownloadResumeWithItem:(DWDownloadItem *)item andCell:(DWOfflineTableViewCell *)cell
{
    if (item.downloader) {
        
        item.videoDownloadStatus = DWDownloadStatusDownloading;
        [cell updateDownloadStatus:item];
        
        [item.downloader resume];
        
        return;
    }
}

- (void)videoDownloadPauseWithItem:(DWDownloadItem *)item andCell:(DWOfflineTableViewCell *)cell
{
    if (!item.downloader) {
        return;
    }
    
    [item.downloader pause];
    item.videoDownloadStatus = DWDownloadStatusPause;
    [cell updateDownloadStatus:item];
}

# pragma mark - timer

- (void)addTimer
{
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerHandler) userInfo:nil repeats:YES];
    }
}

- (void)removeTimer
{
    [self.timer invalidate];
}

- (void)timerHandler
{
    
    DWDownloadItem *item = nil;
    NSInteger index = 0;
    for (item in self.downloadingItems.items) {
        if (item.videoDownloadStatus == DWDownloadStatusWait) {
            break;
        }
        index++;
    }
    
    if (!item) {
        return;
    }
    // 开始下载
    logdebug(@"download start item: %@", item);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    
    DWOfflineTableViewCell *cell = (DWOfflineTableViewCell *)[self.downloadingTableView cellForRowAtIndexPath:indexPath];
    logdebug(@"index: %ld %ld item: %@", (long)indexPath.section, (long)indexPath.row, item);
    
    [self videoDownloadStartWithItem:item andCell:cell];
}

@end
