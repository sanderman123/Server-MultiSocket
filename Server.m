//
//  Server.m
//  EZAudioPassThroughExample
//
//  Created by Sander on 11/25/14.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import "Server.h"
#import "CAPlayThroughObjC.h"
@implementation Server

- (void) createServerOnPort: (UInt16) p {
    port = p;
//    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    NSError *error = [NSError alloc];
    if (![udpSocket bindToPort:port error:&error]) {
        NSLog(@"Error binding port: %@", error.localizedDescription);
    } else {
        NSLog(@"Port binding succeeded");
    }
    
    if (![udpSocket beginReceiving:&error]){
        NSLog(@"Error starting receiving: %@", error.localizedDescription);
    } else {
        NSLog(@"Succesfully started receiving");
    }
    
    clientAddresses = [[NSMutableArray alloc] init];
    clients = [[NSMutableArray alloc]init];
    clientNames = [[NSMutableArray alloc]init];
    clientCount = 0;
    tag = 0;
    
    NSLog(@"UDP server started on port %i", port);
}

- (void) sendToAll: (NSData *) data {
    for (int i = 0; i < clientCount; i++){
        [clients[i] sendData:data toAddress:clientAddresses[i] withTimeout:-1 tag:tag];
    }
    tag++;
}

-(void)addClient:(NSData *)address name:(NSString *) name{
    clientCount++;
    
    [clientAddresses addObject: address];
    [clientNames addObject: name];
    [[CAPlayThroughObjC sharedCAPlayThroughObjC:nil] refreshConnectedClients];
    
    //Open a new socket
    [clients addObject: [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)]];
    
    //Open a unique port
    NSError *error = [NSError alloc];
    UInt16 uniquePort = port + clientCount;
    if (![[clients lastObject] bindToPort:uniquePort error:&error]) {
        NSLog(@"Error binding port: %i, %@", uniquePort, error.localizedDescription);
    } else {
        NSLog(@"Client socket added on port: %i", uniquePort);
    }
    
    [self initializeClient:address];
}

-(void)initializeClient:(NSData *)address {
    
    NSData *data = [self getChannelNamesAsData];
    [udpSocket sendData:data toAddress:address withTimeout:-1 tag:tag];
}

-(void)sendUpdateToClients{
    NSData* data = [self getChannelNamesAsData];
    [self sendToAll:data];
}

-(NSData *)getChannelNamesAsData{
    NSArray *cnames = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil].channelNames;
    NSString *str = @"";
    
    for(int i = 0; i < (int)cnames.count; i++){
        if(i > 0){
            str = [str stringByAppendingString:@":"];
        }
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@",[cnames objectAtIndex:i]]];
    }
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

- (NSMutableArray*)getClientNames{
    return clientNames;
}


- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    NSLog(@"Received data with length: %lu", (unsigned long)data.length);
    
    NSString *clientName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Data: %@", clientName);
    
    BOOL known = false;
    for (NSData *c in clientAddresses){
        if([c isEqualToData:address]){
            known = true;
            break;
        }
    }
    if (!known) {
        [self addClient:address name:clientName];
    }
}

@end
