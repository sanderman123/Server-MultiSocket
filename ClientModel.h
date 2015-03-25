//
//  Client.h
//  CAPlayThrough
//
//  Created by Sander Valstar on 3/17/15.
//
//

#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine/TheAmazingAudioEngine.h"
#import "MyAudioPlayer.h"
#import "GCDAsyncUdpSocket.h"

@interface ClientModel : NSObject<AEAudioReceiver>{
    int numChannels;
//    AEAudioController *audioController;
    NSMutableData *mutableData1;
    NSMutableData *mutableData2;
    bool flag;
    dispatch_queue_t prepareAndSendDataThread;
    NSData *dataL;
    NSData *dataR;
}
//@property (nonatomic,strong) NSMutableData *mutableData1;
//@property (nonatomic,strong) NSMutableData *mutableData2;
@property (nonatomic,strong) AEAudioController *audioController;
@property (nonatomic,strong) NSMutableArray *audioPlayers;
@property (nonatomic,strong) NSMutableArray *channelGroups;
@property (nonatomic,strong) MyAudioPlayer *player;
@property (nonatomic,strong) NSData *audioAddress;
@property (nonatomic,strong) NSData *updateAddress;
@property (nonatomic,strong) GCDAsyncUdpSocket *streamSocket;
@property (nonatomic,strong) GCDAsyncUdpSocket *updateSocket;
@property (nonatomic,strong) NSString *uuid;
@property (nonatomic,strong) NSString *name;
//@property (nonatomic,strong) NSMutableData *mutableData;

-(instancetype)initWithAudioController:(AEAudioController*)audioController NumberOfChannels:(int)n ClientInfo:(NSMutableDictionary*) clientInfoDict;
-(void)addToCircularBuffer:(AudioBufferList*)abl ChannelIndex:(int)index;
-(void)mixAudioBufferListArray:(NSArray*)ablArray;
-(void)updateChannelSettings:(NSDictionary*)settingsDict;
@end
