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
@synthesize browserViewContainer;
@synthesize statusText;

@synthesize imagesDirectory;
@synthesize defaultImage;
@synthesize imageList;

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
    imagesDirectory =
      [[NSHomeDirectory() stringByAppendingPathComponent:@"test"] retain];
    state = kUninitialized;
  }
  return self;
}

- (void)awakeFromNib {
  [self initializeMainImage];
  [self initializeBrowseList];
  [self setUninitialized];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
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
  
  [[cameras lastObject] requestTakePicture];
  state = kTakingPicture;
  // TODO(ajwong): Setup watchdog timer that will close session and restart if
  // download does not complete in 3 seconds.
}

- (IBAction)scrollBrowseLeft:(id)pId {
  NSClipView* scrollContents = [browserViewContainer contentView];
  NSPoint newOrigin = [scrollContents visibleRect].origin;
  newOrigin.x = newOrigin.x - [browserView cellSize].width;
  newOrigin.x = newOrigin.x > 0 ? newOrigin.x : 0;
  [scrollContents scrollToPoint: newOrigin];
  [browserViewContainer reflectScrolledClipView: scrollContents];
}

- (IBAction)scrollBrowseRight:(id)pId {
  NSClipView* scrollContents = [browserViewContainer contentView];
  NSPoint newOrigin = [scrollContents visibleRect].origin;
  newOrigin.x = newOrigin.x + [browserView cellSize].width;
  CGFloat visibleWidth = [browserViewContainer visibleRect].size.width;
  CGFloat maxScroll = [browserView bounds].size.width - visibleWidth;
  maxScroll = maxScroll < 0 ? 0 : maxScroll;
  newOrigin.x = newOrigin.x > maxScroll ? maxScroll : newOrigin.x;
  [scrollContents scrollToPoint: newOrigin];
  [browserViewContainer reflectScrolledClipView: scrollContents];
}

- (IBAction)print:(id)pId {
  // If the image has edits, save to disk.
  // Print the main image.
  NSPrintInfo* origInfo = [NSPrintInfo sharedPrintInfo];
  NSPrintInfo* newInfo = [[NSPrintInfo alloc] initWithDictionary:[origInfo dictionary]];
  [newInfo setVerticalPagination:NSFitPagination];
  [newInfo setHorizontalPagination:NSFitPagination];
  
  NSPrintOperation *op =
     [NSPrintOperation printOperationWithView:mainImage printInfo:newInfo];
  [op setShowsPrintPanel:NO];
  [op setCanSpawnSeparateThread:YES];
  [op runOperation];
}

- (IBAction)showEffects:(id)pId {
}


//
// ------ IKImageBrowserView delegates------
//
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
  return [imageList count];
}

- (id) imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
  return [imageList objectAtIndex:index];
}

- (void) imageBrowserSelectionDidChange:(IKImageBrowserView *) aBrowser {
  NSIndexSet* indexes = [browserView selectionIndexes];
  if ([indexes count] > 0) {
    ImageInfo* image = [imageList objectAtIndex:[indexes firstIndex]];
    [mainImage setImageWithURL:[image url]];
    [mainImage zoomImageToFit: self]; 
  }
}

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

- (void)addImagesWithPath:(NSString*)path {
  NSFileManager *localFileManager = [[NSFileManager alloc] init];
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
  [localFileManager release];
}

- (void)addAnImageWithPath:(NSString *) path
{
  ImageInfo *imageInfo;

  imageInfo = [[ImageInfo alloc] initWithPath:path];
  [imageList addObject:imageInfo];
  [imageInfo release];
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

    [[cameras lastObject] requestOpenSession];
  }
}


- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing
{
  device.delegate = NULL;
  
  // implement manual observer notification for the cameras property
  [self willChangeValueForKey:@"cameras"];
  [cameras removeObject:device];
  [self didChangeValueForKey:@"cameras"];

  // Open the new camera if there is one.
  if ([cameras count] == 0) {
    [self setUninitialized];
  } else {
    [[cameras lastObject] requestOpenSession];
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
  // TODO(ajwong): Add newly found file into browser.
  NSString* filename = [options objectForKey:ICSavedFilename];
  [self addAnImageWithPath:[imagesDirectory stringByAppendingPathComponent:filename]];
  [browserView reloadData];
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


@end
