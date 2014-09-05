//
//  BKConnectionManager.h
//
//
//  Created by Rodrigo Galvez on 19/03/13.
//  Copyright (c) 2013 Rodrigo Galvez. All rights reserved.
//

#import "BKConnectionManager.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <CommonCrypto/CommonDigest.h>
#import "BKHud.h"

#pragma mark BKCache Methods

#define BOUNDARY_STRING @"--------BOUNDARY--------"

@interface BKCache : NSObject

+ (BKCache *)sharedInstance;

@property (nonatomic, strong) NSMutableDictionary *cache;

@end

@implementation BKCache

+ (BKCache *)sharedInstance
{
    static dispatch_once_t pred;
    static BKCache *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[BKCache alloc] init];
    });
    return shared;
}

- (id)init{
    self = [super init];
    if (self) {
        _cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@end

#pragma mark -
#pragma mark BKData Methods

@interface BKData : NSMutableData

- (void)appendPartWithFormData:(NSData*)data name:(NSString*)name;
- (void)appendPartWithFileData:(NSData*)data name:(NSString*)name fileName:(NSString*)fileName mimeType:(NSString*)mimeType;

@end

@implementation BKData

- (void)appendPartWithFormData:(NSData*)data name:(NSString*)name{
    [self appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BOUNDARY_STRING] dataUsingEncoding:NSUTF8StringEncoding]];
    [self appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", name,data] dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendPartWithFileData:(NSData*)data name:(NSString*)name fileName:(NSString*)fileName mimeType:(NSString*)mimeType{
    [self appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BOUNDARY_STRING] dataUsingEncoding:NSUTF8StringEncoding]];
    [self appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name,fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [self appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [self appendData:[NSData dataWithData:data]];
}

@end

#pragma mark -
#pragma mark BKConnectionManager

NSString * const ApplicationTypeArray[] = {
    @"none",
    @"json",
    @"x-www-form-urlencoded",
    @"multipart/form-data; boundary=%@"
};

NSString * const MethodTypeArray[] = {
    @"POST",
    @"GET",
    @"PUT",
    @"DELETE"
};

@interface BKConnectionManager (){
    NSMutableData *receivedData;
    
    bool activeHud;
    BKHud* hud;
    
    NSString *nameWS;
    id theInfo;
    NSString *connectionType;
    
    NSArray* queueArray;
    int arrayIndex;
    
    NSMutableURLRequest *_originalRequest;
    NSURLConnection *theConnection;
    
    long long expectedBytes;
    long long bytesReceived;

    NSHTTPURLResponse *theResponse;
}

@end

@implementation BKConnectionManager

@synthesize delegate,hudMessage,requestTag,restring3g,showDebugLogs,timeOut,withHud,inQueue,methodType,applicationType,urlWS,httpHeaders,completitionBlock,saveInCache,authorizationBlock,failedAuth,withAlerts;

#pragma mark Initializer

- (id)initWithInfo:(id)info withUrl:(NSString*)theURL inWS:(NSString*)wsName withMethodType:(WSMethodType)theMethodType andApplicationType:(WSApplicationType)theApplicationType delegate:(id)theDelegate{
    self = [super init];
    if (self) {
        theInfo = info;
        urlWS = theURL;
        nameWS = wsName;
        self.delegate = theDelegate;
        hudMessage = @"";
        withHud = NO;
        activeHud = NO;
        withAlerts = YES;
        saveInCache = NO;
        requestTag = 0;
        showDebugLogs = YES;
        restring3g = NO;
        timeOut = 10.0;
        methodType = theMethodType;
        applicationType = theApplicationType;
    }
    return self;
}

#pragma mark Queue Method
- (id)startRequestQueueWithBKConnectionsArray:(NSMutableArray*)array withDelegate:(id)theDelegate{
    if ([super init]) {
        if (!array.count == 0) {
            self.delegate = theDelegate;
            queueArray = array;
            [self performNextConnection];
            hud = [BKHud showHUDanimated:YES];
            [hud setProgress:0];
            [hud setText:@"0%"];
        }
    }
    return self;
}

- (void)performNextConnection{
    if (arrayIndex < queueArray.count) {
        BKConnectionManager *connection = (BKConnectionManager*)queueArray[arrayIndex];
        connection.delegate = self;
        connection.inQueue = YES;
        arrayIndex = arrayIndex + 1;
        connection.withHud = NO;
        [connection sendRequest];
    }else{
        [BKHud hideHUDanimated:YES];
    }
}

-(void)WSdidGetResponse:(id)response inConnectionTag:(int)tag{
    if (showDebugLogs) NSLog(@"WSdidGetResponse on Queue, remains : %d",((int)queueArray.count) - (arrayIndex + 1));
    float percent = [BKConnectionManager calculateProgressForValue:arrayIndex start:0 end:queueArray.count];
    [hud setProgress:percent];
    [hud setText:[NSString stringWithFormat:@"%%%d",(int)(percent*100)]];
    if ([self.delegate respondsToSelector: @selector(WSdidGetResponse:inConnection:andQueueTag:)]){
        [self.delegate WSdidGetResponse:response inConnection:self andQueueTag:arrayIndex-1];
    }
    [self performNextConnection];
}

- (void)progress:(float)value{
    [hud setProgress:value];
}

#pragma mark Connection Methods

- (void)sendRequest{
    if ([BKConnectionManager connectedToNetworkRestring3g:restring3g]) {
        // create the connection with the request
        // and start loading the data
        
        failedAuth = NO;
        
        NSString *jointUrl = [urlWS stringByAppendingString:nameWS];
        NSError *parsingError = nil;
        NSData *postData = Nil;
        
        if (saveInCache) {
            if ([[BKCache sharedInstance].cache objectForKey:jointUrl]) {
                receivedData = [[BKCache sharedInstance].cache objectForKey:jointUrl];
                if (showDebugLogs) NSLog(@"Found in cache!!!");
                [self connectionDidFinishLoading:Nil];
                return;
            }
        }
        
        if (applicationType != WSApplicationTypeNone && theInfo != nil) {
            if (applicationType == WSApplicationTypeJSON) {
                postData = [NSJSONSerialization dataWithJSONObject:theInfo options:NSJSONWritingPrettyPrinted error:&parsingError];
            }
            if (applicationType == WSApplicationTypeUrlEncoded) {
                postData = [NSData dataWithBytes:[(NSString*)theInfo UTF8String] length:[(NSString*)theInfo length]];
            }
        }
        
        if (showDebugLogs) {
            NSLog(@"\n\n-------------------- BKConectionManager Send Info : --------------------\n\n"
                  @"Url : %@ \n"
                  @"WS Name : %@ \n"
                  @"Method Type : %@ \n"
                  @"Application Type : %@ \n"
                  @"PostData: %@ \n"
                  @"\n------------------------------------------------------------------------\n\n",jointUrl,nameWS,MethodTypeArray[methodType],ApplicationTypeArray[applicationType],[[NSString alloc]initWithData:postData encoding:NSUTF8StringEncoding]);
        }
        
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
        _originalRequest = [[NSMutableURLRequest alloc] init];
        [_originalRequest setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [_originalRequest setURL:[NSURL URLWithString:[jointUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        [_originalRequest setHTTPMethod:MethodTypeArray[methodType]];
        [_originalRequest setTimeoutInterval:timeOut];
        if (applicationType != WSApplicationTypeNone) {
            [_originalRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
            [_originalRequest setValue:[NSString stringWithFormat:@"application/%@",ApplicationTypeArray[applicationType]] forHTTPHeaderField:@"Content-Type"];
            [_originalRequest setHTTPBody:postData];
        }
        
        if (applicationType == WSApplicationTypeMultipartFormData) {
            
        }
        
        if (httpHeaders) {
            for (NSString *key in httpHeaders.allKeys) {
                [_originalRequest addValue:httpHeaders[key] forHTTPHeaderField:key];
                if (showDebugLogs) NSLog(@"\n\n-------------------- BKConectionManager Adding Header : --------------------\n\n"
                                         @"Key : %@ \nValue : %@ \n"
                                         @"\n------------------------------------------------------------------------\n\n",key,httpHeaders[key]);
            }
        }
        
        theConnection=[[NSURLConnection alloc] initWithRequest:_originalRequest delegate:self];
        if (theConnection) {
            // Create the NSMutableData to hold the received data.
            // receivedData is an instance variable declared elsewhere.
            receivedData = [NSMutableData data];
        }
        
        if (withHud) {
            if (!activeHud) {
                hud = [BKHud showHUDanimated:YES];
                [hud setText:NSLocalizedString(hudMessage, nil)];
                activeHud = YES;
            }
        }
        
    }else{
        if (withAlerts) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:NSLocalizedString(@"No connection", Nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        }
        if ([self.delegate respondsToSelector: @selector(WSdidFailResponseInConnection:)]){
            [self.delegate WSdidFailResponseInConnection:self];
        }
    }
}

- (void)cancelRequest{
    [theConnection cancel];
    completitionBlock = nil;
    authorizationBlock = nil;
    if (withHud) {
        [BKHud hideHUDanimated:YES];
        activeHud = NO;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
    
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.

    // receivedData is an instance variable declared elsewhere.
    
    theResponse = (NSHTTPURLResponse*)response;
    
    [receivedData setLength:0];
    expectedBytes = [response expectedContentLength];
    if (showDebugLogs) NSLog(@"\n\n---------------- BKConectionManager didReceiveResponse : ---------------\n\n"
                             @"in WS : %@ \n"
                             @"expected bytes : %lld \n"
                             @"in kb : %lld \n"
                             @"in mb : %lld"
                             @"\n------------------------------------------------------------------------\n\n"
                             ,nameWS,expectedBytes,expectedBytes/1024,expectedBytes/(1024*1024));
    if ([self.downloadDelegate respondsToSelector:@selector(WSDownloadExpectedDataSize:)]) {
        [self.downloadDelegate WSDownloadExpectedDataSize:expectedBytes];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Append the new data to receivedData.
    // receivedData is an instance lvariable declared elsewhere.
    [receivedData appendData:data];
    
    NSInteger receivedLen = [data length];
    if ([self.downloadDelegate respondsToSelector: @selector(WSDownloadUpdateProgress:inConnectionTag:)]){
        bytesReceived = (bytesReceived + receivedLen);
        float progress = ((bytesReceived/(float)expectedBytes)*100)/100;
        [self.downloadDelegate WSDownloadUpdateProgress:progress inConnectionTag:requestTag];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
    // inform the user
    self.rawResponseOrErrorDescription = error.localizedDescription;
    
    if (showDebugLogs) NSLog(@"Connection failed! on WS : %@ with Error - %@ %@",
          nameWS,
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
    if (withHud) {
        if (withAlerts) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:NSLocalizedString(@"Couldn't connect", Nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alert show];
        }
        [BKHud hideHUDanimated:YES];
        activeHud = NO;
    }
    
    if ([self.delegate respondsToSelector: @selector(WSdidFailResponseInConnection:)]){
        [self.delegate WSdidFailResponseInConnection:self];
    }
    
    if ([self.downloadDelegate respondsToSelector:@selector(WSDownloadDidFail)]) {
        [self.downloadDelegate WSDownloadDidFail];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
    // receivedData is declared as a method instance elsewhere
    //NSLog(@"Succeeded!");

    NSError *parsingError = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:receivedData
                                                               options:NSJSONReadingAllowFragments
                                                                 error:&parsingError];
    
    self.rawResponseOrErrorDescription = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    
    if (showDebugLogs) {
        NSLog(@"\n\n-------------------- BKConectionManager Response Info : --------------------\n\n"
              @"WS Name : %@ \n"
              @"Response status code : %d \n"
              @"Bytes received : %lu \n"
              @"Method Type : %@ \n"
              @"Application Type : %@ \n"
              @"Raw Response : %@ \n\n"
              @"Response: %@ \n"
              @"------____              ________________________________---\n"
              @"         \\_         __/    ___---------__\n"
              @"          \\      _/      /               \\_\n"
              @"           \\    /       /                  \\\n"
              @"            |  /       | _    _ \\           \\\n"
              @"            | |       / / \\  / \\ |           \\\n"
              @"            | |       ||   ||   ||           |\n"
              @"            | |       | \\_// \\_/ |           |\n"
              @"            | |       |_| (||)   |_______|   |\n"
              @"            | |         |  ||     | _  / /   |\n"
              @"            \\ \\        |_________||  \\/ /   /\n"
              @"             \\ \\_       |_|_|_|_|/|   _/___/\n"
              @"              \\__>       _ _/_ _ /  |\n"
              @"                        .|_|_|_|_|   |\n"
              @"                        |           /\n"
              @"                        |__________/\n"
              @"\n----------------------------------------------------------------------------\n\n",nameWS,(int)theResponse.statusCode,(unsigned long)[receivedData length],MethodTypeArray[methodType],ApplicationTypeArray[applicationType],self.rawResponseOrErrorDescription,dictionary);
    }
    
    if (withHud) {
        [BKHud hideHUDanimated:YES];
        activeHud = NO;
    }
    
    if (saveInCache) {
        if (![[BKCache sharedInstance].cache objectForKey:[urlWS stringByAppendingString:nameWS]]) {
            [[BKCache sharedInstance].cache setObject:receivedData forKey:[urlWS stringByAppendingString:nameWS]];
        }
    }
    
    if (completitionBlock != Nil) {
        completitionBlock(receivedData);
        completitionBlock = nil;
    }
    
    if (authorizationBlock != Nil) {
        authorizationBlock(receivedData,self);
        authorizationBlock = nil;
    }
    
    if (!failedAuth) {
        if ([self.delegate respondsToSelector: @selector(WSdidGetResponse:inConnection:)]){
            [self.delegate WSdidGetResponse:dictionary inConnection:self];
        }
        
        if ([self.downloadDelegate respondsToSelector:@selector(WSDownloadDidFinishWithData:)]) {
            [self.downloadDelegate WSDownloadDidFinishWithData:receivedData];
        }
    }

}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    else
    {
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

+ (void)flushCache{
    [BKCache sharedInstance].cache = nil;
    [BKCache sharedInstance].cache = [[NSMutableDictionary alloc] init];
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse{
    
    if (redirectResponse) {
        // The request you initialized the connection with should be kept as
        // _originalRequest.
        // Instead of trying to merge the pieces of _originalRequest into Cocoa
        // touch's proposed redirect request, we make a mutable copy of the
        // original request, change the URL to match that of the proposed
        // request, and return it as the request to use.
        //
        NSMutableURLRequest *r = [_originalRequest mutableCopy];
        [r setURL: [request URL]];
        theConnection = connection;
        return r;
    } else {
        return request;
    }
    
    return request;
}

#pragma mark -
#pragma mark Utilities

+ (BOOL)connectedToNetworkRestring3g:(BOOL)restring{
    //Create zero addy
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    
    //Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags) {
        printf("Error. Could not recover network reachability flags\n");
        return NO;
    }
    
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    BOOL isWWAN = ([[NSString stringWithFormat:@"%u",flags] integerValue] == 327683) ? YES : NO;
    
    //flags : 327683  262144 //3g
    //flags : 65538  262144  //wifi
    
    //NSLog(@"flags : %u  %d",flags,kSCNetworkReachabilityFlagsIsWWAN);
    
    if (!isWWAN) NSLog(@"You're on WiFi Connection");
    if (isWWAN) NSLog(@"You're on 3g or Edge Connection");
    
    if (!restring) {
        isWWAN = NO;
    }
    
    return (isReachable && !needsConnection && !isWWAN) ? YES : NO;
    
}

+ (NSString *)hashed_stringSha256:(NSString *)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    // This is an iOS5-specific method.
    // It takes in the data, how much data, and then output format, which in this case is an int array.
    CC_SHA256(data.bytes, (int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    // Parse through the CC_SHA256 results (stored inside of digest[]).
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

+ (NSString *)encodeURL:(NSString *)urlString
{
    CFStringRef newString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)urlString, NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8);
    return (NSString *)CFBridgingRelease(newString);
}

+ (float)calculateProgressForValue:(float)value start:(float)start end:(float)end
{
    float diff = (value - start);
    float scope = (end - start);
    float progress;
    
    if(diff != 0.0) {
        progress = diff / scope;
    } else {
        progress = 0.0f;
    }
    
    return progress;
}

@end

