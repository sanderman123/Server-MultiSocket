//
//  MyAudioPlayer.h
//  taaeTest2
//
//  Created by Sander on 1/13/15.
//  Copyright (c) 2015 Sander. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine/TheAmazingAudioEngine.h"
#import "Modules/TPCircularBuffer/TPCircularBuffer.h"
#import "Modules/TPCircularBuffer/TPCircularBuffer+AudioBufferList.h"

@interface MyAudioPlayer : NSObject<AEAudioPlayable>{
    
}

@property (nonatomic, assign) TPCircularBuffer cbuffer;

-(void) addToBufferAudioBufferList: (AudioBufferList *) abl frames: (UInt32)frames timestamp:(const AudioTimeStamp *) time;
-(void) addToBufferWithoutTimeStampAudioBufferList: (AudioBufferList *) abl;

@end
