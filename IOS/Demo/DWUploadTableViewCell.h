#import <UIKit/UIKit.h>
#import "DWUploadItem.h"
#import "DWImageTitleButton.h"

@interface DWUploadTableViewCell : UITableViewCell

@property (strong, nonatomic)UIImageView *thumbnailView;
@property (strong, nonatomic)DWImageTitleButton *statusButton;
@property (strong, nonatomic)UILabel *progressLabel;
@property (strong, nonatomic)UILabel *titleLabel;

@property (strong, nonatomic)UIProgressView *progressView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

-(void)setupCell:(DWUploadItem *)item;

- (void)updateCellProgress:(DWUploadItem *)item;

- (void)updateUploadStatus:(DWUploadItem *)item;

@end
