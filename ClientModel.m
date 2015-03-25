//
//  Client.m
//  CAPlayThrough
//
//  Created by Sander Valstar on 3/17/15.
//
//

#import "ClientModel.h"
//#import "MyAudioPlayer.h"
#import "AudioBufferManager.h"
#import "CAPlayThroughObjC.h"
#import "MyChannelGroup.h"

@implementation ClientModel

-(instancetype)initWithAudioController:(AEAudioController*)audioController NumberOfChannels:(int)n ClientInfo:(NSMutableDictionary*) clientInfoDict{
    //create
    self = [super init];
    
    if (self) {
        //Init client channel group
        numChannels = n;
        NSLog(@"Number of channels: %i",numChannels);

        prepareAndSendDataThread = dispatch_queue_create("com.ClientModel.DataPrepareSend", NULL);
        
        self.audioPlayers = [[NSMutableArray alloc]init];
        self.channelGroups = [[NSMutableArray alloc]init];
        
        self.audioController = audioController;
        AEChannelGroupRef mainChannel = [self.audioController createChannelGroup];
        [self.audioController setVolume:1.0 forChannelGroup:mainChannel];
        
        for (int i = 0; i < numChannels; i++) {
            MyAudioPlayer *player = [[MyAudioPlayer alloc]init];
            AEChannelGroupRef channel = [self.audioController createChannelGroupWithinChannelGroup:mainChannel];
            [self.audioController addChannels:[NSArray arrayWithObject:player] toChannelGroup:channel];
//            if (i == 0) {
//                [audioController setPan:0.9 forChannelGroup:channel];
//            [self addReverbToChannelGroup:channel];
            
//            }
            
            [self.audioController setVolume:1.0 forChannelGroup:channel];
            [self.audioPlayers addObject:player];
            MyChannelGroup *mcgr = [[MyChannelGroup alloc]init];
            mcgr.aecgRef = channel;
            [self.channelGroups addObject:mcgr];
        }
        
        [audioController addOutputReceiver:self forChannelGroup:mainChannel];
        
        //Init Client info
        self.name = (NSString*)[clientInfoDict objectForKey:@"name"];
        self.uuid = (NSString*)[clientInfoDict objectForKey:@"uuid"];
        self.streamSocket = (GCDAsyncUdpSocket*) [clientInfoDict objectForKey:@"streamSocket"];
        self.updateSocket = (GCDAsyncUdpSocket*) [clientInfoDict objectForKey:@"updateSocket"];
        self.audioAddress = (NSData*)[clientInfoDict objectForKey:@"audioAddress"];
        self.updateAddress = (NSData*)[clientInfoDict objectForKey:@"updateAddress"];
        
        self->mutableData1 = [NSMutableData data];
        self->mutableData2 = [NSMutableData data];
        flag = false;
        
        return self;
    } else {
        return nil;
    }
}

-(void)addReverbToChannelGroup:(AEChannelGroupRef) channel {
    AudioComponentDescription component
    = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                      kAudioUnitType_Effect,
                                      kAudioUnitSubType_MatrixReverb);
    NSError *error = NULL;
    AEAudioUnitFilter *reverb = [[AEAudioUnitFilter alloc]
                   initWithComponentDescription:component
                   audioController:_audioController
                   error:&error];
    if ( !reverb ) {
        // Report error
        NSLog(@"Error initializing reverb: %@",error.localizedDescription);
    }
    
    AudioUnitSetParameter(reverb.audioUnit,
                          kReverbParam_DryWetMix,
                          kAudioUnitScope_Global,
                          0,
                          100.f,
                          0);
    
    [self.audioController addFilter:reverb toChannelGroup:channel];
}



-(void)addToCircularBuffer:(AudioBufferList*)abl ChannelIndex:(int)index{
    [((MyAudioPlayer*)[self.audioPlayers objectAtIndex:index]) addToBufferWithoutTimeStampAudioBufferList: abl];
}

-(void)mixAudioBufferListArray:(NSArray*)ablArray{
    for (int i = 0; i < numChannels; i++) {
        //Feed new audio buffer list to each audio player
        [(MyAudioPlayer*)[self.audioPlayers objectAtIndex:i] addToBufferWithoutTimeStampAudioBufferList:((AudioBufferManager*)[ablArray objectAtIndex:i]).buffer];
    }
}

static void receiverCallback(__unsafe_unretained ClientModel *THIS,
                             __unsafe_unretained AEAudioController *audioController,
                             void *source,
                             const AudioTimeStamp *time,
                             UInt32 frames,
                             AudioBufferList *audio) {
    [THIS prepareAndSendData:audio];
}

-(AEAudioControllerAudioCallback)receiverCallback {
    return receiverCallback;
}

-(void)prepareAndSendData:(AudioBufferList *)audio{
    dispatch_async(prepareAndSendDataThread, ^{
        if (audio) {
            
            flag = !flag;
            if(flag){
                if (mutableData1 == nil) {
                    mutableData1 = [NSMutableData data];
                } else {
                    [mutableData1 setLength:0];
                    mutableData1 = nil;
                    mutableData1 = [NSMutableData data];
                }
                
                for (UInt32 y = 0; y < audio->mNumberBuffers; y++){
                    AudioBuffer ab = audio->mBuffers[y];
                    if (ab.mDataByteSize) {
                        [mutableData1 appendBytes:ab.mData length:ab.mDataByteSize];
                    } else {
                        NSLog(@"Error: ab is nil");
                    }
                    
                    //                            Float32 *frame = (Float32*)ab.mData;
                    //                            [mutableData1 appendBytes:frame length:ab.mDataByteSize];
                }
                
                // Send audio to socket
                [_streamSocket sendData:mutableData1 toAddress:_audioAddress withTimeout:-1 tag:222];
                
                //NSLog(@"Audio Sent");
            } else {
                if (mutableData2 == nil) {
                    mutableData2 = [NSMutableData data];
                } else {
                    [mutableData2 setLength:0];
                    mutableData2 = nil;
                    mutableData2 = [NSMutableData data];
                }
                
                AudioBuffer ab1 = audio->mBuffers[0];
                [mutableData2 appendBytes:ab1.mData length:ab1.mDataByteSize];
                AudioBuffer ab2 = audio->mBuffers[1];
                [mutableData2 appendBytes:ab2.mData length:ab2.mDataByteSize];
                
                //            for (UInt32 y = 0; y < audio->mNumberBuffers; y++){
                //                AudioBuffer ab = audio->mBuffers[y];
                //                if (ab.mDataByteSize) {
                //                    [mutableData2 appendBytes:ab.mData length:ab.mDataByteSize];
                //                } else {
                //                    NSLog(@"Error: ab is nil");
                //                }
                
                //                        Float32 *frame = (Float32*)ab.mData;
                //                        [mutableData2 appendBytes:frame length:ab.mDataByteSize];
                //            }
                
                // Send audio to socket
                [_streamSocket sendData:mutableData2 toAddress:_audioAddress withTimeout:-1 tag:223];
            }
        } else {
            NSLog(@"Audio buffer list empty!");
        }
    });
}

-(void)updateChannelSettings:(NSDictionary *)settingsDict{
    int chan = [[settingsDict objectForKey:@"channel"] intValue] - 1;
    AEChannelGroupRef cgr = ((MyChannelGroup*)[self.channelGroups objectAtIndex:chan]).aecgRef;

    [self.audioController setVolume:[[settingsDict objectForKey:@"volume"] floatValue] forChannelGroup:cgr];
    [self.audioController setPan: [[settingsDict objectForKey:@"pan"] floatValue] forChannelGroup:cgr];
    [self.audioController setMuted: [[settingsDict objectForKey:@"muted"] boolValue] forChannelGroup:cgr];
}



@end
