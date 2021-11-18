//
//  SplashZone.m
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "SplashZone.h"
#import "Box2DHelpers.h"

@implementation SplashZone

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict
{
    if ((self = [super init]))
    {
        world = theWorld;
        [self setDictionary:dict];
        [self setGameObjectType:kSplashZoneType];
        [self setupBody];
        [self setupFixtures];
        [self setupEmitters];
    }
    return self;
}

-(void)setupEmitters
{
    [self setSplashEmitters:[NSMutableArray array]];
    NSString *emitterName = [_dictionary valueForKey:@"Splash_1"];
    int count = 1;
    while ([emitterName length])
    {
        [_splashEmitters addObject:emitterName];
        count++;
        emitterName = [_dictionary valueForKey:[NSString stringWithFormat:@"Splash_%i", count]];
    }
}

-(void)setupBody
{
    float x = [[_dictionary valueForKey:@"x"] floatValue];
    float y = [[_dictionary valueForKey:@"y"] floatValue];
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    body = world->CreateBody(&bodyDef);
    body->SetUserData(self);
    [self setPosition:ccp(x, y)];
}

-(void)setupFixtures
{
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
    float fX, fY;
    int n;
    NSString *pointsString;
    NSArray *pointsArray;
    
    b2FixtureDef groundFixtureDef;
    groundFixtureDef.filter.categoryBits = kCollideNoneCat;
    groundFixtureDef.filter.maskBits = kCollideAllMask;

    pointsString = [_dictionary valueForKey:@"polylinePoints"];
    
    if ([pointsString length])
    {
        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
        n = pointsArray.count;
        
        b2EdgeShape groundShape;
        groundFixtureDef.shape = &groundShape;
        int i;
        b2Vec2 left;
        b2Vec2 right;
        
        for(i = 0; i < n - 2; ++i)
        {
            fX = [[pointsArray objectAtIndex:i] floatValue];
            ++i;
            // flip y-position (TMX y-origin is upper-left)
            fY = - [[pointsArray objectAtIndex:i] floatValue];
            left.Set(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
            fX = [[pointsArray objectAtIndex:i+1] floatValue];
            fY = - [[pointsArray objectAtIndex:i+2] floatValue];
            right.Set(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
            groundShape.Set(left, right);
            
            body->CreateFixture(&groundFixtureDef);
        }
    }
}

-(void)dealloc
{
    [self setDictionary:nil];
    [super dealloc];
}

@end
