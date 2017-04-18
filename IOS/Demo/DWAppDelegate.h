#import <UIKit/UIKit.h>
#import "DWUploadItem.h"
#import "DWDownloadItem.h"


@interface DWAppDelegate : UIResponder <UIApplicationDelegate>
{
    BOOL isDownloaded;
}
@property (assign, nonatomic)BOOL isDownloaded;
@property (strong, nonatomic)UIWindow *window;
@property (strong, nonatomic)DWDownloadItems *downloadFinishItems;
@property (strong, nonatomic)DWDownloadItems *downloadingItems;

@property (strong, nonatomic)DWUploadItems *uploadItems;

@end
