//
//  ImageInfo.h
//  Photobooth
//
//  Created by Albert Wong on 10/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ImageInfo : NSObject {
  NSURL* url;
}

@property(retain,nonatomic) NSURL* url;

// Converts to a url.
- (id)initWithPath:(NSString*)path;

@end
