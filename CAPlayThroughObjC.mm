//
//  CAPlayThroughObjC.m
//  CAPlayThrough
//
//  Created by Hsiu Jesse on 1/17/15.
//
//

#import <Foundation/Foundation.h>
#import "CAPlayThroughObjC.h"

@implementation CAPlayThroughObjC


static CAPlayThroughObjC* _sharedCAPlayThroughObjC = nil;
/** The data byte size of 1 channel in the AudioBufferList */
const int DATA_SIZE_1_CHN = 64;
bool flag;
@synthesize udpServer;
@synthesize tcpServer;
@synthesize serverStarted;
@synthesize streaming;
@synthesize btnStartStream;
@synthesize btnStartServer;
@synthesize tfPort;
@synthesize channelsInfo;

static int TextFieldContext = 0;

void TransferAudioBuffer (void *THIS,  AudioBufferList *list)
{
    //    if(THIS == Nil)
    //    {
    //        THIS = [[CAPlayThroughObjC alloc]init];
    //        [(id)THIS initVariables];
    //    }
    //    @autoreleasepool {
    
    [(__bridge /*__bridge */id) THIS encodeAudioBufferList:list];
    
    
    //    list = [(id) self decodeAudioBufferList:tmp];
    //    return list;
    //    }
    
}
void* initializeInstance(void *THIS){
//    THIS = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil];//[[CAPlayThroughObjC alloc]init];
    THIS = (__bridge void*)[CAPlayThroughObjC sharedCAPlayThroughObjC:nil];//[[CAPlayThroughObjC alloc]init];
    [(__bridge /*__bridge */id)THIS initVariables];
    return THIS;
}
+(CAPlayThroughObjC*)sharedCAPlayThroughObjC:(CAPlayThroughObjC*) Playthrough
{
    @synchronized([CAPlayThroughObjC class])
    {
        if (!_sharedCAPlayThroughObjC)
            _sharedCAPlayThroughObjC = Playthrough;
        
        return _sharedCAPlayThroughObjC;
    }
    
    return nil;
}

-(void)initVariables
{
    if (abl == Nil) {
        flag = false;
        pepareAblThread = dispatch_queue_create("CAPlaythrough.prepareABL", NULL);
        testThread = dispatch_queue_create("CAPlaythrough.testThread", NULL);
        initializedAblArrays = false;
        abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        byteData = (Byte*) malloc(DATA_SIZE_1_CHN*8); //should maybe be a different value in the future
        byteData2 = (Byte*) malloc(DATA_SIZE_1_CHN*8);
        
//        NSURL *furl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"black.jpeg"]];
        NSString *folderPath = [NSString stringWithFormat:@"%@/images", [[NSBundle mainBundle] bundlePath]];
        NSString *path = [NSString stringWithFormat:@"%@/singer1.png",folderPath];
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"music-note" ofType:@"png"];
        NSURL *furl = [NSURL fileURLWithPath: path];
        defaultImage = [[NSImage alloc] init];
        [defaultImage initWithContentsOfURL:furl];

//        NSOpenPanel *panel = [NSOpenPanel openPanel];
//        [panel setCanChooseFiles:YES];
//        [panel setCanChooseDirectories:NO];
//        [panel setAllowsMultipleSelection:NO]; // yes if more than one file/dir is allowed
//        
//        NSInteger clicked = [panel runModal];
//        
//        if (clicked == NSFileHandlingPanelOKButton) {
//            for (NSURL *url in [panel URLs]) {
//                // do something with the url here.
//                defaultImage = [[NSImage alloc] initWithContentsOfURL:url];
//            }
//        }

        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidChangeNotification object:nil];
        
        self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
//        self.audioController.preferredBufferDuration = 0.0029;
//        self.audioController.preferredBufferDuration = 0.00145;
//        self.audioController.preferredBufferDuration = 0.000725;
//        self.audioController.preferredBufferDuration = 0.0003625;
        
//        //Add channels and players
        player = [[MyAudioPlayer alloc] init];
        channel = [self.audioController createChannelGroup];
        //add channel i with player i to the audio controller as a new channel
        [self.audioController addChannels:[NSArray arrayWithObject:player] toChannelGroup: channel];
        float vol = 1.0;
        //Initialize channel volumes
        [self.audioController setVolume:vol forChannelGroup:channel];
        [self.audioController setPan:0.0 forChannelGroup:channel];
        NSError *error = [NSError alloc];
        if(![self.audioController start:&error]){
            NSLog(@"Error starting AudioController: %@", error.localizedDescription);
        }
        clients = [[NSMutableArray alloc]init];
    }
}

- (void)encodeAudioBufferList:(AudioBufferList *)ablist {
    dispatch_sync(pepareAblThread, ^{
        
//        [player addToBufferWithoutTimeStampAudioBufferList:ablist];
        
        //NSMutableData *data = [NSMutableData data];
        
        //    NSLog(@"Frame data size: %i",ablist->mBuffers[0].mDataByteSize*2);
        if(streaming == true){
            //        if(mutableData == nil){
            //            mutableData = [NSMutableData data];
            //        } else {
            //            [mutableData setLength:0];
            //        }
            //
            //        for (UInt32 y = 0; y < ablist->mNumberBuffers; y++){
            //            AudioBuffer ab = ablist->mBuffers[y];
            //            Float32 *frame = (Float32*)ab.mData;
            //            [mutableData appendBytes:frame length:ab.mDataByteSize];
            //        }
            //
            //        if (udp) {
            //            [udpServer sendToAll:mutableData];
            //        } else {
            //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //                [tcpServer sendToAll:mutableData];
            //            });
            //        }
            
            //        [udpServer sendToAll:mutableData];
            //        tcpServer.audioDataFlag = 1;
            //        [dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) addope]
            // return mutableData;
        } else if (serverStarted && !initializedChannels){
            initializedChannels = true;
            
            _numChannels = ablist->mNumberBuffers;
            [_labelChannels setStringValue:[NSString stringWithFormat:@"%@ %i",_labelChannels.stringValue, _numChannels]];
            
            channelsInfo = [[NSMutableArray alloc]init];
            NSLog(@"Numchannels %i", _numChannels);
            
            //NSDictionary *dict = [[NSDictionary alloc]init];
            for(int i = 0; i < _numChannels;i++){
                //  [dict setValue:[NSString stringWithFormat:@"Channel %i",i+1] forKey:@"name"];
                //            [dict setValue:@"123" forKey:@"name"];
                //            [dict initWithObjectsAndKeys:[NSString stringWithFormat:@"Channel %i",i+1] ?: [NSNull null], @"name", nil];
                NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSString stringWithFormat:@"Channel %i",i+1],@"name", nil];
                NSDictionary *imgDict = [[NSDictionary alloc] initWithObjectsAndKeys:@"music-note",@"fileName",@"png",@"fileExtension", nil];
                [dict setObject:imgDict forKey:@"image"];
                //[NSDictionary        dictionaryWithObject:@"Cannel X" forKey:@"name"];
                //            dict = @{ @"name" :[NSString stringWithFormat:@"Channel %i",i+1]};
                [channelsInfo addObject:dict];
                //[dict autorelease];
            }
            
            //        clientMixer = [[ClientMixer alloc]initWithAudioController:self.audioController NumberOfChannels:_numChannels];
            //        [self.audioController addOutputReceiver:clientMixer forChannelGroup:channel];
            NSLog(@"audioController num channels: %lu",(unsigned long)self.audioController.channels.count);
            //        [_audioController addChannels:[NSArray arrayWithObject:clientMixer.player] toChannelGroup:channel];
            
            
            ablArray1 = [[NSMutableArray alloc]init];
            for (int i = 0; i < _numChannels; i++) {
                AudioBufferManager *abm = [[AudioBufferManager alloc]init];
                abm.buffer = AEAllocateAndInitAudioBufferList(self.audioController.audioDescription, DATA_SIZE_1_CHN);
                [ablArray1 addObject:abm];
            }
            ablArray2 = [[NSMutableArray alloc]init];
            for (int i = 0; i < _numChannels; i++) {
                AudioBufferManager *abm = [[AudioBufferManager alloc]init];
                abm.buffer = AEAllocateAndInitAudioBufferList(self.audioController.audioDescription, DATA_SIZE_1_CHN);
                [ablArray2 addObject:abm];
            }
            
            initializedAblArrays = true;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_sharedCAPlayThroughObjC initTables];
            });
            
        } else if(initializedAblArrays){
            flag = !flag;
            if (flag) {
                //Devide the ABL into one stereo ABL per channel
                for (int i = 0; i < _numChannels; i++) {
                    //ablist->mBuffers[i]
                    ((AudioBufferManager*)[ablArray1 objectAtIndex:i]).buffer->mBuffers[0] = ablist->mBuffers[i];
                    ((AudioBufferManager*)[ablArray1 objectAtIndex:i]).buffer->mBuffers[1] = ablist->mBuffers[i];
                }
                for (int i = 0; i < (int)clients.count; i++) {
                    [[clients objectAtIndex:i] mixAudioBufferListArray:ablArray1];
                }
                //            [clientMixer mixAudioBufferListArray:ablArray1];
            } else {
                for (int i = 0; i < _numChannels; i++) {
                    //ablist->mBuffers[i]
                    ((AudioBufferManager*)[ablArray2 objectAtIndex:i]).buffer->mBuffers[0] = ablist->mBuffers[i];
                    ((AudioBufferManager*)[ablArray2 objectAtIndex:i]).buffer->mBuffers[1] = ablist->mBuffers[i];
                }
                for (int i = 0; i < (int)clients.count; i++) {
                    [[clients objectAtIndex:i] mixAudioBufferListArray:ablArray2];
                }
                //            [clientMixer mixAudioBufferListArray:ablArray2];
            }
        }
    });
}

-(void)initTables
{
    clientsTableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 148, 200)];
    clientsTableView = [[NSTableView alloc]initWithFrame:NSMakeRect(0, 0, 148, 200)];
    
    [clientsTableView setDataSource:self];
    [clientsTableView setDelegate:self];
    
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"www"];
    [[column1 headerCell] setStringValue:@"Connected Clients"];
    [column1 setWidth:148];
    [clientsTableView addTableColumn:column1];
    //    [tableview reloadData];
    
    [clientsTableContainer setDocumentView:clientsTableView];
    [clientsTableContainer setHasVerticalScroller:YES];
    [_sharedCAPlayThroughObjC addSubview:clientsTableContainer];
    clientsTableView.tag = 0;
    
    channelsTableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(200, 0, 230, 200)];
    channelsTableView = [[NSTableView alloc]initWithFrame:NSMakeRect(0, 0, 230, 200)];
    [channelsTableView setDataSource:self];
    [channelsTableView setDelegate:self];
    
    NSTableColumn * columnIndex = [[NSTableColumn alloc] initWithIdentifier:@"index"];
    NSTableColumn * columnName = [[NSTableColumn alloc] initWithIdentifier:@"name"];
    NSTableColumn * columnImage = [[NSTableColumn alloc] initWithIdentifier:@"image"];
    [[columnIndex headerCell] setStringValue:@"No"];
    [[columnName headerCell] setStringValue:@"Name"];
    [[columnImage headerCell] setStringValue:@"Img"];
    [columnIndex setWidth:20];
    [columnName setWidth:160];
    [columnImage setWidth:20];
    [channelsTableView addTableColumn:columnIndex];
    [channelsTableView addTableColumn:columnName];
    [channelsTableView addTableColumn:columnImage];
    
    [channelsTableContainer setDocumentView:channelsTableView];
    [channelsTableContainer setHasVerticalScroller:YES];
    [_sharedCAPlayThroughObjC addSubview:channelsTableContainer];
    
    [channelsTableView setDoubleAction:@selector(doubleClick:)];
    channelsTableView.tag = 1;
    [channelsTableView reloadData];
}

- (AudioBufferList *)decodeAudioBufferList:(NSData *)data {
    
    if (data.length > 0) {
        int nc = 2; // This value should be changed once there are more than 2 channels
        
        //AudioBufferList *abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        abl->mNumberBuffers = nc;
        
        NSUInteger len = [data length];
        
        //Take the range of the first buffer
        NSUInteger olen = 0;
        // NSUInteger lenx = len / nc;
        NSUInteger step = len / nc;
        int i = 0;
        
        while (olen < len) {
            
            //NSData *d = [NSData alloc];
            NSData *pd = [data subdataWithRange:NSMakeRange(olen, step)];
            NSUInteger l = [pd length];
            NSLog(@"l: %lu",(unsigned long)l);
            //            Byte *byteData = (Byte*) malloc(l);
            if(i == 0){
                memcpy(byteData, [pd bytes], l);
                if(byteData){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    abl->mBuffers[i].mNumberChannels = 1;
                    abl->mBuffers[i].mData = byteData;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            } else {
                memcpy(byteData2, [pd bytes], l);
                if(byteData2){
                    
                    //I think the zero should be 'i', but for some reason that doesn't work...
                    abl->mBuffers[i].mDataByteSize = (UInt32)l;
                    abl->mBuffers[i].mNumberChannels = 1;
                    abl->mBuffers[i].mData = byteData2;
                    //                memcpy(&self.abl->mBuffers[i].mData, byteData, l);
                }
            }
            
            
            //Update the range to the next buffer
            olen += step;
            //lenx = lenx + step;
            i++;
            //            free(byteData);
        }
        return abl;
    }
    return nil;
}

-(void)btnStartServerClicked:(id)sender{
    serverStarted = true;
    udp = true;
    streaming = false;
    udpServer = [[Server alloc] init];
    [udpServer createServerOnPort:[tfPort intValue]];
    
    if (udp) {

    } else {
        tcpServer = [[TCPServer alloc] init];
        [tcpServer startServerOnPort:[tfPort intValue]];
    }
    
//    NSLog(@"Numchannels: %i", _numChannels);
//    channelNames = [[NSMutableArray alloc] init];
//    for(int i = 0; i < _numChannels;i++){
//        [channelNames addObject:[NSString stringWithFormat:@"Channel %i",i]];
//    }

}

-(void)btnStartStreamClicked:(id)sender{
    if (serverStarted) {
        
        if (streaming == false) {
            //Start stream
            //            btnStartStream.stringValue = [NSString stringWithFormat:@"Stop stream"];
            btnStartStream.title = [NSString stringWithFormat:@"Stop stream"];
            streaming = true;
            
            
            //First test sending data
            /*NSString *testString = @"test";
             NSData *testData = [testString dataUsingEncoding:NSUTF8StringEncoding];
             [server send:testData];*/
        } else {
            btnStartStream.title = [NSString stringWithFormat:@"Start stream"];
            streaming = false;
        }
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView.tag == 0){
        NSMutableArray *names = [udpServer getClientNames];
        NSLog(@"Number of Clients: %lu",(unsigned long)[names count]);
        return [names count];
    } else {
        return _numChannels;
    }
}
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
//{
//    NSLog(@"called2");
////    id returnValue=nil;
////
////    // The column identifier string is the easiest way to identify a table column.
////    NSString *columnIdentifer = [tableColumn identifier];
////    NSLog(@"%@",columnIdentifer);
////
////    // Get the name at the specified row in namesArray
////    NSString *theName = @"yay";//[namesArray objectAtIndex:rowIndex];
////
////
////
////    // Compare each column identifier and set the return value to
////    // the Person field value appropriate for the column.
////    if ([columnIdentifer isEqualToString:@"MainCell"]) {
////        returnValue = theName;
////    }
////
////
////    return returnValue;
//    return @"perfect";
//}
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 20;
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTextField *result = [tableView makeViewWithIdentifier:@"MainCell" owner:self] ;
    if (result == nil) {
        result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 148, 10)];
        result.identifier = @"MainCell";
        result.bordered = false;
    }
    if(tableView.tag == 0){
        NSMutableArray *names = [udpServer getClientNames];
        result.stringValue = [names objectAtIndex:row];
        
        // Return the result
    } else {
        if(tableView.tableColumns[0] == tableColumn){
            result.stringValue = [NSString stringWithFormat:@"%li",row + 1];
        } else if(tableView.tableColumns[1] == tableColumn){
            result.stringValue = [[channelsInfo objectAtIndex:row] objectForKey:@"name"];
        } else {
            if((int)[channelsInfo count] == _numChannels){
                NSImageView *image = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 20, 20)];
                [image setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@.%@",[[[channelsInfo objectAtIndex:row] objectForKey:@"image"] objectForKey:@"fileName"],[[[channelsInfo objectAtIndex:row] objectForKey:@"image"] objectForKey:@"fileExtension"]]]];
                return image;
            }
        }
    }
    return result;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    selectedRow = [[notification object] selectedRow];
}

-(void)controlTextDidEndEditing:(NSNotification *)obj{
    NSString *string = [[[obj object] selectedCell] stringValue];
    
    [[channelsInfo objectAtIndex:(NSUInteger)selectedRow] setObject:string forKey:@"name"];
    
//    [channelNames replaceObjectAtIndex:(NSUInteger)selectedRow withObject:string];
    //inform clients of new channel name
    [udpServer sendUpdateToClients];
//    tcpServer.audioDataFlag = 0;
//    [tcpServer sendUpdateToClients];
}

-(void)refreshConnectedClients{
    [clientsTableView reloadData];
}

-(void)addConnectedClientWithInfo:(NSMutableDictionary *)clientInfoDict{
    ClientModel *client = [[ClientModel alloc]initWithAudioController:self.audioController NumberOfChannels:self.numChannels ClientInfo:clientInfoDict];
    [clients addObject:client];
}

- (void)doubleClick:(id)object {
    // This gets called after following steps 1-3.
    if(object == channelsTableView){
        NSInteger rowNumber = [channelsTableView clickedRow];
        NSInteger colNumber = [channelsTableView clickedColumn];
        
        if(colNumber == 2){
            NSImage *image = [[NSImage alloc]init];
            
            NSOpenPanel *panel = [NSOpenPanel openPanel];
            [panel setCanChooseFiles:YES];
            [panel setCanChooseDirectories:NO];
            [panel setAllowsMultipleSelection:NO]; // yes if more than one file/dir is allowed
            
            NSInteger clicked = [panel runModal];
            NSString *fileName = [[NSString alloc] init];
            NSString *fileExtension = [[NSString alloc] init];
            
            if (clicked == NSFileHandlingPanelOKButton) {
                for (__strong NSURL *url in [panel URLs]) {
                    [image initWithContentsOfURL:url];
                    fileExtension = [url pathExtension];
                    url = [url URLByDeletingPathExtension];
                    fileName = [url lastPathComponent];
                    
                    // do something with the url here.
                    //image = [[NSImage alloc] initWithContentsOfURL:url];
                }
                
                NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:fileName,@"fileName",fileExtension,@"fileExtension", nil];
                
                
                [[channelsInfo objectAtIndex:rowNumber] setObject:dict forKey:@"image"];
                
//                [channelImages replaceObjectAtIndex:rowNumber withObject:image];
//                [server sendChannelImageToClients:image index:rowNumber];
                [udpServer sendUpdateToClients];
//                tcpServer.audioDataFlag = 0;
//                [tcpServer sendChannelImageToClients:fileName format:fileExtension index:rowNumber];
                    [channelsTableView reloadData];
            }
        }
    }
}

-(void)updateClientChannelInfo:(NSData *)infoData{
    NSDictionary *infoDict = [NSJSONSerialization JSONObjectWithData:infoData options:0 error:nil];
    for (int i = 0; i < (int)clients.count; i++) {
        ClientModel *cm = (ClientModel*)[clients objectAtIndex:i];
        if([cm.uuid isEqualToString:[infoDict objectForKey:@"uuid"]]){
            [cm updateChannelSettings:infoDict];
        }
    }
}

@end