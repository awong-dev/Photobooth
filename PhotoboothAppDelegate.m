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
@synthesize statusText;

@synthesize defaultImageUrl;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed: (NSApplication *)sender
{
  // terminate when last window was closed
  return YES;
}

- (id)init
{
  if (self = [super init])
  {
    NSString* defaultImagePath = @"/Users/awong/marmalade.png";
    self.defaultImageUrl = [NSURL fileURLWithPath: defaultImagePath];
  }
  return self;
}

- (void)awakeFromNib
{  
  
  [mainImage setImageWithURL:self.defaultImageUrl];
  
  // customize the IKImageView...
  [mainImage setDoubleClickOpensImageEditPanel: YES];
  [mainImage setCurrentToolMode: IKToolModeCrop];
  [mainImage zoomImageToFit: self];
  [mainImage setDelegate: self];
}

- (IBAction)takePicture:(id)pId {
  NSLog(@"Smile! Taking picture.");  
}

- (IBAction)scrollBrowseLeft:(id)pId {
  NSLog(@"Browse Left");
}

- (IBAction)scrollBrowseRight:(id)pId {
  NSLog(@"Browse Right");
}
@end
