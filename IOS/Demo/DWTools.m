#import "DWTools.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@implementation DWTools

+ (NSInteger)getFileSizeWithPath:(NSString *)filePath Error:(NSError **)error
{
    NSFileManager *fileManager = nil;
    NSDictionary *fileAttr = nil;
    NSInteger fileSize;
    
    fileManager = [NSFileManager defaultManager];
    
    fileAttr = [fileManager attributesOfItemAtPath:filePath error:error];
    if (error && *error) {
        return -1;
    }
    
    fileSize = (NSInteger)[[fileAttr objectForKey:NSFileSize] longLongValue];
    
    return fileSize;
}

+ (UIImage *)getImage:(NSString *)videoPath atTime:(NSTimeInterval)time Error:(NSError **)error
{
    if (!videoPath) {
        return nil;
    }
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[[NSURL alloc] initFileURLWithPath:videoPath] options:nil];
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                                                    actualTime:NULL error:error];
    
    logdebug(@"thumbnailImageRef: %p %@", thumbnailImageRef, thumbnailImageRef);
    if (!thumbnailImageRef) {
        return nil;
    }
    
    UIImage *thumbnailImage = [[UIImage alloc] initWithCGImage:thumbnailImageRef];
    logdebug(@"thumbnailImage: %p", thumbnailImage);
    
    CFRelease(thumbnailImageRef);
    
    return thumbnailImage;
}

+ (BOOL)saveVideoThumbnailWithVideoPath:(NSString *)vieoPath toFile:(NSString *)ThumbnailPath Error:(NSError **)error
{
    NSError *er;
    UIImage *image = [DWTools getImage:vieoPath atTime:1 Error:&er];
    if (er) {
        logerror(@"get video thumbnail failed: %@", [er localizedDescription]);
        if (error) {
            *error = er;
        }
        return NO;
    }
    
    [UIImagePNGRepresentation(image) writeToFile:ThumbnailPath atomically:YES];
    
    logdebug(@"image: %@", image);
    
    return YES;
    
}

+ (NSString *)formatSecondsToString:(NSInteger)seconds
{
    NSString *hhmmss = nil;
    if (seconds < 0) {
        return @"00:00:00";
    }
    
    int h = (int)round((seconds%86400)/3600);
    int m = (int)round((seconds%3600)/60);
    int s = (int)round(seconds%60);
    
    hhmmss = [NSString stringWithFormat:@"%02d:%02d:%02d", h, m, s];
    
    return hhmmss;
}
+ (UIImage *)imageCompressForSize:(UIImage *)sourceImage targetSize:(CGSize)size{
    
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = size.width;
    CGFloat targetHeight = size.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO){
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = heightFactor;
            
        }
        else{
            scaleFactor = widthFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            thumbnailPoint.x = (targetWidth - scaledWidth)/2;
            
        }else if(widthFactor < heightFactor){
            thumbnailPoint.y = (targetHeight - scaledHeight)/2;
            
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil){
        NSLog(@"scale image fail");
    }
    
    UIGraphicsEndImageContext();
    return newImage;
}

@end
