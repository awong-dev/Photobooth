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

@interface PhotoboothAppDelegate : NSObject {
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
}

@property(retain, nonatomic) IBOutlet NSWindow *window;
@property(retain, nonatomic) IBOutlet IKImageView *mainImage;
@property(retain, nonatomic) IBOutlet IKImageBrowserView *browserView;
@property(retain, nonatomic) IBOutlet NSScrollView *browserViewContainer;
@property(retain, nonatomic) IBOutlet NSTextField *statusText;

@property(retain, nonatomic) NSString* imagesDirectory;
@property(retain, nonatomic) ImageInfo* defaultImage;
@property(retain, nonatomic) NSMutableArray* imageList;

// UI Actions.
- (IBAction)takePicture:(id)pId;
- (IBAction)scrollBrowseLeft:(id)pId;
- (IBAction)scrollBrowseRight:(id)pId;

// IKImageBrowserView delegates.
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser;
- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index;

// Internal functions.
- (void)initializeMainImage;
- (void)initializeBrowseList;
- (void)addImagesWithPath:(NSString*) path;
- (void)addAnImageWithPath:(NSString *)path;
@end
