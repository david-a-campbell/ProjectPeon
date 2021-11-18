//
//  Bridge.m
//  rover
//
//  Created by David Campbell on 6/20/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Bridge.h"
#import "Constants.h"
#import "Box2DHelpers.h"

@implementation Bridge

-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld
{
    if ((self = [super init]))
    {
        slackPercent = 100;
        if ([dict valueForKey:@"Slack"]!=nil) {
            slackPercent = fabsf(100-[[dict valueForKey:@"Slack"] floatValue]);}
        slackPercent = slackPercent/100.0;
        x = [[dict valueForKey:@"x"] floatValue];
        y = [[dict valueForKey:@"y"] floatValue];
        height = [[dict valueForKey:@"height"] floatValue];
        width = [[dict valueForKey:@"width"] floatValue];
        world = theWorld;
        fileName = [NSString stringWithFormat:@"%@", [dict valueForKey:Texture]];
        CCSprite *plank = [CCSprite spriteWithFile:fileName];
        [plank setScale:2*SCREEN_SCALE];
        plankSize = CGSizeMake([plank boundingBox].size.width, [plank boundingBox].size.height);
        start = ccp(x+plankSize.width/2, y+height-plankSize.height/2);
        [self createBridge];
    }
    return self;
}

- (void)createBridge
{
    b2Vec2 location = b2Vec2(start.x/pixelsToMeterRatio(),start.y/pixelsToMeterRatio());
    b2Body *lastBody;
    int max = floor(width/(plankSize.width*3/4));
    for(int i = 0; i < max; i++) 
    {        
        Box2DSprite *plank = [Box2DSprite spriteWithFile:fileName]; 
        [plank setScale:2*SCREEN_SCALE];
        plank.gameObjectType = kBridgeType;
        
        b2BodyDef bodyDef;
        bodyDef.bullet = true;
        bodyDef.type = b2_dynamicBody;

        bodyDef.position = location;
        
        plank.body = world->CreateBody(&bodyDef);
        plank.body->SetUserData(plank);
        
        b2PolygonShape shape;   
        b2Vec2 boxCenter = b2Vec2(0,0);
        shape.SetAsBox(plankSize.width/2/pixelsToMeterRatio(), plankSize.height/2/pixelsToMeterRatio(), boxCenter, 0);        
        
        b2FixtureDef fixtureDef;
        fixtureDef.filter.categoryBits = kGroundCat;
        fixtureDef.filter.maskBits = kDontCollideWithGround;
        fixtureDef.shape = &shape;
        fixtureDef.friction = 1.0;
        fixtureDef.restitution = 0.3;
        
        fixtureDef.density = 150000*slackPercent;
        plank.body->CreateFixture(&fixtureDef);
        
        if (i == 0 || i == max-1)
        {
            b2Vec2 anchorLoc = location;
            if (i==max-1)
            {
                anchorLoc.x += ((plankSize.width*3/4))/pixelsToMeterRatio();
            }
            b2BodyDef fixedBodyDef;
            fixedBodyDef.type = b2_staticBody;
            fixedBodyDef.position = anchorLoc;
            b2Body *fixedBody = world->CreateBody(&fixedBodyDef);
            
            b2RevoluteJointDef jd;
            jd.Initialize(fixedBody, plank.body, fixedBody->GetWorldPoint(b2Vec2(0, 0)));
            jd.lowerAngle = CC_DEGREES_TO_RADIANS(-MAX_BRIDGE_ANGLE);
            jd.upperAngle = CC_DEGREES_TO_RADIANS(MAX_BRIDGE_ANGLE);
            jd.enableLimit = true;
            world->CreateJoint(&jd);
        }
        
        if (i > 0)
        {
            b2RevoluteJointDef jd;
            jd.Initialize(lastBody, plank.body, plank.body->GetWorldPoint(b2Vec2(0, 0)));
            jd.lowerAngle = CC_DEGREES_TO_RADIANS(-MAX_BRIDGE_ANGLE);
            jd.upperAngle = CC_DEGREES_TO_RADIANS(MAX_BRIDGE_ANGLE);
            jd.enableLimit = true;
            world->CreateJoint(&jd); 
        }
        location.x += ((plankSize.width*3/4))/pixelsToMeterRatio();
        lastBody = plank.body; 
        [self addChild:plank z:(i%2 == 0?0:1)];
    }   
}

@end
