//
//  PlayerCart.m
//  rover
//
//  Created by David Campbell on 3/9/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "PlayerCart.h"
#import "Box2DHelpers.h"
#import "CartPart.h"
#import "SimpleQueryCallback.h"
#import "DeletePartQueryCallback.h"
#import "Bar.h"
#import "ShockAbsorber.h"
#import "Wheel.h"
#import "DeleteAble.h"
#import "SaveManager.h"

#define FUEL 350.0f
#define FUEL_UPGRADE 525.0f

@interface PlayerCart (Private)
-(void)createBodyAtLocation:(CGPoint)location;
@end

@implementation PlayerCart
@synthesize components;

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setComponents:nil];
    [shockDelete release];
    shockDelete = nil;
    fuelRegenTimer = nil;
    [super dealloc];
}

- (id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location 
{
    if ((self = [super init])) 
    {
        [self setFuelMax];
        world = theWorld;
        gameObjectType = kPlayerCartType;
        characterHealth = 100.0f;
        components = [[NSMutableArray alloc] init];
        shockDelete = [[NSMutableArray alloc] init];
        [self createBodyAtLocation:location];
        [self setupFuelTimer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemPurchased:) name:NOTIFICATION_PURCHASED_ITEM object:nil];
    }
    return self;
}

-(void)setPosition:(CGPoint)position
{
    [super setPosition:ccp(position.x+positionOffset.x, position.y+positionOffset.y)];
}

- (void)createBodyAtLocation:(CGPoint)location 
{
    b2BodyDef bd;
    bd.type = b2_staticBody;
    bd.position = b2Vec2(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    body = world->CreateBody(&bd);
    body->SetUserData(self);
    originalPosition = location;
}

-(void)itemPurchased:(NSNotification*)notification
{
    NSDictionary* userInfo = [notification userInfo];
    NSString *pID= [userInfo objectForKey:@"ProductID"];
    if ([pID isEqualToString:PRODUCT_BOOST_50])
    {
        fuelLimit = FUEL_UPGRADE;
    }
}

-(void)setFuelMax
{
    if ([[SaveManager sharedManager] hasBooster50Unlocked])
    {
        fuelLimit = FUEL_UPGRADE;
    }else
    {
        fuelLimit = FUEL;
    }
}

-(void)setupFuelTimer
{
    fuelRegenTimer = [[CCProgressTimer alloc] init];
    [self addChild:fuelRegenTimer];
    [fuelRegenTimer release];
}

-(void)drainFuelAmount:(int)fuelAmount
{
    if (_fuel > 0)
    {
        _fuel -= fuelAmount;
    }
    
    if (_fuel <= 0)
    {
        CCProgressTo *progress = [CCProgressTo actionWithDuration:1.5];
        [fuelRegenTimer runAction:progress];
    }
}

-(void)regainFuel
{
    if (_fuel < [self maxFuel])
    {
        _fuel += 1;
    }
}

-(BOOL)hasFuel
{
    return _fuel > 0 && [fuelRegenTimer numberOfRunningActions] == 0;
}

-(float)maxFuel
{
    return fuelLimit;
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    [self regainFuel];
}

-(void)moveBodyToCart
{
    if ([components count])
    {
        CartPart *rightMostPart = [components objectAtIndex:0];
        for (CartPart* part in components)
        {
            if ((part.gameObjectType != kShockPartType))
            {
                rightMostPart = part;
            }
        }
        
        for (CartPart* part in components)
        {
            if ((part.start.x > rightMostPart.start.x || part.end.x > rightMostPart.end.x)&& (part.gameObjectType != kShockPartType))
            {
                rightMostPart = part;
            }
        }
        positionOffset = ccp(rightMostPart.positionOffset.x*pixelsToMeterRatio(), rightMostPart.positionOffset.y*pixelsToMeterRatio());
        body->SetUserData(nil);
        world->DestroyBody(body);
        body = rightMostPart.body;
        [self setPosition:ccp(body->GetPosition().x*pixelsToMeterRatio(), body->GetPosition().y*pixelsToMeterRatio())];
    } 
}

-(CGPoint)averagePosition
{
    CGPoint point = ccp(0, 0);
    float sumOfFactors = 0;
    
    for (CartPart *part in [self components])
    {
        float distance = ccpDistance([self position], part.position);
        if (distance > 1024){continue;}
        float factor = (1024-distance)/1024;
    
        point = ccp(point.x+(part.position.x*factor), point.y+(part.position.y*factor));
        sumOfFactors+=factor;
    }
    point = ccp(point.x/sumOfFactors, point.y/sumOfFactors);
    return point;
}

-(void)createCartPhysics
{
    b2Body* worldBodies = world->GetBodyList();
    while (worldBodies)
    {
        GameObject* object = (GameObject*)worldBodies->GetUserData();
        
        if (object.gameObjectType == kPlayerCartType)
        {
            worldBodies->SetType(b2_dynamicBody);
        }
        worldBodies = worldBodies->GetNext();
    }
}

-(void)startCartGameplay
{
    _fuel = [self maxFuel];
    [self createCartPhysics];
    [self removeSwivelIndicators];
}

-(void)removeSwivelIndicators
{
    for (CartPart *part in components)
    {
        if ([[part class] isSubclassOfClass:[Wheel class]]) {
            Wheel* aWheel = (Wheel*)part;
            [aWheel hidePivotIndicator];
        }
    }
}

-(void)addSwivelIndicators
{
    for (CartPart *part in components)
    {
        if ([[part class] isSubclassOfClass:[Wheel class]]) {
            Wheel* aWheel = (Wheel*)part;
            [aWheel showPivotIndicator];
        }
    }
}

-(void)resetCartBody
{
    [self createBodyAtLocation:originalPosition];
    [self setPosition:ccp(body->GetPosition().x*pixelsToMeterRatio(), body->GetPosition().y*pixelsToMeterRatio())];
    [self destroyCartPhysics];
    for (CartPart *part in components) 
    {
        if (!part.isReadyForRemoval)
        {
            [part resetPart];
        }
    }
}

-(void)removeNonGameplayFixtures
{
    for (CartPart *part in [self components])
    {
        if (!part.isReadyForRemoval && ![[part class] isSubclassOfClass:[Wheel class]])
        {
            [part destroyExtraFixtures];
        }
    }
}

-(void)destroyCartPhysics
{
    b2Body* worldBodies = world->GetBodyList();
    while (worldBodies)
    {
        if (worldBodies == body)
        {
            worldBodies = worldBodies->GetNext();
            continue;
        }
        GameObject* object = (GameObject*)worldBodies->GetUserData();
        if (object.gameObjectType == kPlayerCartType)
        {
            worldBodies->SetUserData(nil);
            world->DestroyBody(worldBodies);
        }
        worldBodies = worldBodies->GetNext();
    }
}

-(float)fullMass
{
    float fullMass = 0;
    for (CartPart *part in components)
    {
        fullMass+= part.body->GetMass();
    }
    return fullMass;
}

-(CartPart*)deletePartAtLocation:(CGPoint)location outputShocks:(NSMutableArray*)outShocks
{
    b2Vec2 thePoint(location.x / pixelsToMeterRatio(), location.y / pixelsToMeterRatio());
    DeletePartQueryCallback callback(thePoint, nil);
    b2AABB aabb;
    b2Vec2 delta = b2Vec2(10, 10);
    aabb.lowerBound = thePoint - delta;
    aabb.upperBound = thePoint + delta;
    world->QueryAABB(&callback, aabb);
    b2Fixture *foundFixture = callback.fixtureFound;
    CartPart *returnPart = nil;
    
    if (foundFixture != nil)
    {
        CartPart* part = (CartPart*)foundFixture->GetUserData();
        returnPart = [[[CartPart alloc] initWithStart:[part start] andEnd:[part end] andCart:nil] autorelease];
        [returnPart setGameObjectType:[part gameObjectType]];

        [self deleteCartPart:part];
        
        for (ShockAbsorber *shock in shockDelete)
        {
            CartPart* tempShock = [[CartPart alloc] initWithStart:[shock start] andEnd:[shock end] andCart:nil];
            [tempShock setGameObjectType:[shock gameObjectType]];
            [outShocks addObject:tempShock];
            [tempShock release];
        }
        
        [components removeObject:part];
        [components removeObjectsInArray:shockDelete];
        [shockDelete removeAllObjects];
        [self resetCartBody];
        [self addSwivelIndicators];
    }
    return returnPart;
}

-(void)highlightCartPartAt:(CGPoint)highlightPoint 
{
    b2Vec2 thePoint(highlightPoint.x / pixelsToMeterRatio(), highlightPoint.y / pixelsToMeterRatio());
    DeletePartQueryCallback callback(thePoint, nil);
    b2AABB aabb;
    b2Vec2 delta = b2Vec2(10, 10);
    aabb.lowerBound = thePoint - delta;
    aabb.upperBound = thePoint + delta;
    world->QueryAABB(&callback, aabb);
    b2Fixture *foundFixture = callback.fixtureFound;
    
    if (foundFixture != nil)
    {
        CartPart* part = (CartPart*)foundFixture->GetUserData();
        if (part != highlightedPart)
        {
            [self unhighlightPart];
        }
        [part highlightMe];
        highlightedPart = part;
    }else {
        [self unhighlightPart];
    }
}

-(void)deleteHighlightedPart
{
    [self deleteCartPart:highlightedPart];
    [components removeObject:highlightedPart];
    [components removeObjectsInArray:shockDelete];
    [shockDelete removeAllObjects];
    highlightedPart = nil;
    [self resetCartBody];
    [self addSwivelIndicators];
}

-(void)unhighlightPart
{
    if (highlightedPart != nil)
    {
        [highlightedPart unHighlightMe];
        highlightedPart = nil;
    }    
}

-(void)highlightAllParts
{
    for (CartPart *part in components)
    {
        [part highlightMe];
    }
}

-(void)unhighlightAllParts
{
    for (CartPart *part in components)
    {
        [part unHighlightMe];
    }
}

-(void)deleteCartPart:(CartPart*)partToDelete
{
    if (partToDelete != nil)
    {
        [partToDelete destroyExtraFixtures];
        
        switch (partToDelete.gameObjectType)
        {
            case kMotorPartType:
            case kMotor50PartType:
            case kWheelPartType:
            case kBarPartType:
            case kBoosterPartType:
            case kBooster50PartType:
            {
                b2Fixture *fixture = partToDelete.fixture;
                [self deleteConnectedShocks:fixture];
                b2Body *tempBody = fixture->GetBody();
                fixture->SetUserData(nil);
                tempBody->DestroyFixture(fixture);
                if (!doesBodyHaveFixtures(tempBody))
                {
                    tempBody->SetUserData(nil);
                    world->DestroyBody(tempBody);
                }
                [partToDelete setIsReadyForRemoval:YES];
                [partToDelete removeFromParentAndCleanup:YES];
            }break;
            case kShockPartType:
            {
                ShockAbsorber *shock = (ShockAbsorber*)partToDelete;
                [shock setIsReadyForRemoval:YES];
                shock.joint->SetUserData(nil);
                shock.body->SetUserData(nil);
                world->DestroyJoint(shock.joint);
                world->DestroyBody(shock.body);
                [shock removeFromParentAndCleanup:YES];
            }break;
            default:
                break;
        }
    }
    partToDelete = nil;
}

-(void)deleteConnectedShocks:(b2Fixture*)fixture
{
    for (CartPart* part in components)
    {
        if (part.gameObjectType == kShockPartType)
        {
            ShockAbsorber *shock = (ShockAbsorber*)part;
            if (shock.fixture1 == fixture || shock.fixture2 == fixture)
            {
                if (shock.fixture1 == fixture)
                {
                    //Swap points for use in edit mode
                    [shock swapPoints];
                }
                [shockDelete addObject:part];
                [shock setIsReadyForRemoval:YES];
                shock.joint->SetUserData(nil);
                shock.body->SetUserData(nil);
                world->DestroyJoint(shock.joint);
                world->DestroyBody(shock.body);
                [shock removeFromParentAndCleanup:YES];
            }
        }
    }
}


-(void)deleteAllCartParts
{
    for (CartPart *part in components)
    {
        if (![[part class] isSubclassOfClass:[ShockAbsorber class]]) 
        {
            [self deleteCartPart:part];
        }
    }
    [shockDelete removeAllObjects];
    [components removeAllObjects];
}

-(double)pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    double bearingRadians = atan2(originPoint.y, originPoint.x); // get bearing in radians
    double bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

-(void)dissapear
{
    for (CartPart* part in components)
    {
        [part dissapear];
    }
}

-(void)reappear
{
    for (CartPart* part in components)
    {
        [part reappear];
    }    
}

-(void)applybreakableJoints
{
    for (CartPart *part in components)
    {
        if ([part gameObjectType] != kShockPartType) {
            b2JointEdge *aJoint = part.body->GetJointList();
            while (aJoint) {
                CartPart *jointPart = (CartPart*)aJoint->joint->GetUserData();
                if ([jointPart gameObjectType] == kShockPartType) {
                    aJoint = aJoint->next;
                    continue;
                }

                b2Vec2 reaction = aJoint->joint->GetReactionForce(1.0f/60.0f);
                float reactionTorque = aJoint->joint->GetReactionTorque(1.0f/60.0f);
                if (fabs(reaction.x) > 10000*5 || fabs(reaction.y) > 10000*5 || fabs(reactionTorque) > 10000*10) {
                    aJoint->joint->SetUserData(nil);
                    world->DestroyJoint(aJoint->joint);
                }
                
                aJoint = aJoint->next;
            }
        }
    }
}

-(NSArray*)componentsInOrderOfZ
{
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"zOrder" ascending:YES] autorelease];
    return [[self components] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

-(int)partCount
{
    int count = 0;
    for (CartPart *part in [self components])
    {
        if (![part isReadyForRemoval] && part.gameObjectType != kShockPartType)
        {
            count++;
        }
    }
    return count;
}

-(BOOL)body:(b2Body *)aBody isWithinRadius:(float)radius
{
    float rad = radius/pixelsToMeterRatio();
    float distance = b2Distance(body->GetPosition(), aBody->GetPosition());
    return distance <= rad;
}

@end
