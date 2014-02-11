//
//  BMMessage.m
//  Bitmarket
//
//  Created by Steve Dekorte on 1/25/14.
//  Copyright (c) 2014 Bitmarkets.org. All rights reserved.
//

#import "BMMessage.h"
#import "BMServerProxy.h"
#import "BMClient.h"

@implementation BMMessage

- (id)init
{
    self = [super init];
    self.actions = [NSMutableArray arrayWithObjects:@"send", @"broadcast", @"delete", nil];
    return self;
}

+ (BMMessage *)withDict:(NSDictionary *)dict
{
    id instance = [[[self class] alloc] init];
    [instance setDict:dict];
    return instance;
}


- (NSDictionary *)dict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.encodingType forKey:@"encodingType"];
    [dict setObject:self.toAddress forKey:@"toAddress"];
    [dict setObject:self.msgid forKey:@"msgid"];
    [dict setObject:self.message forKey:@"message"];
    [dict setObject:self.fromAddress forKey:@"fromAddress"];
    [dict setObject:self.receivedTime forKey:@"receivedTime"];
    [dict setObject:self.lastActionTime forKey:@"lastActionTime"];
    [dict setObject:self.subject forKey:@"subject"];
    [dict setObject:[NSNumber numberWithBool:self.read] forKey:@"read"];
    return dict;
}

- (void)setDict:(NSDictionary *)dict
{
    self.encodingType = [dict objectForKey:@"encodingType"];
    self.toAddress = [dict objectForKey:@"toAddress"];
    self.msgid = [dict objectForKey:@"msgid"];
    self.message = [dict objectForKey:@"message"];
    self.fromAddress = [dict objectForKey:@"fromAddress"];
    self.receivedTime = [dict objectForKey:@"receivedTime"];
    self.lastActionTime = [dict objectForKey:@"lastActionTime"];
    self.subject = [dict objectForKey:@"subject"];
    self.read = [[dict objectForKey:@"read"] boolValue];
}

- (NSString *)subjectString
{
    return [self.subject decodedBase64];
}

- (NSString *)messageString
{
    return [self.message decodedBase64];
}

- (NSString *)nodeTitle
{
    return self.fromAddressLabel;
}

- (NSString *)nodeSubtitle
{
    return self.subjectString;
}

- (NSString *)fromAddressLabel
{
    BMContact *contact = [[[BMClient sharedBMClient] contacts] contactWithAddress:self.fromAddress];
    if (contact && contact.label && ![contact.label isEqualToString:@""])
    {
        return contact.label;
    }
    
    BMIdentity *identity = [[[BMClient sharedBMClient] identities] identityWithAddress:self.fromAddress];
    if (identity && identity.label && ![identity.label isEqualToString:@""])
    {
        return identity.label;
    }
    
    return self.fromAddress;
}

- (NSDate *)date
{
    NSInteger unixTime = 0;
    
    if (self.receivedTime)
    {
        unixTime = [self.receivedTime integerValue];
    }
    
    if (self.lastActionTime)
    {
        unixTime = [self.lastActionTime integerValue];
    }

    if (unixTime)
    {
        return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)unixTime];
    }
    
    return nil;
}

// -----------------------

- (id)send
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"sendMessage"];
    
    // subject and message in base64
    NSArray *params = [NSArray arrayWithObjects:self.toAddress, self.fromAddress, self.subject, self.message, nil];
    
    [message setParameters:params];
    [message sendSync];
    
    return [message parsedResponseValue];
}

- (id)broadcast
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"sendBroadcast"];
    
    // subject and message in base64
    NSArray *params = [NSArray arrayWithObjects:self.fromAddress, self.subject, self.message, nil];
    
    [message setParameters:params];
    [message sendSync];
    
    return [message parsedResponseValue];
}

- (id)delete
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"trashMessage"];
    NSArray *params = [NSArray arrayWithObjects:self.msgid, nil];
    [message setParameters:params];
    [message sendSync];
    [self postChanged];
    return [message parsedResponseValue];
}

- (id)setReadState:(BOOL)isRead
{
    BMProxyMessage *message = [[BMProxyMessage alloc] init];
    [message setMethodName:@"getInboxMessageByID"];
    NSArray *params = [NSArray arrayWithObjects:self.msgid, [NSNumber numberWithBool:isRead], nil];
    [message setParameters:params];
    [message sendSync];
    return [message parsedResponseValue];
}

- (void)markAsRead
{
    if (!self.read)
    {
        [self setReadState:YES];
        [self postChanged];
    }
}

- (void)markAsUnread
{
    if (self.read)
    {
        [self setReadState:NO];
        [self postChanged];
    }
}

- (void)postChanged
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BMMessageChanged" object:self];
}



@end
