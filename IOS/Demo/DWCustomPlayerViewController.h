#import <UIKit/UIKit.h>
#import "DWSDK.h"

@interface DWCustomPlayerViewController : UIViewController

@property (copy, nonatomic)NSString *videoId;
@property (copy, nonatomic)NSString *videoLocalPath;
@property (assign, nonatomic)BOOL playMode;
@property (strong, nonatomic)NSArray *videos;
@property (assign, nonatomic)NSInteger indexpath;

@end
