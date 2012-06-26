//
//  IRWebAPIXOAuthAuthenticator.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

@class IRWebAPIAuthenticator;
@interface IRWebAPIXOAuthAuthenticator : IRWebAPIAuthenticator

@property (nonatomic, readwrite, copy) NSString *consumerKey;
@property (nonatomic, readwrite, copy) NSString *consumerSecret;

@property (nonatomic, readwrite, copy) NSString *retrievedToken;
@property (nonatomic, readwrite, copy) NSString *retrievedTokenSecret;
	
@end
