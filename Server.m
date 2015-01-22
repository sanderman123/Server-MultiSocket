//
//  Server.m
//  EZAudioPassThroughExample
//
//  Created by Sander on 11/25/14.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import "Server.h"

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
    clientCount = 0;
    tag = 0;
    
    NSLog(@"UDP server started on port %i", port);
}

- (void) send: (NSData *) data {
    for (int i = 0; i < clientCount; i++){
        [clients[i] sendData:data toAddress:clientAddresses[i] withTimeout:-1 tag:tag];
    }
    tag++;
}


-(void)addClient:(NSData *)address{
    clientCount++;
    
    [clientAddresses addObject: address];
    
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
}


- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    NSLog(@"Received data with length: %lu", (unsigned long)data.length);
    
    NSLog(@"Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    BOOL known = false;
    for (NSData *c in clientAddresses){
        if([c isEqualToData:address]){
            known = true;
            break;
        }
    }
    if (!known) {
        [self addClient:address];
    }
}

@end
