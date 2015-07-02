//
//  ChannelEqualizer.h
//  CAPlayThrough
//
//  Created by Sander Valstar on 4/8/15.
//
//

#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine/TheAmazingAudioEngine.h"    
#import "Superpowered3BandEQ.h"

@interface ChannelEqualizer : NSObject<AEAudioFilter>

@property (nonatomic) Superpowered3BandEQ *eqLeft;
@property (nonatomic) Superpowered3BandEQ *eqRight;

-(instancetype)initWithSampleRate:(int)sampleRate;
-(bool)setBand:(int)bandIndex GainValue:(float)gain;
@end
