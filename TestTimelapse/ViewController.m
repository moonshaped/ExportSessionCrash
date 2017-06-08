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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *timelapseURL = [[NSBundle mainBundle] URLForResource:@"timelapse" withExtension:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:timelapseURL];
    NSString *outputFilePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"output.mov"];
    
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
    
    int timeScale = 100000;
    int videoDurationI = (int) (CMTimeGetSeconds([videoAsset duration]) * (float) timeScale);
    CMTime videoDuration = CMTimeMake(videoDurationI, timeScale);
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoDuration);
    
    NSArray<AVAssetTrack *> *videoTracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    
    [compositionVideoTrack insertTimeRange:videoTimeRange
                                   ofTrack:videoTrack
                                    atTime:kCMTimeZero
                                     error:nil];
    
    NSURL *outptVideoUrl = [NSURL fileURLWithPath:resultPath];
    self.exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                     presetName:AVAssetExportPresetHighestQuality];
    
    self.exporter.outputURL = outptVideoUrl;
    self.exporter.outputFileType = AVFileTypeQuickTimeMovie;
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
    
    __block PHObjectPlaceholder *placeholder;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filePath]];
        placeholder = [createAssetRequest placeholderForCreatedAsset];
    } completionHandler:^(BOOL success, NSError *error) {
        
        if(!success)
            @throw [NSException exceptionWithName:@"Export to camera roll failed"
                                           reason:[error description]
                                         userInfo:nil];
        else
            NSLog(@"Exported to camera roll");
        
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
