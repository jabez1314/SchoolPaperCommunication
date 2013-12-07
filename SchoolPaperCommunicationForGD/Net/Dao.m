//
//  Dao.m
//  XiaoxuntongModelDemo
//
//  Created by 陈 正梁 on 12/2/13.
//  Copyright (c) 2013 陈 正梁. All rights reserved.
//

#import "Dao.h"
#import "Reachability.h"
#import "XXTModelController.h"
#import "UIApplication+appinfo.h"
#import "SSZipArchive.h"
@interface Dao ()

-(void)initNetworkStateObserver;
-(void)reachabilityChanged:(NSNotification*)note;
-(NSDictionary *)request:(NSString *)urlString dict:(NSDictionary *)dict;
-(void)insertUserInfoToDictionary:(NSMutableDictionary*) dict;
-(NSString*) getUrlForModule:(NSString*) moduleName WithCmd:(NSString*) cmdStr;

@end

@implementation Dao

@synthesize reachbility;

#define WTF                      YES

//此处为基本ip地址
//#define baseUrl  @"http://localhost:8888/index.php"
#define baseUrl @"http://120.197.89.182:8080/mobile/pull"

#define userModuleUrl            @"login"
#define messageModuleUrl         @"messages"
#define contactsModuleUrl        @"contacts"
#define sysModuleUrl             @"modules"
#define otherModuleUrl           @"others"


//此处为基本操作码与URL后缀

#define loginCmd                @"10011"

#define messageListCmd          @"10021"
#define messageStatusUpdateCmd  @"10022"
#define sendGroupMessageCmd     @"10023"
#define messageTemplatesCmd     @"10024"
#define getModuleMessageCmd     @"10025"
#define messageHistoryCmd       @"10026"
#define getMessageReceiverCmd   @"10027"

#define sendInstantMessageCmd   @"10031"
#define getContactListCmd       @"10032"

#define microblogsListCmd       @"10041"
#define postMicroblogCmd        @"10042"
#define postCommentCmd          @"10043"
#define postLikeCmd             @"10044"
#define microblogDetailCmd      @"10045"
#define getCommentAndLikesCmd   @"10046"

//此处为一些常量 - 可以把它们移到config.h里
#define PLATFORM @"ios"
#define APIVERSION @"1.0"

#define messageRequestInterval 20.0f

+(id)sharedDao{
    static Dao* sharedDaoer;
    @synchronized(self){
        if(sharedDaoer == nil){
            sharedDaoer = [[Dao alloc] init];
            [sharedDaoer initNetworkStateObserver];
        }
    }
    return sharedDaoer;
}

-(void)initNetworkStateObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            //blockLabel.text = @"Block Says Reachable";
            self.reachbility = YES;
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reachbility = NO;
            //blockLabel.text = @"Block Says Unreachable";
        });
    };
    
    [reach startNotifier];
}



-(void) setTimerForMessageList{
    NSTimer* timer= [NSTimer timerWithTimeInterval:messageRequestInterval
                            target:self
                          selector:@selector(requestForMessageList)
                          userInfo:nil
                           repeats:YES] ;
    [[NSRunLoop currentRunLoop] addTimer:timer
                                 forMode:NSDefaultRunLoopMode];
    
    [[NSRunLoop currentRunLoop] run];
}

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        //有网
        //notificationLabel.text = @"Notification Says Reachable";
        reachbility = YES;
    }
    else
    {
        reachbility = NO;
        //断网
        //notificationLabel.text = @"Notification Says Unreachable";
    }
}

/**
 * @name request
 * @pam1 urlString：the url of the query's destination
 * @pam2 dict:to format the post array of the http .
 * @result return a NSDictionary contains the data what the protocol wo agree to.return nil 代表 联网失败。
 **/
-(NSDictionary *)request:(NSString *)urlString dict:(NSDictionary *)dict{
    
    NSDictionary *response = [[NSDictionary alloc] init];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    //create a request for the http-query.
    //And we set the request type to ignorecache to confirm each time we invoke this function,we
    //acquire the latest data .
    if(!self.reachbility) return nil;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:3.0f ];
    //format the post array
    NSMutableData *postData = [[NSMutableData alloc] init];
    int l = [dict count];
    NSArray *arr = [dict allKeys];
    
    for (int i = 0 ; i < l ; ++i) {
        if(i > 0 ){
            NSString *temp = @"&";
            [postData appendData:[temp dataUsingEncoding:NSUTF8StringEncoding]];
        }
        NSString *key = [arr objectAtIndex:i];
        NSString *param = [dict objectForKey:key];
        NSString *params = [[NSString alloc]initWithFormat:@"%@=%@",key,param];
        
        [postData appendData:[params dataUsingEncoding:NSUTF8StringEncoding]];
        //        NSLog(@"%@",params);
    }
    
    //set http method and body.
    if (WTF == YES)
        [request setHTTPMethod:@"GET"];
    else
    {
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:postData];
    }
    //start the connnection and block the thread.
    NSError *error;
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    //create the NSDictionary from the json result.
    if (error) {
        NSLog(@"Something wrong: %@",[error description]);
        return nil;
    }
    NSString* receivedStr = [NSString stringWithUTF8String:[received bytes]];
    NSLog(@"data %@",receivedStr);
//    if (received != NULL) {
    response = [NSJSONSerialization JSONObjectWithData:received options:NSJSONReadingMutableContainers error:&error];
    //just for Log.
    NSString *str1 = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
    NSLog(@"received dic %@",str1);
    
//    }
    
    return response;
}

- (void) insertUserInfoToDictionary:(NSMutableDictionary *)dict{
    [dict setObject:PLATFORM forKey:@"platform"];
    [dict setObject:APIVERSION forKey:@"version"];
    
    if ([XXTModelGlobal sharedModel].sessionId != nil){
        [dict setObject:[XXTModelGlobal sharedModel].sessionId forKey:@"sessionKey"];
        [dict setObject:[XXTModelGlobal sharedModel].currentUser.pid forKey:@"userId"];
        [dict setObject:[XXTModelGlobal sharedModel].currentUser.schoolId forKey:@"schoolId"];
        [dict setObject:[XXTModelGlobal sharedModel].currentUser.areaAbbr forKey:@"areaAbbr"];
        [dict setObject:[NSNumber numberWithInt:[XXTModelGlobal sharedModel].currentUser.type] forKey:@"userType"];
    }
}

- (NSString*) getUrlForModule:(NSString *)moduleName WithCmd:(NSString *)cmdStr{
    if (WTF == YES)
        return [NSString stringWithFormat:@"%@/%@/%@",baseUrl,moduleName,cmdStr];
    else
        return [NSString stringWithFormat:@"%@/%@/",baseUrl,moduleName];
}

- (NSInteger) requestForLogin:(NSString *)username password:(NSString *)pwd{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:[NSNumber numberWithInt:[loginCmd intValue]] forKey:@"cmd"];
    [postDic setObject:username forKey:@"account"];
    [postDic setObject:pwd forKey:@"pwd"];
    [postDic setObject:[UIApplication appVersion] forKey:@"appVersion"];
    [postDic setObject:[UIApplication sysVersion] forKey:@"sysVersion"];
    [postDic setObject:@"iOS" forKey:@"platform"];
    [postDic setObject:[UIApplication deviceType] forKey:@"model"];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    NSString* screenSize = [NSString stringWithFormat:@"%d×%d",(int)screenWidth,(int)screenHeight];
    [postDic setObject:screenSize forKey:@"screenSize"];
    if ([[UIApplication deviceType] isEqualToString:@"Simulator"]){
        [postDic setObject:@"ThisIsSimulator" forKey:@"deviceToken"];
    }
    else{
        [postDic setObject:[XXTModelGlobal sharedModel].deviceToken forKey:@"deviceToken"];
    }
    [postDic setObject:[UIApplication appId] forKey:@"appId"];
    
    NSString* url = [self getUrlForModule:userModuleUrl WithCmd:loginCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController loginSuccess:rs];
    }
    
    return ret;
}

- (NSInteger) requestForMessageList
{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:messageListCmd forKey:@"cmd"];
    
    NSDate* lastUpdateTime = [XXTModelGlobal sharedModel].currentUser.lastUpdateTimeForMessageList;
    NSString* lastUpdateTimeString = [NSDate stringValueOfDate:lastUpdateTime];
    [postDic setObject:lastUpdateTimeString forKey:@"updateTime"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:messageModuleUrl WithCmd:messageListCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        NSArray *newMessagesList = [rs objectForKey:@"items"];
        if ([newMessagesList count] > 0)
            [XXTModelController receivedNewMessages:newMessagesList];
    }
    return ret;
}

- (NSInteger) requestForMessageStatusUpdateWithMessageObjects:(NSArray *)messageObjects{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:messageStatusUpdateCmd forKey:@"cmd"];
    NSMutableArray* msgIdsArr = [NSMutableArray array];
    for (XXTMessageReceive* message in messageObjects){
        [msgIdsArr addObject:message.msgId];
    }
    [postDic setObject:msgIdsArr forKey:@"msgIds"];
    
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:messageModuleUrl WithCmd:messageStatusUpdateCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController ReceiveMessageStatusUpdate:messageObjects];
    }
    
    return ret;
}

- (NSInteger) requestForSendGroupMessage:(XXTMessageSend *)messageToSend{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:sendGroupMessageCmd forKey:@"cmd"];
    
    NSMutableArray* groupIdsItem = [NSMutableArray array];
    for (NSString* groupId in messageToSend.sendToGroupIdArr){
        NSMutableDictionary* groupInfoDic = [NSMutableDictionary dictionary];
        XXTGroup* group = [[XXTModelGlobal sharedModel].currentUser getGroupObjectById:groupId];
        [groupInfoDic setObject:groupId forKey:@"id"];
        [groupInfoDic setObject:[NSNumber numberWithInt:group.groupType] forKey:@"type"];
        [groupIdsItem addObject:groupInfoDic];
    }
    [postDic setObject:groupIdsItem forKey:@"groupIdsItem"];
    
    NSMutableArray* receiverIdsItem = [NSMutableArray array];
    for (NSString* receiverId in messageToSend.sendToPersonIdArr){
        NSMutableDictionary* receiverInfoDic = [NSMutableDictionary dictionary];
        XXTPersonBase* person = [[XXTModelGlobal sharedModel].currentUser getPersonObjectById:receiverId];
        [receiverInfoDic setObject:receiverId forKey:@"id"];
        [receiverInfoDic setObject:[NSNumber numberWithInt:person.type] forKey:@"type"];
        [receiverIdsItem addObject:receiverInfoDic];
    }
    [postDic setObject:receiverIdsItem forKey:@"receiverIdsItem"];
    
    [postDic setObject:messageToSend.content forKey:@"Content"];
    NSMutableArray* imagesArr = [NSMutableArray array];
    for (XXTImage* image in messageToSend.images){
        NSMutableDictionary* imageDic = [NSMutableDictionary dictionary];
        [imageDic setObject:image.originPicURL forKey:@"original"];
        [imageDic setObject:image.thumbPicURL forKey:@"thumb"];
        [imagesArr addObject:imageDic];
    }
    [postDic setObject:imagesArr forKey:@"images"];
    
    NSMutableArray* audioArr = [NSMutableArray array];
    for (XXTAudio* audio in messageToSend.audios){
        NSMutableDictionary* audioDic = [NSMutableDictionary dictionary];
        [audioDic setObject:audio.audioURL forKey:@"url"];
        [audioDic setObject:[NSNumber numberWithInt:audio.duration] forKey:@"duration"];
        [audioArr addObject:audioDic];
    }
    [postDic setObject:audioArr forKey:@"audios"];
    
    NSString *url = [self getUrlForModule:messageModuleUrl WithCmd:sendGroupMessageCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController groupMessageSendSuccess:messageToSend WithDictionary:rs];
    }
    
    return ret;
}

- (NSInteger) requestForMessageTemplates{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:messageTemplatesCmd forKey:@"cmd"];
    NSDate* lastUpdateTime = [XXTModelGlobal sharedModel].currentUser.lastUpdateTimeForMessageTemplates;
    NSString* lastUpdateTimeStr = [NSDate stringValueOfDate:lastUpdateTime];
    [postDic setObject:lastUpdateTimeStr forKey:@"updateTime"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString* url = [self getUrlForModule:messageModuleUrl WithCmd:messageTemplatesCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController receivedMessageTemplatesDictionary:rs];
    }
    
    return ret;
}

- (NSInteger) requestForMessageHistoryWithDate:(NSDate *)date isPull:(BOOL)isPull pageSize:(int)pageSize keyword:(NSString *)keyword type:(XXTHistoryType)type{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:messageHistoryCmd forKey:@"cmd"];
    NSString *lastUpdateTimeStr = [NSDate stringValueOfDate:date];
    [postDic setObject:lastUpdateTimeStr forKey:@"dateTime"];
    [postDic setObject:[NSNumber numberWithInt:isPull] forKey:@"isPull"];
    [postDic setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    if (keyword == nil) keyword = @"";
    [postDic setObject:keyword forKey:@"key"];
    [postDic setObject:[NSNumber numberWithInt:type] forKey:@"type"];
    
    [self insertUserInfoToDictionary:postDic];
    
    NSString* url = [self getUrlForModule:messageModuleUrl WithCmd:messageHistoryCmd];
//    if (WTF)
//        url = @"http://localhost:8888/messageHistory.php";
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController receivedMessageHistoryDictionary:rs];
    }
    
    return ret;
}

- (NSInteger) requestForMessageReceivers:(XXTHistoryMessage *)message{
    int ret = 0;
    
    NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
    [postDic setObject:getMessageReceiverCmd forKey:@"cmd"];
    [postDic setObject:message.msgId forKey:@"id"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString* url = [self getUrlForModule:messageModuleUrl WithCmd:getMessageReceiverCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController receivedMessageHistoryReceiverDic:rs ForMessage:message];
    }
    
    return ret;
}

- (NSInteger) requestForModuleMessages{
    int ret = 0;
    
    NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
    [postDic setObject:getModuleMessageCmd forKey:@"cmd"];
    NSDate* lastUpdateTime = [XXTModelGlobal sharedModel].currentUser.lastUpdateTimeForModuleMessage;
    NSString* lastTimeStr = [NSDate stringValueOfDate:lastUpdateTime];
    [postDic setObject:lastTimeStr forKey:@"updateTime"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString* url = [self getUrlForModule:messageModuleUrl WithCmd:getModuleMessageCmd];
    if (WTF)
        url = @"http://localhost:8888/moduleMessage.php";
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController receivedModuleMessageDic:rs];
    }
    
    return ret;
}

- (NSInteger) requestForSendInstantMessage:(XXTMessageSend *)messageToSend{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:sendInstantMessageCmd forKey:@"cmd"];
    
    NSString* receiverId = [messageToSend.sendToPersonIdArr objectAtIndex:0];
    XXTContactPerson* receiver = (XXTContactPerson*)[[XXTModelGlobal sharedModel].currentUser getPersonObjectById:receiverId];
    [postDic setObject:receiverId forKey:@"id"];
    [postDic setObject:[NSNumber numberWithInt:receiver.type] forKey:@"type"];
    
    [postDic setObject:messageToSend.content forKey:@"Content"];
    NSMutableArray* imagesArr = [NSMutableArray array];
    for (XXTImage* image in messageToSend.images){
        NSMutableDictionary* imageDic = [NSMutableDictionary dictionary];
        [imageDic setObject:image.originPicURL forKey:@"original"];
        [imageDic setObject:image.thumbPicURL forKey:@"thumb"];
        [imagesArr addObject:imageDic];
    }
    [postDic setObject:imagesArr forKey:@"images"];
    
    NSMutableArray* audioArr = [NSMutableArray array];
    for (XXTAudio* audio in messageToSend.audios){
        NSMutableDictionary* audioDic = [NSMutableDictionary dictionary];
        [audioDic setObject:audio.audioURL forKey:@"url"];
        [audioDic setObject:[NSNumber numberWithInt:audio.duration] forKey:@"duration"];
        [audioArr addObject:audioDic];
    }
    [postDic setObject:audioArr forKey:@"audios"];
    
    NSString *url = [self getUrlForModule:contactsModuleUrl WithCmd:sendInstantMessageCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController instantMessageSendSuccess:messageToSend WithDictionary:rs];
    }
    
    return ret;
}

- (NSInteger) requestForGetContactList{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:getContactListCmd forKey:@"cmd"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString* url = [self getUrlForModule:contactsModuleUrl WithCmd:getContactListCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    if (ret == 1){
        NSString* zipUrlStr = [rs objectForKey:@"downUrl"];
        if (zipUrlStr == nil || [zipUrlStr isEqualToString:@""])
            return 404;
        NSURL *zipURL = [NSURL URLWithString:zipUrlStr];
        NSData *data = [NSData  dataWithContentsOfURL:zipURL];
        NSString *fileName = [[zipURL path] lastPathComponent];
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [data writeToFile:filePath atomically:YES];
        NSString *unzipPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"linkMan.json"];
        [SSZipArchive unzipFileAtPath:filePath toDestination:NSTemporaryDirectory()];
        NSData* unzipData = [NSData dataWithContentsOfFile:unzipPath];
        
        NSError* error;
        NSArray *groupDicArr = [NSJSONSerialization JSONObjectWithData:unzipData options:NSJSONReadingMutableContainers error:&error];
        
        [XXTModelController receivedContactsListDicArr:groupDicArr];
        
    }
    
    return ret;
}

- (NSInteger) requestForMicroblogsListWithType:(XXTMicroblogCircleType)circleType isPull:(NSInteger)isPull pageSize:(NSInteger)pageSize
{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:microblogsListCmd forKey:@"cmd"];
    [postDic setObject:[NSNumber numberWithInt:circleType] forKey:@"type"];
    NSDate* lastUpdateTime = [[XXTModelGlobal sharedModel].currentUser.lastUpdateTimeForMicroblogListArr objectAtIndex:circleType];
    NSString* lastUpdateTimeString = [NSDate stringValueOfDate:lastUpdateTime];
    [postDic setObject:lastUpdateTimeString forKey:@"updateTime"];
    [postDic setObject:[NSNumber numberWithInt:isPull] forKey:@"isPull"];
    [postDic setObject:[NSNumber numberWithInt:pageSize] forKey:@"pageSize"];
    
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:microblogsListCmd];
    NSDictionary *rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        NSArray* microblogArr = [rs objectForKey:@"items"];
        [XXTModelController receivedMicroblogDics:microblogArr WithType:circleType];
    }
    
    return ret;
}

- (NSInteger) requestForPostMicroblog:(XXTMicroblog *)microblog{
    int ret = 0 ;
    
    NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
    [postDic setObject:postMicroblogCmd forKey:@"cmd"];
    if (microblog.content != nil)
        [postDic setObject:microblog.content forKey:@"content"];
    if ([microblog.images count] > 0){
        NSMutableArray* imagesDicArr = [NSMutableArray array];
        for (XXTImage* image in microblog.images){
            NSMutableDictionary* imageDic = [NSMutableDictionary dictionary];
            [imageDic setObject:image.originPicURL forKey:@"original"];
            [imageDic setObject:image.thumbPicURL forKey:@"thumb"];
            [imagesDicArr addObject:imageDic];
        }
        [postDic setObject:imagesDicArr forKey:@"images"];
    }
    if ([microblog.audios count]>0){
        NSMutableArray* audiosDicArr = [NSMutableArray array];
        for (XXTAudio* audio in microblog.audios){
            NSMutableDictionary* audioDic = [NSMutableDictionary dictionary];
            [audioDic setObject:audio.audioURL forKey:@"url"];
            [audioDic setObject:[NSNumber numberWithInt:audio.duration] forKey:@"duration"];
            [audiosDicArr addObject:audioDic];
        }
        [postDic setObject:audiosDicArr forKey:@"audios"];
    }
    
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:postMicroblogCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController postMicroblogSuccess:microblog WithDic:rs];
    }
    
    return ret;
}

- (NSInteger) requestforPostComment:(XXTComment*) comment microblog:(XXTMicroblog *)microblog{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:postCommentCmd forKey:@"cmd"];
    [postDic setObject:comment.content forKey:@"content"];
    [postDic setObject:microblog.msgId forKey:@"id"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:postCommentCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController postCommentSuccess:comment ToMicroblog:microblog WithDic:rs];
    }
    
    return  ret;
}

- (NSInteger) requestForPostLike:(XXTMicroblog *)microblog{
    int ret = 0;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:postLikeCmd forKey:@"cmd"];
    [postDic setObject:microblog.msgId forKey:@"id"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:postLikeCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController postLikeSuccessToMicroblog:microblog WithDic:rs];
    }
    
    return ret;
}

- (NSInteger) requestForMicroblogDetail:(XXTMicroblog *)microblog{
    int ret = 0 ;
    
    NSMutableDictionary *postDic = [NSMutableDictionary dictionary];
    [postDic setObject:microblogDetailCmd forKey:@"cmd"];
    [postDic setObject:microblog.msgId forKey:@"id"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:microblogDetailCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController microblogDetail:rs forMicroblog:microblog];
    }
    
    return ret;
}

- (NSInteger) requestForMyCommentAndLikes{
    int ret = 0 ;
    
    NSMutableDictionary* postDic = [NSMutableDictionary dictionary];
    [postDic setObject:getCommentAndLikesCmd forKey:@"cmd"];
    NSDate* lastUpdateTime = [XXTModelGlobal sharedModel].currentUser.lastUpdateTimeForCommentsAndLikes;
    NSString* lastUpdateTimeString = [NSDate stringValueOfDate:lastUpdateTime];
    [postDic setObject:lastUpdateTimeString forKey:@"updateTime"];
    [self insertUserInfoToDictionary:postDic];
    
    NSString *url = [self getUrlForModule:sysModuleUrl WithCmd:getCommentAndLikesCmd];
    NSDictionary* rs = [self request:url dict:postDic];
    
    ret = [[rs objectForKey:@"resultState"] intValue];
    
    if (ret == 1){
        [XXTModelController getCommentsAndLikes:[rs objectForKey:@"item"]];
    }
    
    return ret;
}

@end
