//
//  PhotoboothAppDelegate.m
//  Photobooth
//
//  Created by Albert J. Wong on 7/20/10.
//  Copyright 2010. All rights reserved.
//

#import "PhotoboothAppDelegate.h"

#import <Quartz/Quartz.h>

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
      [NSHomeDirectory() stringByAppendingPathComponent:@"test"];
  }
  return self;
}

- (void)awakeFromNib {
  [self initializeMainImage];
  [self initializeBrowseList];
}

//
// ------ UI Actions -------
//
- (IBAction)takePicture:(id)pId {
  NSLog(@"Smile! Taking picture.");  
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
  [mainImage setDoubleClickOpensImageEditPanel: YES];
  [mainImage setCurrentToolMode: IKToolModeCrop];
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
    if ([extension isEqualToString: @"jpg"] ||
        [extension isEqualToString: @"png"]) {
      [self addAnImageWithPath:[imagesDirectory stringByAppendingPathComponent:file]];
    }
  }
  [localFileManager release];
}

- (void) addAnImageWithPath:(NSString *) path
{
  ImageInfo *imageInfo;

  imageInfo = [[ImageInfo alloc] initWithPath:path];
  [imageList addObject:imageInfo];
  [imageInfo release];
}

@end
