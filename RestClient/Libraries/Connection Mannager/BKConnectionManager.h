//
//  BKConnectionManager.h
//
//
//  Created by Rodrigo Galvez on 19/03/13.
//  Copyright (c) 2013 Rodrigo Galvez. All rights reserved.
//  Version  1.7

#import <Foundation/Foundation.h>

/*!
 @Typedef WSApplicationType
 */
typedef enum{
    /// No application Type
    WSApplicationTypeNone,
    /// JSON application Type
    WSApplicationTypeJSON,
    /// UrlEncoded application Type
    WSApplicationTypeUrlEncoded,
    /// MultipartFormData application Type
    WSApplicationTypeMultipartFormData
}WSApplicationType;

/*!
 @Typedef WSMethodType
*/
typedef enum{
    /// POST Method Type
    WSMethodTypePOST,
    /// GET Method Type
    WSMethodTypeGET,
    /// PUT Method Type
    WSMethodTypePUT,
    /// DELETE Method Type
    WSMethodTypeDELETE
}WSMethodType;

@class BKConnectionManager;             //define class, so protocol can see MyClass
@protocol BKConnectionManagerDelegate <NSObject>  //define delegate protocol
@optional
- (void) WSdidGetResponse:(id)response inConnection:(BKConnectionManager*)connection;
- (void) WSdidGetResponse:(id)response inConnection:(BKConnectionManager*)connection andQueueTag:(int)queueTag;
- (void) activeInternetConnection;
- (void) WSdidFailResponseInConnection:(BKConnectionManager*)connection;
- (void) WSUpdateDownloadProgress:(float)progress inConnectionTag:(BKConnectionManager*)connection;
@end //end protocol

@protocol BKConnectionManagerDownloadDelegate <NSObject>
@optional
- (void) WSDownloadExpectedDataSize:(float)expectedSize;
- (void) WSDownloadUpdateProgress:(float)progress inConnectionTag:(int)tag;
- (void) WSDownloadDidFinishWithData:(NSData*)dowloadData;
- (void) WSDownloadDidFail;
@end

@interface BKConnectionManager : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate,BKConnectionManagerDelegate> {
}

@property (nonatomic, weak) id <BKConnectionManagerDelegate> delegate; //define BKConnectionManagerDelegate as delegate

@property (nonatomic, weak) id <BKConnectionManagerDownloadDelegate> downloadDelegate;

/*!
 * @brief Property to set the tag of this connection to easily recognize it on the delegate
 */
@property int requestTag;

/*!
 * @brief Property to set the timeout of the request
 */
@property float timeOut;

/*!
 * @brief Property to set the url on the WS, sometimes you need to ask for it before sending the request, so this property is made to set when that happends. If you don't need to wait you can just send this parameter on the init method
 */
@property (nonatomic, strong) NSString *urlWS;

/*!
 * @brief Property to show logs of what is happening, by default is set to YES.
 */
@property BOOL showDebugLogs;

/*!
 * @brief Property to restring the connection only to wifi, by deafult is set to NO.
 */
@property BOOL restring3g;

/*!
 * @brief Property to display a hud with text to make the user wait until it's done, by deafult is set to NO
 */
@property BOOL withHud;

/*!
 * @brief Property to display a Alert Views to the user, default is YES.
 */
@property BOOL withAlerts;

/*!
 * @brief Property to display a message inside the hud.
 */
@property (nonatomic, strong) NSString *hudMessage;

/*!
 * @brief Property to use in a queue, you should never set this property.
 */
@property BOOL inQueue;

/*!
 * @brief Property to save on a temporary cache the data you're requesting, it's useful for image downloading and the use of the completition block.
 */
@property BOOL saveInCache;

/*!
 * @brief Property to set the applicationType with the enumeration WSApplicationType that is define at the top of this file.
 */
@property WSApplicationType applicationType;

/*!
 * @brief Property to set the applicationType with the enumeration SWMethodType that is define at the top of this file.
 */
@property WSMethodType methodType;

/*!
 * @brief Property to add any httpHeader that you need, each header is added before the request is send to the server.
 */
@property (nonatomic, strong) NSDictionary *httpHeaders;

/*!
 * @brief Property to add a completition action when the request finish loading.
 */
@property (nonatomic, strong) void (^completitionBlock)(NSData *response);

/*!
 * @brief Property to add a authorization action when the request finish loading.
 */
@property (nonatomic, strong) void (^authorizationBlock)(NSData *response, BKConnectionManager *currentConnection);

/*!
 * @brief Property to be set on the authorizationBlock to notify that the authorizationBlock has performed an action.
 */
@property (nonatomic, assign) BOOL failedAuth;


/*!
 * @brief Property to get the raw response of the request or the error description if something goes wrong
 */
@property (nonatomic, strong) NSString *rawResponseOrErrorDescription;

/*!
 * @brief  Method to init a request to the url specified.
 * @code [[BKConnectionManager alloc] initWithInfo:post withUrl:BaseURL inWS:Login withMethodType:WSMethodTypePOST andApplicationType:WSApplicationTypeJSON delegate:delegate];
 * @param info  when JSON must be a NSDictionary, when URLEnconded a NSString
 * @param theURL  the url at wich the request will be send.
 * @param wsName  Sometimes there is a base url and only the last part change, this is to specify the part that change.
 * @param theMethodType  Enum defined at the top of this file.
 * @param theApplicationType  Enum defined at the top of this file.
 * @param delegate  The class that will recive the delegate methods that are specified at the begining of this file.
 * @returns  self.
 */
- (id)initWithInfo:(id)info withUrl:(NSString*)theURL inWS:(NSString*)wsName withMethodType:(WSMethodType)theMethodType andApplicationType:(WSApplicationType)theApplicationType delegate:(id)theDelegate;

/*!
 * @brief  Method to start the connection.
 * @param  nil
 * @returns  nil
 */
- (void)sendRequest;

/*!
 * @brief  Method to cancel the connection.
 * @param  nil
 * @returns  nil
 */
- (void)cancelRequest;

/*!
 * @brief  Method to send a queue of request to make
 * @param array  the NSMutableArray that contains all the BKConnectionManagers to be requested.
 * @returns  the reference to this queue (must be retain).
 */
- (id)startRequestQueueWithBKConnectionsArray:(NSMutableArray*)array withDelegate:(id)theDelegate;

/*!
 * @brief  Method to flush the cache (release some memory)
 * @param  nil
 * @returns  nil
 */
+ (void)flushCache;

/*!
 * @brief  Method to know if you are currently connected to a network
 * @param restring  if set to YES only wifi will be tested
 * @returns  BOOL value YES  when you have connection ,NO  if you don't
 */
+ (BOOL)connectedToNetworkRestring3g:(BOOL)restring;

/*!
 * @brief  Method to hash a string in Sha256
 * @param  NSString to encode
 * @returns  hashed string
 */
+ (NSString *)hashed_stringSha256:(NSString *)input;

/*!
 * @brief  Method to encode de url
 * @param  url to enconde
 * @returns  encoded NSString
 */
+ (NSString *)encodeURL:(NSString *)urlString;

/*!
 * @brief  Method to calculet progress
 * @param  value  actual value
 * @param  start  initial value
 * @param  end    final value
 * @returns  progress in float (between 0 to 1)
 */
+ (float)calculateProgressForValue:(float)value start:(float)start end:(float)end;

/*!
 * @brief  Method to get the progress on the current queue. (Is meant to be use internaly by the queue)
 * @param  value
 * @returns  nil
 */
- (void)progress:(float)value;

@end

