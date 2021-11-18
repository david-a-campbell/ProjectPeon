//
//  CompositeSprite.m
//  rover
//
//  Created by David Campbell on 7/13/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "CompositeSprite.h"
#import "Box2DHelpers.h"
#import "PRFilledPolygon.h"
#import "UIImage+Extras.h"
#import "PRRatcliffTriangulator.h"
#import "AnimatedSprite.h"

@implementation CompositeSprite

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict objectGroup:(CCTMXObjectGroup *)spriteObjects
{
    if ((self = [super init]))
    {
        world = theWorld;
        isSatellite = [[dict valueForKey:@"IsSatellite"] intValue];
        compositeSpriteID = [[dict valueForKey:@"CompositeSpriteID"] intValue];
        [self setDictionary:dict];
        [self setGameObjectType:kCompositeSpriteType];
        [self setupBody];
        [self setupTriangulatedFixtures];
        if (isSatellite)
        {
            [self setupPrismaticJoint];
        }
        [self setupTexture];
        if (compositeSpriteID != 0)
        {
            [self setupAditionalTextures:spriteObjects];
            [self setupAnimations:spriteObjects];
        }
    }
    return self;
}

-(void)setupBody
{
    float x = [[_dictionary valueForKey:@"x"] floatValue];
    float y = [[_dictionary valueForKey:@"y"] floatValue];
    originalPosition.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = originalPosition;
    body = world->CreateBody(&bodyDef);
    body->SetUserData(self);
    if (isSatellite)
    {
        body->SetGravityScale(0);
    }
    [self setPosition:ccp(x, y)];
}

-(void)setupTriangulatedFixtures
{
    b2FixtureDef fixtureDef;
    fixtureDef.density = 10000;
    fixtureDef.friction = 1;
    fixtureDef.restitution = 0.2;
    
    
     NSString *pointsString = [_dictionary valueForKey:@"polygonPoints"];
    if ([pointsString length])
    {
        [self triangulatePoints:pointsString ontoBody:body withFixtureDef:fixtureDef offset:CGSizeMake(0, 0) flipY:YES];
    }
}

-(void)setupPrismaticJoint
{
    float x = [[_dictionary valueForKey:@"x"] floatValue];
    float y = [[_dictionary valueForKey:@"y"] floatValue];
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    anchorBody = world->CreateBody(&bodyDef);
    anchorBody->SetGravityScale(0);
    
    b2PrismaticJointDef jointDef;
    CGPoint vector = ccp(1, 0);
    vector = ccpNormalize(vector);
    jointDef.Initialize(body, anchorBody, anchorBody->GetWorldCenter(), b2Vec2(vector.x, vector.y));
    world->CreateJoint(&jointDef);
}

-(void)setupTexture
{
    NSString *pointsString = [_dictionary valueForKey:@"polygonPoints"];
    if (![pointsString length]){return;}
    NSString *textureString = [_dictionary valueForKey:@"Texture"];
    if (![textureString length]) {return;}
    
    [self setupTexture:textureString withPoints:[self polygonPointsFromString:pointsString offset:CGSizeMake(0, 0) flipY:YES]];
}

-(void)setupAditionalTextures:(CCTMXObjectGroup*)spriteObjects
{
    NSMutableArray *objectArray = [spriteObjects objects];
    for (id object in objectArray)
    {
        if ([[object valueForKey:@"type"] isEqualToString:@"CompositeSpriteTexture"])
        {
            if ([[object valueForKey:@"CompositeSpriteID"] intValue] != compositeSpriteID)
            {
                continue;
            }
            
            NSString *pointsString = [object valueForKey:@"polygonPoints"];
            if (![pointsString length]){return;}
            NSString *textureString = [object valueForKey:@"Texture"];
            if (![textureString length]) {return;}
            int zOrd = [[object valueForKey:@"ZOrder"] intValue];
            
            NSMutableArray *polyArray = [self polygonPointsFromString:pointsString offset:CGSizeMake(0, 0) flipY:YES];
            PRFilledPolygon *texturedArea = [self getTexture:textureString withPoints:polyArray];
            
            [self addChild:texturedArea z:zOrd];
        }
    }
}

-(void)setupAnimations:(CCTMXObjectGroup*)spriteObjects
{
    NSMutableArray *objectArray = [spriteObjects objects];
    for (id object in objectArray)
    {
        if ([[object valueForKey:@"type"] isEqualToString:@"CompositeSpriteAnimation"])
        {
            if ([[object valueForKey:@"CompositeSpriteID"] intValue] != compositeSpriteID)
            {
                continue;
            }
            
            AnimatedSprite *sprite = [[AnimatedSprite alloc] initWithDict:object];
            if (!sprite)
            {
                continue;
            }
            float x = [[object valueForKey:@"x"] floatValue];
            float y = [[object valueForKey:@"y"] floatValue];
            float width = [[object valueForKey:@"width"] floatValue];
            float height = [[object valueForKey:@"height"] floatValue];
            x = x+width/2.0f;
            y = y+height/2.0f;
            
            int zOrd = [[object valueForKey:@"ZOrder"] intValue];
            [sprite setScale:(2*SCREEN_SCALE)];
            [[sprite texture] setAliasTexParameters];
            [sprite setOriginalPosition:ccp(x - _position.x, y - _position.y)];
            [self addChild:sprite z:zOrd];
        }
    }
}

-(void)reset
{
    body->SetTransform(originalPosition, body->GetAngle());
}

-(void)dealloc
{
    [self setDictionary:nil];
    [super dealloc];
}

@end
