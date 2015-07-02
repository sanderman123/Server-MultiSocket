//
//  TCPServer.h
//  CAPlayThrough
//
//  Created by Sander Valstar on 2/9/15.
//
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@interface TCPServer : NSObject<GCDAsyncSocketDelegate>{
    dispatch_queue_t socketQueue;
    GCDAsyncSocket *listenSocket;
    NSMutableArray *clients;
    BOOL isRunning;
    int tag;
    int clientCount;
}

@property (nonatomic) int audioDataFlag;

-(int) startServerOnPort:(int)port;
//-(void) stopServer;

-(void) sendToAll:(NSData*) data;

-(void)initializeClient:(GCDAsyncSocket *)sock;
-(NSData *)getChannelNamesAsData;
-(void)sendUpdateToClients;

-(void)sendChannelImageToClients:(NSString*)name format:(NSString*) format index:(int)index;

@end
