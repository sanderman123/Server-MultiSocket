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
@synthesize server;
@synthesize serverStarted;
@synthesize streaming;
@synthesize btnStartStream;
@synthesize btnStartServer;
@synthesize tfPort;
@synthesize channelNames;

static int TextFieldContext = 0;

void TransferAudioBuffer (void *THIS,  AudioBufferList *list)
{
    //    if(THIS == Nil)
    //    {
    //        THIS = [[CAPlayThroughObjC alloc]init];
    //        [(id)THIS initVariables];
    //    }
    //    @autoreleasepool {
    
    [(/*__bridge */id) THIS encodeAudioBufferList:list];
    
    
    //    list = [(id) self decodeAudioBufferList:tmp];
    //    return list;
    //    }
    
}
void* initializeInstance(void *THIS){
    THIS = [CAPlayThroughObjC sharedCAPlayThroughObjC:nil];//[[CAPlayThroughObjC alloc]init];
    [(/*__bridge */id)THIS initVariables];
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
        abl = (AudioBufferList*) malloc(sizeof(AudioBufferList));
        byteData = (Byte*) malloc(1024); //should maybe be a different value in the future
        byteData2 = (Byte*) malloc(1024);
        streaming = false;
        server = [[[Server alloc] init] retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlTextDidEndEditing:) name:NSControlTextDidChangeNotification object:nil];

    }
}

- (void)encodeAudioBufferList:(AudioBufferList *)ablist {
    //NSMutableData *data = [NSMutableData data];
    if(streaming == true){
        if(mutableData == nil){
            mutableData = [NSMutableData data];
        } else {
            [mutableData setLength:0];
        }
        
        for (UInt32 y = 0; y < ablist->mNumberBuffers; y++){
            AudioBuffer ab = ablist->mBuffers[y];
            Float32 *frame = (Float32*)ab.mData;
            [mutableData appendBytes:frame length:ab.mDataByteSize];
        }
        
        [server sendToAll:mutableData];
        // return mutableData;
    } else if (serverStarted && !initializedChannels){
        _numChannels = ablist->mNumberBuffers;
        [_labelChannels setStringValue:[NSString stringWithFormat:@"%@ %i",_labelChannels.stringValue, _numChannels]];
        channelNames = [[NSMutableArray alloc] init];
        NSLog(@"Numchannels %i", _numChannels);
        for(int i = 0; i < _numChannels;i++){
            [channelNames addObject:[NSString stringWithFormat:@"Channel %i",i+1]];
        }
        initializedChannels = true;
    }
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
    [server createServerOnPort:[tfPort intValue]];
    
//    NSLog(@"Numchannels: %i", _numChannels);
//    channelNames = [[NSMutableArray alloc] init];
//    for(int i = 0; i < _numChannels;i++){
//        [channelNames addObject:[NSString stringWithFormat:@"Channel %i",i]];
//    }
    
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
    
    channelsTableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(200, 0, 200, 200)];
    channelsTableView = [[NSTableView alloc]initWithFrame:NSMakeRect(0, 0, 200, 200)];
    
    [channelsTableView setDataSource:self];
    [channelsTableView setDelegate:self];
    
    NSTableColumn * columnA = [[NSTableColumn alloc] initWithIdentifier:@"www"];
    NSTableColumn * columnB = [[NSTableColumn alloc] initWithIdentifier:@"www"];
    [[columnA headerCell] setStringValue:@"No"];
    [[columnB headerCell] setStringValue:@"Name"];
    [columnA setWidth:20];
    [columnB setWidth:180];
    [channelsTableView addTableColumn:columnA];
    [channelsTableView addTableColumn:columnB];
    
    [channelsTableContainer setDocumentView:channelsTableView];
    [channelsTableContainer setHasVerticalScroller:YES];
    [_sharedCAPlayThroughObjC addSubview:channelsTableContainer];
    
    channelsTableView.tag = 1;
    [channelsTableView reloadData];
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
        NSMutableArray *names = [server getClientNames];
        NSLog(@"%lu",(unsigned long)[names count]);
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
    NSTextField *result = [[tableView makeViewWithIdentifier:@"MainCell" owner:self] autorelease];
    if (result == nil) {
        result = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 148, 10)];
        result.identifier = @"MainCell";
        result.bordered = false;
    }
    if(tableView.tag == 0){
        NSMutableArray *names = [server getClientNames];
        result.stringValue = [names objectAtIndex:row];
        
        // Return the result
    } else {
        if(tableView.tableColumns[0] == tableColumn){
            result.stringValue = [NSString stringWithFormat:@"%li",row + 1];
        } else {
            result.stringValue = [channelNames objectAtIndex:row];
        }
    }
    return result;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    selectedRow = [[notification object] selectedRow];
}

-(void)controlTextDidEndEditing:(NSNotification *)obj{
    NSString *string = [[[obj object] selectedCell] stringValue];
    [channelNames replaceObjectAtIndex:(NSUInteger)selectedRow withObject:string];
    //inform clients of new channel name
    [server sendUpdateToClients];
}

-(void)controlTextDidChange:(NSNotification *)obj{
    NSLog(@"Yaay");
}

-(void)controlTextDidBeginEditing:(NSNotification *)obj{
    NSLog(@"BOEE");
}

-(void)refreshConnectedClients{
    [clientsTableView reloadData];
}

@end