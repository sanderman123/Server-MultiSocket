//
//  TCPServer.m
//  CAPlayThrough
//
//  Created by Sander Valstar on 2/9/15.
//
//

#import "TCPServer.h"
#import "CAPlayThroughObjC.h"

@implementation TCPServer
@synthesize audioDataFlag;

-(instancetype)init{
    if((self = [super init])){
        isRunning = false;
        clientCount = 0;
        audioDataFlag = false;
        clients = [[NSMutableArray alloc] init];
        
        socketQueue = dispatch_queue_create("socketQueue", NULL);
//        dispatch_set_target_queue(socketQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        //listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
        listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
//        [self startServerOnPort:0];
    }
    return self;
}

-(int)startServerOnPort:(int) port{
    if(!isRunning)
    {
        
        if (port < 0 || port > 65535)
        {
            port = 0;
        }
        
        NSError *error = nil;
        if(![listenSocket acceptOnPort:port error:&error])
        {
            NSLog(@"Error starting server: %@", error);
            return -1;
        }
        
        port = [listenSocket localPort];
        
        NSLog(@"Echo server started on port %hu", [listenSocket localPort]);
        tag = 0;
        isRunning = YES;
        
    } else {
        NSLog(@"Server already started");
    }

    return port;
}

-(void)sendToAll:(NSData *)data{
//    NSMutableData *flaggedData = [NSMutableData alloc];
//    
//    flaggedData = [NSMutableData dataWithBytes: &audioDataFlag length: sizeof(int)];
//    [flaggedData appendData:data];
    for (int i = 0; i < clientCount; i++){
        //        [clients[i] sendData:data toAddress:clientAddresses[i] withTimeout:-1 tag:tag];
        //[((GCDAsyncSocket*) clients[i]) writeData:data withTimeout:-1 tag:tag];
        
//        [clients[i] writeData:flaggedData withTimeout:-1 tag:audioDataFlag];
        [clients[i] writeData:data withTimeout:-1 tag:0];
    }
    
    NSLog(@"Data sent");
//    tag++;
}

-(void)initializeClient:(GCDAsyncSocket *)sock {
//    audioDataFlag = 0;
//    NSMutableData *flaggedData = [NSMutableData alloc];
//    flaggedData = [NSMutableData dataWithBytes: &audioDataFlag length: sizeof(int)];
//    
//    [flaggedData appendData:[self getChannelNamesAsData]];
//    //[udpSocket sendData:data toAddress:address withTimeout:-1 tag:tag];
//    [sock writeData:flaggedData withTimeout:-1 tag:0];
    NSData* data = [self getChannelNamesAsData];
    [sock writeData:data withTimeout:-1 tag:0];
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

-(void)sendUpdateToClients{
    NSData* data = [self getChannelNamesAsData];
    [self sendToAll:data];
}

-(void)sendChannelImageToClients:(NSString*)name format:(NSString*) format index:(int)index{
    NSString *str = [NSString stringWithFormat:@"image:%i:%@:%@",index,name,format];
    NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [self sendToAll:strData];
}


-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    NSString* h = [newSocket connectedHost];
    int p = [newSocket connectedPort];
    NSLog(@"Did accept new socket: %@:%i",h,p);
    [clients addObject:newSocket];
    clientCount++;
    [listenSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
//    NSString *msg = @"Blaat";
//    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
//    [newSocket writeData:data withTimeout:-1 tag:0];
//    [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
    
    [self initializeClient:newSocket];
    
    [newSocket readDataWithTimeout:-1 tag:0];
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if (sock != listenSocket)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                
                NSLog(@"Client disconnected");
                
            }
        });
        
        @synchronized(clients)
        {
            [clients removeObject:sock];
            clientCount--;
        }
    }

}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)t{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, t);
}


@end
