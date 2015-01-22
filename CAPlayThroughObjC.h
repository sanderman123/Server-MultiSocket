//
//  CAPlayThroughObjC.h
//  CAPlayThrough
//
//  Created by Hsiu Jesse on 1/17/15.
//
//

#include <CoreAudio/CoreAudio.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#import "CAPlayThroughObjCinterface.h"
#import <Cocoa/Cocoa.h>

#import "GCDAsyncUdpSocket.h"
#import "Server.h"

// An Objective-C class that needs to be accessed from C++
@interface CAPlayThroughObjC : NSView
{
    AudioBufferList *abl;
    NSMutableData *mutableData;
    Byte *byteData;// = (Byte*) malloc(l);
    Byte *byteData2;// = (Byte*) malloc(l);
    
    bool already_init;
    
}

@property (nonatomic,strong) Server* server;
@property (nonatomic,assign) bool streaming;
@property (nonatomic,assign) bool serverStarted;
//+(CAPlayThroughObjC*)sharedCAPlayThroughObjC;
+(CAPlayThroughObjC*)sharedCAPlayThroughObjC:(CAPlayThroughObjC*) Playthrough;

// The Objective-C member function you want to call from C++
- (void) encodeAudioBufferList:(AudioBufferList *)abl;
- (AudioBufferList *) decodeAudioBufferList: (NSData *) data;

@property (nonatomic, strong)IBOutlet NSButton *btnStartServer;
@property (nonatomic, strong)IBOutlet NSButton *btnStartStream;
@property (nonatomic, strong)IBOutlet NSTextField *tfPort;


-(IBAction)btnStartServerClicked:(id)sender;
-(IBAction)btnStartStreamClicked:(id)sender;
@end
