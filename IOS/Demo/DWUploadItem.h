#import <Foundation/Foundation.h>
#import "DWUploader.h"

enum {
    DWUploadStatusWait = 1,
    DWUploadStatusLoadLocalFileInvalid,
    DWUploadStatusStart,
    DWUploadStatusUploading,
    DWUploadStatusPause,
    DWUploadStatusResume,
    DWUploadStatusFail,
    DWUploadStatusFinish
};
typedef NSInteger DWUploadStatus;

@interface DWUploadItem : NSObject

@property (strong, nonatomic)NSString *videoPath;
@property (strong, nonatomic)NSString *videoThumbnailPath;
@property (strong, nonatomic)NSString *videoTitle;
@property (strong, nonatomic)NSString *videoTag;
@property (strong, nonatomic)NSString *videoDescripton;
@property (assign, nonatomic)float videoUploadProgress;
@property (assign, nonatomic)NSInteger videoFileSize;
@property (assign, nonatomic)NSInteger videoUploadedSize;
@property (assign, nonatomic)DWUploadStatus videoUploadStatus;
@property (strong, nonatomic)NSDictionary *uploadContext;
@property (strong, nonatomic)DWUploader *uploader;

- (id)initWithItem:(NSDictionary *)item;
- (NSDictionary *)getItemDictionary;
- (NSString*)description;
- (UIImage *)getVideoThumbnail;

- (void)getUploadStatusDescribe:(NSString **)string andImageName:(NSString **)imageName;

@end


@interface DWUploadItems : NSObject

@property (strong, nonatomic)NSMutableArray *items;
@property (assign, atomic)BOOL isBusy;

- (id)initWithPath:(NSString *)path;
- (void)removeObjectAtIndex:(NSUInteger)index;

- (BOOL)writeToPlistFile:(NSString*)filename;

@end
