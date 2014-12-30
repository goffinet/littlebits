//
//  YFRHttpHelper.m
//  LittleBits
//
//  Created by Chris Wilson on 12/29/14.
//  Copyright (c) 2014 Yepher. All rights reserved.
//

#import "YFRHttpHelper.h"
#import "GCDAsyncSocket.h"
#import "YFRBaseRequest.h"

static NSString* const SERVER_URL = @"https://api-http.littlebitscloud.cc";

@interface YFRHttpHelper ()


@end

@implementation YFRHttpHelper


- (void) doRequest:(YFRBaseRequest*) requestObj {
    
    NSString *requestStr = [NSString stringWithFormat:@"%@%@",SERVER_URL, [requestObj requestPath]];
    if (requestStr == nil) {
        NSLog(@"no request URL!");
        return;
    }
    
    NSURL *requestUrl = [NSURL URLWithString:requestStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    
    NSMutableDictionary *headers = [NSMutableDictionary new];

    NSString* userToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"TOKEN"];
    
    // add standard headers
    NSString* token = [NSString stringWithFormat:@"Bearer %@", userToken];
    [headers setObject:token forKey:@"Authorization"];

    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        // add header
        [request setValue:value forHTTPHeaderField:key];
    }];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
//    if ([requestObj requestType] == YFR_REQUEST_TYPE_POST) {
//        NSDictionary *requestData = [handler getRequestBody];
//    }
    
    NSHTTPURLResponse *response;
    NSError *error = nil;
    
    // send request to server
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSInteger responseCode = [response statusCode];
    if (responseCode == 200) {
    
        // Get JSON result (server sends back JSON response for several non-200 status codes)
        NSString *contentType = [[[response allHeaderFields] valueForKey:@"content-type"] lowercaseString];
        id jsonResponse = [self getJsonResponse:result withContentType:contentType];

        NSLog(@"JsonResponse: %@", jsonResponse);
        [requestObj handleResponse:jsonResponse];
    } else {
        NSLog(@"Failed to make request because: %@", response);
    }
    
}

- (id)getJsonResponse:(NSData *)jsonData withContentType:(NSString *)contentType {
    id jsonResponse = nil;
    
    if (jsonData != nil && ([contentType hasPrefix:@"application/json"] || contentType == nil)) {
        NSError *jsonError = nil;
        jsonResponse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError != nil) {
            jsonResponse = nil;
            NSString *receivedJsonString = [NSString stringWithUTF8String:[jsonData bytes]];
            NSLog(@"%s Failed to parse JSON, because %@, json=%@", __FUNCTION__, jsonError, receivedJsonString);
        }
    }
    else if (jsonData != nil) {
        NSLog(@"WARN: API not returning Content-Type: application/json! instead returning: %@", contentType);
        return [self getJsonResponse:jsonData withContentType:nil];
    }
    return jsonResponse;
}

@end