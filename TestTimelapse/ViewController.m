//
//  ViewController.m
//  TestTimelapse
//
//  Created by mdaymard on 08/06/2017.
//  Copyright © 2017 AVCL. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>

@interface ViewController ()

@property(nonatomic, strong) NSTimer *progressTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *timelapseURL = [[NSBundle mainBundle] URLForResource:@"timelapse" withExtension:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:timelapseURL];
    
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *outputFilePath = [documents stringByAppendingPathComponent:@"output.mp4"];
    
    [self exportVideo:asset to:outputFilePath];
}

- (void)exportVideo:(AVAsset *)videoAsset
                 to:(NSString *)resultPath{
    
    if([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:resultPath error:&error];
        if(error != nil)
            @throw [NSException exceptionWithName:@"Cannot remove existing file"
                                           reason:[error description]
                                         userInfo:nil];
    }
    
    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *compositionVideoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                    preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // Video duration is approximately 18,352 secs
    // If we reduce the time range, the export will work.
    /*int timeScale = 100000;
    int videoDurationIa = (int) (CMTimeGetSeconds([videoAsset duration]) * (float) timeScale);
    int videoDurationI = 1835000;
    int videoStartI = 100;
    CMTime videoStart = CMTimeMake(videoStartI, timeScale);
    CMTime videoDuration = CMTimeMake(videoDurationI, timeScale);
    CMTimeRange videoTimeRange = CMTimeRangeMake(videoStart, videoDuration);*/
    
    NSArray<AVAssetTrack *> *videoTracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    
    CMTimeRange videoTimeRange = [videoTrack timeRange];
    
    [compositionVideoTrack insertTimeRange:videoTimeRange
                                   ofTrack:videoTrack
                                    atTime:kCMTimeZero
                                     error:nil];
    
    NSURL *outptVideoUrl = [NSURL fileURLWithPath:resultPath];
    self.exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                     presetName:AVAssetExportPresetHighestQuality];
    
    self.exporter.outputURL = outptVideoUrl;
    self.exporter.outputFileType = AVFileTypeMPEG4;
    self.exporter.shouldOptimizeForNetworkUse = YES;
    
    [self.exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (self.exporter.status) {
                case AVAssetExportSessionStatusFailed:{
                    @throw [NSException exceptionWithName:@"failed export"
                                                   reason:[self.exporter.error description]
                                                 userInfo:nil];
                }
                case AVAssetExportSessionStatusCancelled:
                    @throw [NSException exceptionWithName:@"cancelled export"
                                                   reason:@"Export cancelled"
                                                 userInfo:nil];
                    
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"Export finished");
                    [self exportVideoToCameraRoll:resultPath];
                }
                    break;
                    
                default:
                    break;
            }
        });
    }];
}

- (void)exportVideoToCameraRoll:(NSString *)filePath {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (filePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(filePath,nil,nil,nil);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
