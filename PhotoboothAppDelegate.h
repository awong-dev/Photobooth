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
  NSTextField *statusText;
  NSButton *printButton;

  // Preferences Sheet Elements.
  NSWindow *preferencesSheet;
  NSTextField *selectedImagesDirectory;
  IKDeviceBrowserView *deviceBrowserView;

  // Controller state.
  NSString* imagesDirectory;
  ImageInfo* defaultImage;
  NSMutableArray* imageList;  // Holds images from oldest to most recent.
  enum CaputreState state;
  NSTimer* cameraResetWatchdog;  // Resets to ready if camera is taking too long.
  NSUserDefaults* preferences;
  SEL printSheetDidEndSelector;
  NSPrintInfo *printInfo;
  
  // Camera search state.
  ICDeviceBrowser* deviceBrowser;
  NSMutableArray* cameras;
  ICCameraDevice* activeCamera;
}

@property(retain, nonatomic) IBOutlet NSWindow *window;
@property(retain, nonatomic) IBOutlet IKImageView *mainImage;
@property(retain, nonatomic) IBOutlet IKImageBrowserView *browserView;
@property(retain, nonatomic) IBOutlet NSTextField *statusText;
@property(retain, nonatomic) IBOutlet NSButton *printButton;

// Preferences sheet stuff.
@property(retain, nonatomic) IBOutlet NSWindow *preferencesSheet;
@property(retain, nonatomic) IBOutlet NSTextField *selectedImagesDirectory;
@property(retain, nonatomic) IBOutlet IKDeviceBrowserView *deviceBrowserView;

@property(readonly, retain) NSString* imagesDirectory;
@property(retain, nonatomic) ImageInfo* defaultImage;
@property(retain, nonatomic) NSMutableArray* imageList;

// UI Actions.
- (IBAction)takePicture:(id)pId;
- (IBAction)scrollBrowseLeft:(id)pId;
- (IBAction)scrollBrowseRight:(id)pId;
- (IBAction)print:(id)pId;
- (IBAction)showPageLayout:(id)pId;
- (IBAction)showPrintPanel:(id)pId;
- (IBAction)resetPrintInfo:(id)pId;

// Preferences Sheetl Actions.
- (IBAction)savePreferences:(id)pId;
- (IBAction)cancelPreferences:(id)pId;
- (IBAction)showPreferences:(id)pId;
- (IBAction)showImageDirectoryChooser:(id)pId;
- (void)deviceBrowserView:(IKDeviceBrowserView *)deviceBrowserView
        didEncounterError:(NSError *)error;
- (void)deviceBrowserView:(IKDeviceBrowserView *)deviceBrowserView
       selectionDidChange:(ICDevice *)device;

// IKImageBrowserView delegates.
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser;
- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index;

// ICDeviceBrowserDelegate
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)device moreComing:(BOOL)moreComing;
- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing;

// Public API.
- (void)setImagesDirectory:(NSString*)path;

// Internal functions.
- (void)initializeMainImage;
- (void)initializeBrowseList;
- (void)rescanImagesDirectory;
- (void)addImagesWithPath:(NSString*)path;
- (void)addAnImageWithPath:(NSString*)path;
- (void)setReadyText:(NSString*)deviceName;
- (void)setDownloadingText:(NSString*)filename;
- (void)setUninitialized;
- (void)setActiveCamera:(ICCameraDevice*)camera;
- (void)snapshotWatchdog:(NSTimer*)timer;
@end
