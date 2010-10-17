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
  NSWindow *fullscreenWindow;
  NSWindow *countdownWindow;
  NSImageView *countdowView;
  IKImageView* mainImage;
  IKImageBrowserView *browserView;
  NSTextField *statusText;
  NSButton *printButton;

  // Preferences Sheet Elements.
  NSWindow *preferencesSheet;
  NSTextField *selectedImagesFolder;
  NSTextField *selectedSmilesFolder;
  NSButton *setImagesFolderButton;
  NSButton *setSmilesFolderButton;
  IKDeviceBrowserView *deviceBrowserView;

  // Stock images.
  ImageInfo* defaultImage;
  ImageInfo* countdownImage0;
  ImageInfo* countdownImage1;
  ImageInfo* countdownImage2;
  ImageInfo* countdownImage3;
  NSMutableArray* smileList;
	
  // Stock sounds.
	NSSound *beepSound;

  // Controller state.
  NSRect originalFrame;
  NSString* imagesFolder;
  NSString* smileDirectory;
  NSMutableArray* imageList;  // Holds images from oldest to most recent.
  enum CaputreState state;
  NSUserDefaults* preferences;
  SEL printSheetDidEndSelector;
  NSPrintInfo *printInfo;
  NSTimer* cameraResetWatchdog;  // Resets to ready if camera doesn't snap.
  NSTimer* countdownTimer;  // Timer for executing the countdown.
  int currentCount;  // Used during the count-down to taking a picture.
                     // Snapshot happens at 0.
  
  // Camera search state.
  ICDeviceBrowser* deviceBrowser;
  NSMutableArray* cameras;
  ICCameraDevice* activeCamera;
}

@property(retain, nonatomic) IBOutlet NSWindow *window;
@property(retain, nonatomic) IBOutlet NSWindow *fullscreenWindow;
@property(retain, nonatomic) IBOutlet NSWindow *countdownWindow;
@property(retain, nonatomic) IBOutlet NSImageView *countdownView;
@property(retain, nonatomic) IBOutlet IKImageView *mainImage;
@property(retain, nonatomic) IBOutlet IKImageBrowserView *browserView;
@property(retain, nonatomic) IBOutlet NSTextField *statusText;
@property(retain, nonatomic) IBOutlet NSButton *printButton;

// Preferences sheet stuff.
@property(retain, nonatomic) IBOutlet NSWindow *preferencesSheet;
@property(retain, nonatomic) IBOutlet NSTextField *selectedImagesFolder;
@property(retain, nonatomic) IBOutlet NSTextField *selectedSmilesFolder;
@property(retain, nonatomic) IBOutlet NSButton* setImagesFolderButton;
@property(retain, nonatomic) IBOutlet NSButton* setSmilesFolderButton;
@property(retain, nonatomic) IBOutlet IKDeviceBrowserView *deviceBrowserView;

@property(readonly, retain, nonatomic) NSString* imagesFolder;
@property(readonly, retain, nonatomic) NSString* smilesFolder;
@property(retain, nonatomic) ImageInfo* defaultImage;
@property(retain, nonatomic) ImageInfo* countdownImage0;
@property(retain, nonatomic) ImageInfo* countdownImage1;
@property(retain, nonatomic) ImageInfo* countdownImage2;
@property(retain, nonatomic) ImageInfo* countdownImage3;
@property(retain, nonatomic) NSMutableArray* imageList;
@property(retain, nonatomic) NSMutableArray* smileList;
@property(retain, nonatomic) NSSound* beepSound;

// UI Actions.
- (IBAction)takePicture:(id)pId;
- (IBAction)print:(id)pId;
- (IBAction)showPageLayout:(id)pId;
- (IBAction)showPrintPanel:(id)pId;
- (IBAction)resetPrintInfo:(id)pId;
- (IBAction)resetMarginsPagination:(id)pId;
- (IBAction)enterFullscreen:(id)pId;
- (IBAction)leaveFullscreen:(id)pId;

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
- (void)setImagesFolder:(NSString*)path;
- (void)setSmilesFolder:(NSString*)path;

// Internal functions.
- (void)initializeMainImage;
- (void)initializeBrowseList;
- (void)rescanImagesDirectory;
- (void)rescanSmilesFolder;
- (void)addImagesWithPath:(NSString*)path to:(NSMutableArray*)targetList;
- (void)addAnImageWithPath:(NSString*)path to:(NSMutableArray*)targetList;
- (void)setReadyText:(NSString*)deviceName;
- (void)setDownloadingText:(NSString*)filename;
- (void)setUninitialized;
- (void)setActiveCamera:(ICCameraDevice*)camera;
- (void)snapshotWatchdog:(NSTimer*)timer;
- (void)onCountdown:(NSTimer*)timer;
- (void)createCountdownUI;
- (void)showCountdownUI;
- (void)hideCountdownUI;
- (void)updateCountdownUI:(int)count;
- (void)updateMainImage:(ImageInfo*)info shouldZoom:(BOOL)zoom;
- (void)updateCountdownImage:(ImageInfo*)info shouldZoom:(BOOL)zoom;
@end
