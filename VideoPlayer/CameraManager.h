//
//  TTMCaptureManager.h
//  VideoPlayer
//
//  Created by Vladyslav Gusakov on 4/13/16.
//  Copyright © 2016 Vladyslav Gusakov. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import CoreMedia;
@import UIKit;

typedef NS_ENUM(NSUInteger, CameraType) {
    CameraTypeBack,
    CameraTypeFront,
};

typedef NS_ENUM(NSUInteger, OutputMode) {
    OutputModeVideoData,
    OutputModeMovieFile,
};


@protocol CameraManagerDelegate <NSObject>
- (void)didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                                      error:(NSError *)error;
@end


@interface CameraManager : NSObject {
    BOOL isFrontCamera;
}

@property (nonatomic, assign) id<CameraManagerDelegate> delegate;
@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

- (instancetype)initWithPreviewView:(UIView *)previewView
                preferredCameraType:(CameraType)cameraType
                         outputMode:(OutputMode)outputMode;
- (void)resetFormat;
- (void)switchFormatWithDesiredFPS:(CGFloat)desiredFPS;
- (void)startRecording;
- (void)stopRecording;
+ (AVCaptureDevice *)frontCaptureDevice;
- (BOOL) swapCameras;

@end
