//
//  TTMCaptureManager.m
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

#import "CameraManager.h"
#import <AVFoundation/AVFoundation.h>


@interface CameraManager () <AVCaptureFileOutputRecordingDelegate>

{
    CMTime defaultVideoMaxFrameDuration;
    OutputMode currentOutputMode;
}
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) AVCaptureDevice *videoDevice;

@end

@implementation CameraManager

- (instancetype)initWithPreviewView:(UIView *)previewView
                preferredCameraType:(CameraType)cameraType
                         outputMode:(OutputMode)outputMode
{
    self = [super init];
    
    if (self) {
        
        currentOutputMode = outputMode;
        
        NSError *error;
        
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
        
        self.videoDevice = cameraType == CameraTypeFront ? [CameraManager frontCaptureDevice] : [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (cameraType == CameraTypeFront) {
            isFrontCamera = YES;
        }
        else {
            isFrontCamera = NO;
        }
        AVCaptureDeviceInput *videoIn = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
        
        if (error) {
            NSLog(@"Video input creation failed");
            return nil;
        }
        
        if (![self.captureSession canAddInput:videoIn]) {
            NSLog(@"Video input add-to-session failed");
            return nil;
        }
        [self.captureSession addInput:videoIn];
        
        
        // save the default format
        self.defaultFormat = self.videoDevice.activeFormat;
        defaultVideoMaxFrameDuration = self.videoDevice.activeVideoMaxFrameDuration;
        
        NSLog(@"videoDevice.activeFormat:%@", self.videoDevice.activeFormat);
        
        AVCaptureDevice *audioDevice= [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        [self.captureSession addInput:audioIn];
        
        if (previewView) {
            self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
            self.previewLayer.frame = previewView.bounds;
            self.previewLayer.contentsGravity = kCAGravityResizeAspectFill;
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [previewView.layer insertSublayer:self.previewLayer atIndex:0];
        }
        
        if (outputMode == OutputModeMovieFile) {
            self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            [self.movieFileOutput setMovieFragmentInterval:kCMTimeInvalid];
            [self.captureSession addOutput:self.movieFileOutput];
        }
        
        [self.captureSession startRunning];
    }
    return self;
}

+ (AVCaptureDevice *)frontCaptureDevice {
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == AVCaptureDevicePositionFront)
        {
            return device;
        }
    }
    
    return [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

// =============================================================================
#pragma mark - Public

- (void)resetFormat {
    
    BOOL isRunning = self.captureSession.isRunning;
    
    if (isRunning) {
        [self.captureSession stopRunning];
    }
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [videoDevice lockForConfiguration:nil];
    videoDevice.activeFormat = self.defaultFormat;
    videoDevice.activeVideoMaxFrameDuration = defaultVideoMaxFrameDuration;
    [videoDevice unlockForConfiguration];
    
    if (isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS
{
    BOOL isRunning = self.captureSession.isRunning;
    
    if (isRunning)  [self.captureSession stopRunning];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            
            if (range.minFrameRate <= desiredFPS && desiredFPS <= range.maxFrameRate && range.maxFrameRate <= desiredFPS && width >= maxWidth) {
                NSLog(@"||| min: %f max: %f width: %d maxwidth: %d", range.minFrameRate, range.maxFrameRate, width, maxWidth);

                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    
    if (selectedFormat) {
        
        if ([videoDevice lockForConfiguration:nil]) {
            
            NSLog(@"selected format:%@", selectedFormat);
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)desiredFPS);
            [videoDevice unlockForConfiguration];
        }
    }
    
    if (isRunning) [self.captureSession startRunning];
}

- (void)startRecording {
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString* dateTimePrefix = [formatter stringFromDate:[NSDate date]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    if (currentOutputMode == OutputModeMovieFile) {
        
        int fileNamePostfix = 0;
        NSString *filePath = nil;
        
        do
            filePath =[NSString stringWithFormat:@"/%@/%@-%i.mp4", documentsDirectory, dateTimePrefix, fileNamePostfix++];
        while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
        
        self.fileURL = [NSURL fileURLWithPath:filePath];
        
        [self.movieFileOutput startRecordingToOutputFileURL:self.fileURL recordingDelegate:self];
    }
}

- (void)stopRecording {
    
    if (currentOutputMode == OutputModeMovieFile) {
        
        [self.movieFileOutput stopRecording];
    }
}

- (BOOL) swapCameras
{
    isFrontCamera = !isFrontCamera;
    
    AVCaptureDevicePosition desiredPosition;
    if (isFrontCamera == YES) {
        desiredPosition = AVCaptureDevicePositionFront;
    }
    else {
        desiredPosition = AVCaptureDevicePositionBack;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.captureSession beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [self.captureSession inputs]) {
                [self.captureSession removeInput:oldInput];
            }
            [self.captureSession addInput:input];
            [self.captureSession commitConfiguration];
            break;
        }
    }
    
    return YES;
}

// =============================================================================
#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void) captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
       fromConnections:(NSArray *)connections
{
    _isRecording = YES;
}

- (void) captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
       fromConnections:(NSArray *)connections error:(NSError *)error
{
    //    [self saveRecordedFile:outputFileURL];
    _isRecording = NO;
    
    if ([self.delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAtURL:error:)]) {
        [self.delegate didFinishRecordingToOutputFileAtURL:outputFileURL error:error];
    }
}

@end
