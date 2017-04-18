#import "DWAppDelegate.h"
#import "DWAccountViewController.h"
#import "DWUploadViewController.h"
#import "DWPlayerViewController.h"
#import "DWDownloadViewController.h"

#define DWDownloadingItemPlistFilename @"downloadingItems.plist"
#define DWDownloadFinishItemPlistFilename @"downloadFinishItems.plist"

#define DWUploadItemPlistFilename @"uploadItems.plist"
@interface DWAppDelegate ()

@property (strong, nonatomic)DWAccountViewController *accountViewController;
@property (strong, nonatomic)DWUploadViewController *uploadViewController;
@property (strong, nonatomic)DWPlayerViewController *playerViewController;
@property (strong, nonatomic)DWDownloadViewController *downloadViewController;
@property (strong, nonatomic)UITabBarController *tabBarController;
@end
@implementation DWAppDelegate

@synthesize isDownloaded;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DWLog setIsDebugHttpLog:YES];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.accountViewController = [[DWAccountViewController alloc] init];
    UINavigationController *accountNavigation = [[UINavigationController alloc] initWithRootViewController:self.accountViewController];
    
    self.uploadViewController = [[DWUploadViewController alloc] init];
    UINavigationController *uploadNavigation = [[UINavigationController alloc] initWithRootViewController:self.uploadViewController];
    
    self.playerViewController = [[DWPlayerViewController alloc] init];
    UINavigationController *playerNavigation = [[UINavigationController alloc] initWithRootViewController:self.playerViewController];
    
    self.downloadViewController = [[DWDownloadViewController alloc] init];
    UINavigationController *downloadNavigation = [[UINavigationController alloc] initWithRootViewController:self.downloadViewController];
    
    NSArray *viewControllers = @[
                                 accountNavigation,
                                 uploadNavigation,
                                 playerNavigation,
                                 downloadNavigation];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = viewControllers;
    self.tabBarController.selectedViewController = accountNavigation;
    //    [self.window addSubview:self.tabBarController.view];
    [self.window setRootViewController:self.tabBarController];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
    // 下载
    [self.downloadingItems writeToPlistFile:DWDownloadingItemPlistFilename];
    [self.downloadFinishItems writeToPlistFile:DWDownloadFinishItemPlistFilename];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadDownloadItems" object:nil];
    
    // 上传
    [self.uploadItems writeToPlistFile:DWUploadItemPlistFilename];
    for (DWUploadItem *item in self.uploadItems.items) {
        if (item.uploader) {
            [item.uploader pause];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [application beginBackgroundTaskWithExpirationHandler:^{
        
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // 下载
    if (!self.downloadingItems) {
        self.downloadingItems = [[DWDownloadItems alloc] initWithPath:DWDownloadingItemPlistFilename];
    }
    if (!self.downloadFinishItems) {
        self.downloadFinishItems = [[DWDownloadItems alloc] initWithPath:DWDownloadFinishItemPlistFilename];
    }
    
    // 上传
    self.uploadItems = [[DWUploadItems alloc] initWithPath:DWUploadItemPlistFilename];
    for (DWUploadItem *item in self.uploadItems.items) {
        switch (item.videoUploadStatus) {
            case DWUploadStatusStart:
                item.videoUploadStatus = DWUploadStatusWait;
                break;
                
            case DWUploadStatusUploading:
                item.videoUploadStatus = DWUploadStatusWait;
                break;
                
            default:
                break;
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
