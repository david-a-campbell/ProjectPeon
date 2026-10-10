//
//  PlayerClip.m
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PlayerClipGround.h"
#ifdef PROJECTPEON_MAC
#import "PeonViewport.h"
#import "Box2DHelpers.h"
#endif

@implementation PlayerClipGround

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict isSolid:(BOOL)solid
{
    if ((self = [super initWithWorld:theWorld andDict:dict isSolid:solid]))
    {
        [self setGameObjectType:kPlayerClipType];
    }
    return self;
}

#ifdef PROJECTPEON_MAC
-(void)setupBody
{
    [super setupBody];
    if ([[self.dictionary valueForKey:@"name"] isEqualToString:@"leftClip"])
    {
        CGFloat inset = (PeonPresentationSize(CGSizeMake(1024,768)).width-1024)/2;
        CGPoint position = ccp(self.position.x-inset, self.position.y);
        body->SetTransform(b2Vec2(position.x/pixelsToMeterRatio(), position.y/pixelsToMeterRatio()), body->GetAngle());
        self.position = position;
    }
}
#endif

-(void)setupTexture
{}
@end
