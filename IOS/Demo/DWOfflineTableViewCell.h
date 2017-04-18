#import <UIKit/UIKit.h>
#import "DWDownloadItem.h"

@interface DWOfflineTableViewCell : UITableViewCell

@property (strong, nonatomic)UIButton *statusButton;
@property (strong, nonatomic)UILabel *progressLabel;
@property (strong, nonatomic)UILabel *videoIdLabel;
@property (strong, nonatomic)UIProgressView *progressView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier downloadFinish:(BOOL)finish;

- (void)setupCell:(DWDownloadItem *)item;

- (void)updateCellProgress:(DWDownloadItem *)item;

- (void)updateDownloadStatus:(DWDownloadItem *)item;

@end
