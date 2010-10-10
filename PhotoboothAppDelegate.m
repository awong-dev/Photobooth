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

@implementation PhotoboothAppDelegate

@synthesize window;
@synthesize mainImage;
@synthesize browserView;
@synthesize statusText;
@synthesize printButton;

@synthesize preferencesSheet;
@synthesize selectedImagesDirectory;
@synthesize deviceBrowserView;

@synthesize imagesDirectory;
@synthesize defaultImage;
@synthesize imageList;

NSString* kPrintInfoPref = @"UserPrintInfoRaw";
NSString* kImageDirectoryPref = @"UserImageDirectory";

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
          [NSHomeDirectory() stringByAppendingPathComponent:@"marmalade.png"]];
    imageList = [[NSMutableArray alloc] init];
    printSheetDidEndSelector =
        @selector(printSheetDidEnd:returnCode:contextInfo:);
  }
  return self;
}


- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
  // Load preferences.
  preferences = [NSUserDefaults standardUserDefaults];  
  NSData* defaultPrintInfo = [preferences dataForKey:kPrintInfoPref];
  NSString* defaultImageDirectory =
      [preferences objectForKey:kImageDirectoryPref];
  printInfo =
      [NSUnarchiver unarchiveObjectWithData:defaultPrintInfo];
  
  if (printInfo == nil) {
    printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin:0];
    [printInfo setLeftMargin:0];
    [printInfo setRightMargin:0];
    [printInfo setBottomMargin:0];
    [printInfo setVerticalPagination:NSFitPagination];
    [printInfo setHorizontalPagination:NSFitPagination];
  } else {
    [NSPrintInfo setSharedPrintInfo:printInfo]; 
  }
  if (defaultImageDirectory == nil) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory,
        NSUserDomainMask, YES);
    defaultImageDirectory = [paths objectAtIndex:0];
  }

  // Fixup the UI.
  [self setImagesDirectory:defaultImageDirectory];
  [self initializeMainImage];
  [self setUninitialized];


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
  if (state != kReady) {
    // TODO(awong): Pop up an eror?
    return;
  }
  
  [activeCamera requestTakePicture];
  state = kTakingPicture;
  // TODO(ajwong): Setup watchdog timer that will close session and restart if
  // download does not complete in 3 seconds.
  if (cameraResetWatchdog != nil) {
    [cameraResetWatchdog invalidate];
    cameraResetWatchdog = nil;
  }
  cameraResetWatchdog = [[NSTimer
                         scheduledTimerWithTimeInterval:2.0
                                                 target:self
                                               selector:@selector(snapshotWatchdog:)
                                               userInfo:nil
                                                repeats:NO]
                         retain];
}

- (IBAction)scrollBrowseLeft:(id)pId {
  NSIndexSet *visibleIndexes = [browserView visibleItemIndexes];
  [browserView scrollIndexToVisible:[visibleIndexes firstIndex]];
  [browserView setNeedsDisplay:YES];
}

- (IBAction)scrollBrowseRight:(id)pId {
  NSIndexSet *visibleIndexes = [browserView visibleItemIndexes];
  [browserView scrollIndexToVisible:[visibleIndexes lastIndex]];
  [browserView setNeedsDisplay:YES];
}

- (IBAction)print:(id)pId {
  // If the image has edits, save to disk.
  // Print the main image.  The IKImageView does not seem to support printing
  // directly which is strange.
  NSSize imageSize = [mainImage imageSize];
  NSImage* image = [[NSImage alloc] initWithCGImage:[mainImage image]
                                               size:imageSize];
  NSRect frameSize = NSMakeRect(0, 0, imageSize.width, imageSize.height);
  NSImageView* printableView = [[NSImageView alloc] initWithFrame:frameSize];
  // TODO(ajwong): Use the image file directly to preserve color profile?
  [printableView setImage:image];

  NSPrintOperation *op =
      [NSPrintOperation printOperationWithView:printableView
                                     printInfo:printInfo];
  if (pId == printButton) {
    [op setShowsPrintPanel:NO];
  }
  // TODO(ajwong): Set the print job title here.
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
  [printInfo setTopMargin:0];
  [printInfo setLeftMargin:0];
  [printInfo setRightMargin:0];
  [printInfo setBottomMargin:0];
  [printInfo setVerticalPagination:NSFitPagination];
  [printInfo setHorizontalPagination:NSFitPagination];
}

//
// ------ Preferences Sheet Actions ------
//

- (IBAction)showPreferences:(id)pId {
  [NSApp beginSheet:preferencesSheet modalForWindow:window
      modalDelegate:self didEndSelector:NULL contextInfo:nil];
}

- (IBAction)savePreferences:(id)pId {
  [self setImagesDirectory:[selectedImagesDirectory stringValue]];
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
      [selectedImagesDirectory setStringValue:[panel filename]];
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
    ImageInfo* image = [self imageBrowser:browserView itemAtIndex:[indexes firstIndex]];
    [mainImage setImageWithURL:[image url]];
    [mainImage zoomImageToFit: self]; 
  }
}


//
// ------ Public API -------
//
- (void)setImagesDirectory:(NSString*) path {
  if ([imagesDirectory isEqual:path]) {
    return;
  }
  // We write our own setting becaus we want to always update the labels when
  // we set this path.
  [imagesDirectory release];
  imagesDirectory = path;
  [imagesDirectory retain];

  [preferences setObject:imagesDirectory forKey:kImageDirectoryPref];
  [preferences synchronize];
  
  [selectedImagesDirectory setStringValue:imagesDirectory];
  [self rescanImagesDirectory];
};


//
// ------ Internal functions -------
//

- (void)initializeMainImage {
  [mainImage setImageWithURL:self.defaultImage.url];
  
  // customize the IKImageView...
  [mainImage setDoubleClickOpensImageEditPanel: NO];
  [mainImage setCurrentToolMode: IKToolModeNone];
  [mainImage zoomImageToFit: self]; 
  [mainImage setDelegate: self];
}

- (void)initializeBrowseList {
  [self addImagesWithPath:imagesDirectory];
  [browserView setZoomValue:1.0f];
  [browserView setContentResizingMask:NSViewWidthSizable];  // Don't grow veritcally.
  [browserView setAllowsMultipleSelection:NO];
  [browserView reloadData];
}

- (void)rescanImagesDirectory {
  [imageList removeAllObjects];
  [self addImagesWithPath:imagesDirectory];
  [self initializeBrowseList];
}

- (void)addImagesWithPath:(NSString*)path {
  NSFileManager *localFileManager = [[[NSFileManager alloc] init] autorelease];
  NSDirectoryEnumerator *dirEnum =
    [localFileManager enumeratorAtPath:imagesDirectory];

  NSString *file;
  while (file = [dirEnum nextObject]) {
    NSString* extension = [file pathExtension];
    if ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame ||
        [extension caseInsensitiveCompare:@"png"] == NSOrderedSame) {
      [self addAnImageWithPath:[imagesDirectory stringByAppendingPathComponent:file]];
    }
  }
}

- (void)addAnImageWithPath:(NSString *) path
{
  ImageInfo *imageInfo;

  imageInfo = [[[ImageInfo alloc] initWithPath:path] autorelease];
  [imageList addObject:imageInfo];
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
  [self addAnImageWithPath:[
      imagesDirectory stringByAppendingPathComponent:filename]];
  [browserView reloadData];
  [self imageBrowserSelectionDidChange:browserView];
  
  // Must scroll *after* we've reloaded the data, otherwise we use the stale array.
  [browserView scrollIndexToVisible:0];
  NSIndexSet* selectFirst = [[NSIndexSet alloc] initWithIndex:0];
  [browserView setSelectionIndexes:selectFirst byExtendingSelection:NO];  
  
  [self setReadyText: [[file device] name]];
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
      dictionaryWithObject:[NSURL fileURLWithPath:imagesDirectory]
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
}

@end
