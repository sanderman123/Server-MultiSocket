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

#import "TheAmazingAudioEngine/TheAmazingAudioEngine.h"
#import "MyAudioPlayer.h"
#import "ClientModel.h"
#import "AudioBufferManager.h"

#import "GCDAsyncUdpSocket.h"
#import "Server.h"
#import "TCPServer.h"

// An Objective-C class that needs to be accessed from C++
@interface CAPlayThroughObjC : NSView<NSTableViewDataSource,NSTableViewDelegate>
{
    AudioBufferList *abl;
    NSMutableData *mutableData;
    Byte *byteData;// = (Byte*) malloc(l);
    Byte *byteData2;// = (Byte*) malloc(l);
    
    bool already_init;
    
    NSTableView *clientsTableView;
    NSScrollView *clientsTableContainer;
    
    NSTableView *channelsTableView;
    NSScrollView *channelsTableContainer;
    
    NSImage *defaultImage;

    bool initializedChannels;
    bool initializedAblArrays;
    int selectedRow;
    
    bool udp;
    
    MyAudioPlayer *player;
    AEChannelGroupRef channel;
//    ClientMixer *clientMixer;
    NSMutableArray *clients;
    NSMutableArray *ablArray1;
    NSMutableArray *ablArray2;
    
    dispatch_queue_t pepareAblThread;
    dispatch_queue_t testThread;
}
@property (nonatomic,strong) AEAudioController *audioController;
@property (nonatomic,strong) Server* udpServer;
@property (nonatomic,strong) TCPServer* tcpServer;
@property (nonatomic,assign) bool streaming;
@property (nonatomic,assign) bool serverStarted;
@property (nonatomic, assign) int numChannels;
@property (nonatomic, strong) NSMutableArray *channelsInfo;
//+(CAPlayThroughObjC*)sharedCAPlayThroughObjC;
+(CAPlayThroughObjC*)sharedCAPlayThroughObjC:(CAPlayThroughObjC*) Playthrough;

// The Objective-C member function you want to call from C++
- (void) encodeAudioBufferList:(AudioBufferList *)abl;
- (AudioBufferList *) decodeAudioBufferList: (NSData *) data;

- (void) refreshConnectedClients;
- (void) addConnectedClientWithInfo:(NSMutableDictionary*)clientInfoDict;
- (void) updateClientChannelInfo:(NSData*)infoData;
- (void)doubleClick:(id)nid;

@property (nonatomic, strong)IBOutlet NSButton *btnStartServer;
@property (nonatomic, strong)IBOutlet NSButton *btnStartStream;
@property (nonatomic, strong)IBOutlet NSTextField *tfPort;
@property (nonatomic, strong)IBOutlet NSTextField *labelChannels;

-(IBAction)btnStartServerClicked:(id)sender;
-(IBAction)btnStartStreamClicked:(id)sender;
@end
