//
//  VideoViewController.m
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import "VideoViewController.h"
#import "CameraManager.h"
#import "SVProgressHUD.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface VideoViewController () <CameraManagerDelegate> {
    NSTimeInterval startTime;
    BOOL isNeededToSave;
    BOOL animating;
}

- (IBAction)backToGallery:(id)sender;
- (IBAction)switchCamera:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)changeFpsTo:(UISegmentedControl*)sender;

@property (strong, nonatomic) IBOutlet UISegmentedControl *fpsSegmentedContol;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) CameraManager *captureManager;
@property (nonatomic, assign) NSTimer *timer;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.captureManager = [[CameraManager alloc] initWithPreviewView:self.previewView
                                                     preferredCameraType:CameraTypeBack
                                                              outputMode:OutputModeMovieFile];
    self.captureManager.delegate = self;
}

-(void) viewDidLayoutSubviews {
    self.captureManager.previewLayer.frame = self.previewView.bounds;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    
//    [self.captureManager updateOrientationWithPreviewView:self.previewView];
//}

#pragma mark - Timer Handler

- (void)timerHandler:(NSTimer *)timer {
    
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval recorded = current - startTime;
    
    self.statusLabel.text = [NSString stringWithFormat:@"%.2f", recorded];
}

#pragma mark - Save File

- (void)saveRecordedFile:(NSURL *)recordedFile {
    
    [SVProgressHUD showWithStatus:@"Saving..."
                         maskType:SVProgressHUDMaskTypeGradient];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        [assetLibrary writeVideoAtPathToSavedPhotosAlbum:recordedFile
                                         completionBlock:
         ^(NSURL *assetURL, NSError *error) {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 [SVProgressHUD dismiss];
                 
                 NSString *title;
                 NSString *message;
                 
                 if (error != nil) {
                     
                     title = @"Failed to save video";
                     message = [error localizedDescription];
                 }
                 else {
                     title = @"Saved!";
                     message = nil;
                 }
                 
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
                 [alert show];
             });
         }];
    });
}

#pragma mark - AVCaptureManagerDelegate

- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL error:(NSError *)error {
    
    if (error) {
        NSLog(@"error:%@", error);
        return;
    }
    
    if (!isNeededToSave) {
        return;
    }
    
    [self saveRecordedFile:outputFileURL];
}

- (IBAction)backToGallery:(id)sender {
    //stop player
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchCamera:(id)sender {
    [self.captureManager swapCameras];
}

- (IBAction)record:(id)sender {
    
    // REC START
    if (!self.captureManager.isRecording) {
        
        // change UI
        [self startSpin];
        self.fpsSegmentedContol.enabled = NO;
        
        // timer start
        startTime = [[NSDate date] timeIntervalSince1970];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                      target:self
                                                    selector:@selector(timerHandler:)
                                                    userInfo:nil
                                                     repeats:YES];
        
        [self.captureManager startRecording];
    }
    // REC STOP
    else {
        
        isNeededToSave = YES;
        [self.captureManager stopRecording];
        
        [self.timer invalidate];
        self.timer = nil;
        
        self.fpsSegmentedContol.enabled = YES;
        [self stopSpin];
    }

}

- (IBAction)changeFpsTo:(UISegmentedControl*)sender {
    
    CGFloat desiredFps = 0.0;
    switch (self.fpsSegmentedContol.selectedSegmentIndex) {
        case 0:
        default:
        {
            desiredFps = 30.0;
            break;
        }
        case 1:
            desiredFps = 60.0;
            break;
        case 2:
            desiredFps = 240.0;
            break;
    }
    
    [SVProgressHUD showWithStatus:@"Switching..."
                         maskType:SVProgressHUDMaskTypeGradient];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        if (desiredFps > 0.0) {
            [self.captureManager switchFormatWithDesiredFPS:desiredFps];
        }
        else {
            [self.captureManager resetFormat];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD dismiss];
        });
    });
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
    
}

-(BOOL)shouldAutorotate {
    return NO;
}

- (void) spinWithOptions: (UIViewAnimationOptions) options {
    // this spin completes 360 degrees every 2 seconds
    [UIView animateWithDuration: 0.5f
                          delay: 0.0f
                        options: options
                     animations: ^{
                         self.recordButton.imageView.transform = CGAffineTransformRotate(self.recordButton.imageView.transform, M_PI / 2);
                     }
                     completion: ^(BOOL finished) {
                         if (finished) {
                             if (animating) {
                                 // if flag still set, keep spinning with constant speed
                                 [self spinWithOptions: UIViewAnimationOptionCurveLinear];
                             } else if (options != UIViewAnimationOptionCurveEaseOut) {
                                 // one last spin, with deceleration
                                 [self spinWithOptions: UIViewAnimationOptionCurveEaseOut];
                             }
                         }
                     }];
}

- (void) startSpin {
    if (!animating) {
        animating = YES;
        [self spinWithOptions: UIViewAnimationOptionCurveEaseIn];
    }
}

- (void) stopSpin {
    // set the flag to stop spinning after one last 90 degree increment
    animating = NO;
}

@end
