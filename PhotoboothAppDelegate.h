//
//  PhotoboothAppDelegate.h
//  Photobooth
//
//  Created by Albert J. Wong on 7/20/10.
//  Copyright 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

#import "ImageInfo.h";

enum CaputreState {
  kUninitialized,
  kReady,
  kTakingPicture,
  kDownloadingFile,
};

@interface PhotoboothAppDelegate : NSObject<ICDeviceBrowserDelegate, ICCameraDeviceDelegate> {
 @private
  // UI Elements.
  NSWindow *window;
  IKImageView* mainImage;
  IKImageBrowserView *browserView;
  NSScrollView* browserViewContainer;
  NSTextField *statusText;

  // Controller state.
  NSString* imagesDirectory;
  ImageInfo* defaultImage;
  NSMutableArray* imageList;  // Holds images from oldest to most recent.
  enum CaputreState state;
  
  // Camera search state.
  ICDeviceBrowser* deviceBrowser;
  NSMutableArray* cameras;
}

@property(retain, nonatomic) IBOutlet NSWindow *window;
@property(retain, nonatomic) IBOutlet IKImageView *mainImage;
@property(retain, nonatomic) IBOutlet IKImageBrowserView *browserView;
@property(retain, nonatomic) IBOutlet NSScrollView *browserViewContainer;
@property(retain, nonatomic) IBOutlet NSTextField *statusText;

@property(retain) NSString* imagesDirectory;
@property(retain, nonatomic) ImageInfo* defaultImage;
@property(retain, nonatomic) NSMutableArray* imageList;

// UI Actions.
- (IBAction)takePicture:(id)pId;
- (IBAction)scrollBrowseLeft:(id)pId;
- (IBAction)scrollBrowseRight:(id)pId;
- (IBAction)print:(id)pId;
- (IBAction)showEffects:(id)pId;

// IKImageBrowserView delegates.
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser;
- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index;

// ICDeviceBrowserDelegate
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)device moreComing:(BOOL)moreComing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing;

// Internal functions.
- (void)initializeMainImage;
- (void)initializeBrowseList;
- (void)addImagesWithPath:(NSString*)path;
- (void)addAnImageWithPath:(NSString*)path;
- (void)setReadyText:(NSString*)deviceName;
- (void)setDownloadingText:(NSString*)filename;
- (void)setUninitialized;
@end
