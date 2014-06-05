//
//  HFPViewController.m
//  Hands Free Player
//
//  Created by Marcio Klepacz on 6/5/14.
//  Copyright (c) 2014 Marcio Klepacz. All rights reserved.
//

#import "HFPViewController.h"
@import AVFoundation;

@interface HFPViewController ()

@property (nonatomic, weak) IBOutlet UIView *facePreviewView;

@property (nonatomic, weak) IBOutlet UIImageView *leftEyeImageView;
@property (nonatomic, weak) IBOutlet UIImageView *rightEyeImageView;
@property (nonatomic, weak) IBOutlet UIImageView *mouthImageView;

@property (nonatomic, weak) IBOutlet UIImageView *albumCoverImageView;

@property (nonatomic, weak) IBOutlet UIButton *fowardButton;
@property (nonatomic, weak) IBOutlet UIButton *backwardButton;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@property (nonatomic, strong) AVCaptureDevice *deviceFrontCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *facePreviewLayer;

@property (nonatomic) dispatch_queue_t videoDataOutputQueue;

@end

@implementation HFPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self setupFrontalCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupFrontalCamera
{
    AVCaptureDevice *device = self.deviceFrontCamera;
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error) {
        NSLog(@"Error while getting the deviceInput: %@", error);
        return;
    }
    
    if ([captureSession canAddInput:deviceInput]){
        [captureSession addInput:deviceInput];
    }
    
    // Make a video data output
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
    NSDictionary *rgbOutputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCMPixelFormat_32BGRA]};
    
    self.videoDataOutput.videoSettings = rgbOutputSettings;
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES; // discard if the data output queue is blocked

    // create a serial dispatch queue used for the sample buffer delegate
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    if ([captureSession canAddOutput:self.videoDataOutput]){
        [captureSession addOutput:self.videoDataOutput];
    }
    
    // get the output for doing face detection.
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
    
    self.facePreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    self.facePreviewLayer.backgroundColor = [[UIColor blackColor] CGColor];
    self.facePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    CALayer *rootLayer = [self.facePreviewView layer];
    
    rootLayer.masksToBounds = YES;
    self.facePreviewLayer.frame = rootLayer.bounds;
    [rootLayer addSublayer:self.facePreviewLayer];
    
    [captureSession startRunning];
}

-(AVCaptureDevice *)deviceFrontCamera
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    
}

@end
