//
//  PlayerViewController.h
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/14/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerViewController : UIViewController

@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic ,strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) NSURL *url;
@end
