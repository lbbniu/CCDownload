#import "DWUploadItem.h"
#import "DWTools.h"

@implementation DWUploadItem

- (id)initWithItem:(NSDictionary *)item
{
    self = [super init];
    if (self) {
        _videoPath = [item objectForKey:@"videoPath"];
        _videoThumbnailPath = [item objectForKey:@"videoThumbnailPath"];
        _videoTitle = [item objectForKey:@"videoTitle"];
        _videoTag = [item objectForKey:@"videoTag"];
        _videoDescripton = [item objectForKey:@"videoDescripton"];
        _videoUploadProgress = [[item objectForKey:@"videoUploadProgress"] floatValue];
        _videoFileSize = (NSInteger)[[item objectForKey:@"videoFileSize"] longLongValue];
        _videoUploadedSize = (NSInteger)[[item objectForKey:@"videoUploadedSize"] longLongValue];
        _videoUploadStatus = [[item objectForKey:@"videoUploadStatus"] integerValue];
        _uploadContext = [item objectForKey:@"uploadContext"];
    }
    
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@", [self getItemDictionary]];
}

- (NSDictionary *)getItemDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (self.videoPath) {
        [dict setObject:self.videoPath forKey:@"videoPath"];
    }
    if (self.videoThumbnailPath) {
        [dict setObject:self.videoThumbnailPath forKey:@"videoThumbnailPath"];
    }
    if (self.videoTitle) {
        [dict setObject:self.videoTitle forKey:@"videoTitle"];
    }
    if (self.videoTag) {
        [dict setObject:self.videoTag forKey:@"videoTag"];
    }
    if (self.videoDescripton) {
        [dict setObject:self.videoDescripton forKey:@"videoDescripton"];
    }
    [dict setObject:[NSNumber numberWithFloat:self.videoUploadProgress] forKey:@"videoUploadProgress"];
    [dict setObject:[NSNumber numberWithInteger:self.videoFileSize] forKey:@"videoFileSize"];
    [dict setObject:[NSNumber numberWithInteger:self.videoUploadedSize] forKey:@"videoUploadedSize"];
    [dict setObject:[NSNumber numberWithInteger:self.videoUploadStatus] forKey:@"videoUploadStatus"];
    if (self.uploadContext) {
        [dict setObject:self.uploadContext forKey:@"uploadContext"];
    }
    
    return dict;
}

- (void)getUploadStatusDescribe:(NSString **)string andImageName:(NSString **)imageName
{
    switch (self.videoUploadStatus) {
        case DWUploadStatusWait:
            *imageName = @"download-stat-waiting";
            *string =  @"等待";
            break;
            
        case DWUploadStatusLoadLocalFileInvalid:
            *imageName = @"download-status-hold";
            *string = @"本地文件加载失败";
            break;
            
        case DWUploadStatusStart:
            *imageName = @"upload-status-uploading";
            *string = @"开始";
            break;
            
        case DWUploadStatusUploading:
        case DWUploadStatusResume:
            *imageName = @"upload-status-uploading";
            *string = @"上传中";
            break;
            
        case DWUploadStatusPause:
            *imageName = @"download-status-hold";
            *string = @"暂停";
            break;
            
        case DWUploadStatusFail:
            *imageName = @"download-status-fail";
            *string = @"失败";
            break;
            
        case DWUploadStatusFinish:
            *imageName = @"upload-status-finish";
            *string = @"完成";
            break;
            
        default:
            break;
    }
}

- (UIImage *)getVideoThumbnail
{
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:self.videoThumbnailPath];
    
    if (isExist) {
        return [[UIImage alloc] initWithContentsOfFile:self.videoThumbnailPath];
    }
    UIImage *image = [DWTools getImage:self.videoPath atTime:1 Error:nil];
    
    [UIImagePNGRepresentation(image) writeToFile:self.videoThumbnailPath atomically:YES];
    
    return image;
}

@end


@implementation DWUploadItems

- (id)initWithPath:(NSString *)filename
{
    self = [super init];
    if (self) {
        NSArray *array = [self readFromPlistFile:filename];
        NSMutableArray *items = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in array) {
            DWUploadItem *item = [[DWUploadItem alloc] initWithItem:dict];
            [items insertObject:item atIndex:0];
        }
        _items = items;
        logdebug(@"load %ld %@", (long)[_items count], _items);
    }
    
    return self;
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    DWUploadItem *item = [self.items objectAtIndex:index];
    
    [[NSFileManager defaultManager] removeItemAtPath:item.videoThumbnailPath error:nil];
    
    [self.items removeObjectAtIndex:index];
}

- (BOOL)writeToPlistFile:(NSString*)filename
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (DWUploadItem *item in self.items) {
        NSDictionary *dict = [item getItemDictionary];
        [array insertObject:dict atIndex:0];
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:filename];
    
    BOOL success = [data writeToFile:path atomically:YES];
    logdebug(@"write %ld %@ to %@", (long)array.count, array, path);
    
    return success;
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

