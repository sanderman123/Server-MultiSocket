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
//#import "CAPlayThroughObjC.h"

@interface Server : NSObject <NSApplicationDelegate, GCDAsyncUdpSocketDelegate>{
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
    UInt16 port;
    NSMutableArray *clientAddresses;
    NSMutableArray *clients;
    NSMutableArray *clientNames;
    NSMutableArray *clientJoinRequests;
    int tag;
    int clientCount;
}

//- (id) init;

- (void) initializeClient: (NSData*) address;

- (void) sendUpdateToClients;

//- (void)sendChannelImageToClients:(NSImage*)image index:(int)index;
-(void)sendChannelImageToClients:(NSString*)name format:(NSString*) format index:(int)index;

- (NSData*) getChannelNamesAsData;

- (void) createServerOnPort: (UInt16) port;

- (void) sendToAll: (NSData *) data;

- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext;

- (void)addClientWithAddress:(NSData *)address AndInfo:(NSMutableDictionary*) jsonDictionary;

- (NSMutableArray*)getClientNames;

@end
