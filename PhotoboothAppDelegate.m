//
//  PhotoboothAppDelegate.m
//  Photobooth
//
//  Created by Albert J. Wong on 7/20/10.
//  Copyright 2010. All rights reserved.
//

#import "PhotoboothAppDelegate.h"

#import <Quartz/Quartz.h>
#import <ImageCaptureCore/ImageCaptureCore.h>
#import <ApplicationServices/ApplicationServices.h>

@implementation PhotoboothAppDelegate

@synthesize window;
@synthesize fullscreenWindow;
@synthesize countdownWindow;
@synthesize countdownView;
@synthesize countdownStatus;
@synthesize mainImage;
@synthesize browserView;
@synthesize statusText;
@synthesize printButton;

@synthesize preferencesSheet;
@synthesize selectedImagesFolder;
@synthesize selectedSmilesFolder;
@synthesize setImagesFolderButton;
@synthesize setSmilesFolderButton;
@synthesize deviceBrowserView;

@synthesize imagesFolder;
@synthesize smilesFolder;
@synthesize defaultImage;
@synthesize countdownImage0;
@synthesize countdownImage1;
@synthesize countdownImage2;
@synthesize countdownImage3;
@synthesize countdownImageN1;
@synthesize imageList;
@synthesize smileList;
@synthesize beepSound;

NSString* kPrintInfoPref = @"UserPrintInfoRaw";
NSString* kImageFolderPref = @"UserImageDirectory";
NSString* kSmilesFolderPref = @"UserSmileDirectory";

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
  // terminate when last window was closed
  return YES;
}

- (id)init {
  if (self = [super init])
  {
    self.defaultImage = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"camera" ofType:@"png"]];
    self.countdownImage0 = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"film-leader-0" ofType:@"png"]];
    self.countdownImage1 = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"film-leader-1" ofType:@"png"]];
    self.countdownImage2 = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"film-leader-2" ofType:@"png"]];
    self.countdownImage3 = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"film-leader-3" ofType:@"png"]];
    self.countdownImageN1 = 
      [[ImageInfo alloc] initWithPath:
        [[NSBundle mainBundle] pathForResource:@"film-leader--1" ofType:@"png"]];    
    imageList = [[NSMutableArray alloc] init];
    smileList = [[NSMutableArray alloc] init];
    printSheetDidEndSelector =
        @selector(printSheetDidEnd:returnCode:contextInfo:);
	  beepSound = [NSSound soundNamed:@"beep.wav"];
  }
  return self;
}

- (void)awakeFromNib {
  // Load preferences.
  preferences = [NSUserDefaults standardUserDefaults];  
  NSData* defaultPrintInfo = [preferences dataForKey:kPrintInfoPref];
  NSString* defaultImageFolder = [preferences objectForKey:kImageFolderPref];
  NSString* defaultSmilesFolder = [preferences objectForKey:kSmilesFolderPref];
  if (defaultPrintInfo) {
    printInfo =
      [NSUnarchiver unarchiveObjectWithData:defaultPrintInfo];
  } else {
    printInfo = nil;
  }

  if (printInfo == nil) {
    printInfo = [NSPrintInfo sharedPrintInfo];
    [self resetPrintInfo:nil];
  } else {
    [NSPrintInfo setSharedPrintInfo:printInfo]; 
  }
  if (defaultImageFolder == nil) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory,
        NSUserDomainMask, YES);
    defaultImageFolder = [paths objectAtIndex:0];
  }
  if (defaultSmilesFolder == nil) {
    defaultSmilesFolder = @"";
  }

  // Setup the UI.
  [self setImagesFolder:defaultImageFolder];
  [self setSmilesFolder:defaultSmilesFolder];
  [self initializeMainImage];
  [self setUninitialized];
  [self createCountdownUI];
}


- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
  // Setup cameras.
  cameras = [[NSMutableArray alloc] initWithCapacity:0];
  
  // Get an instance of ICDeviceBrowser
  deviceBrowser = [[ICDeviceBrowser alloc] init];
  // Assign a delegate
  deviceBrowser.delegate = self;
  
  // We only want local caneras.
  deviceBrowser.browsedDeviceTypeMask = deviceBrowser.browsedDeviceTypeMask 
    | ICDeviceTypeMaskCamera
    | ICDeviceLocationTypeMaskLocal;

  [deviceBrowser start];
}

- (void)applicationWillTerminate:(NSNotification*)notification {
  deviceBrowser.delegate = NULL;
  [deviceBrowser stop];
  [deviceBrowser release];
  [cameras release];
}

//
// ------ UI Actions -------
//
- (IBAction)takePicture:(id)pId {
  [self showCountdownUI];

  // Do 3 second countdown.
  currentCount = 3;
  [self updateCountdownUI:currentCount];
  [NSTimer
    scheduledTimerWithTimeInterval:1.0
                            target:self
                          selector:@selector(onCountdown:)
                          userInfo:nil
                           repeats:YES];
}

- (IBAction)onCountdown:(NSTimer*)timer {
  [self updateCountdownUI:--currentCount];
  if (currentCount == 1) {
    snapsLeft = 3;
    [NSTimer scheduledTimerWithTimeInterval:1.2
                                     target:self
                                   selector:@selector(onSnapTimer:)
                                   userInfo:nil
                                    repeats:NO];
  } else if (currentCount <= -1) {
    [timer invalidate];
    timer = nil;
  }
}

- (void)onSnapTimer:(NSTimer*)timer {
  if (snapsLeft > 0) {
    snapsLeft--;
    [self snapCamera];
  }
}

- (void)snapCamera {
  state = kTakingPicture;    
  [activeCamera requestTakePicture];
  if (cameraResetWatchdog != nil) {
    [cameraResetWatchdog invalidate];
    [cameraResetWatchdog release];
    cameraResetWatchdog = nil;
  }
  cameraResetWatchdog = [[NSTimer
    scheduledTimerWithTimeInterval:4.0
                            target:self
                          selector:@selector(snapshotWatchdog:)
                          userInfo:nil
                           repeats:NO]
                           retain];
}


- (void)updateCountdownUI:(int)count {
  switch (count) {      
    case -1:
      [self updateCountdownImage:self.countdownImageN1 shouldZoom:NO];
      break;      

    default:
    case 0:
    {
      int smileCount = [smileList count];
      NSLog(@"SmileCount: %d", smileCount);
      if (smileCount != 0)  {
        int i = rand() % smileCount;
        [self updateCountdownImage:[smileList objectAtIndex:i] shouldZoom:NO];
      } else {
        [self updateCountdownImage:self.countdownImage0 shouldZoom:NO];
      }
    }
      
      break;

    case 1:
      [self updateCountdownImage:self.countdownImage1 shouldZoom:NO];
      [beepSound play];
      break;

    case 2:
      [self updateCountdownImage:self.countdownImage2 shouldZoom:NO];
      [beepSound play];
      break;
 
    case 3:
      [self updateCountdownImage:self.countdownImage3 shouldZoom:NO];
      [beepSound play];
      break;
  }
  [countdownView setNeedsDisplay:YES];
}

- (IBAction)print:(id)pId {
  // If the image has edits, save to disk.
  // Print the main image.  The IKImageView does not seem to support printing
  // directly which is strange.
  NSIndexSet* indexes = [browserView selectionIndexes];
  if ([indexes count] == 0) {
    return;
  }
  ImageInfo* imageInfo = [self imageBrowser:browserView
                                itemAtIndex:[indexes firstIndex]];
  NSImage* image = [[NSImage alloc] initByReferencingURL:[imageInfo url]];
  NSSize imageSize = [image size];
  NSRect frameSize = NSMakeRect(0, 0, imageSize.width, imageSize.height);
  NSImageView* printableView = [[NSImageView alloc] initWithFrame:frameSize];
  [printableView setImage:image];

  // Force orientation here.
  if (imageSize.width > imageSize.height) {
    [printInfo setOrientation:NSLandscapeOrientation];
  } else {
    [printInfo setOrientation:NSPortraitOrientation];
  }

  NSPrintOperation *op =
      [NSPrintOperation printOperationWithView:printableView
                                     printInfo:printInfo];
  if (pId == printButton) {
    [op setShowsPrintPanel:NO];
  }
  [op setJobTitle:
      [[NSString alloc] initWithFormat:@"Photobooth: %@", [[imageInfo url] path]]];  
  [op runOperationModalForWindow:window
                        delegate:self
                  didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
                      contextInfo:NULL];
}

- (void)printSheetDidEnd:(id)sheet
              returnCode:(int)returnCode
             contextInfo:(void *)contextInfo {
  if (returnCode == NSOKButton) {
    [preferences setObject:
        [NSArchiver archivedDataWithRootObject:[sheet printInfo]]
                    forKey:kPrintInfoPref];
    [preferences synchronize];
  }
}

- (void)printOperationDidRun:(NSPrintOperation *)op
                     success:(BOOL)success 
                 contextInfo:(void *)contextInfo {
  if (success) {
    printInfo = [[op printInfo] retain];
    [preferences setObject:
        [NSArchiver archivedDataWithRootObject:printInfo]
                    forKey:kPrintInfoPref];
    [preferences synchronize];
  }
}

- (IBAction)showPageLayout:(id)pId {
  NSPageLayout *pageLayout = [NSPageLayout pageLayout];
  [pageLayout beginSheetWithPrintInfo:printInfo
                       modalForWindow:window
                             delegate:self
                       didEndSelector:printSheetDidEndSelector
                          contextInfo:nil];
}

- (IBAction)showPrintPanel:(id)pId {
  NSPrintPanel *printPanel = [NSPrintPanel printPanel];
  [printPanel beginSheetWithPrintInfo:printInfo
                       modalForWindow:window
                             delegate:self
                       didEndSelector:printSheetDidEndSelector
                          contextInfo:nil];
}

- (IBAction)resetPrintInfo:(id)pId {
  printInfo = [[NSPrintInfo alloc] initWithDictionary:[NSDictionary dictionary]];
  [NSPrintInfo setSharedPrintInfo: printInfo];
  [self resetMarginsPagination:pId];
}

- (IBAction)resetMarginsPagination:(id)pId {
  [printInfo setTopMargin:0];
  [printInfo setLeftMargin:0];
  [printInfo setRightMargin:0];
  [printInfo setBottomMargin:0];
  [printInfo setVerticalPagination:NSClipPagination];
  [printInfo setHorizontalPagination:NSFitPagination];
  [printInfo setVerticallyCentered:YES];
  [printInfo setHorizontallyCentered:YES];
}

- (IBAction)enterFullscreen:(id)pId {
  originalFrame = [window frame];
  [window setFrame:[window frameRectForContentRect:[[window screen] frame]]
           display:YES
           animate:YES];
  if ([[window screen] isEqual:[[NSScreen screens] objectAtIndex:0]]) {
    [NSMenu setMenuBarVisible:NO];
  }

  fullscreenWindow = [[NSWindow alloc]
    initWithContentRect:[window contentRectForFrameRect:[window frame]]
              styleMask:NSBorderlessWindowMask
                backing:NSBackingStoreBuffered
                  defer:YES
                 screen:[window screen]];
  [fullscreenWindow setLevel:NSFloatingWindowLevel];
  [fullscreenWindow setContentView:[window contentView]];
  [fullscreenWindow setTitle:[window title]];
  [fullscreenWindow setFrame:[[window screen] frame]
                     display:YES
                     animate:YES];
  [fullscreenWindow makeKeyAndOrderFront:nil];
}

- (IBAction)leaveFullscreen:(id)pId {
  if (fullscreenWindow != nil) {
    [window setContentView:[fullscreenWindow contentView]];
    [fullscreenWindow setLevel:NSNormalWindowLevel];
    [fullscreenWindow orderOut:nil];
    fullscreenWindow = nil;    
    [window setFrame:originalFrame
             display:YES
             animate:YES];
    [NSMenu setMenuBarVisible:YES];
  }
}

//
// ------ Preferences Sheet Actions ------
//

- (IBAction)showPreferences:(id)pId {
  [NSApp beginSheet:preferencesSheet modalForWindow:window
      modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction)savePreferences:(id)pId {
  [self setImagesFolder:[selectedImagesFolder stringValue]];
  [self setSmilesFolder:[selectedSmilesFolder stringValue]];
  [preferencesSheet orderOut:nil];
  [NSApp endSheet:preferencesSheet];
  activeCamera = [(ICCameraDevice*)[deviceBrowserView selectedDevice] retain];
}

- (IBAction)cancelPreferences:(id)pId {
  [preferencesSheet orderOut:nil];
  [NSApp endSheet:preferencesSheet];
}

- (IBAction)showImageDirectoryChooser:(id)pId {
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  [panel setCanChooseFiles:NO];
  [panel setCanChooseDirectories:YES];
  [panel beginWithCompletionHandler: ^ (NSInteger result) {
    if (result == NSFileHandlingPanelOKButton) {
      if (pId == setImagesFolderButton) {
        [selectedImagesFolder setStringValue:[panel filename]];
      } else if (pId == setSmilesFolderButton) {
        [selectedSmilesFolder setStringValue:[panel filename]];
      }
    }
  }];
}

- (void)deviceBrowserView:(IKDeviceBrowserView *)deviceBrowserView
       selectionDidChange:(ICDevice *)device {
}

- (void)deviceBrowserView:(IKDeviceBrowserView *)deviceBrowserView
        didEncounterError:(NSError *)error {
}

//
// ------ IKImageBrowserView delegates------
//
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
  return [imageList count];
}

- (id) imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
  return [imageList objectAtIndex:[imageList count] - index - 1];
}

- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) aBrowser {
  NSIndexSet* indexes = [browserView selectionIndexes];
  if ([indexes count] > 0) {
    [self updateMainImage:[self imageBrowser:browserView itemAtIndex:[indexes firstIndex]]
               shouldZoom:YES];
  }
}

//
// ------ Public API -------
//
- (void)setImagesFolder:(NSString*) path {
  if ([imagesFolder isEqual:path]) {
    return;
  }
  // We write our own setting becaus we want to always update the labels when
  // we set this path.
  [imagesFolder release];
  imagesFolder = path;
  [imagesFolder retain];

  [preferences setObject:imagesFolder forKey:kImageFolderPref];
  [preferences synchronize];
  
  [selectedImagesFolder setStringValue:imagesFolder];
  [self rescanImagesDirectory];
};

- (void)setSmilesFolder:(NSString*) path {
  if ([smilesFolder isEqual:path]) {
    return;
  }
  // We write our own setting becaus we want to always update the labels when
  // we set this path.
  [smilesFolder release];
  smilesFolder = path;
  [smilesFolder retain];
  
  [preferences setObject:smilesFolder forKey:kSmilesFolderPref];
  [preferences synchronize];
  
  [selectedSmilesFolder setStringValue:smilesFolder];
  [self rescanSmilesFolder];
};

//
// ------ Internal functions -------
//

- (void)initializeMainImage {
  [self updateMainImage:self.defaultImage shouldZoom:NO];
  
  // customize the IKImageView...
  [mainImage setDoubleClickOpensImageEditPanel: NO];
  [mainImage setCurrentToolMode: IKToolModeNone];
  [mainImage setDelegate: self];
}

- (void)initializeBrowseList {
  [browserView setZoomValue:1.0f];
  [browserView setContentResizingMask:NSViewWidthSizable];  // Don't grow veritcally.
  [browserView setAllowsMultipleSelection:NO];
  [browserView reloadData];
}

- (void)rescanImagesDirectory {
  [imageList removeAllObjects];
  [self addImagesWithPath:imagesFolder to:imageList];
  [self initializeBrowseList];
}

- (void)rescanSmilesFolder {
  NSLog(@"Scanning: %@", smilesFolder);
  if (![smilesFolder isEqual: @""]) {
    [smileList removeAllObjects];
    [self addImagesWithPath:smilesFolder to:smileList];
  }
}

- (void)addImagesWithPath:(NSString*)path to:(NSMutableArray*)targetList {
  NSFileManager *localFileManager = [[[NSFileManager alloc] init] autorelease];
  NSDirectoryEnumerator *dirEnum =
    [localFileManager enumeratorAtPath:path];

  NSString *file;
  while (file = [dirEnum nextObject]) {
    NSString* extension = [file pathExtension];
    if ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
        [extension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
      [self addAnImageWithPath:[path stringByAppendingPathComponent:file]
                            to:targetList];
    }
  }
}

- (void)addAnImageWithPath:(NSString *)path to:(NSMutableArray*)targetList
{
  ImageInfo *imageInfo;

  imageInfo = [[[ImageInfo alloc] initWithPath:path] autorelease];
  [targetList addObject:imageInfo];
}


// ----- ICDeviceBrowser protocol -----

// Method delegates for device added and removed
//
// Device browser maintains list of cameras as key-value pairs, so delegate
// must call willChangeValueForKey to modify list
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{    
  if ( addedDevice.type & ICDeviceTypeCamera )
  {
    if ([addedDevice.capabilities indexOfObject:ICCameraDeviceCanTakePicture] == NSNotFound) {
      NSLog(@"Device: %@ cannot take pictures", addedDevice.name);		
      return;
    }
    NSLog(@"Adding device: %@", addedDevice.name);
    addedDevice.delegate = self;
    
    // implement manual observer notification for the cameras property
    [self willChangeValueForKey:@"cameras"];
    [cameras addObject:addedDevice];
    [self didChangeValueForKey:@"cameras"];

    if (activeCamera == nil) {
      [self setActiveCamera:(ICCameraDevice*)addedDevice];
    }
  }
}


- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing
{
  device.delegate = NULL;

  // implement manual observer notification for the cameras property
  [self willChangeValueForKey:@"cameras"];
  [cameras removeObject:device];
  [self didChangeValueForKey:@"cameras"];
  
  if (activeCamera == device && [cameras count] == 0) {
    [self setActiveCamera:nil];
  } else {
    [self setActiveCamera:[cameras lastObject]];
  }
}

// Check to see if the camera has image files to download
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ( [keyPath isEqualToString:@"selectedObjects"] && (object == self) )
  {
    [self willChangeValueForKey:@"canDownload"];
    [self didChangeValueForKey:@"canDownload"];
  }
}

// ---- ICCameraDeviceDelegate ----

- (void)didRemoveDevice:(ICDevice*)device {
  // Do nothing. device browser delegate handles our state.
}

- (void)didDownloadFile:(ICCameraFile*)file
                  error:(NSError*)error
                options:(NSDictionary*)options
            contextInfo:(void*)contextInfo {
  NSString* filename = [options objectForKey:ICSavedFilename];
  [self addAnImageWithPath:[imagesFolder stringByAppendingPathComponent:filename]
                        to:imageList];
  [browserView reloadData];
  [self imageBrowserSelectionDidChange:browserView];
  
  // Must scroll *after* we've reloaded the data, otherwise we use the stale array.
  [browserView scrollIndexToVisible:0];
  NSIndexSet* selectFirst = [[NSIndexSet alloc] initWithIndex:0];
  [browserView setSelectionIndexes:selectFirst byExtendingSelection:NO];  
  
  [self setReadyText:[[file device] name]];
  [cameraResetWatchdog invalidate];
  [cameraResetWatchdog release];
  cameraResetWatchdog = nil;
  NSLog(@"Snaps left %d\n", snapsLeft);
  if (snapsLeft > 0) {
    [self onSnapTimer:nil];
  } else {
    [self hideCountdownUI];
  }
}

- (void)cameraDevice:(ICCameraDevice*)camera didAddItem:(ICCameraItem*)item {
  NSLog(@"Item name %@", [item name]);
  if (state != kTakingPicture) {
    // Ignore random item adds since we only want the result of the snapshot.
    // The camera seems to like to send all its pictures at startup, so this
    // is useful.
    return;
  }
  if (![item isKindOfClass:[ICCameraFile class]]) {
    // We only handle files.
    return;
  }
  
  // Download it if it's an image.
  if ([[item UTI] isEqualToString:(NSString*)kUTTypeImage]) {
    NSDictionary* downloadOptions = [NSDictionary
      dictionaryWithObject:[NSURL fileURLWithPath:imagesFolder]
                    forKey:ICDownloadsDirectoryURL];

    [camera requestDownloadFile:(ICCameraFile*)item
                        options:downloadOptions
           downloadDelegate:self
            didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:)
                contextInfo:NULL];
    [self setDownloadingText:[item name]];
  }
}

- (void)device:(ICDevice*)device didOpenSessionWithError:(NSError*)error {
  if (error != nil) {
    NSLog(@"Error %@", error);
    return;
  }
  [self setReadyText:[device name]];
}

- (void)device:(ICDevice*)device didCloseSessionWithError:(NSError*)error {
  if (error != nil) {
    NSLog(@"Error %@", error);
  }
  // We retained this in setActiveCamera.
  [device release];
}

- (void)setReadyText:(NSString*)deviceName {
  state = kReady;
  [statusText setStringValue:
      [[NSString alloc] initWithFormat:@"%@ Ready", deviceName]];  
}

- (void)setDownloadingText:(NSString*)filename {
  state = kDownloadingFile;
  [statusText setStringValue:
      [[NSString alloc] initWithFormat:@"Downloading %@", filename]];  
}

- (void)setUninitialized {
  state = kUninitialized;
  [statusText setStringValue:@"No Camera Found"];
}

- (void)setActiveCamera:(ICCameraDevice*)camera {
  [activeCamera requestCloseSession];
  activeCamera = [camera retain];
  if (camera != nil) {
    [activeCamera requestOpenSession];
  } else {
    [self setUninitialized];
  }
}

- (void)snapshotWatchdog:(NSTimer*)timer {
  if (activeCamera) {
    [self setReadyText:[activeCamera name]];
  } else {
    [self setUninitialized];
  }
  [self hideCountdownUI];
}

- (void)updateMainImage:(ImageInfo*)info shouldZoom:(BOOL)zoom {
  [mainImage setImageWithURL:info.url];
  if (zoom) {
    [mainImage zoomImageToFit: self]; 
  }
  [mainImage setNeedsDisplay:YES];
}

- (void)updateCountdownImage:(ImageInfo*)info shouldZoom:(BOOL)zoom {
  NSImage *image = [[[NSImage alloc] initWithContentsOfURL:info.url] autorelease];
//  if (zoom) {
    [image setScalesWhenResized: YES];
    [image setSize: [countdownView frame].size];
//  }
  [countdownView setImage:image];
  [countdownView setNeedsDisplay:YES];
}

- (void)showCountdownUI {
  // Capture the main display
  if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
      NSLog( @"Couldn't capture the main display!" );
      // Note: you'll probably want to display a proper error dialog here
  }

  [countdownWindow makeKeyAndOrderFront:nil];
}

- (void)createCountdownUI {
  int windowLevel;
  NSRect screenRect;

  // Get the shielding window level
  windowLevel = CGShieldingWindowLevel();
   
  // Get the screen rect of our main display
  screenRect = [[NSScreen mainScreen] frame];
   
  // Put up a new window
  countdownWindow = [[NSWindow alloc]
    initWithContentRect:screenRect
              styleMask:NSBorderlessWindowMask
                backing:NSBackingStoreBuffered
                  defer:NO
                 screen:[NSScreen mainScreen]];
                                      
  [countdownWindow setLevel:windowLevel];
  [countdownWindow setBackgroundColor:[NSColor blackColor]];
   
  // Create countdown view and add it
  countdownView = [[NSImageView alloc] initWithFrame: screenRect];
  [countdownView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [countdownWindow setContentView:countdownView];

  // Add a text overlay for messages.
  countdownStatus = [[NSTextField alloc] initWithFrame: screenRect];
}

- (void)hideCountdownUI
{
  [countdownWindow orderOut:self];

  // Capture the main display
  if (CGDisplayRelease( kCGDirectMainDisplay ) != kCGErrorSuccess) {
    NSLog( @"Couldn't release the main display!" );
    // Note: you'll probably want to display a proper error dialog here
  }
}

@end
