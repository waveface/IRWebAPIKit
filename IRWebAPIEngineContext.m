//
//  IRWebAPIContext.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngineContext.h"

@interface IRWebAPIEngineContext ()

@property (nonatomic, readwrite, copy) NSURL *baseURL;

@end


@implementation IRWebAPIEngineContext
@synthesize baseURL = _baseURL;

- (id) initWithBaseURL:(NSURL *)inBaseURL {

	self = [super init];
	if (!self)
		return nil;
	
	_baseURL = [inBaseURL copy];
	
	return self;

}

- (id) init {

	return [self initWithBaseURL:nil];

}

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	return [NSURL URLWithString:inMethodName relativeToURL:self.baseURL];

}

@end


@implementation IRWebAPIEngineMutableContext : IRWebAPIEngineContext
@dynamic baseURL;

@end
