#import "DWDownloadViewController.h"
#import "DWOfflineViewController.h"
#import "DWDownloadTableViewCell.h"

@interface DWDownloadViewController () <UITableViewDataSource, UITableViewDelegate>
{
    DWDownloader *downloader;
    NSString *videoid;
}
@property (strong, nonatomic)UITableView *tableView;
@property (strong, nonatomic)NSArray *videoIds;
@property (strong, nonatomic)NSDictionary *playInfo;

@end

@implementation DWDownloadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"下载";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"下载"
                                                        image:[UIImage imageNamed:@"tabbar-down"]
                                                          tag:0];
        if (IsIOS7) {
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar-down-selected"];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:@"离线"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(offlineButtonItemAction:)];
    
    self.navigationItem.rightBarButtonItem = buttonItem;
    
    [self generateTestData];
    
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
    self.tableView.rowHeight = 60.0f;
    [self.view addSubview:self.tableView];
    logdebug(@"self.view.frame: %@ self.tableView.frame: %@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.tableView.frame));
}

- (void)generateTestData
{
    // TODO: 待下载视频ID列表，可根据需求自定义
    self.videoIds = @[@"0DE87E129151F23B9C33DC5901307461",
                      @"56AF3FA9E76F216C9C33DC5901307461",
                      @"4D4C63D0A3C2C9E79C33DC5901307461",
                      @"782AA1BFBC0391099C33DC5901307461",
                      @"7F856BC682B085579C33DC5901307461",
                      @"A26E29D55EEC7CEF9C33DC5901307461",
                      @"BCC8432C1B97E9329C33DC5901307461",
                      @"DB4FAE443BB85A379C33DC5901307461",
                      @"869944D405C896BA9C33DC5901307461",
                      @"AEAA2DF5A7BDDB379C33DC5901307461",
                      @"19428F1CB86E8F309C33DC5901307461",
                      @"881FD4563801BCD29C33DC5901307461",
                      @"FD06098BB3DF4E2A9C33DC5901307461"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.videoIds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"DWDownloadViewCorollerCellId";
    
    videoid = self.videoIds[indexPath.row];
    
    DWDownloadTableViewCell *cell = (DWDownloadTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[DWDownloadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        [cell.downloadButton addTarget:self action:@selector(offlineButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.downloadButton.tag = indexPath.row;
    }
    
    [cell setupCell:videoid];
    
    return cell;
}

- (void)offlineButtonItemAction:(UIButton *)button
{
    DWOfflineViewController *offlineViewController = [[DWOfflineViewController alloc] init];
    offlineViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:offlineViewController animated:NO];
}

- (void)offlineButtonAction:(UIButton *)button
{
    
    NSInteger indexPath = button.tag;
    NSString *videoId = self.videoIds[indexPath];
    
    DWOfflineViewController *offlineViewController = [[DWOfflineViewController alloc] init];
    offlineViewController.hidesBottomBarWhenPushed = YES;
    offlineViewController.videoId = videoId;
    
    [self.navigationController pushViewController:offlineViewController animated:NO];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    videoid = self.videoIds[indexPath.row];
    
    downloader = [[DWDownloader alloc] initWithUserId:DWACCOUNT_USERID
                                           andVideoId:videoid
                                                  key:DWACCOUNT_APIKEY];
    DWDownloadViewController *downloadCtr = self;
    [downloader getPlayInfo];
    downloader.getPlayinfoBlock =^(NSDictionary *playUrls){
        NSDictionary *playInfo = playUrls;
        
        downloadCtr.playInfo = [NSDictionary dictionaryWithDictionary:playInfo];
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"选择清晰度" delegate:downloadCtr cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:nil, nil];
        
        NSArray *definitions = [playInfo  valueForKey:@"definitionDescription"];
        for (NSString *definition in definitions) {
            [sheet addButtonWithTitle:definition];
        }
        [sheet showInView:downloadCtr.view];
    };
    
    downloader.failBlock = ^(NSError *error){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"选择清晰度" delegate:downloadCtr cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
        [sheet showInView:downloadCtr.view];

    };
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //获取PlayInfo 配对url 推送offlineview
    
    NSArray *videos = [self.playInfo valueForKey:@"definitions"];
    if (buttonIndex != 0) {
        
        NSDictionary *videoInfo = videos[(int)buttonIndex-1];

        NSString *definition = [[NSString alloc] initWithFormat:@"%@",[videoInfo valueForKey:@"definition"] ];
        NSString *playurl = [[NSString alloc] initWithFormat:@"%@",[videoInfo valueForKey:@"playurl"] ];

        
        DWOfflineViewController *offlineViewController = [[DWOfflineViewController alloc] init];
        offlineViewController.hidesBottomBarWhenPushed = YES;
        offlineViewController.videoId = videoid;
        offlineViewController.definition = definition;
        offlineViewController.playUrl = playurl;
        
        [self.navigationController pushViewController:offlineViewController animated:NO];
    }
    
}
@end
