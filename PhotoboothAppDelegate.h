//
//  PhotoboothAppDelegate.h
//  Photobooth
//
//  Created by Albert J. Wong on 7/20/10.
//  Copyright 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface PhotoboothAppDelegate : NSObject {
 @private
  NSWindow *window;
  IKImageView* mainImage;
  IKImageBrowserView *browserView;
  NSTextField *statusText;
  NSURL* defaultImageUrl;
}

@property(retain, nonatomic) IBOutlet NSWindow *window;
@property(retain, nonatomic) IBOutlet IKImageView *mainImage;
@property(retain, nonatomic) IBOutlet IKImageBrowserView *browserView;
@property(retain, nonatomic) IBOutlet NSTextField *statusText;

@property(retain, nonatomic) NSURL* defaultImageUrl;

- (IBAction)takePicture:(id)pId;
- (IBAction)scrollBrowseLeft:(id)pId;
- (IBAction)scrollBrowseRight:(id)pId;

@end
