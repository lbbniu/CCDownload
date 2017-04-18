
#import <Foundation/Foundation.h>
typedef void (^DWErrorBlock)(NSError *error);
typedef void (^DWAdInfoFinishBlock)(NSDictionary *response);

@interface DWAdInfo : NSObject

@property (copy, nonatomic)DWErrorBlock errorBlock;
@property (copy, nonatomic)DWAdInfoFinishBlock finishBlock;

@property (assign, nonatomic)NSInteger time;
@property (assign, nonatomic)BOOL canClick;
@property (assign, nonatomic)BOOL canSkip;
@property (strong, nonatomic)NSMutableArray *ad;


- (id)initWithUserId:(NSString *)userId andVideoId:(NSString *)videoId type:(NSString *)type;

- (void)start;

@end
