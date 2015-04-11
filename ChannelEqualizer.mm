//
//  ChannelEqualizer.m
//  CAPlayThrough
//
//  Created by Sander Valstar on 4/8/15.
//
//

#import "ChannelEqualizer.h"

@implementation ChannelEqualizer

-(instancetype)initWithSampleRate:(int)sampleRate{
    self = [super init];
    self.eqLeft = new Superpowered3BandEQ(sampleRate);
    self.eqLeft->bands[0] = 1.0f;
    self.eqLeft->bands[1] = 1.0f;
    self.eqLeft->bands[2] = 1.0f;
    self.eqLeft->enable(false);
    self.eqRight = new Superpowered3BandEQ(sampleRate);
    self.eqRight->bands[0] = 1.0f;
    self.eqRight->bands[1] = 1.0f;
    self.eqRight->bands[2] = 1.0f;
    self.eqRight->enable(false);
    return self;
}

-(bool)setBand:(int)bandIndex GainValue:(float)gain{
    assert(0 <= bandIndex && bandIndex <= 2);
    assert(0.0f <= gain && gain <= 2.0f);
    if (gain > 1.0f && bandIndex == 0) {
        self.eqLeft->bands[bandIndex] = gain * 1.2f;
        self.eqRight->bands[bandIndex] = gain * 1.2f;
    } else {
        self.eqLeft->bands[bandIndex] = gain;
        self.eqRight->bands[bandIndex] = gain;
    }
    if (gain != 1.0f && self.eqLeft->enabled == false) {
        self.eqLeft->enable(true);
        self.eqRight->enable(true);
    } else if (gain == 1.0f){
        if (self.eqLeft->bands[0] == 1.0f && self.eqLeft->bands[1] == 1.0f && self.eqLeft->bands[2] == 1.0f) {
            self.eqLeft->enable(false);
            self.eqRight->enable(false);
        }
    }
    return self.eqLeft->enabled;
}

static OSStatus filterCallback(__unsafe_unretained ChannelEqualizer *THIS,
                               __unsafe_unretained AEAudioController *audioController,
                               AEAudioControllerFilterProducer producer,
                               void *producerToken,
                               const AudioTimeStamp *time,
                               UInt32 frames,
                               AudioBufferList *audio) {
    // Pull audio
    OSStatus status = producer(producerToken, audio, &frames);
    if ( status != noErr ) status;
    // Now filter audio in 'audio'
    THIS->_eqLeft->process((float*)audio->mBuffers[0].mData, (float*)audio->mBuffers[0].mData, frames/2);
    THIS->_eqRight->process((float*)audio->mBuffers[1].mData, (float*)audio->mBuffers[1].mData, frames/2);
    return noErr;
}
-(AEAudioControllerFilterCallback)filterCallback {
    return (AEAudioControllerFilterCallback)filterCallback;
}
//self.filter = [[MyFilterClass alloc] init];

@end
