//
//  Thingy.m
//  rover
//
//  Created by David Campbell on 5/12/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Thingy.h"
#import "Box2DHelpers.h"
#import "Constants.h"
#import "GameManager.h"
#import "SplashZone.h"
#import "EmitterManager.h"

@implementation Thingy

static int thingyZCount = -100;

-(id)initWithWorld:(b2World *)theWorld atLocation:(CGPoint)location startDynamic:(BOOL)dyn
{
    if ((self = [super init]))
    {
        startDynamic = dyn;
        world = theWorld;
        [self setPosition:location];
        [self initAnimations];
        [self createBodyAtLocation:location];
        
        spinningTimer = [[CCProgressTimer alloc] init];
        [self addChild:spinningTimer];
        whachuTimer = [[CCProgressTimer alloc] init];
        [self addChild:whachuTimer];
        
        characterHealth = 100;
        gameObjectType = kThingyBasic;
        thingyZCount++;
        finishedZooming = YES;
        
        [self changeState:kStateIdle];
        [self setRandomDirection];
        if (startDynamic) {
            [self zoomInActions];
        }
    }
    return self;
}

-(void)zoomInActions
{
    [self changeState:kStateSpinning];
    finishedZooming = NO;
    [self setScale:0.001];
    [self makeDynamic];
    body->ApplyAngularImpulse(-8000);
    CCSequence *seq = [CCSequence actions:[CCScaleTo actionWithDuration:0.7 scale:1], [CCCallFunc actionWithTarget:self selector:@selector(finishZoom)],nil];
    [self runAction:seq];
}

-(void)finishZoom
{
    body->SetGravityScale(1);
    float time = 1.0 - fabs(world->GetGravity().y)/20.0;
    if (time < 0) {time = 0;}
    [self performSelector:@selector(changeBodyMask) withObject:nil afterDelay:time];
}

-(void)changeBodyMask
{
    b2Filter filter;
    filter.groupIndex = 0;
    filter.maskBits = kCollideAllMask;
    b2Fixture *aFix = body->GetFixtureList();
    while (aFix) {
        aFix->SetFilterData(filter);
        aFix = aFix->GetNext();
    }
    finishedZooming = YES;
}

-(void)setRandomDirection
{
    int num = random()%(3);
    if (num == 0)
    {
        direction = kDirectionForward;
    }else if(num == 1)
    {
        direction = kDirectionRight;
    }else if(num == 2)
    {
        direction = kDirectionLeft;
    }
}

-(void)createBodyAtLocation:(CGPoint)location
{
    originalPosition = location;
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    //bodyDef.bullet = YES;
    bodyDef.position = b2Vec2(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    body = world->CreateBody(&bodyDef);
    body->SetUserData(self);
    
    b2FixtureDef fixtureDef;
    fixtureDef.density = 2000.0;
    fixtureDef.friction = 0.3;
    fixtureDef.restitution = 0.5;
    fixtureDef.filter.groupIndex = 0;
    fixtureDef.filter.categoryBits = kThingyCat;
    fixtureDef.filter.maskBits = kThingyGhostMask;
    
    b2Vec2 verts1[] = {
        [self configurePointX:2 Y:25],
        [self configurePointX:2 Y:62],
        [self configurePointX:31 Y:93],
        [self configurePointX:69 Y:93],
        [self configurePointX:98 Y:66],
        [self configurePointX:100 Y:30],
        [self configurePointX:76 Y:3],
        [self configurePointX:30 Y:2]
    };
    
    b2PolygonShape shape1;
    shape1.Set(verts1, 8);
    fixtureDef.shape = &shape1;
    body->CreateFixture(&fixtureDef)->SetUserData(self);
    body->SetGravityScale(fabs(1.2/world->GetGravity().y));
}

-(b2Vec2)configurePointX:(float)x Y:(float)y
{
    float xOffset = 25;
    float yOffset = 23.25;
    return b2Vec2((x/2.0f -xOffset)/pixelsToMeterRatio(), (y/2.0f -yOffset)/pixelsToMeterRatio());
}

-(void)makeDynamic
{
    body->SetType(b2_dynamicBody);
}

-(void)resetThingy
{
    characterHealth = 100;
    [self destroyThingyPhysics];
    [self createBodyAtLocation:originalPosition];
    [self setPosition:ccp(body->GetPosition().x*pixelsToMeterRatio(), body->GetPosition().y*pixelsToMeterRatio())];
    [self changeState:kStateIdle];
    [self setRandomDirection];
}

-(void)destroyThingyPhysics
{
    body->SetUserData(nil);
    world->DestroyBody(body);
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects
{
    if (characterState == kStateDead)
    {
        return;
    }
    
    b2Vec2 velocity  = body->GetLinearVelocity();
    float angularVelocity = body->GetAngularVelocity();
    
    if(isBodyCollidingWithObjectType(body, kGroundType) || isBodyCollidingWithObjectType(body, kBridgeType)  || isBodyCollidingWithObjectType(body, kBreakableGroundType))
    {
        if(characterState == kStateFalling || characterState == kStateFloating || characterState == kStateSpinning)
        {
            [self setCharacterHealth:0];
        }
    }
    
    //All states must be contained in if-else structure. States at top override states at bottom.
    if ([self characterHealth] <= 0)
    {
        [self changeState:kStateDead];
    }
    else if (fabs(angularVelocity) > 8 || [spinningTimer numberOfRunningActions])
    {
        if (![spinningTimer numberOfRunningActions])
        {
            CCProgressTo *progress = [CCProgressTo actionWithDuration:3];
            [spinningTimer runAction:progress];
            [self changeState:kStateSpinning];
        }
    }
    else if (velocity.y < -8)
    {
        [self changeState:kStateFalling];
    }
    else if (velocity.y >= 30 || fabs(velocity.x) >=30)
    {
        [self changeState:kStateFloating];
    }
    else
    {
        [self changeState:kStateIdle];
    }
}

-(void)changeState:(CharacterStates)newState
{
    if (characterState == newState || !finishedZooming)
    {
        return;
    }
    
    [self stopAllActions];
    id action = nil;
    [self setCharacterState:newState];
    [self setRandomDirection];
    
    switch (newState)
    {
        case kStateDead:
            if (direction == kDirectionRight) {
                action = [CCAnimate actionWithAnimation:_deadRightAnim];
            }else if (direction == kDirectionLeft) {
                action = [CCAnimate actionWithAnimation:_deadLeftAnim];
            }else {
                action = [CCAnimate actionWithAnimation:_deadAnim];
            }
            break;
        case kStateFloating:
            if (direction == kDirectionRight) {
                action = [CCAnimate actionWithAnimation:_floatingRightAnim];
            }else if (direction == kDirectionLeft) {
                action = [CCAnimate actionWithAnimation:_floatingLeftAnim];
            }else {
                action = [CCAnimate actionWithAnimation:_floatingAnim];
            }
            [self playWhachuuAfterRandomDelay];
            break;
        case kStateIdle:
            if (direction == kDirectionRight) {
                action = [CCAnimate actionWithAnimation:_idleRightAnim];
            }else if (direction == kDirectionLeft) {
                action = [CCAnimate actionWithAnimation:_idleLeftAnim];
            }else {
                action = [CCAnimate actionWithAnimation:_idleAnim];
            }
            break;
        case kStateFalling:
            if (direction == kDirectionRight) {
                action = [CCAnimate actionWithAnimation:_fallingRightAnim];
            }else if (direction == kDirectionLeft) {
                action = [CCAnimate actionWithAnimation:_fallingLeftAnim];
            }else {
                action = [CCAnimate actionWithAnimation:_fallingAnim];
            }
            break;
        case kStateSpinning:
            if (direction == kDirectionRight){
                action = [CCAnimate actionWithAnimation:_spinRightAnim];
            }else if (direction == kDirectionLeft){
                action = [CCAnimate actionWithAnimation:_spinLeftAnim];
            }else{
                action = [CCAnimate actionWithAnimation:_spinAnim];
            }
            [self playSoundEffect:@"peon_dizzy.mp3" withProbability:0.5];
            break;
        default:
            break;
    }
    if (action != nil)
    {
        [self runAction:action];
    }
    if (characterState != kStateDead)
    {
        [self runAction:[self aliveAction]];
    }
}

-(void)playWhachuuAfterRandomDelay
{
    if (![whachuTimer numberOfRunningActions])
    {
        float random = arc4random_uniform(50);
        float delay = random/100.0f;
        CCSequence *seq = [CCSequence actions:[CCDelayTime actionWithDuration:delay], [CCCallFunc actionWithTarget:self selector:@selector(playWhachuu)], nil];
        [self runAction:seq];
    }
}

-(void)playWhachuu
{
    if (![whachuTimer numberOfRunningActions])
    {
        [self playSoundEffect:@"whachuuuu.mp3" withProbability:0.5];
        CCProgressTo *progress = [CCProgressTo actionWithDuration:4];
        [whachuTimer runAction:progress];
    }
}

-(void)initAnimations
{
    [self setSpinAnim:[self loadPlistForAnimationWithName:@"spinAnim" andClassName:NSStringFromClass([self class])]];
    [self setSpinLeftAnim:[self loadPlistForAnimationWithName:@"spinLeftAnim" andClassName:NSStringFromClass([self class])]];
    [self setSpinRightAnim:[self loadPlistForAnimationWithName:@"spinRightAnim" andClassName:NSStringFromClass([self class])]];
    
    [self setDeadAnim:[self loadPlistForAnimationWithName:@"deadAnim" andClassName:NSStringFromClass([self class])]];
    [self setDeadLeftAnim:[self loadPlistForAnimationWithName:@"deadLeftAnim" andClassName:NSStringFromClass([self class])]];
    [self setDeadRightAnim:[self loadPlistForAnimationWithName:@"deadRightAnim" andClassName:NSStringFromClass([self class])]];
    
    [self setFallingAnim:[self loadPlistForAnimationWithName:@"fallingAnim" andClassName:NSStringFromClass([self class])]];
    [self setFallingLeftAnim:[self loadPlistForAnimationWithName:@"fallingLeftAnim" andClassName:NSStringFromClass([self class])]];
    [self setFallingRightAnim:[self loadPlistForAnimationWithName:@"fallingRightAnim" andClassName:NSStringFromClass([self class])]];
    
    [self setFloatingAnim:[self loadPlistForAnimationWithName:@"floatingAnim" andClassName:NSStringFromClass([self class])]];
    [self setFloatingLeftAnim:[self loadPlistForAnimationWithName:@"floatingLeftAnim" andClassName:NSStringFromClass([self class])]];
    [self setFloatingRightAnim:[self loadPlistForAnimationWithName:@"floatingRightAnim" andClassName:NSStringFromClass([self class])]];
    
    [self setIdleAnim:[self loadPlistForAnimationWithName:@"idleAnim" andClassName:NSStringFromClass([self class])]];
    [self setIdleLeftAnim:[self loadPlistForAnimationWithName:@"idleLeftAnim" andClassName:NSStringFromClass([self class])]];
    [self setIdleRightAnim:[self loadPlistForAnimationWithName:@"idleRightAnim" andClassName:NSStringFromClass([self class])]];
}

-(int)getThingyZCount
{
    return thingyZCount;
}

-(void)dissableSfx
{
    [self setCanPlaySound:NO];
}

-(CCRepeatForever*)aliveAction
{
    CCScaleTo *scale1 = [CCScaleTo actionWithDuration:1.0f scaleX:1.10 scaleY:1.0f];
    CCScaleTo *scale2 = [CCScaleTo actionWithDuration:0.5f scaleX:1.0f scaleY:1.15];
    id sequence = [CCSequence actions:scale1, scale2,nil];
    CCRepeatForever *aliveAction = [CCRepeatForever actionWithAction:sequence];
    return aliveAction;
}

- (void)dealloc
{
    [self setDeadAnim:nil];
    [self setFallingAnim:nil];
    [self setFloatingAnim:nil];
    [self setIdleAnim:nil];
    [self setDeadLeftAnim:nil];
    [self setDeadRightAnim:nil];
    [self setFallingLeftAnim:nil];
    [self setFallingRightAnim:nil];
    [self setFloatingAnim:nil];
    [self setFloatingLeftAnim:nil];
    [self setIdleLeftAnim:nil];
    [self setIdleRightAnim:nil];
    [self setSpinAnim:nil];
    [self setSpinLeftAnim:nil];
    [self setSpinRightAnim:nil];
    [whachuTimer release];
    whachuTimer = nil;
    [spinningTimer release];
    spinningTimer = nil;
    thingyZCount--;
    [super dealloc];
}


@end
