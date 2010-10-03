//
//  PhotoboothAppDelegate.m
//  Photobooth
//
//  Created by Albert Wong on 7/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotoboothAppDelegate.h"
#import <Quartz/Quartz.h>

@implementation PhotoboothAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	mCameras = [[NSMutableArray alloc] initWithCapacity:0];
	// Get an instance of ICDeviceBrowser
    mDeviceBrowser = [[ICDeviceBrowser alloc] init];
    // Assign a delegate
    mDeviceBrowser.delegate = self;
    // Look for cameras in all available locations
    mDeviceBrowser.browsedDeviceTypeMask = mDeviceBrowser.browsedDeviceTypeMask 
	| ICDeviceTypeMaskCamera
	| ICDeviceLocationTypeMaskLocal
	| ICDeviceLocationTypeMaskShared
	| ICDeviceLocationTypeMaskBonjour
	| ICDeviceLocationTypeMaskBluetooth
	| ICDeviceLocationTypeMaskRemote;
	
	NSLog(@"Go Go device browser!");
    // Start browsing for cameras
    [mDeviceBrowser start];	
}

// Stop browser and release it when done
- (void)applicationWillTerminate:(NSNotification*)notification {
	mDeviceBrowser.delegate = NULL;
	[mDeviceBrowser stop];
	[mDeviceBrowser release];
	[mCameras release];
}

// Method delegates for device added and removed
//
// Device browser maintains list of cameras as key-value pairs, so delegate
// must call willChangeValueForKey to modify list
- (void)deviceBrowser:(ICDeviceBrowser*)browser didAddDevice:(ICDevice*)addedDevice moreComing:(BOOL)moreComing
{    
    if ( addedDevice.type & ICDeviceTypeCamera )
    {
		NSEnumerator *e = [addedDevice.capabilities objectEnumerator];
		NSString* capability;
		NSLog(@"We want: %@", ICCameraDeviceCanTakePicture);
		while (capability = [e nextObject]) {
			NSLog(@"%@ has capatibilty %@", addedDevice.name, capability);
		}
		NSLog(@"Adding device: %@", addedDevice.name);		
		addedDevice.delegate = self;
		
		// implement manual observer notification for the cameras property
        [self willChangeValueForKey:@"cameras"];
		[mCameras addObject:addedDevice];
        [self didChangeValueForKey:@"cameras"];
    }
}


- (void)deviceBrowser:(ICDeviceBrowser*)browser didRemoveDevice:(ICDevice*)device moreGoing:(BOOL)moreGoing
{
    device.delegate = NULL;
    
    // implement manual observer notification for the cameras property
    [self willChangeValueForKey:@"cameras"];
	[mCameras removeObject:device];
    [self didChangeValueForKey:@"cameras"];
}

- (void)didRemoveDevice:(ICDevice*)removedDevice
{
    [mCamerasController removeObject:removedDevice];
}

// Check to see if the camera has image files to download
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ( [keyPath isEqualToString:@"selectedObjects"] && (object == mMediaFilesController) )
    {
        [self willChangeValueForKey:@"canDownload"];
        [self didChangeValueForKey:@"canDownload"];
    }
}

- (BOOL)canDownload
{
    if ( [[mMediaFilesController selectedObjects] count] )
        return YES;
    else
        return NO;
}

// Download images
// (Add a download button in interface builder -- use boolean to enable button)
- (void)downloadFiles:(NSArray*)files
{
    NSDictionary* options = [NSDictionary dictionaryWithObject:[NSURL fileURLWithPath:[@"~/Pictures" stringByExpandingTildeInPath]] forKey:ICDownloadsDirectoryURL];
    
    for ( ICCameraFile* f in files )
    {
        [f.device requestDownloadFile:f options:options downloadDelegate:self didDownloadSelector:@selector(didDownloadFile:error:options:contextInfo:) contextInfo:NULL];
    }
}

// Done downloading -- log results to console for debugging
- (void)didDownloadFile:(ICCameraFile*)file error:(NSError*)error options:(NSDictionary*)options contextInfo:(void*)contextInfo
{
    NSLog( @"didDownloadFile called with:\n" );
    NSLog( @"  file:        %@\n", file );
    NSLog( @"  error:       %@\n", error );
    NSLog( @"  options:     %@\n", options );
    NSLog( @"  contextInfo: %p\n", contextInfo );
}

@end
