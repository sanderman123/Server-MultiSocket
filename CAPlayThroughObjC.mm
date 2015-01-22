//
//  CAPlayThroughObjC.m
//  CAPlayThrough
//
//  Created by Hsiu Jesse on 1/17/15.
//
//

#import <Foundation/Foundation.h>
#import "CAPlayThroughObjC.h"

@implementation CAPlayThroughObjC
static CAPlayThroughObjC* _sharedCAPlayThroughObjC = nil;
@synthesize server;
@synthesize serverStarted;
@synthesize streaming;
@synthesize btnStartStream;
@synthesize btnStartServer;
@synthesize tfPort;

void TransferAudioBuffer (void *THIS,  AudioBufferList *list)
{
//    if(THIS == Nil)
//    {
//        THIS = [[CAPlayThroughObjC alloc]init];
//        [(id)THIS initVariables];
//    }
//    @autoreleasepool {
    
     [(/*__bridge */id) THIS encodeAudioBufferList:list];
    
    
//    list = [(id) self decodeAudioBufferList:tmp];
//    return list;
//    }
    
}
void* initializeInstance(void *THIS){
    THIS = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil];//[[CAPlayThroughObjC alloc]init];
    [(/*__bridge */id)THIS initVariables];
    return THIS;
}
+(CAPlayThroughObjC*)sharedCAPlayThroughObjC:(CAPlayThroughObjC*) Playthrough
{
    @synchronized([CAPlayThroughObjC class])
    {
        if (!_sharedCAPlayThroughObjC)
            _sharedCAPlayThroughObjC = Playthrough;
        
        return _sharedCAPlayThroughObjC;
    }
    
    return nil;
}
-(void)initVariables
{
    if (abl == Nil) {
        abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        byteData = (Byte*) malloc(1024); //should maybe be a different value in the future
        byteData2 = (Byte*) malloc(1024);
        streaming = false;
        server = [[[Server alloc] init] retain];
    }
}

- (void)encodeAudioBufferList:(AudioBufferList *)ablist {
    //NSMutableData *data = [NSMutableData data];
    if(streaming == true){
        if(mutableData == nil){
            mutableData = [NSMutableData data];
        } else {
            [mutableData setLength:0];
        }
    
        for (UInt32 y = 0; y < ablist->mNumberBuffers; y++){
            AudioBuffer ab = ablist->mBuffers[y];
            Float32 *frame = (Float32*)ab.mData;
            [mutableData appendBytes:frame length:ab.mDataByteSize];
        }
        
        [server send:mutableData];
       // return mutableData;
    }
}

- (AudioBufferList *)decodeAudioBufferList:(NSData *)data {
    
    if (data.length > 0) {
        int nc = 2; // This value should be changed once there are more than 2 channels
        
        //AudioBufferList *abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        abl->mNumberBuffers = nc;
        
        NSUInteger len = [data length];
        
        //Take the range of the first buffer
        NSUInteger olen = 0;
        // NSUInteger lenx = len / nc;
        NSUInteger step = len / nc;
        int i = 0;
        
        while (olen < len) {
            
            //NSData *d = [NSData alloc];
            NSData *pd = [data subdataWithRange:NSMakeRange(olen, step)];
            NSUInteger l = [pd length];
            NSLog(@"l: %lu",(unsigned long)l);
            //            Byte *byteData = (Byte*) malloc(l);
            if(i == 0){
                memcpy(byteData, [pd bytes], l);
                if(byteData){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    abl->mBuffers[i].mNumberChannels = 1;
                    abl->mBuffers[i].mData = byteData;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            } else {
                memcpy(byteData2, [pd bytes], l);
                if(byteData2){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    abl->mBuffers[i].mNumberChannels = 1;
                    abl->mBuffers[i].mData = byteData2;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            }
            
            
            //Update the range to the next buffer
            olen += step;
            //lenx = lenx + step;
            i++;
            //            free(byteData);
        }
        return abl;
    }
    return nil;
}

-(void)btnStartServerClicked:(id)sender{
    [server createServerOnPort:[tfPort intValue]];
    serverStarted = true;
}

-(void)btnStartStreamClicked:(id)sender{
    if (serverStarted) {
        
        if (streaming == false) {
            //Start stream
//            btnStartStream.stringValue = [NSString stringWithFormat:@"Stop stream"];
            btnStartStream.title = [NSString stringWithFormat:@"Stop stream"];
            streaming = true;
            
            
            //First test sending data
            /*NSString *testString = @"test";
             NSData *testData = [testString dataUsingEncoding:NSUTF8StringEncoding];
             [server send:testData];*/
        } else {
            btnStartStream.title = [NSString stringWithFormat:@"Start stream"];
            streaming = false;
        }
    }

}

@end