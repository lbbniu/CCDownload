#import "DWPlayerViewController.h"
#import "DWPlayerTableViewCell.h"
#import "DWCustomPlayerViewController.h"

@interface DWPlayerViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic)UITableView *tableView;
@property (strong, nonatomic)NSArray *videoIds;

@end

@implementation DWPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"播放";
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"播放"
                                                        image:[UIImage imageNamed:@"tabbar-play"]
                                                          tag:0];
        if (IsIOS7) {
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar-play-selected"];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    logdebug(@"self.view.frame:%@ self.tableView.frame: %@", NSStringFromCGRect(self.view.frame), NSStringFromCGRect(self.tableView.frame));
}

# pragma mark - processer

- (void)generateTestData
{
    //TODO: 待播放视频ID，可根据需求自定义
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
    static NSString *cellId = @"DWPlayerViewCorollerCellId";
    
    NSString *videoid = self.videoIds[indexPath.row];
    
    DWPlayerTableViewCell *cell = (DWPlayerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[DWPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        [cell.playButton addTarget:self action:@selector(playerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.playButton.tag = indexPath.row;
    }
    
    [cell setupCell:videoid];
    
    return cell;
}

- (void)playerButtonAction:(UIButton *)button
{
    NSInteger indexPath = button.tag;
    NSString *videoId = self.videoIds[indexPath];
    
    UIAlertController *playAlert = [UIAlertController alertControllerWithTitle:@"选择播放模式" message:nil preferredStyle:  UIAlertControllerStyleActionSheet];

    [playAlert addAction:[UIAlertAction actionWithTitle:@"普通版" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        DWCustomPlayerViewController *player = [[DWCustomPlayerViewController alloc] init];
        player.playMode = NO;
        player.videoId = videoId;
        player.videos = self.videoIds;
        player.indexpath = indexPath;
        player.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:player animated:NO];

    }]];
    [playAlert addAction:[UIAlertAction actionWithTitle:@"广告版" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action){
        DWCustomPlayerViewController *player = [[DWCustomPlayerViewController alloc] init];
        player.playMode = YES;
        player.videoId = videoId;
        
        player.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:player animated:NO];

    }]];
    [playAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }]];
    [self presentViewController:playAlert animated:true completion:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
