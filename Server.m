//
//  Server.m
//  EZAudioPassThroughExample
//
//  Created by Sander on 11/25/14.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import "Server.h"
#import "CAPlayThroughObjC.h"

#include <netinet/in.h>
#include <arpa/inet.h>

@implementation Server

- (void) createServerOnPort: (UInt16) p {
    port = p;
//    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
//    self.bufferQueue =
    dispatch_queue_t serverQueue = dispatch_queue_create("com.mydomain.app.serverqueue", NULL);
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:serverQueue /*dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)*/];
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
    
//    clientJoinRequests =[[NSMutableArray alloc] init];
//    clientAddresses = [[NSMutableArray alloc] init];
    clients = [[NSMutableArray alloc]init];
//    clientNames = [[NSMutableArray alloc]init];
    clientCount = 0;
    tag = 123;
    
    NSLog(@"UDP server started on port %i", port);
}

- (void) sendToAll: (NSData *) data {
    for (NSDictionary *client in clients) {
        [[client objectForKey:@"streamSocket"] sendData:data toAddress:[client objectForKey:@"audioAddress"] withTimeout:-1 tag:9999];
    }
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    NSLog(@"Socket closed with error: %@",error.localizedDescription);
}

-(void)addClientWithAddress:(NSData *)address AndInfo:(NSMutableDictionary*) jsonDictionary{
    //New client
    clientCount++;
    //Open a new socket
    dispatch_queue_t streamQueue = dispatch_queue_create("com.mydomain.app.streamqueue", NULL);
    GCDAsyncUdpSocket *streamSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:streamQueue/*dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)*/];
    
    //Open a unique port
    NSError *error = [NSError alloc];
    if (![streamSocket bindToPort:0 error:&error]) {
        NSLog(@"Error binding port: %@", error.localizedDescription);
    } else {
        NSLog(@"Client stream socket added on port: %i", streamSocket.localPort);
    }
    
    [jsonDictionary setObject:streamSocket forKey:@"streamSocket"];
    
    dispatch_queue_t updateQueue = dispatch_queue_create("com.mydomain.app.updatequeue", NULL);
    GCDAsyncUdpSocket *updateSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:updateQueue /*Queuedispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)*/];
    
    //Open a unique port
    error = [NSError alloc];
    if (![updateSocket bindToPort:0 error:&error]) {
        NSLog(@"Error binding port: %@", error.localizedDescription);
    } else {
        NSLog(@"Client update socket added on port: %i", updateSocket.localPort);
    }
    
    if (![updateSocket beginReceiving:&error]){
        NSLog(@"Error update socket starting receiving: %@", error.localizedDescription);
    } else {
        NSLog(@"Update Socket succesfully started receiving");
    }
    
    
    [jsonDictionary setObject:updateSocket forKey:@"updateSocket"];
    
    //New client, remeber the uuid and name
    [clients addObject:jsonDictionary];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CAPlayThroughObjC sharedCAPlayThroughObjC:nil] refreshConnectedClients];
    });
    
    
    [self initializeClient:address];
}

-(void)initializeClient:(NSData *)address {
    
    NSData *data = [self getChannelNamesAsData];
    [udpSocket sendData:data toAddress:address withTimeout:-1 tag:tag];
}

-(void)sendUpdateToClients{
    NSData* data = [self getChannelNamesAsData];
    for (int i = 0; i < clientCount; i++) {
        [[[clients objectAtIndex:i] objectForKey:@"updateSocket"] sendData:data toAddress:[[clients objectAtIndex:i] objectForKey:@"updateAddress"] withTimeout:100 tag:9998];
    }
//    NSLog(@"Update sent");
}
//won't used anymore
-(void)sendChannelImageToClients:(NSString*)name format:(NSString*) format index:(int)index{
    //NSArray *images = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil].channelImages;
   // NSImage *image = [images objectAtIndex:index];
    NSString *str = [NSString stringWithFormat:@"image:%i:%@:%@",index,name,format];
    NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
    for (int i = 0; i < clientCount; i++) {
        [udpSocket sendData:strData toAddress:[[clients objectAtIndex:i] objectForKey:@"updateAddress"] withTimeout:-1 tag:9997];
    }
    
//    NSData *imageData = [[NSData alloc]initWithData:[image TIFFRepresentation]];
//    imageData = [image TIFFRepresentation];
//    [self sendToAll:imageData];
}

-(NSData *)getChannelNamesAsData{
    NSArray *cnames = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil].channelsInfo;
    NSMutableDictionary *postDict = [[NSMutableDictionary alloc]init];
    [postDict setValue:cnames forKey:@"channels"];
    [postDict setValue:[NSString stringWithFormat:@"udp"] forKey:@"audio"];
    [postDict setValue:[NSString stringWithFormat:@"udp"] forKey:@"update"];
//    
//    
//    
//    NSString *str = @"";
//    
//    for(int i = 0; i < (int)cnames.count; i++){
//        if(i > 0){
//            str = [str stringByAppendingString:@":"];
//        }
//        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@",[cnames objectAtIndex:i]]];
//    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:nil];
    
//    [str dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

- (NSMutableArray*)getClientNames{
    return clientNames;
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"Did not send tag: %li, Error: %@", tag, error.localizedDescription);
}


- (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
//    NSLog(@"Received data with length: %lu", (unsigned long)data.length);
    NSError *e = nil;
    NSMutableDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
    
//    for (NSDictionary *item in jsonDictionary) {
//        NSLog(@"New item %@", item);
//    }
    if (sock == udpSocket) {
        
        for (int i = 0; i < clientCount; i++) {
            NSMutableDictionary *client = [clients objectAtIndex:i];
            
            if (client != nil && [[client valueForKey:@"uuid"] isEqualToString: [jsonDictionary valueForKey:@"uuid"]]) {
                //Register audio streaming and update sockets to the client
                if ([[jsonDictionary valueForKey:@"socket"] isEqualToString:@"updateSocket"]) {
                    //Register an update socket to the client
                    [client setObject:address forKey:@"updateAddress"];
                } else if ([[jsonDictionary valueForKey:@"socket"] isEqualToString:@"audioSocket"]) {
                    //Register an audio stream socket to the client and complete the client adding process
                    [client setObject:address forKey:@"audioAddress"];
                    [[CAPlayThroughObjC sharedCAPlayThroughObjC:nil] addConnectedClientWithInfo:client];
                    [self sendUpdateToClients];
                }
                //            for (NSDictionary *item in client) {
                //                NSLog(@"Updated item %@", item);
                //            }
                
                return;
            }
        }
        
        //New client
        [self addClientWithAddress:address AndInfo:jsonDictionary];
        
        
        NSString *clientName = [jsonDictionary valueForKey:@"name"];
        NSLog(@"Client with name: %@, connected", clientName);
    } else {
        for (int i = 0; i < clientCount; i++) {
            NSMutableDictionary *client = [clients objectAtIndex:i];
            if (client != nil && [[client valueForKey:@"uuid"] isEqualToString: [jsonDictionary valueForKey:@"uuid"]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[CAPlayThroughObjC sharedCAPlayThroughObjC:nil] updateClientChannelInfo:data];
                });
                
            }
//            if (address == [client objectForKey:@"updateAddress"]) {
//                //Update channel settings for client
//                [[CAPlayThroughObjC sharedCAPlayThroughObjC:nil] updateClientChannelInfo:data];
//            }
        }
    }
}

@end
