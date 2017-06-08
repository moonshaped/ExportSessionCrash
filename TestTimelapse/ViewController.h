//
//  ViewController.h
//  TestTimelapse
//
//  Created by mdaymard on 08/06/2017.
//  Copyright © 2017 AVCL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController

@property(nonatomic, strong) AVAssetExportSession *exporter;

@end

