#import <UIKit/UIKit.h>
#import "DWSDK.h"
#import "DWOfflineTableViewCell.h"


@interface DWOfflineViewController : UIViewController

@property (strong, nonatomic)NSString *videoId;

@property (strong, nonatomic)NSString *playUrl;

@property (strong, nonatomic)NSString *definition;

- (void)addTask;
- (void)loadDownloadItems;

@end
