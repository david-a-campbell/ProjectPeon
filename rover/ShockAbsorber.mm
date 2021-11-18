//
//  shockAbsorber.m
//  rover
//
//  Created by David Campbell on 3/13/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "ShockAbsorber.h"
#import "PlayerCart.h"
#import "Box2DHelpers.h"
#import "ShockQueryCallback.h"
#import "PlayerCart.h"
#import "Bar.h"

@implementation ShockAbsorber
@synthesize joint, fixture1, fixture2, setupSuccessful;

- (id)initWithStart:(CGPoint)touchStartLocation andEnd: (CGPoint)touchEndLocation andCart:(PlayerCart *)theCart
{
    if ((self = [super initWithStart:touchStartLocation andEnd:touchEndLocation andCart:theCart])) 
    {
        gameObjectType = kShockPartType;
        [self setupJoint];
        if (setupSuccessful)
        {
            [self createSensorBody];
            [self setupImage];
        }
    }
    return self;
}

-(void)setupImage
{
    ShockBar = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksBar.png"]];
    Bolt1 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksEnd.png"]];
    Bolt2 = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksEnd.png"]];
    ShockPiston = [[CCSprite alloc] initWithSpriteFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"shocksPiston.png"]];
    
    [ShockBar setScaleY:1];
    [Bolt1 setScale:1];
    [Bolt2 setScale:1];
    [ShockPiston setScaleY:1];
    
    BoltOriginalHeight = [Bolt1 boundingBox].size.height;
    ShockBarOriginalLength = [ShockBar boundingBox].size.width;
    
    float barLength = ccpDistance(start, end);
    [ShockPiston setScaleX:barLength/ShockBarOriginalLength];
    
    [Bolt2 setFlipX:YES];
    
    [Bolt1 setPosition:ccp([Bolt1 boundingBox].size.width/2,0)];

    [self addChild:ShockBar];
    [self addChild:ShockPiston];
    [self addChild:Bolt1];
    [self addChild:Bolt2];
}

-(void)setPositionWithPoint:(CGPoint)posA andPoint:(CGPoint)posB
{
    float length = ccpDistance(posA, posB);
    float barLength = length;
    if (barLength < 0){barLength = 0;}
    
    float rotation = -[self pointPairToBearingDegrees:posA secondPoint:posB];
    CGPoint center = ccpMidpoint(posA, posB);
    
    [ShockBar setScaleX:barLength/ShockBarOriginalLength];
    [ShockBar setPosition:ccp(0,0)];
    [ShockPiston setPosition:ccp(0,0)];
    [Bolt1 setPosition:ccp(-length/2,0)];
    [Bolt2 setPosition:ccp(length/2,0)];
    
    [self setRotation:rotation];
    [self setPosition:center];
}

-(void)setupJoint
{
    setupSuccessful = NO;
    b2Vec2 b2Start(start.x/pixelsToMeterRatio(), start.y/pixelsToMeterRatio());
    b2Vec2 b2End(end.x/pixelsToMeterRatio(), end.y/pixelsToMeterRatio());
    b2AABB aabb;
    b2Vec2 delta = b2Vec2(1, 1);
    aabb.lowerBound = b2Start - delta;
    aabb.upperBound = b2Start + delta;
    ShockQueryCallback callback(b2Start, nil);
    world->QueryAABB(&callback, aabb);
    fixture1 = callback.bestFixture();
    if (fixture1 != nil) 
    {
        aabb.lowerBound = b2End - delta;
        aabb.upperBound = b2End +delta;
        ShockQueryCallback callback2(b2End, fixture1);
        world->QueryAABB(&callback2, aabb);
        fixture2 = callback2.bestFixture();
        if (fixture2 != nil)
        {
            if (fixture1->GetBody() == fixture2->GetBody()) 
                return;
            
            CartPart* part1 = (CartPart*)fixture1->GetUserData();
            CartPart* part2 = (CartPart*)fixture2->GetUserData();
            
            adjPivot1 = b2Start;
            adjPivot2 = b2End;
            
            if (part1.gameObjectType == kWheelPartType || part1.gameObjectType == kMotorPartType || part1.gameObjectType == kMotor50PartType)
            {
                adjPivot1 = [self AdjustPivot:adjPivot1 ForCenter:fixture1->GetBody()->GetWorldCenter()];
            }
            if (part2.gameObjectType == kWheelPartType || part2.gameObjectType == kMotorPartType || part2.gameObjectType == kMotor50PartType)
            {
                adjPivot2 = [self AdjustPivot:adjPivot2 ForCenter:fixture2->GetBody()->GetWorldCenter()];
            }
            if (part1.gameObjectType == kBarPartType)
            {
                if (!fixture1->TestPoint(adjPivot1))
                {
                    adjPivot1 = [self adjustPoint:adjPivot1 ForBar:(Bar*)part1];
                }
            }
            if (part2.gameObjectType == kBarPartType)
            {
                if (!fixture2->TestPoint(adjPivot2))
                {
                    adjPivot2 = [self adjustPoint:adjPivot2 ForBar:(Bar*)part2];
                }
            }
            
            b2DistanceJointDef jointDef = [self getJointDef];
            jointDef.Initialize(fixture1->GetBody(), fixture2->GetBody(), adjPivot1, adjPivot2);
            start = ccp(adjPivot1.x*pixelsToMeterRatio(), adjPivot1.y*pixelsToMeterRatio());
            end = ccp(adjPivot2.x*pixelsToMeterRatio(), adjPivot2.y*pixelsToMeterRatio());
            
            joint = world->CreateJoint(&jointDef);
            joint->SetUserData(self);
            setupSuccessful = YES;
            
            if (part1.isInForeground || part2.isInForeground)
            {
                [self setIsInForeground:YES];
            }
        }
    }
}

-(b2DistanceJointDef)getJointDef
{
    b2DistanceJointDef jointDef;
    //Slack - smaller numbers increase slack - 3.0
    jointDef.frequencyHz = 2.7f;
    //Bounce - smaller numbers reduce bounce - 0.01
    jointDef.dampingRatio = 0.002f;
    jointDef.collideConnected = YES;
    return jointDef;
}

-(b2Vec2)adjustPoint:(b2Vec2)p ForBar:(Bar*)bar
{
    CGPoint point = ccp(p.x*pixelsToMeterRatio(), p.y*pixelsToMeterRatio());
    CGPoint otherEnd = ccpRotateByAngle([bar end], [bar start], CC_DEGREES_TO_RADIANS(-180));
    CGPoint pivot;
    float distanceToA = ccpDistance([bar end], point);
    float distanceToB = ccpDistance(otherEnd, point);
    
    if (distanceToA < distanceToB)
    {
        pivot = otherEnd;
    }else
    {
        pivot = [bar end];
    }
    
    float angle1 = [self pointPairToBearingDegrees:pivot secondPoint:point];
    float angle2 = [self pointPairToBearingDegrees:pivot secondPoint:[bar start]];
    
    float angleFinal = fabs(angle1-angle2) > 90 ? 360-fabs(angle1-angle2):fabs(angle1-angle2);
    angleFinal = 2.0f*angleFinal;
    
    CGPoint otherSide = ccpRotateByAngle(point, pivot, CC_DEGREES_TO_RADIANS(angleFinal));
    CGPoint adjustedPoint = ccpIntersectPoint([bar end], otherEnd, point, otherSide);
    return b2Vec2(adjustedPoint.x/pixelsToMeterRatio(), adjustedPoint.y/pixelsToMeterRatio());
}

-(b2Vec2)AdjustPivot:(b2Vec2)pivot ForCenter:(b2Vec2)center
{
    CGPoint piv = ccp(pivot.x, pivot.y);
    CGPoint cen = ccp(center.x, center.y);
    
    if (ccpDistance(piv, cen)<=(MIN_WHEEL_LENGTH/1.5)/pixelsToMeterRatio())
    {
        return center;
    }else {
        return pivot;
    }
}

-(void)createSensorBody
{
    b2FixtureDef fixtureDef;
    fixtureDef.filter.maskBits = kCollideWithNone;
    fixtureDef.isSensor = true;
    b2PolygonShape shape;
    float mainAngle = [self pointPairToBearingDegrees:start secondPoint:end]; 
    float distance = ccpDistance(start, end);
    shape.SetAsBox((18/2.0)/pixelsToMeterRatio(), (distance/2.0)/pixelsToMeterRatio(), b2Vec2(0,0), CC_DEGREES_TO_RADIANS(mainAngle + 90));
    fixtureDef.shape = &shape;
    b2BodyDef bodyDef;
    CGPoint mid = ccpMidpoint(start, end);
    bodyDef.position = b2Vec2(mid.x/pixelsToMeterRatio(), mid.y/pixelsToMeterRatio());
    bodyDef.type = b2_staticBody;
    body = world->CreateBody(&bodyDef);

    fixture = body->CreateFixture(&fixtureDef);
    fixture->SetUserData(self);
}

-(BOOL)moveJointFrom:(b2Fixture *)oldFix to:(b2Fixture *)newFix
{
    if (oldFix == fixture1)
    {
        fixture1 = newFix;
    }else
    {
        fixture2 = newFix;
    }
    
    if (fixture1->GetBody() == fixture2->GetBody())
    {
        return NO;
    }
    
    //Dont destroy joint here - will happen when old fix is removed
    //world->DestroyJoint(joint);
    joint->SetUserData(NULL);
    
    b2DistanceJointDef jointDef = [self getJointDef];
    jointDef.Initialize(fixture1->GetBody(), fixture2->GetBody(), adjPivot1, adjPivot2);
    joint = world->CreateJoint(&jointDef);
    joint->SetUserData(self);
    return YES;
}

-(void)highlightMe
{
    [super highlightMe];
    [ShockBar setColor:highlightedColor];
    [Bolt1 setColor:highlightedColor];
    [Bolt2 setColor:highlightedColor];
    [ShockPiston setColor:highlightedColor];
}

-(void)unHighlightMe
{
    [super unHighlightMe];
    [ShockBar setColor:originalColor];
    [Bolt1 setColor:originalColor];
    [Bolt2 setColor:originalColor];
    [ShockPiston setColor:originalColor];
}

-(void)dealloc
{
    world = nil;
    cart = nil;
    joint = nil;
    fixture1 = nil;
    fixture2 = nil;
    [ShockBar release];
    ShockBar = nil;
    [Bolt1 release];
    Bolt1 = nil;
    [Bolt2 release];
    Bolt2 = nil;
    [ShockPiston release];
    ShockPiston = nil;
    [super dealloc];
}

-(void)swapPoints
{
    CGPoint tempStart = start;
    [self setStart:end];
    [self setEnd:tempStart];
}

-(void)resetPart;
{
    [self setupJoint];
    //This is a special case where deleting another shock will cause the sensor to be doubled
    [self destroyExtraFixtures];
    [self createSensorBody];
}

-(void)destroyExtraFixtures
{
    if (fixture)
    {
        fixture->SetUserData(nil);
        body->DestroyFixture(fixture);
        fixture = nil;
    }
}

-(void)removeFromParentAndCleanup:(BOOL)cleanup
{
    fixture1 = nil;
    fixture2 = nil;
    joint = nil;
    [super removeFromParentAndCleanup:cleanup];
}

@end
