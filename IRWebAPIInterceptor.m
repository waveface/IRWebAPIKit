//
//  IRWebAPIInterceptor.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 6/25/12.
//
//

#import "IRWebAPIInterceptor.h"

@implementation IRWebAPIInterceptor
@synthesize receiver = _receiver;

- (id) forwardingTargetForSelector:(SEL)aSelector {

	if ([_receiver respondsToSelector:aSelector])
		return _receiver;
	
	return	[super forwardingTargetForSelector:aSelector];
	
}

- (BOOL) respondsToSelector:(SEL)aSelector {

	if ([_receiver respondsToSelector:aSelector])
		return YES;
	
	return [super respondsToSelector:aSelector];
	
}

@end
