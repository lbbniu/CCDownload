#import "DWOfflineTableViewCell.h"

@implementation DWOfflineTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self createViewForDownloading];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier downloadFinish:(BOOL)finish
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if (finish) {
            [self createViewForDownloadFinish];
        } else {
            [self createViewForDownloading];
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)createViewForDownloadFinish
{
    /**
     *
     *  +-------------------------------------------+
     *  | +-----------------------------+           |
     *  | | videoId(32byte)             |           |
     *  | +-----------------------------+   button  |
     *  | videoSize                                 |
     *  +-------------------------------------------+
     *  
     */
    
    
    // 视频video
    self.videoIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, 245, 30)];
    [self.videoIdLabel setNumberOfLines:1];
    self.videoIdLabel.font = [UIFont systemFontOfSize:10];
    [self addSubview:self.videoIdLabel];
    
    // 文件大小
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 50, 245, 20)];
    self.progressLabel.font = [UIFont systemFontOfSize:14];
    [self.progressLabel setNumberOfLines:1];
    [self addSubview:self.progressLabel];
    
    self.statusButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.statusButton setFrame:CGRectMake(260, 20, 22, 22)];
    [self.statusButton setUserInteractionEnabled:YES];
    [self.statusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.statusButton setImage:[UIImage imageNamed:@"download-play-button"] forState:UIControlStateNormal];
    [self addSubview:self.statusButton];
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

-(void)createViewForDownloading
{
    /**
     *
     *  +-------------------------------------------+
     *  | +-----------------------------+           |
     *  | | videoId(32byte)             |           |
     *  | +-----------------------------+   button  |
     *  | +-----------------------------+           |
     *  | | progress                    |           |
     *  | +-----------------------------+           |
     *  | progress                                  |
     *  +-------------------------------------------+
     *  
     */
    
    
    // 视频video
    self.videoIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 5, 245, 30)];
    self.videoIdLabel.numberOfLines = 1;
    self.videoIdLabel.font = [UIFont systemFontOfSize:10];
    [self addSubview:self.videoIdLabel];
    
    // 进度条
    self.progressView = [[UIProgressView alloc]
                                    initWithFrame:CGRectMake(16, 37.5, 245, 10)];
    [self.progressView setProgressViewStyle:UIProgressViewStyleDefault];
    [self addSubview:self.progressView];
    
    
    // 文件大小进度
    self.progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 55, 245, 20)];
    self.progressLabel.numberOfLines = 1;
    self.progressLabel.font = [UIFont systemFontOfSize:14];
    [self addSubview:self.progressLabel];
    
    //下载状态按钮
    self.statusButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.statusButton setFrame:CGRectMake(270, 20, 22, 22)];
    [self.statusButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self addSubview:self.statusButton];
    
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

-(void)setupCell:(DWDownloadItem *)item
{
    // 视频标题
    if (item.definition) {
        NSString *labelName = [[NSString alloc] initWithFormat:@"%@-%@",[item videoId],[item definition]];
        NSLog(@"labelName : %@",labelName);

        [self.videoIdLabel setText:labelName];
    } else {
        [self.videoIdLabel setText:[item videoId]];
    }
    
    // 设置进度条宽度为
    if (item.videoDownloadStatus == DWDownloadStatusFinish) {
        [self.progressView setHidden:YES];
        NSLog(@"hidden: %@", item);
        
    } else {
        [self.progressView setHidden:NO];
        [self.progressView setProgress:[item videoDownloadProgress]];
    }
    
    // 设置 下载状态按钮
    [self updateDownloadStatus:item];
    // 文件大小进度
    if (item.videoDownloadStatus == DWDownloadStatusFinish) {
        float fileSizeMB = [item videoFileSize]/1024.0/1024.0;
        [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM", fileSizeMB]];
        
    } else {
        float downloadedSizeMB = [item videoDownloadedSize]/1024.0/1024.0;
        float fileSizeMB = [item videoFileSize]/1024.0/1024.0;
        [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", downloadedSizeMB, fileSizeMB]];
    }
}

- (void)updateCellProgressWithProgress:(float)progress andUownloadedSize:(NSInteger)downloadedSize fileSize:(NSInteger)fileSize
{
    [self.progressView setProgress:progress];
    
    float downloadedSizeMB = downloadedSize/1024.0/1024.0;
    float fileSizeMB = fileSize/1024.0/1024.0;
    [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", downloadedSizeMB, fileSizeMB]];
}

- (void)updateCellProgress:(DWDownloadItem *)item
{
    [self.progressView setProgress:item.videoDownloadProgress];
    
    float downloadedSizeMB = [item videoDownloadedSize]/1024.0/1024.0;
    float fileSizeMB = [item videoFileSize]/1024.0/1024.0;
    [self.progressLabel setText:[NSString stringWithFormat:@"%0.1fM/%0.1fM", downloadedSizeMB, fileSizeMB]];
}

- (void)updateDownloadStatus:(DWDownloadItem *)item
{
    [self.statusButton setBackgroundImage:[item getDownloadStatusImage] forState:UIControlStateNormal];
}

@end
