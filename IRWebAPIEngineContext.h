//
//  IRWebAPIContext.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface IRWebAPIEngineContext : NSObject

@property (nonatomic, readonly, copy) NSURL *baseURL;

- (id) initWithBaseURL:(NSURL *)inBaseURL;

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName;

@end


@interface IRWebAPIEngineMutableContext : IRWebAPIEngineContext

@property (nonatomic, readwrite, copy) NSURL *baseURL;

@end
