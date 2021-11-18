//
//  ShockImageSet.m
//  rover
//
//  Created by David Campbell on 8/1/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "ShockImageSet.h"

@implementation ShockImageSet
-(id)init
{
    if (self = [super init])
    {
        _tempShockBar = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksBar.png"]];
        _tempShockBolt1 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksEnd.png"]];
        _tempShockBolt2 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksEnd.png"]];
        _tempShockPiston = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksPiston.png"]];
        _tempShock = [[CCSprite alloc] init];
        
        [_tempShockBar setScaleY:1];
        [_tempShockBolt1 setScale:1];
        [_tempShockBolt2 setScale:1];
        [_tempShockPiston setScaleY:1];
        
        _tempShockBarOriginalLength = [_tempShockBar boundingBox].size.width;
        _tempShockPistonOriginalLength = [_tempShockPiston boundingBox].size.width;
        _tempShockBoltOriginalHeight = [_tempShockBolt1 boundingBox].size.height;
        [_tempShockBolt2 setFlipX:YES];
        [_tempShockBolt1 setPosition:ccp([_tempShockBolt1 boundingBox].size.width/2,0)];
        
        [_tempShock addChild:_tempShockBar];
        [_tempShock addChild:_tempShockBolt1];
        [_tempShock addChild:_tempShockBolt2];
        [_tempShock addChild:_tempShockPiston];
        [_tempShockBar setOpacity:150];
        [_tempShockBolt1 setOpacity:150];
        [_tempShockBolt2 setOpacity:150];
        [_tempShockPiston setOpacity:150];
    }
    return self;
}

-(void)dealloc
{
    [self setTempShock:nil];
    [self setTempShockBar:nil];
    [self setTempShockBolt1:nil];
    [self setTempShockBolt2:nil];
    [self setTempShockPiston:nil];
    [super dealloc];
}
@end
