#import "DWUploadTableViewCell.h"

@interface DWUploadTableViewCell ()

@end

@implementation DWUploadTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self createView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)createView
{
    // 视频缩略图
    self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 18, 80, 60)];
    [self addSubview:self.thumbnailView];
    
    // 视频标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 18, 130, 30)];
    [self.titleLabel setNumberOfLines:1];
    self.titleLabel.font = [UIFont systemFontOfSize:12];
    [self addSubview:self.titleLabel];
    
    // 文件大小进度
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 53, 130, 20)];
    [self.progressLabel setNumberOfLines:1];
    [self.progressLabel setFont:[UIFont systemFontOfSize:10]];
    [self addSubview:self.progressLabel];
    
    // 进度条宽度
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(110, 78, 130, 10)];
    [self.progressView setProgressViewStyle:UIProgressViewStyleDefault];
    [self addSubview:self.progressView];
    
    //上传按钮
    self.statusButton = [DWImageTitleButton buttonWithType:UIButtonTypeCustom];
    [self.statusButton setFrame:CGRectMake(254, 32, 40, 40)];
    self.statusButton.adjustsImageWhenHighlighted = YES;
    self.statusButton.showsTouchWhenHighlighted =YES;
    [self.statusButton setUserInteractionEnabled:YES];
    [self.statusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.statusButton.titleLabel.font = [UIFont systemFontOfSize:10];
    [self addSubview:self.statusButton];
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

-(void)setupCell:(DWUploadItem *)item
{
    // 视频缩略图
    UIImage *image = [item getVideoThumbnail];
    [self.thumbnailView setImage:image];
    
    // 视频标题
    [self.titleLabel setText:[item videoTitle]];
    
    // 文件大小进度
    float uploadedSizeMB = [item videoUploadedSize]/1024.0/1024.0;
    float fileSizeMB = [item videoFileSize]/1024.0/1024.0;
    [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", uploadedSizeMB, fileSizeMB]];
    [self.progressLabel setNumberOfLines:1];
    
    // 进度条宽度
    [self.progressView setProgress:[item videoUploadProgress]];
    
    // 上传按钮
    NSString *statusTitle = nil;
    NSString *imageName = nil;
    [item getUploadStatusDescribe:&statusTitle andImageName:&imageName];
    loginfo(@"statusTitle: %@ imageName: %@", statusTitle, imageName);
    [self.statusButton setTitle:statusTitle forState:UIControlStateNormal];
    [self.statusButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [self.statusButton imageUp:2];
    // 是否禁用 上传状态按钮 的交互
    if ([self isDisableStatusButtonUserInteraction:item]) {
        loginfo(@"disable");
        [self.statusButton setUserInteractionEnabled:NO];
    } else {
        [self.statusButton setUserInteractionEnabled:YES];
    }
}

- (void)updateCellProgressWithProgress:(float)progress andUploadedSize:(NSInteger)uploadedSize fileSize:(NSInteger)fileSize
{
    [self.progressView setProgress:progress];
    
    float uploadedSizeMB = uploadedSize/1024.0/1024.0;
    float fileSizeMB = fileSize/1024.0/1024.0;
    [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", uploadedSizeMB, fileSizeMB]];
}

- (void)updateCellProgress:(DWUploadItem *)item
{
    [self.progressView setProgress:[item videoUploadProgress]];
    
    float uploadedSizeMB = [item videoUploadedSize]/1024.0/1024.0;
    float fileSizeMB = [item videoFileSize]/1024.0/1024.0;
    [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", uploadedSizeMB, fileSizeMB]];
}

- (void)updateUploadStatus:(DWUploadItem *)item
{
    NSString *statusTitle = nil;
    NSString *imageName = nil;
    [item getUploadStatusDescribe:&statusTitle andImageName:&imageName];
    [self.statusButton setTitle:statusTitle forState:UIControlStateNormal];
    [self.statusButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    if ([self isDisableStatusButtonUserInteraction:item]) {
        // 如果上传成功，则使按钮不响应点击
        [self.statusButton setUserInteractionEnabled:NO];
    }
}

- (BOOL)isDisableStatusButtonUserInteraction:(DWUploadItem *)item
{
    BOOL disable = NO;
    
    switch (item.videoUploadStatus) {
        case DWUploadStatusLoadLocalFileInvalid:
            disable = YES;
            break;
            
        case DWUploadStatusFinish:
            disable = YES;
            break;
            
        default:
            break;
    }
    
    return disable;
}


@end
