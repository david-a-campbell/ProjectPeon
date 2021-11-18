//
//  MovieTapHandler.m
//  rover
//
//  Created by David Campbell on 10/5/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "MovieTapHandler.h"

@implementation MovieTapHandler

-(id)init
{
    if (self = [super init])
    {
        [self setTouchEnabled:YES];
    }
    return self;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
//    [[self delegate] movieTapHandlerWasTapped];
    return YES;
}

- (void)registerWithTouchDispatcher
{
    //Must have negative priority to block ccmenuItems behind
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-2000 swallowsTouches:YES];
}

-(void)dealloc
{
    [super dealloc];
}


@end
