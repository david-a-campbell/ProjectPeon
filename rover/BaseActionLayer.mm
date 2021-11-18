//
//  BaseActionLayer.m
//  rover
//
//  Created by David Campbell on 3/3/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "BaseActionLayer.h"
#import "Box2DSprite.h"
#import "SimpleQueryCallback.h"
#import "Box2DHelpers.h"
#import "GameManager.h"
#import "PlayerCart.h"
#import "Bar.h"
#import "Wheel.h"
#import "Motor.h"
#import "ShockAbsorber.h"
#import "Booster.h"
#import "Thingy.h"
#import "Wormhole.h"
#import "Pod.h"
#import "SaveManager.h"
#import "Elevator.h"
#import "UIImage+Extras.h"
#import "DeleteAble.h"
#import "Rock.h"
#import "Ground.h"
#import "BreakableGround.h"
#import "SpriteTrigger.h"
#import "ForceArea.h"
#import "CompositeSprite.h"
#import "PunkParallax.h"

@implementation BaseActionLayer
@synthesize playerCart;

- (id)initWithTileMapName:(NSString *)tileMap
{
    if ((self = [super initWithTileMapName:tileMap]))
    {
        tileMapName = tileMap;
        [[SaveManager sharedManager] setCreationDelegate:self];
        accelerationArray = [[CCArray alloc] init];
        parallaxHolderArray = [[CCArray alloc] init];
        touchArray = [[CCArray alloc] init];
        morphGroundArray = [[CCArray alloc] init];
        playerVelocities = [[NSMutableArray alloc] init];
        shouldFollowSprite = NO;
        levelWasCompleted = NO;
        [self setupWorld];
        //[self setupDebugDraw];
        [self scheduleUpdate];
        
        [self setTouchEnabled:NO];
        self.accelerometerEnabled = NO;
        
        [self setAnchorPoint:CGPointMake(0, 0)];
        [self setupParallaxLayers];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCartComplete) name:NOTIFICATION_FADE_SAVE_BACKING object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(levelComplete) name:NOTIFICATION_LEVEL_COMPLETE object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [playerVelocities release];
    playerVelocities = nil;
    [accelerationArray release];
    accelerationArray = nil;
    [touchArray release];
    touchArray = nil;
    [morphGroundArray release];
    morphGroundArray = nil;
    [parallaxHolderArray release];
    parallaxHolderArray = nil;
    if (world)
    {
        [self deleteWorldBodies];
        delete world;
        world = NULL;
    }
    if (debugDraw) 
    {
        delete debugDraw;
        debugDraw = nil;
    }
    [self setPlayerCart:nil];
    delete contactListner;
    [super dealloc];
}

-(void)deleteWorldBodies
{
    for (b2Body *b=world->GetBodyList(); b!=NULL; b=b->GetNext())
    {
        b->SetUserData(nil);
        world->DestroyBody(b);
    }
}

-(NSString*)TileMapName
{
    return tileMapName;
}

-(NSString*)spriteLayerName
{
    return ObjectGroupSprites;
}

-(NSString*)collisionsLayerName
{
    return ObjectGroupCollisions;    
}

-(NSString*)placeholderLayerName
{
    return @"GameplayParallax";
}

-(int)defaultZOrder
{
    return -10000;
}

-(CCArray*)getMorphGroundArray
{
    return morphGroundArray;
}

-(void)setupParallaxLayers
{
    mapInfo = [CCTMXMapInfo formatWithTMXFile:_tileMapName];
    mapWidth = ([tileMapNode tileSize].width*[tileMapNode mapSize].width);
    mapHeight = ([tileMapNode tileSize].height*[tileMapNode mapSize].height);
    
    parrallaxNode = [[PunkParallax alloc] init];
    [parrallaxNode setMapSize:ccp(mapWidth, mapHeight)];
    [parrallaxNode setAnchorPoint:ccp(0, 0)];
    [parrallaxNode setPosition:ccp(0, 0)];
    [self addChild:parrallaxNode z:GroundZ-1];
    [parrallaxNode release];
    
    CCTMXObjectGroup *spriteGroup = [tileMapNode objectGroupNamed:[self spriteLayerName]];
    if (spriteGroup != nil)
    {
        [self processSpriteGroup:spriteGroup];
    }
    
    CCTMXObjectGroup *collisionsGroup = [tileMapNode objectGroupNamed:[self collisionsLayerName]];
    if (collisionsGroup != nil)
    {
        [self processCollisionGroup:collisionsGroup];
    }
    
    CCTMXObjectGroup *placeholderGroup = [tileMapNode objectGroupNamed:[self placeholderLayerName]];
    if (placeholderGroup != nil)
    {
        [self processLayerPlaceholderGroup:placeholderGroup];
    }
    
    float x = 0;
    float y = -9.8;
    if ([tileMapNode propertyNamed:@"GravityX"]) {
        x = [[tileMapNode propertyNamed:@"GravityX"] floatValue];
    }
    if ([tileMapNode propertyNamed:@"GravityY"]) {
        y = [[tileMapNode propertyNamed:@"GravityY"] floatValue];
    }
    mapTime = 1;
    if ([tileMapNode propertyNamed:@"Time"])
    {
        mapTime = [[tileMapNode propertyNamed:@"Time"] floatValue];
    }
    world->SetGravity(b2Vec2(x*2,y*2));

    tileMapNode = nil;
}

-(float)getMapTime
{
    return mapTime;
}

- (void)setupWorld
{
    world = new b2World(b2Vec2(0, -9.8*2));
    world->SetContinuousPhysics(YES);
    contactListner = new ContactListner();
    world->SetContactListener(contactListner);
}

-(b2World*)getWorld
{
    return world;
}

-(PlayerCart*)getCart
{
    return playerCart;
}

- (void)setupDebugDraw 
{    
    debugDraw = new GLESDebugDraw();
    debugDraw->SetFlags(b2Draw::e_shapeBit | b2Draw::e_jointBit);
    world->SetDebugDraw(debugDraw);  
}

-(void)createCartPlayerAtLocation:(CGPoint)location
{
    PlayerCart *playerCartTemp = [[PlayerCart alloc] initWithWorld:world atLocation:location];
    [self setPlayerCart:playerCartTemp];
    [self addChild:playerCart];
    [playerCartTemp release];
    [self createClipBlockAtLocation:location];
}

-(void)createClipBlockAtLocation:(CGPoint)location
{
    CGSize winSize = [[CCDirector sharedDirector] winSizeInPixels];
    winSize = CGSizeMake(winSize.width/(2*SCREEN_SCALE)/pixelsToMeterRatio(), winSize.height/(2*SCREEN_SCALE)/pixelsToMeterRatio());
    CGFloat halfBoxHeight = winSize.height/8.0f;
    location = ccp(location.x/pixelsToMeterRatio(), location.y/pixelsToMeterRatio());
    location.y = location.y-winSize.height/2.0f-halfBoxHeight+(GroundHeight-2.0f)/pixelsToMeterRatio();
    
    b2BodyDef clipBodyDef;
    clipBodyDef.type = b2_staticBody;
    clipBodyDef.position.Set(location.x, location.y);
    b2Body *clipBody = world->CreateBody(&clipBodyDef);
    b2FixtureDef groundFixtureDef;
    groundFixtureDef.filter.categoryBits = kGroundCat;
    groundFixtureDef.density = 100000.0;
    groundFixtureDef.friction = 1;
    groundFixtureDef.restitution = 0.2;
    b2PolygonShape shape;
    

    shape.SetAsBox(winSize.width, halfBoxHeight);
    groundFixtureDef.shape = &shape;
    
    clipBody->CreateFixture(&groundFixtureDef);
}

-(void)createBarWithStart:(CGPoint)start andEnd:(CGPoint)end
{
    Bar *aBar = [[Bar alloc] initWithStart:start andEnd:end andCart:playerCart];
    [self addChild:aBar z:[aBar zOrder]];
    [aBar release];
}

-(void)createWheelWithStart:(CGPoint)start andEnd:(CGPoint)end
{
    Wheel *aWheel = [[Wheel alloc] initWithStart:start andEnd:end andCart:playerCart andType:kWheelPartType];
    [self addChild:aWheel z:[aWheel zOrder]];
    [aWheel release];
}

-(void)createMotorWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type
{
    Motor *aMotor = [[Motor alloc] initWithStart:start andEnd:end andCart:playerCart andType:type];
    [accelerationArray addObject:aMotor];
    [self addChild:aMotor z:[aMotor zOrder]];
    [aMotor release];
}

-(void)createBoosterWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type
{
    Booster *aBooster = [[Booster alloc] initWithStart:start andEnd:end andCart:playerCart andLayer:self andType:type];
    [touchArray addObject:aBooster];
    [self addChild:aBooster z:[aBooster zOrder]];
    [aBooster release];
}

-(void)createShockWithStart:(CGPoint)start andEnd:(CGPoint)end
{
    ShockAbsorber *anAbsorber = [[ShockAbsorber alloc] initWithStart:start andEnd:end andCart:playerCart];
    
    if ([anAbsorber setupSuccessful])
        [self addChild:anAbsorber z:[anAbsorber zOrder]];
    else
        [[playerCart components] removeObject:anAbsorber];
    
    [anAbsorber release];
}

-(PlayerCart *)getPlayerCart
{
    return playerCart;
}

-(CartPart*)deletePartAtLocation:(CGPoint)location outputShocks:(NSMutableArray *)outShocks
{
    return [playerCart deletePartAtLocation:location outputShocks:outShocks];
}

-(void)deletePartStarted:(CGPoint)start
{
    [playerCart highlightCartPartAt:start];
}

-(void)deletePartMoved:(CGPoint)moved
{
    [playerCart highlightCartPartAt:moved];
}

-(void)deletePartEnded
{
    [playerCart deleteHighlightedPart];
}

-(void)deletePartCanceled
{
    [playerCart unhighlightPart];
}

-(void)deleteAllCartParts
{
    [playerCart deleteAllCartParts];
}

-(void)highlightCart
{
    [playerCart highlightAllParts];
}

-(void)unhighlightCart
{
    [playerCart unhighlightAllParts];
}

-(int)numberOfCartParts
{
    return [playerCart partCount];
}

-(CGPoint)getNewScreenPositionWithScale: (float) scale
{
    float xStop = 256;
    float yStop = 256;
    
    CGSize winSize = CGSizeMake([CCDirector sharedDirector].winSize.width/scale, [CCDirector sharedDirector].winSize.height/scale);

    float velFac = ([self playerVelPercentage]+1)/2.0f;
    float wiggleFactor = 1 - velFac;
    float wiggleRoom = fabsf((winSize.width/3.3) - (winSize.width - winSize.width/5));
    float fixedPositionX = (winSize.width/3.3) + wiggleRoom*wiggleFactor;
    
    float fixedPositionY = winSize.height/2;
    float newX = fixedPositionX - [playerCart averagePosition].x;
    float newY = fixedPositionY - [playerCart averagePosition].y;
    
    //for stopping on the left
    newX = MIN(newX, -xStop);
    //for stopping on the right
    newX = MAX(newX, -mapWidth+winSize.width+xStop);
    //for stopping on the bottom
    newY = MIN(newY, -yStop);
    
    return ccp(newX*scale, newY*scale);
}

-(float)playerVelPercentage
{
    float avg = [self calcAvgPlayerVelocity];
    if (fabsf(avg)>15)
    {
        avg = avg > 0 ? 15:-15;
    }
    avg = avg/15;
    return avg;
}

-(float)calcAvgPlayerVelocity
{
    float velocity = [playerCart body]->GetLinearVelocity().x;
    [playerVelocities insertObject:[NSNumber numberWithFloat:velocity] atIndex:0];
    if ([playerVelocities count]>60)
    {
        [playerVelocities removeLastObject];
    }
    
    float playerVelAvg = 0;
    for (NSNumber *value in playerVelocities)
    {
        playerVelAvg+=[value floatValue];
    }
    playerVelAvg = playerVelAvg/[playerVelocities count];
    return playerVelAvg;
}

- (void)followSprite
{   
    if (!shouldFollowSprite)
        return;
    if (playerCart == nil)
        return;

    CGPoint newPos = [self getNewScreenPositionWithScale:[self scale]];
    [self setPosition:newPos];
}

-(void)setPosition:(CGPoint)position
{
    for (BaseParallaxLayer *aLayer in parallaxHolderArray)
    {
        [aLayer setParallaxPosition:position];
    }
    [super setPosition:position];
}

-(void)setScaleX:(float)scaleX
{
    for (BaseParallaxLayer *aLayer in parallaxHolderArray)
    {
        [aLayer setParallaxScaleX:scaleX];
    }
    [super setScaleX:scaleX];
}

-(void)setScaleY:(float)scaleY
{
    for (BaseParallaxLayer *aLayer in parallaxHolderArray)
    {
        [aLayer setParallaxScaleY:scaleY];
    }
    [super setScaleY:scaleY];
}

-(void)movementDidOccur:(CGPoint)movement
{    
    CCArray *removeArray = [[CCArray alloc] init];
    for (id accelerationObject in accelerationArray)
    {
        id<JoystickDelegate> accelObject = (NSObject<JoystickDelegate>*)accelerationObject;
        if ([accelObject shouldRemoveFromAccelerationArray])
        {
            [removeArray addObject:accelObject];
        }else
        {
            [accelObject movementDidOccur:movement];
        }
    }
    [accelerationArray removeObjectsInArray:removeArray];
    [removeArray release];
}

-(void)buttonPressBegan
{
    CCArray *removeArray = [[CCArray alloc] init];
    for (id touchObject in touchArray)
    {
        id<JoystickDelegate> touched = (NSObject<JoystickDelegate>*)touchObject;
        if ([touched shouldRemoveFromTouchArray])
        {
            [removeArray addObject:touched];
        }else
        {
            [(NSObject<JoystickDelegate>*)touchObject buttonPressBegan];
        }
    }
    [touchArray removeObjectsInArray:removeArray];
    [removeArray release];
}

-(void)buttonPressEnded
{
    CCArray *removeArray = [[CCArray alloc] init];
    for (id touchObject in touchArray)
    {
        id<JoystickDelegate> touched = (NSObject<JoystickDelegate>*)touchObject;
        if ([touched shouldRemoveFromTouchArray])
        {
            [removeArray addObject:touched];
        }else
        {
            [(NSObject<JoystickDelegate>*)touchObject buttonPressEnded];
        }
    }
    [touchArray removeObjectsInArray:removeArray];
    [removeArray release];
}

-(void)addParallaxLayer:(BaseParallaxLayer*)layer
{
    [parallaxHolderArray addObject:layer];
}

-(void)update:(ccTime)dt 
{
    if ([[GameManager sharedGameManager] isPaused])
    {
        return;
    }
    
    //Best so far - world->Step(dt*2.0f, 7, 5);
    world->Step(dt*2.0f, 10, 8);
    
    for(b2Body *b=world->GetBodyList(); b!=NULL; b=b->GetNext()) 
    {    
        if (b->GetUserData() != NULL)
        {
            Box2DSprite *sprite = (Box2DSprite *) b->GetUserData();
            //update the player sprites position
            if (playerCart.body == b) 
            {
                b2Vec2 playerPos = b->GetPosition();
                [playerCart setPosition:ccp(playerPos.x*pixelsToMeterRatio(),playerPos.y*pixelsToMeterRatio())];
                [playerCart setRotation:CC_RADIANS_TO_DEGREES(b->GetAngle() * -1)];
            }
            //update all other sprites position
            GameObjectType type = sprite.gameObjectType;
            if (type == kGroundType || type == kPlayerClipType)
                continue;
            //update cart fixture positions
            if (sprite.gameObjectType == kPlayerCartType)
            {
                b2Fixture *cartFixture = b->GetFixtureList();
                while (cartFixture)
                {
                    if (cartFixture->GetUserData() != NULL)
                    {
                        CartPart *part = (CartPart*)cartFixture->GetUserData();
                        part.position = ccp(b->GetPosition().x * pixelsToMeterRatio(),
                                            b->GetPosition().y * pixelsToMeterRatio());
                        part.rotation =  CC_RADIANS_TO_DEGREES(b->GetAngle()*-1);
                    }
                    cartFixture = cartFixture->GetNext();
                }
                //update cart joint positions
                b2JointEdge *jointEdge = b->GetJointList();
                while (jointEdge)
                {
                    b2Joint *joint = jointEdge->joint;
                    if (joint->GetUserData() != NULL)
                    {
                        CartPart *part = (CartPart*)joint->GetUserData();
                        if ([[part class] isSubclassOfClass:[ShockAbsorber class]])
                        {
                            ShockAbsorber* shock = (ShockAbsorber*)part;
                            CGPoint posA = ccp(joint->GetAnchorA().x, joint->GetAnchorA().y);
                            CGPoint posB = ccp(joint->GetAnchorB().x, joint->GetAnchorB().y);
                            [shock setPositionWithPoint:ccpMult(posA, pixelsToMeterRatio()) andPoint:ccpMult(posB, pixelsToMeterRatio())];
                        }
                    }
                    jointEdge = jointEdge->next;
                }
            }else
            {
                sprite.position = ccp(b->GetPosition().x * pixelsToMeterRatio(), 
                                      b->GetPosition().y * pixelsToMeterRatio());
                sprite.rotation = CC_RADIANS_TO_DEGREES(b->GetAngle() * -1);
            }
        }  
    }

    CCArray *listOfGameObjects = [self children]; 
    for (GameObject *tempChar in listOfGameObjects) { 
        if ([[tempChar class] isSubclassOfClass:[GameObject class]]) 
        {
            [tempChar updateStateWithDeltaTime:dt 
                          andListOfGameObjects:listOfGameObjects]; 
        }
    }
    [self followSprite];
    
    //[playerCart applybreakableJoints];
}

-(void)draw
{
    if (debugDraw)
    {
        ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
        kmGLPushMatrix();
        kmGLScalef(32, 32, 0);
        world->DrawDebugData();
        kmGLPopMatrix();
    }
    [super draw];
}

-(void)saveCart
{
    if (saveCartRender)
    {
        [[saveCartRender sprite] stopAllActions];
        [saveCartRender removeFromParentAndCleanup:YES];
    }
    saveCartRender = [self takeCartScreenShot];
    [[saveCartRender sprite] setOpacity:0];
    [[saveCartRender sprite] setPosition:[[SaveManager sharedManager] convertToActionSpace:ccp(512, 384)]];
    [self addChild:saveCartRender z:10000];

    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.3 opacity:255];
    [[saveCartRender sprite] runAction:fade];
    id sequence = [CCSequence actions:[CCDelayTime actionWithDuration:0.4], [CCCallFunc actionWithTarget:self selector:@selector(processSave)], nil];
    [self runAction:sequence];
}

-(void)processSave
{
    UIImage *saveImage = [saveCartRender getUIImage];
    saveImage = [saveImage imageByScalingProportionallyToSize:CGSizeMake(512.0, 384.0)];
    [[SaveManager sharedManager] saveCart:playerCart andImage:saveImage];   
}

-(CCRenderTexture*)takeCartScreenShot
{
    [CCDirector sharedDirector].nextDeltaTimeZero = YES;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCRenderTexture* rtx = [CCRenderTexture renderTextureWithWidth:winSize.width height:winSize.height];
    
    CCSprite *saveBacking = [CCSprite spriteWithFile:@"blueprints_backing.png"];
    [saveBacking setScale:2*(SCREEN_SCALE)];
    [saveBacking setPosition: ccp(512.0, 384.0)];
    
    [rtx begin];
    [saveBacking visit];
    for (CartPart *part in [playerCart componentsInOrderOfZ])
    {
        [part setSnapshotPosition:ccp(part.position.x+[self position].x, part.position.y+[self position].y)];
        [part visit];
    }
    [rtx end];
    return rtx;
}

-(void)saveCartComplete
{    
    CCFadeOut *fade = [CCFadeOut actionWithDuration:1.5];
    [[saveCartRender sprite] runAction:[CCSequence actions:fade, [CCCallFunc actionWithTarget:self selector:@selector(removeCartRender)], nil]];
}

-(void)removeCartRender
{
    [saveCartRender removeFromParentAndCleanup:YES];
    saveCartRender = nil;
}

-(void)cleanup
{
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [super cleanup];
}

-(CCArray*)arrayOfType:(GameObjectType)type
{
    CCArray *listOfGameObjects = [self children];
    CCArray *typeArray = [CCArray array];
    for (GameObject *tempChar in listOfGameObjects) {
        if (![[tempChar class] isSubclassOfClass:[GameObject class]])
            continue;
        
        if ([tempChar gameObjectType] == type)
        {
            [typeArray addObject:tempChar];
        }
    }
    return typeArray;
}

-(void)resetRocks
{
    [[self arrayOfType:kRockType] makeObjectsPerformSelector:@selector(resetRock)];
    [[self arrayOfType:kBreakableGroundType]  makeObjectsPerformSelector:@selector(resetGround)];
}

-(void)resetCompositeSprites
{
    [[self arrayOfType:kCompositeSpriteType] makeObjectsPerformSelector:@selector(reset)];
}

-(void)resetSpriteTriggers
{
    [[self arrayOfType:kSpriteTrigger] makeObjectsPerformSelector:@selector(resetTrigger)];
}

-(void)disableThingySounds
{
    [[self arrayOfType:kThingyBasic] makeObjectsPerformSelector:@selector(dissableSfx)];
}

-(void)makeThingiesDynamic
{
    [[self arrayOfType:kThingyBasic] makeObjectsPerformSelector:@selector(makeDynamic)];
}

-(void)resetThingies
{
    [[self arrayOfType:kThingyBasic] makeObjectsPerformSelector:@selector(resetThingy)];
}

-(void)removeThingies
{
    CCArray *thingies = [self arrayOfType:kThingyBasic];
    [thingies makeObjectsPerformSelector:@selector(destroyThingyPhysics)];
    [thingies makeObjectsPerformSelector:@selector(removeFromParent)];
}

-(Wormhole*)getWormhole
{
    CCArray *array = [self arrayOfType:kWormholeType];
    if ([array count])
    {
        return [array objectAtIndex:0];
    }
    return nil;
}

-(Pod*)getPod
{
    CCArray *array = [self arrayOfType:kPodType];
    if ([array count])
    {
        return [array objectAtIndex:0];
    }
    return nil;    
}

-(void)resetElevators
{
    [[self arrayOfType:kElevatorType] makeObjectsPerformSelector:@selector(resetElevator)];  
}

-(void)resetForces
{
    [[self arrayOfType:kForceAreaType] makeObjectsPerformSelector:@selector(resetForceCycle)];
}

-(void)openWormhole
{
    [[self getWormhole] spawnPeons];
}

-(void)resetWormhole
{
    [[self getWormhole] resetWormhole];
}

-(int)getPeonCount
{
    return [[self getWormhole] peonCount];
}

-(int)getPodPeonCount
{
    return [[self getPod] countPeons];
}

-(void)startAction
{
    [self stopAllActions];
    [playerCart removeNonGameplayFixtures];
    [playerCart moveBodyToCart];
    [self zoomOutAction];
}

-(void)stopAction
{
    [self resetGamePlay];
    [self zoomInAction];
}

-(void)resetAction
{
    [self resetGamePlay];
    [playerCart removeNonGameplayFixtures];
    [playerCart moveBodyToCart];
    
    id moveAction = [CCMoveTo actionWithDuration:[self timeToTravel] position:resetPosition];
    id sequence = [CCSequence actions:moveAction, [CCCallFunc actionWithTarget:self selector:@selector(endResetAction)], nil];
    [self runAction:sequence];
}

-(void)endResetAction
{
    [playerCart reappear];
    [self beginGameplay];
}

-(void)beginGameplay
{
    shouldFollowSprite = YES;
    [_controlsDelegate enableControls];
    [playerCart startCartGameplay];
    [self openWormhole];
}

-(void)zoomOutAction
{
    CGFloat newScale = 0.35;
    
    CGPoint scaleCenter = [self getNewScreenPositionWithScale:newScale];
    resetPosition = scaleCenter;
    
    id scaleAction = [CCScaleTo actionWithDuration:0.5f scale:newScale];
    id moveAction = [CCMoveTo actionWithDuration:0.5f position:scaleCenter];
    id allActions = [CCSpawn actions:scaleAction, moveAction, nil];
    id sequence = [CCSequence actions:allActions, [CCCallFunc actionWithTarget:self selector:@selector(endZoomOut)], nil];
    [self runAction:sequence];
}

-(void)endZoomOut
{
    [self beginGameplay];
}

-(void)zoomInAction
{
    id scaleAction = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
    id moveAction = [CCMoveTo actionWithDuration:[self timeToTravel] position:resetPosition];
    id moveAction2 = [CCMoveTo actionWithDuration:0.5f position:originalPosition];
    id spawn = [CCSpawn actions:scaleAction, moveAction2, nil];
    id sequence = [CCSequence actions:moveAction, spawn, [CCCallFunc actionWithTarget:self selector:@selector(endZoomIn)], nil];
    [self runAction:sequence];
}

-(void)endZoomIn
{
    [playerCart reappear];
    [playerCart addSwivelIndicators];
    if (levelWasCompleted) {
        [[self getPod] resetPod];
        levelWasCompleted = NO;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_END_GAMEPLAY object:nil];
}

-(float)timeToTravel
{
    float time = 5*((fabs(originalPosition.x-self.position.x))/mapWidth);
    time = time < 1? 1:time;
    return time;
}

-(void)levelComplete
{
    levelWasCompleted = YES;
    shouldFollowSprite = NO;
    CGFloat newScale = 0.20;
    //
    float xStop = 256;
    float yStop = 256;
    CGSize winSize = CGSizeMake([CCDirector sharedDirector].winSize.width/newScale, [CCDirector sharedDirector].winSize.height/newScale);
    float fixedPositionX = winSize.width/2;
    float fixedPositionY = winSize.height/2;
    float newX = fixedPositionX - [[self getPod] position].x;
    float newY = fixedPositionY - [[self getPod] position].y;
    
    //for stopping on the left
    newX = MIN(newX, -xStop);
    //for stopping on the right
    newX = MAX(newX, (-mapWidth)+winSize.width+xStop);
    //for stopping on the bottom
    newY = MIN(newY, -yStop);

    CGPoint scaleCenter = ccp(newX*newScale, newY*newScale);
    //
    id scaleAction = [CCScaleTo actionWithDuration:1.0f scale:newScale];
    id moveAction = [CCMoveTo actionWithDuration:1.0f position:scaleCenter];
    id allActions = [CCSpawn actions:scaleAction, moveAction, nil];
    [self runAction:[CCSequence actions:allActions, [CCDelayTime actionWithDuration:5], [CCCallFunc actionWithTarget:self selector:@selector(liftOffPod)],nil]];
    
    [self disableThingySounds];
    [_controlsDelegate dissableControls];
}

-(void)liftOffPod
{
    [[self getPod] liftOffWithWeight:[[self playerCart] fullMass]];
}

-(BOOL)cartHasParts
{
    return ([[playerCart components] count]>0);
}

-(void)resetGamePlay
{
    [self stopAllActions];
    [_controlsDelegate dissableControls];
    shouldFollowSprite = NO;
    [playerCart dissapear];
    [playerCart resetCartBody];
    [self resetWormhole];
    [self removeThingies];
    [self resetRocks];
    [self resetCompositeSprites];
    [self resetElevators];
    [self resetForces];
    [self resetSpriteTriggers];
    
    //For items not directly attached to this class
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_RESET_GAMEPLAY object:nil userInfo:nil];
}

@end
