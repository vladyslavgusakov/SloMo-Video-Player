//
//  PlayerViewController.m
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/14/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import "PlayerViewController.h"
#import "PlayerView.h"

@interface PlayerViewController () {
    BOOL _played;
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;
    NSURL *videoURL;
    AVPlayerLayer *playerLayer;
    CGFloat totalDuration;
    BOOL isSlowMotion;

}



@property (weak, nonatomic) IBOutlet PlayerView *playerView;

@property (weak, nonatomic) IBOutlet UIProgressView *videoProgress;
@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (nonatomic ,strong) id playbackTimeObserver;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *slowMotionButton;
@property (weak, nonatomic) IBOutlet UISlider *videoSlider;


- (IBAction)back:(id)sender;
- (IBAction)playOrPause:(UIButton *)sender;
- (IBAction)activateSlowMotion:(UIButton *)sender;
- (IBAction)videoSliderValueChanged:(UISlider *)sender;
- (IBAction)videoSliderTouched:(UISlider *)sender;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void) viewWillAppear:(BOOL)animated {
    
    videoURL = self.url;
    
    // Do any additional setup after loading the view.
    self.playerItem = [AVPlayerItem playerItemWithURL:videoURL];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    playerLayer = ((AVPlayerLayer *)self.playerView.layer);
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerView.player = self.player;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    isSlowMotion = NO;
    _played = NO;

    [self.videoProgress setProgress:0];
    [self.videoSlider setValue:0];
    
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    self.playbackTimeObserver = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = (CGFloat)playerItem.currentTime.value/(CGFloat)playerItem.currentTime.timescale;
//        NSLog(@"sec: %f", currentSecond);
        [self.videoProgress setProgress: currentSecond/totalDuration animated:YES];
        [self.videoSlider setValue:currentSecond/totalDuration animated:YES];
        NSString *timeString = [self convertTime:currentSecond];
        self.currentTime.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            CMTime duration = self.playerItem.duration;
            totalDuration = CMTimeGetSeconds(duration);
            _totalTime = [self convertTime:totalDuration];
            self.currentTime.text = [NSString stringWithFormat:@"00:00:00/%@",_totalTime];
            NSLog(@"movie total duration:%f", totalDuration);
            
            [self monitoringPlayback:self.playerItem];
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    }
}

- (NSString *)convertTime:(int)totalSeconds{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    _played = NO;
    [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [self.playerView.player pause];
}

- (IBAction)playOrPause:(UIButton *)sender {
    
    _played = !_played;

    if (_played == YES) {
        [self.playerView.player play];
        [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    } else {
        [self.playerView.player pause];
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    }

}

- (IBAction)activateSlowMotion:(UIButton *)sender {
    
    isSlowMotion = !isSlowMotion;
    
    if (isSlowMotion == YES) {
        [self.playerView.player setRate:0.05];
        [sender setImage:[UIImage imageNamed:@"turtle_filled.png"] forState:UIControlStateNormal];
    }
    else {
        [self.playerView.player setRate:1];
        [sender setImage:[UIImage imageNamed:@"turtle.png"] forState:UIControlStateNormal];
    }
    
    _played = YES;
    [self.playPauseButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
    
    
    
}

- (IBAction)videoSliderValueChanged:(UISlider *)sender {
    
    [self.playerView.player seekToTime:CMTimeMakeWithSeconds(sender.value, 1) completionHandler:^(BOOL finished) {
        [self.playerView.player play];
    }];
}

- (IBAction)videoSliderTouched:(UISlider *)sender {
//    [self.playerView.player play];
}

- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    [self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.videoProgress setProgress:0];
        [self.videoSlider setValue:0];
        _played = NO;
        isSlowMotion = NO;
        [self.slowMotionButton setImage:[UIImage imageNamed:@"turtle.png"] forState:UIControlStateNormal];
        [self.playPauseButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
//        [self.videoSlider setValue:0.0 animated:YES];
    }];
}
@end
