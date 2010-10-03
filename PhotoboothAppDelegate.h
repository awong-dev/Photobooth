//
//  PhotoboothAppDelegate.h
//  Photobooth
//
//  Created by Albert Wong on 7/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface PhotoboothAppDelegate : NSObject <
	NSApplicationDelegate,
	ICDeviceBrowserDelegate,
	ICCameraDeviceDelegate> {
    NSWindow *window;
		
	// Define Interface Builder outlets for two
	// array controllers -- one for cameras,
	// one for the chosen camera's files
	IBOutlet  NSArrayController *  mCamerasController;
	IBOutlet  NSArrayController *  mMediaFilesController;
		
	// Define IB outlets for the tableviews used to
	// display the cameras and the chosen camera's contents
	IBOutlet  NSTableView * mCameraContentTableView;
	IBOutlet  NSTableView * mCamerasTableView;
		
		
	ICDeviceBrowser * mDeviceBrowser;
	NSMutableArray * mCameras;

}

@property (assign) IBOutlet NSWindow *window;
@property(retain)   NSMutableArray* cameras;

@end
