//
//  ImageInfo.m
//  Photobooth
//
//  Created by Albert Wong on 10/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ImageInfo.h"
#import <Quartz/Quartz.h>


@implementation ImageInfo

@synthesize url;

- (id)initWithPath:(NSString*)path {
  if (self = [super init]) {
    self.url = [NSURL fileURLWithPath: path];
  }
  return self;
}

- (NSString *) imageRepresentationType {
  return IKImageBrowserNSURLRepresentationType;
}

- (id)  imageRepresentation {
  return self.url;
}

- (NSString *) imageUID {
  return [self.url absoluteString];
}

@end
