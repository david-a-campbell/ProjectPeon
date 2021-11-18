//
//  Ground.m
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Ground.h"
#import "Box2DHelpers.h"
#import "PRFilledPolygon.h"
#import "UIImage+Extras.h"
#import "PRRatcliffTriangulator.h"

@implementation Ground
@synthesize dictionary, filledPolygon1, filledPolygon2;

-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict isSolid:(BOOL)solid
{
    if ((self = [super init]))
    {
        isSolid = solid;
        world = theWorld;
        [self setDictionary:dict];
        [self setGameObjectType:kGroundType];
        [self setupBody];
        [self setupTriangulatedFixtures];
        [self setupTexture];
        [self setupDust];
    }
    return self;
}

-(float)density
{
    return 100000.0;
}

-(void)setupBody
{
    float x = [[dictionary valueForKey:@"x"] floatValue];
    float y = [[dictionary valueForKey:@"y"] floatValue];
    b2BodyDef groundBodyDef;
    if (!isSolid || [[dictionary valueForKey:@"polylinePoints"] length])
    {
        groundBodyDef.bullet = YES;
    }
    groundBodyDef.type = b2_staticBody;
    groundBodyDef.position.Set(x/pixelsToMeterRatio(), y/pixelsToMeterRatio());
    body = world->CreateBody(&groundBodyDef);
    body->SetUserData(self);
    [self setPosition:ccp(x, y)];
}

-(void)setupTriangulatedFixtures
{
    triangulator = [[[PRRatcliffTriangulator alloc] init] autorelease];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
    float fX, fY;
    int n;
    NSString *pointsString;
    NSArray *pointsArray;
    
    b2FixtureDef groundFixtureDef;
    groundFixtureDef.filter.categoryBits = kGroundCat;
    groundFixtureDef.density = [self density];
    groundFixtureDef.friction = 1;
    groundFixtureDef.restitution = 0.2;
    
    pointsString = [dictionary valueForKey:@"polygonPoints"];
    
    if (isSolid)
    {
        if ([pointsString length])
        {
            [self polygonatePoints:pointsString ontoBody:body withFixtureDef:groundFixtureDef offset:CGSizeMake(0, 0) flipY:YES forcePolygonation:YES];
        }
        return;
    }

    BOOL isPolygon = YES;
    if (![pointsString length])
    {
        isPolygon = NO;
        pointsString = [dictionary valueForKey:@"polylinePoints"];
    }
    
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
            
            if (isPolygon && i==n-3)
            {
                left = right;
                fX = [[pointsArray objectAtIndex:0] floatValue];
                fY = [[pointsArray objectAtIndex:1] floatValue];
                right.Set(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
                groundShape.Set(left, right);
                
                body->CreateFixture(&groundFixtureDef);
            }
        }
    }
}

-(void)setupDust
{
    [self setDustEmitters:[NSMutableArray array]];
    NSString *dustName = [dictionary valueForKey:@"Dust_1"];
    int count = 1;
    while ([dustName length])
    {
        [_dustEmitters addObject:dustName];
        count++;
        dustName = [dictionary valueForKey:[NSString stringWithFormat:@"Dust_%i", count]];
    }
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
    [_dustEmitters release];
    _dustEmitters = nil;
    filledPolygon2 = nil;
    filledPolygon1 = nil;
    [super dealloc];
}

@end








//
//-(void)setupFixture
//{
//    // TMX polygon points delimiters (Box2d points must have counter-clockwise winding)
//    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
//    float fX, fY;
//    int n;
//    int i, k;
//    NSString *pointsString;
//    NSArray *pointsArray;
//
//    pointsString = [dictionary valueForKey:@"polygonPoints"];
//    if (pointsString != NULL)
//    {
//        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
//        n = pointsArray.count;
//        b2ChainShape shape;
//        int size = n/2;
//        b2Vec2 *vertArray = new b2Vec2[size];
//        // build polygon verticies;
//        for (i = 0, k = 0; i < n; ++k)
//        {
//            fX = [[pointsArray objectAtIndex:i] floatValue];
//            ++i;
//            // flip y-position (TMX y-origin is upper-left)
//            fY = - [[pointsArray objectAtIndex:i] floatValue];
//            ++i;
//            vertArray[k] = b2Vec2(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
//        }
//        shape.CreateLoop(vertArray, size);
//        delete[] vertArray;
//        vertArray = NULL;
//
//        b2FixtureDef fixtureDef;
//        fixtureDef.shape = &shape;
//        fixtureDef.friction = 1.0;
//        fixtureDef.restitution = 0.2;
//        fixtureDef.density = 1000000.0;
//
//        body->CreateFixture(&fixtureDef);
//    }
//
//    pointsString = [dictionary valueForKey:@"polylinePoints"];
//    if (pointsString != NULL)
//    {
//        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
//        n = pointsArray.count;
//
//        b2EdgeShape groundShape;
//        b2FixtureDef groundFixtureDef;
//        groundFixtureDef.shape = &groundShape;
//        groundFixtureDef.density = 1000000.0;
//        groundFixtureDef.friction = 1.0;
//        groundFixtureDef.restitution = 0.2;
//        int i;
//        b2Vec2 left;
//        b2Vec2 right;
//
//        for(i = 0; i < n - 2; ++i)
//        {
//            fX = [[pointsArray objectAtIndex:i] floatValue];
//            ++i;
//            // flip y-position (TMX y-origin is upper-left)
//            fY = - [[pointsArray objectAtIndex:i] floatValue];
//            left.Set(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
//            fX = [[pointsArray objectAtIndex:i+1] floatValue];
//            fY = - [[pointsArray objectAtIndex:i+2] floatValue];
//            right.Set(fX/pixelsToMeterRatio(), fY/pixelsToMeterRatio());
//            groundShape.Set(left, right);
//
//            body->CreateFixture(&groundFixtureDef);
//        }
//    }
//}
