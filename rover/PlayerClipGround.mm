//
//  PlayerClip.m
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PlayerClipGround.h"

@implementation PlayerClipGround

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict isSolid:(BOOL)solid
{
    if ((self = [super initWithWorld:theWorld andDict:dict isSolid:solid]))
    {
        [self setGameObjectType:kPlayerClipType];
    }
    return self;
}

-(void)setupTexture
{}
@end
