//
//  Server.h
//  EZAudioPassThroughExample
//
//  Created by Sander on 11/25/14.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GCDAsyncUdpSocket.h"

@interface Server : NSObject <NSApplicationDelegate, GCDAsyncUdpSocketDelegate>{
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
    UInt16 port;
    NSMutableArray *clientAddresses;
    NSMutableArray *clients;
    int tag;
    int clientCount;
}

//- (id) init;

- (void) createServerOnPort: (UInt16) port;

- (void) send: (NSData *) data;

- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;

- (void) addClient: (NSData *) address;

@end
