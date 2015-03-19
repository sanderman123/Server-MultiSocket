//
//  AudioBufferManager.h
//  taaeTest2
//
//  Created by Sander Valstar on 1/31/15.
//  Copyright (c) 2015 Sander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TPCircularBuffer+AudioBufferList.h"
@interface AudioBufferManager : NSObject

@property (assign) AudioBufferList *buffer;
@end
