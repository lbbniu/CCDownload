#import "DWUploadViewController.h"
#import "DWUploadInfoSetupViewController.h"
#import "DWUploadTableViewCell.h"
#import "DWUploadItem.h"
#import "DWTools.h"

#import <MobileCoreServices/MobileCoreServices.h>
#include<AssetsLibrary/AssetsLibrary.h>

@interface DWUploadViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic)DWUploadInfoSetupViewController *uploadInfoSetupViewController;
@property (strong, nonatomic)DWUploadItems *uploadItems;
@property (strong, nonatomic)NSString *videoPath;

@property (strong, nonatomic)UITableView *tableView;

/**
 *  定时器用来处理处于wait的任务。
 */
@property (strong, nonatomic)NSTimer *timer;

@end

@implementation DWUploadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"上传";
        
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"上传"
                                                        image:[UIImage imageNamed:@"tabbar-upload"]
                                                          tag:0];
        if (IsIOS7) {
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar-upload-selected"];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
    
    self.navigationItem.rightBarButtonItem = addItem;
    
    [self loadUploadItems];
    
    CGRect frame = [[UIScreen mainScreen] bounds];
    if (!IsIOS7) {
        // 20 为电池栏高度
        // 44 为导航栏高度
        // 49 为标签栏的高度
        frame.size.height = frame.size.height - 20 - 44 - 49;
    }
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 96;
    [self.view addSubview:self.tableView];
    logdebug(@"self.view.frame: %@ self.tableView.frame: %@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.tableView.frame));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addTimer];
    
    [self addVideoFileToUpload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self removeTimer];
}

# pragma mark - processer

- (void)addAction:(UIBarButtonItem *)item
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"选择"
                                        delegate:self
                               cancelButtonTitle:nil
                          destructiveButtonTitle:@"取消"
                               otherButtonTitles:@"从相册选择", nil];
    
    [sheet showInView:self.view];
}

#pragma mark - UIActionSheetDelegate

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSUInteger sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    NSLog(@"buttonIndex: %ld", (long)buttonIndex);
    
    switch (buttonIndex) {
        case 0:
            // 取消选择
            return;
            
        case 1:
            // 从相册中选择
            break;
            
        default:
            return;
            break;
    }
    
    DWVideoCompressController *imagePicker = [[DWVideoCompressController alloc] initWithQuality: DWUIImagePickerControllerQualityTypeMedium andSourceType:DWUIImagePickerControllerSourceTypePhotoLibrary andMediaType:DWUIImagePickerControllerMediaTypeMovieAndImage];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:NO completion:^{}];
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    loginfo(@"info: %@", info);
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (![mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"警告"
                                                        message:@"请选择一个视频文件"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    self.videoPath = [videoURL path];
    loginfo(@"moviePath: %@", self.videoPath);
    
    // 跳转到 设置视频标题、标签、简介等信息界面。
    DWUploadInfoSetupViewController *viewController = [[DWUploadInfoSetupViewController alloc] init];
    
    [self.navigationController pushViewController:viewController animated:NO];
    self.uploadInfoSetupViewController = viewController;
    
	[picker dismissViewControllerAnimated:NO completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:NO completion:^{}];
}

#pragma mark - UINavigationControllerDelegate

# pragma mark - processer
- (void)addVideoFileToUpload
{
    if (self.uploadInfoSetupViewController == nil
        || self.uploadInfoSetupViewController.isCancel) {
        self.uploadInfoSetupViewController = nil;
        self.videoPath = nil;
        
        return;
    }
    
    NSError *error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    
    NSString *videoTitle = [self.uploadInfoSetupViewController videoTitle];
    NSString *videoTag = [self.uploadInfoSetupViewController videoTag];
    NSString *videoDescription = [self.uploadInfoSetupViewController videoDescription];
    
    DWUploadItem *item = [[DWUploadItem alloc] init];
    item.videoUploadStatus = DWUploadStatusWait;
    item.videoPath = self.videoPath;
    item.videoTitle = videoTitle;
    item.videoTag = videoTag;
    item.videoDescripton = videoDescription;
    item.videoUploadProgress = 0.0f;
    item.videoUploadedSize = 0;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.videoPath]) {
        item.videoUploadStatus = DWUploadStatusLoadLocalFileInvalid;
        goto done;
    }
    
    // 文件不存在则不设置
    item.videoThumbnailPath = [NSString stringWithFormat:@"%@/%@.png", documentDirectory, videoTitle];
    [DWTools saveVideoThumbnailWithVideoPath:self.videoPath toFile:item.videoThumbnailPath Error:&error];
    if (error) {
        item.videoUploadStatus = DWUploadStatusLoadLocalFileInvalid;
        loginfo(@"save thumbnail %@ failed: %@", self.videoPath, [error localizedDescription]);
        goto done;
    }
    
    item.videoFileSize = [DWTools getFileSizeWithPath:self.videoPath Error:&error];
    if (error) {
        item.videoUploadStatus = DWUploadStatusLoadLocalFileInvalid;
        loginfo(@"get videoPath %@ failed: %@", self.videoPath, [error localizedDescription]);
        item.videoFileSize = 0;
        goto done;
    }
    
done:
    
    [self.uploadItems.items addObject:item];
    logdebug(@"add item: %@", item);
    logdebug(@"self.uploadItems.items: %@", self.uploadItems.items);
    
    [self.tableView reloadData];
    
    // 清空数据
    self.uploadInfoSetupViewController = nil;
    self.videoPath = nil;
}

- (void)loadUploadItems
{
    self.uploadItems = DWAPPDELEGATE.uploadItems;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.uploadItems.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"DWUploadViewCorollerCellId";
    
    DWUploadTableViewCell *cell = (DWUploadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil){
        cell = [[DWUploadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        [cell.statusButton addTarget:self action:@selector(videoUploadStatusButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.statusButton.tag = indexPath.row;
    }
    
    DWUploadItem *item = self.uploadItems.items[indexPath.row];
    [cell setupCell:item];
    
    // 重置 uploader 的block块。
    if (item.uploader) {
        [self setUploadBlockWithItem:item andCell:cell];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        logdebug(@"deleted item: %@", self.uploadItems.items[indexPath.row]);
        [self.uploadItems removeObjectAtIndex:indexPath.row];
        
        [tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate

#pragma mark - upload

- (void)videoUploadStatusButtonAction:(UIButton *)button
{
    DWUploadTableViewCell* cell = nil;

    NSInteger indexPath = button.tag;
    NSIndexPath *index = [NSIndexPath indexPathForRow:indexPath inSection:0];
    cell = (DWUploadTableViewCell *)[self.tableView cellForRowAtIndexPath:index];
        
    DWUploadItem *item = [self.uploadItems.items objectAtIndex:indexPath];
    switch (item.videoUploadStatus) {
        case DWUploadStatusWait:
            // 状态转为 开始上传
            if (DWAPPDELEGATE.uploadItems.isBusy) {
                break;
            }
            DWAPPDELEGATE.uploadItems.isBusy = YES;
            
            [self videoUploadStartWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusStart:
            // 状态转为 暂停上传
            DWAPPDELEGATE.uploadItems.isBusy = NO;
            [self videoUploadPauseWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusUploading:
            // 状态转为 暂停上传
            DWAPPDELEGATE.uploadItems.isBusy = NO;
            [self videoUploadPauseWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusPause:
            // 状态转为 开始上传
            if (DWAPPDELEGATE.uploadItems.isBusy) {
                break;
            }
            DWAPPDELEGATE.uploadItems.isBusy = YES;
            
            [self videoUploadResumeWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusResume:
            // 状态转为 暂停上传
            DWAPPDELEGATE.uploadItems.isBusy = NO;
            [self videoUploadPauseWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusLoadLocalFileInvalid:
            // 报警 告知用户 "本地文件不存在，删除任务重新添加文件"
            DWAPPDELEGATE.uploadItems.isBusy = NO;
            [self videoUploadFailedAlert:@"本地文件不存在，删除任务重新添加文件"];
            break;
            
        case DWUploadStatusFail:
            // 状态转为 继续上传
            if (DWAPPDELEGATE.uploadItems.isBusy) {
                break;
            }
            DWAPPDELEGATE.uploadItems.isBusy = YES;
            [self videoUploadResumeWithItem:item andCell:cell];
            break;
            
        case DWUploadStatusFinish:
            // 在 DWUploadStatusStart 和 DWUploadStatusResume 状态中
            // 如果上传完成，则至 cell.statusButton.userInteractionEnabled = NO 不在接收交互事件。
            // 所以这里不需要做处理。
            break;
            
        default:
            break;
    }
}

- (void)videoUploadFailedAlert:(NSString *)info
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                    message:info
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    
    [alert show];
}

- (void)setUploadBlockWithItem:(DWUploadItem *)item andCell:(DWUploadTableViewCell *)cell
{
    DWUploader *uploader = item.uploader;
    
    uploader.progressBlock = ^(float progress, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        item.videoUploadProgress = progress;
        item.videoUploadedSize = totalBytesWritten;
        
        [cell updateCellProgress:item];
    };
    
    uploader.finishBlock = ^() {
        loginfo(@"finish");
        item.videoUploadStatus = DWUploadStatusFinish;
        [cell updateUploadStatus:item];
        
        DWAPPDELEGATE.uploadItems.isBusy = NO;
    };
    
    uploader.failBlock = ^(NSError *error) {
        loginfo(@"error: %@", [error localizedDescription]);
        item.uploader = nil;
        item.videoUploadStatus = DWUploadStatusFail;
        [cell updateUploadStatus:item];
        
        DWAPPDELEGATE.uploadItems.isBusy = NO;
    };
    
    uploader.pausedBlock = ^(NSError *error) {
        loginfo(@"error: %@", [error localizedDescription]);
        item.videoUploadStatus = DWUploadStatusPause;
        [cell updateUploadStatus:item];
        
        DWAPPDELEGATE.uploadItems.isBusy = NO;
    };
    
    uploader.videoContextForRetryBlock = ^(NSDictionary *videoContext) {
        loginfo(@"context: %@", videoContext);
        item.uploadContext = videoContext;
    };
}

- (void)videoUploadStartWithItem:(DWUploadItem *)item andCell:(DWUploadTableViewCell *)cell
{
    item.uploader = [[DWUploader alloc] initWithUserId:DWACCOUNT_USERID
                                                andKey:DWACCOUNT_APIKEY
                                   uploadVideoTitle:item.videoTitle
                                      videoDescription:item.videoDescripton
                                              videoTag:item.videoTag
                                             videoPath:item.videoPath
                                             notifyURL:@"http://www.bokecc.com/"];
    
    item.videoUploadStatus = DWUploadStatusUploading;
    [cell updateUploadStatus:item];
    
    DWUploader *uploader = item.uploader;
    
    uploader.timeoutSeconds = 20;
    
    [self setUploadBlockWithItem:item andCell:cell];
    
    [uploader start];
}

- (void)videoUploadResumeWithItem:(DWUploadItem *)item andCell:(DWUploadTableViewCell *)cell
{
    if (item.uploadContext) {
        if (!item.uploader) {
            item.uploader = [[DWUploader alloc] initWithVideoContext:item.uploadContext];
        }
        
        item.videoUploadStatus  = DWUploadStatusUploading;
        [cell updateUploadStatus:item];
        item.uploader.timeoutSeconds = 20;
        [self setUploadBlockWithItem:item andCell:cell];
        
        [item.uploader resume];
        
        return;
    }
    
    item.uploader = nil;
    [self videoUploadStartWithItem:item andCell:cell];
}

- (void)videoUploadPauseWithItem:(DWUploadItem *)item andCell:(DWUploadTableViewCell *)cell
{
    if (!item.uploader) {
        return;
    }
    
    [item.uploader pause];
    item.videoUploadStatus = DWUploadStatusPause;
    [cell updateUploadStatus:item];
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
    logdebug(@"self.uploadItems.item count: %ld", (long)self.uploadItems.items.count);
    if (DWAPPDELEGATE.uploadItems.isBusy) {
        logdebug(@"busy");
        return;
    }
    
    DWUploadItem *item = nil;
    NSInteger index = 0;
    for (item in self.uploadItems.items) {
        if (item.videoUploadStatus == DWUploadStatusWait) {
            break;
        }
        index++;
    }
    
    if (!item) {
        logdebug(@"queue is empty");
        return;
    }
    
    // 开始下载
    logdebug(@"upload start item: %@", item);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];

    DWUploadTableViewCell *cell = (DWUploadTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    logdebug(@"index: %ld %ld item: %@", (long)indexPath.section, (long)indexPath.row, item);
    
    DWAPPDELEGATE.uploadItems.isBusy = YES;
    [self videoUploadStartWithItem:item andCell:cell];
}
@end
