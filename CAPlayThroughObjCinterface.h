//
//  CAPlayThroughObjC.h
//  CAPlayThrough
//
//  Created by Hsiu Jesse on 1/17/15.
//
//

#ifndef CAPlayThrough_CAPlayThroughObjCinterface_h
#define CAPlayThrough_CAPlayThroughObjCinterface_h
#import "CAPlayThroughObjC.h"
void TransferAudioBuffer (void *myObjectInstance, AudioBufferList *list);
void* initializeInstance(void *myObjectInstance);
//NSObject* init();
#endif
