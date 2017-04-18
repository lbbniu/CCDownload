#import "DWDownloadItem.h"
#import "DWTools.h"

@implementation DWDownloadItem

- (id)initWithItem:(NSDictionary *)item
{
    self = [super init];
    if (self) {
        _videoId = [item objectForKey:@"videoId"];
        _definition = [item objectForKey:@"definition"];
        _videoPath = [item objectForKey:@"videoPath"];
        _videoDownloadProgress = [[item objectForKey:@"videoDownloadProgress"] floatValue];
        _videoFileSize = (NSInteger)[[item objectForKey:@"videoFileSize"] longLongValue];
        _videoDownloadedSize = [DWTools getFileSizeWithPath:_videoPath Error:nil];
        _videoDownloadStatus = [[item objectForKey:@"videoDownloadStatus"] integerValue];
    }
    
    return self;
}

- (NSString*)description
{
    return [[self getItemDictionary] description];
}

- (NSDictionary *)getItemDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (self.videoId) {
        [dict setObject:self.videoId forKey:@"videoId"];
    }
    if (self.videoPath) {
        [dict setObject:self.videoPath forKey:@"videoPath"];
    }
    if (self.definition) {
        [dict setObject:self.definition forKey:@"quality"];
    }
    
    [dict setObject:[NSNumber numberWithFloat:self.videoDownloadProgress] forKey:@"videoDownloadProgress"];
    [dict setObject:[NSNumber numberWithInteger:self.videoFileSize] forKey:@"videoFileSize"];
    [dict setObject:[NSNumber numberWithInteger:self.videoDownloadedSize] forKey:@"videoDownloadedSize"];
    [dict setObject:[NSNumber numberWithInteger:self.videoDownloadStatus] forKey:@"videoDownloadStatus"];
    
    return dict;
}

- (UIImage *)getDownloadStatusImage
{
    NSString *filename = nil;
    switch (self.videoDownloadStatus) {
        case DWDownloadStatusWait:
            filename = @"download-stat-waiting";
            break;
            
        case DWDownloadStatusStart:
            filename = @"download-status-down";
            break;
            
        case DWDownloadStatusDownloading:
            filename = @"download-status-down";
            break;
            
        case DWDownloadStatusPause:
            filename = @"download-status-hold";
            break;
            
        case DWDownloadStatusFail:
            filename = @"download-status-fail";
            break;
            
        case DWDownloadStatusFinish:
            filename = @"download-play-button";
            break;
            
        default:
            break;
    }
    return [UIImage imageNamed:filename];
}

- (void)getDownloadStatusDescribe:(NSString **)string andImagePath:(NSString **)imagePath
{
    switch (self.videoDownloadStatus) {
        case DWDownloadStatusWait:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-stat-waiting" ofType:@"png"];
            *string =  @"等待";
            break;
            
        case DWDownloadStatusStart:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-status-down" ofType:@"png"];
            *string = @"开始";
            break;
            
        case DWDownloadStatusDownloading:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-status-down" ofType:@"png"];
            *string = @"下载中";
            break;
            
        case DWDownloadStatusPause:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-status-hold" ofType:@"png"];
            *string = @"暂停";
            break;
            
        case DWDownloadStatusFail:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-status-hold" ofType:@"png"];
            *string = @"失败";
            break;
            
        case DWDownloadStatusFinish:
            *imagePath = [[NSBundle mainBundle] pathForResource:@"download-play-button" ofType:@"png"];
            *string = @"播放";
            break;
            
        default:
            break;
    }
}

@end

@implementation DWDownloadItems

- (id)initWithPath:(NSString *)filename
{
    self = [super init];
    if (self) {
        NSArray *array = [self readFromPlistFile:filename];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in array) {
            DWDownloadItem *item = [[DWDownloadItem alloc] initWithItem:dict];
            [items insertObject:item atIndex:0];
        }
        _items = items;
    }
    
    return self;
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    DWDownloadItem *item = [self.items objectAtIndex:index];
    
    [[NSFileManager defaultManager] removeItemAtPath:item.videoPath error:nil];
    
    [self.items removeObjectAtIndex:index];
}

- (BOOL)writeToPlistFile:(NSString*)filename
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (DWDownloadItem *item in self.items) {
        NSDictionary *dict = [item getItemDictionary];
        [array insertObject:dict atIndex:0];
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    BOOL didWriteSuccessfull = [data writeToFile:path atomically:YES];
    logdebug(@"write %ld %@ to %@", (long)array.count, array, path);
    
    return didWriteSuccessfull;
}

- (NSArray *)readFromPlistFile:(NSString*)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    logdebug(@"load: %@ count %ld items: %@", path, (long)[array count], array);
    
    return array;
}

@end
