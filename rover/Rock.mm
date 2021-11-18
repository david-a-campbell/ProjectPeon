//
//  Rock.m
//  rover
//
//  Created by David Campbell on 6/30/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Rock.h"
#import "Box2DHelpers.h"
#import "PRFilledPolygon.h"
#import "UIImage+Extras.h"
#import "PRRatcliffTriangulator.h"

@implementation Rock
@synthesize dictionary, filledPolygon1, filledPolygon2;

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict
{
    if ((self = [super init]))
    {
        world = theWorld;
        [self setDictionary:dict];
        [self setGameObjectType:kRockType];
        [self setupBody];
        [self setupTriangulatedFixtures];
        [self setupTexture];
    }
    return self;
}

-(void)setupBody
{
    float x = [[dictionary valueForKey:@"x"] floatValue];
    float y = [[dictionary valueForKey:@"y"] floatValue];
    b2BodyDef groundBodyDef;
    groundBodyDef.type = b2_dynamicBody;
    groundBodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    body = world->CreateBody(&groundBodyDef);
    body->SetUserData(self);
    [self setPosition:ccp(x, y)];
}

-(void)resetRock
{
    body->SetUserData(nil);
    world->DestroyBody(body);
    [self setupBody];
    [self setupTriangulatedFixtures];
}

-(void)setupTriangulatedFixtures
{
    NSString *pointsString;
    
    b2FixtureDef fixtureDef;
    fixtureDef.filter.categoryBits = kGroundCat;
    fixtureDef.friction = 1;
    fixtureDef.restitution = 0.2;
    fixtureDef.density = 3000.0;
    
    pointsString = [dictionary valueForKey:@"polygonPoints"];
    [self polygonatePoints:pointsString ontoBody:body withFixtureDef:fixtureDef offset:CGSizeMake(0, 0) flipY:YES forcePolygonation:YES];
}

-(void)setupTexture
{
    NSString *pointsString = [dictionary valueForKey:@"polygonPoints"];
    if (![pointsString length]){return;}
    NSString *textureString = [dictionary valueForKey:@"Texture1"];
    if (![textureString length]) {return;}
    
    [self setupTexture:textureString withPoints:[self polygonPointsFromString:pointsString offset:CGSizeMake(0, 0) flipY:YES]];
}

-(void)dealloc
{
    [self setDictionary:nil];
    [filledPolygon1 release];
    [filledPolygon2 release];
    filledPolygon2 = nil;
    filledPolygon1 = nil;
    [super dealloc];
}

@end
