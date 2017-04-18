#import "DWAccountViewController.h"
#import "DWUploadViewController.h"
#import "DWPlayerViewController.h"
#import "DWDownloadViewController.h"
#import "DWImageTitleButton.h"

@interface DWAccountViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic)UITableView *tableView;
@property (strong, nonatomic)NSArray *accountInfo;

@end

@implementation DWAccountViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"账户信息";
        
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"账户"
                                                        image:[UIImage imageNamed:@"tabbar-user"]
                                                          tag:0];
        
        if (IsIOS7) {
            self.tabBarItem.selectedImage = [UIImage imageNamed:@"tabbar-user-selected"];
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDictionary *userId = @{@"title" : @"User ID", @"content" : DWACCOUNT_USERID};
    NSDictionary *apiKey = @{@"title" : @"API Key", @"content" : DWACCOUNT_APIKEY};
    self.accountInfo = @[userId, apiKey];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 60.0;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

# pragma mark - UITableViewDelegate

# pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.accountInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"DWAccountControllerCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    }
    
    NSDictionary *info = [self.accountInfo objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [info objectForKey:@"title"];
    cell.detailTextLabel.text = [info objectForKey:@"content"];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
    
    cell.selectionStyle =  UITableViewCellSelectionStyleNone;
    
    return cell;
}


@end
