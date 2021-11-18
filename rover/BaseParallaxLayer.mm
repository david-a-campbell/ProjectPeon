//
//  BaseParallaxLayer.m
//  rover
//
//  Created by David Campbell on 6/27/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "BaseParallaxLayer.h"
#import "Ground.h"
#import "Rock.h"
#import "PlayerClipGround.h"
#import "Bridge.h"
#import "Elevator.h"
#import "Thingy.h"
#import "Booster.h"
#import "PlayerCart.h"
#import "Wormhole.h"
#import "Pod.h"
#import "PodRamp.h"
#import "NodeData.h"
#import "PunkParallax.h"
#import "ForceArea.h"
#import "TexturedArea.h"
#import "BreakableGround.h"
#import "AnimatedSprite.h"
#import "SpriteTrigger.h"
#import "CompositeSprite.h"
#import "SplashZone.h"

@implementation BaseParallaxLayer

-(void)dealloc
{
    tileMapNode = nil;
    [super dealloc];
}

- (id)initWithTileMapName:(NSString*)tileMapName
{
    if ((self = [super init])) 
    {
        _tileMapName = tileMapName;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
        {
            tileMapNode = [CCTMXTiledMap tiledMapWithTMXFile:tileMapName];
        }
        placeHolderZOrder = 0;
        [tileMapNode setAnchorPoint:ccp(0, 0)];
        [tileMapNode setPosition:ccp(0, 0)];
        [self setAnchorPoint:CGPointMake(0, 0)];
    }
    return self;
}

-(void)setParallaxPosition:(CGPoint)position
{
    [parrallaxNode setPosition:position];
}

-(void)setParallaxScaleY:(float)scaleY
{
    [parrallaxNode setScaleY:scaleY];
}

-(void)setParallaxScaleX:(float)scaleX
{
    [parrallaxNode setScaleX:scaleX];
}

-(NSArray*)placeHolderNames
{
    CCLOG(@"Override Me!");
    return @[];
}

-(NSString*)spriteLayerName
{
    CCLOG(@"Override Me!");
    return @"";
}

-(NSString*)collisionsLayerName
{
    CCLOG(@"Override Me!");
    return @"";    
}

-(void)setupParallaxLayers
{
    mapInfo = [CCTMXMapInfo formatWithTMXFile:_tileMapName];
    mapWidth = ([tileMapNode tileSize].width*[tileMapNode mapSize].width);
    mapHeight = ([tileMapNode tileSize].height*[tileMapNode mapSize].height);
    
    [self setAnchorPoint:ccp(0, 0)];
    [self setPosition: ccp(0, 0)];
    
    parrallaxNode = [[PunkParallax alloc] init];
    [parrallaxNode setMapSize:ccp(mapWidth, mapHeight)];
    [parrallaxNode setAnchorPoint:ccp(0, 0)];
    [parrallaxNode setPosition:ccp(0, 0)];
    [self addChild:parrallaxNode];
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
    
    for (NSString *placeHolderName in [self placeHolderNames])
    {
        CCTMXObjectGroup *layerPlaceholderGroup = [tileMapNode objectGroupNamed:placeHolderName];
        if (layerPlaceholderGroup != nil)
        {
            [self processLayerPlaceholderGroup:layerPlaceholderGroup];
            placeHolderZOrder++;
        }
    }
    
    tileMapNode = nil;
    mapInfo = nil;
}

-(CCTMXTilesetInfo*)tileInfoForGid:(int)gid
{
    for (CCTMXTilesetInfo *tileInfo in [mapInfo tilesets])
    {
        if ([tileInfo firstGid] == gid)
        {
            return tileInfo;
        }
    }
    return nil;
}

-(void)processLayerPlaceholderGroup:(CCTMXObjectGroup*)layerPlaceHolderGroup
{
    CCTexture2DPixelFormat currentFormat = [CCTexture2D defaultAlphaPixelFormat];
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
    
    float groupXRatio = 1;
    float groupYRatio = 1;
    float scale = 1;
    float groupZOrder = placeHolderZOrder;
    float motionX = 0;
    float motionY = 0;
    
    NSMutableArray *placeholderArray = [layerPlaceHolderGroup objects];
    if ([[layerPlaceHolderGroup properties] valueForKey:ParallaxRatioX] != nil)
    {
        groupXRatio = [[[layerPlaceHolderGroup properties] valueForKey:ParallaxRatioX] floatValue];
    }
    if ([[layerPlaceHolderGroup properties] valueForKey:ParallaxRatioY] != nil)
    {
        groupYRatio = [[[layerPlaceHolderGroup properties] valueForKey:ParallaxRatioY] floatValue];
    }
    if ([[layerPlaceHolderGroup properties] valueForKey:ZOrder] != nil)
    {
        groupZOrder = [[[layerPlaceHolderGroup properties] valueForKey:ZOrder] floatValue];
    }
    if ([[layerPlaceHolderGroup properties] valueForKey:Scale] != nil)
    {
        scale = [[[layerPlaceHolderGroup properties] valueForKey:Scale] floatValue];
    }
    if ([[layerPlaceHolderGroup properties] valueForKey:MotionX] != nil)
    {
        motionX = [[[layerPlaceHolderGroup properties] valueForKey:MotionX] floatValue];
    }
    if ([[layerPlaceHolderGroup properties] valueForKey:MotionY] != nil)
    {
        motionY = [[[layerPlaceHolderGroup properties] valueForKey:MotionY] floatValue];
    }
    if ([[[layerPlaceHolderGroup properties] valueForKey:Use8888] intValue])
    {
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    }
    
    for(NSDictionary *placeholder in placeholderArray)
    {
        if ([[placeholder valueForKey:@"type"] isEqualToString:@"AnimatedSprite"])
        {
            [self processAnimatedSprite:placeholder xRatio:groupXRatio yRatio:groupYRatio zOrder:groupZOrder scale:scale];
            continue;
        }
        
        if ([[placeholder valueForKey:@"gid"] length])
        {
            [self processTilePlaceHolder:placeholder xRatio:groupXRatio yRatio:groupYRatio zOrder:groupZOrder scale:scale];
            continue;
        }
        
        if ([[placeholder valueForKey:@"type"] isEqualToString:@"Emitter"])
        {
            [self processEmitter:placeholder xRatio:groupXRatio yRatio:groupYRatio zOrder:groupZOrder scale:scale];
            continue;
        }

       NSString *layerFileName = [placeholder valueForKey:Texture];
        
        if ([layerFileName length])
        {
            CCSprite *layerSprite = [CCSprite spriteWithFile:layerFileName];
            [[layerSprite texture] setAliasTexParameters];
            [layerSprite setAnchorPoint:ccp(0, 0)];
            [layerSprite setScale:(2*scale*SCREEN_SCALE)];
            float x = [[placeholder valueForKey:@"x"] floatValue] * scale;
            float y = [[placeholder valueForKey:@"y"] floatValue] * scale;
            
            if([placeholder valueForKey:ParallaxRatioX] != nil)
            {
                groupXRatio = [[placeholder valueForKey:ParallaxRatioX] floatValue];
            }
            if([placeholder valueForKey:ParallaxRatioY] != nil)
            {
                groupYRatio = [[placeholder valueForKey:ParallaxRatioY] floatValue];
            }
            if ([placeholder valueForKey:ZOrder] != nil)
            {
                groupZOrder = [[placeholder valueForKey:ZOrder] intValue];
            }

            //Never set the position of layerSprite - positionOffset below will do the work
            [parrallaxNode addChild:layerSprite z:groupZOrder parallaxRatio:ccp(groupXRatio, groupYRatio) positionOffset:ccp(x, y) motionOffset:ccp(motionX, motionY)];
        }
    }
    [CCTexture2D setDefaultAlphaPixelFormat:currentFormat];
}

-(void)processTilePlaceHolder:(id)placeholder xRatio:(float)groupXRatio yRatio:(float)groupYRatio zOrder:(float)groupZOrder scale:(float)scale
{
    int gid = [[placeholder valueForKey:@"gid"] intValue];
    CCTMXTilesetInfo *tileInfo = [self tileInfoForGid:gid];
    NSString *tileFileName = [tileInfo sourceImage];
    
    float x = [[placeholder valueForKey:@"x"] floatValue] * scale;
    float y = [[placeholder valueForKey:@"y"] floatValue] * scale;
    
    CCSprite *tileSprite = [CCSprite spriteWithFile:tileFileName];
    [tileSprite setAnchorPoint:ccp(0, 0)];
    [tileSprite setScale:(2*scale*SCREEN_SCALE)];
    [[tileSprite texture] setAliasTexParameters];
    
    [parrallaxNode addChild:tileSprite z:groupZOrder parallaxRatio:ccp(groupXRatio, groupYRatio) positionOffset:ccp(x, y)];
}

-(void)processEmitter:(id)placeholder xRatio:(float)groupXRatio yRatio:(float)groupYRatio zOrder:(float)groupZOrder scale:(float)scale
{
    NSString *emitterType = [placeholder valueForKey:@"EmitterType"];
    
    float xVariance = 0;
    if ([[placeholder valueForKey:@"XVariance"] length])
    {
        xVariance = [[placeholder valueForKey:@"XVariance"] floatValue];
    }
    float yVariance = 0;
    if ([[placeholder valueForKey:@"YVariance"] length])
    {
        yVariance = [[placeholder valueForKey:@"YVariance"] floatValue];
    }
    
    float x = [[placeholder valueForKey:@"x"] floatValue] * scale;
    float y = [[placeholder valueForKey:@"y"] floatValue] * scale;
    
    CCParticleSystemQuad *emitter = [CCParticleSystemQuad particleWithFile:[NSString stringWithFormat:@"%@%@", emitterType, @".plist"]];
    if (xVariance != 0 || yVariance != 0)
    {
        [emitter setPosVar:CGPointMake(xVariance, yVariance)];
    }
    [emitter setAnchorPoint:ccp(0.0, 0.0)];
    [[emitter texture] setAliasTexParameters];
    [emitter setPositionType:kCCPositionTypeGrouped];
    [emitter resetSystem];
    
    [parrallaxNode addChild:emitter z:groupZOrder parallaxRatio:ccp(groupXRatio, groupYRatio) positionOffset:ccp(x, y)];
}

-(void)processAnimatedSprite:(id)placeholder xRatio:(float)groupXRatio yRatio:(float)groupYRatio zOrder:(float)groupZOrder scale:(float)scale
{
    AnimatedSprite *animatedSprite = [[AnimatedSprite alloc] initWithDict:placeholder];
    [animatedSprite setScale:(2*scale*SCREEN_SCALE)];
    [[animatedSprite texture] setAliasTexParameters];
    CCSprite *holderSprite = [CCSprite node];
    [holderSprite addChild:animatedSprite];
    
    float x = [[placeholder valueForKey:@"x"] floatValue] * scale;
    float y = [[placeholder valueForKey:@"y"] floatValue] * scale;
    float width = [[placeholder valueForKey:@"width"] floatValue] * scale;
    float height = [[placeholder valueForKey:@"height"] floatValue] * scale;
    x = x+width/2.0f;
    y = y+height/2.0f;
    
    [parrallaxNode addChild:holderSprite z:groupZOrder parallaxRatio:ccp(groupXRatio, groupYRatio) positionOffset:ccp(x, y)];
    [animatedSprite release];
}

-(void) processCollisionGroup:(CCTMXObjectGroup*)collisionObjects
{
    NSMutableArray *polygonObjectArray = [collisionObjects objects];
    for (id ground in polygonObjectArray)
    {
        if ([[ground valueForKey:@"type"] isEqualToString:TexturedGround])
        {
            [self createTexturedGround:ground];
        }
        else if([[ground valueForKey:@"type"] isEqualToString:TexArea])
        {
            [self createTexturedArea:ground];
        }
        else if([[ground valueForKey:@"type"] isEqualToString:BreakGround])
        {
            [self createBreakableGround:ground withObjectGroup:collisionObjects];
        }
        else if ([[ground valueForKey:@"type"] isEqualToString:TexturedRock])
        {
            [self createTexturedRock:ground];
        }else if([[ground valueForKey:@"type"] isEqualToString:PlayerClip])
        {
            [self createPlayerClip:ground];
        }
    }
}

-(void)processSpriteGroup:(CCTMXObjectGroup*)spriteGroup
{
    //setup player cart first to make sure its ready for other objects
    [self setupPlayerCart:spriteGroup];
    
    NSMutableArray *spriteArray = [spriteGroup objects];
    for (id sprite in spriteArray)
    {
        float x = [[sprite valueForKey:@"x"] floatValue];
        float y = [[sprite valueForKey:@"y"] floatValue];
        float height = [[sprite valueForKey:@"height"] floatValue];
        float width = [[sprite valueForKey:@"width"] floatValue];
        float offsetY = 0;
        float offsetX = 0;
        
        if ([sprite valueForKey:@"OffsetX"])
            offsetX = [[sprite valueForKey:@"OffsetX"] floatValue];
        if ([sprite valueForKey:@"OffsetY"])
            offsetY = [[sprite valueForKey:@"OffsetY"] floatValue];
        
        x += offsetX;
        y += offsetY;
        float posX = x+width/2;
        float posY = y+height/2;
        
        if([[sprite valueForKey:@"type"] isEqualToString:ThingySprite])
        {
            [self createThingySpriteAtLocation:ccp(posX, posY) dynamic:NO];
        }
        else if([[sprite valueForKey:@"type"] isEqualToString:BridgeSprite])
        {
            [self createBridgeSpriteWithDict:sprite];
        }
        else if([[sprite valueForKey:@"type"] isEqualToString:ForceSprite])
        {
            [self createForceAreaWithDict:sprite objectGroup:spriteGroup];
        }
        else if ([[sprite valueForKey:@"type"] isEqualToString:SplashZoneSprite])
        {
            [self createSplashZone:sprite];
        }
        else if([[sprite valueForKey:@"type"] isEqualToString:ElevatorSprite])
        {
            [self createElevator:sprite];
        }
        else if([[sprite valueForKey:@"type"] isEqualToString:WormholeSprite])
        {
            [self createWormholeAtLocation:ccp(posX, posY) withPeonCount:[[sprite valueForKey:@"PeonCount"] intValue]];
        }
        else if ([[sprite valueForKey:@"type"] isEqualToString:PodSprite])
        {
            [self createPodAtLocation:ccp(posX, posY)];
        }
        else if([[sprite valueForKey:@"type"] isEqualToString:TriggerSprite])
        {
            [self createSpriteTriggerWithDict:sprite];
        }
        else if ([[sprite valueForKey:@"type"] isEqualToString:CompSprite])
        {
            [self createCompositeSpriteWithDict:sprite objectGroup:spriteGroup];
        }
    }
}

-(void)setupPlayerCart:(CCTMXObjectGroup*)spriteGroup
{
    NSMutableArray *spriteArray = [spriteGroup objects];
    for (id sprite in spriteArray)
    {
        float x = [[sprite valueForKey:@"x"] floatValue];
        float y = [[sprite valueForKey:@"y"] floatValue];
        float height = [[sprite valueForKey:@"height"] floatValue];
        float width = [[sprite valueForKey:@"width"] floatValue];
        float offsetY = 0;
        float offsetX = 0;
        
        if ([sprite valueForKey:@"OffsetX"])
            offsetX = [[sprite valueForKey:@"OffsetX"] floatValue];
        if ([sprite valueForKey:@"OffsetY"])
            offsetY = [[sprite valueForKey:@"OffsetY"] floatValue];
        
        x += offsetX;
        y += offsetY;
        float posX = x+width/2;
        float posY = y+height/2;
        
        if ([[sprite valueForKey:@"type"] isEqualToString:CartPlayerSprite])
        {
            [self createCartPlayerAtLocation:ccp(posX, posY)];
            originalPosition = ccp(-x,-y);
            [self setPosition:originalPosition];
        }
    }
}

//Sprite Helpers

-(b2World*)getWorld
{
    CCLOG(@"override getWorld");
    return nil;
}

-(PlayerCart*)getCart
{
    CCLOG(@"override getCart");
    return nil;
}

-(CCArray*)getMorphGroundArray
{
    CCLOG(@"override getMorphGroundArray");
    return nil;
}

//SPRITE OBJECTS
-(void)createSplashZone:(id)dict
{
    SplashZone *splash = [[SplashZone alloc] initWithWorld:[self getWorld] andDict:dict];
    [self addChild:splash];
    [splash release];
}

-(void)createTexturedArea:(id)dict
{
    TexturedArea *tex = [[TexturedArea alloc] initWithDict:dict];
    [self addChild:tex z:GroundZ];
    [tex release];
}

-(void)createTexturedGround:(id)ground
{
    Ground *texturedGround = [[Ground alloc] initWithWorld:[self getWorld] andDict:ground isSolid:NO];
    [self addChild:texturedGround z:GroundZ];
    [texturedGround release];
}

-(void)createBreakableGround:(id)ground withObjectGroup:(CCTMXObjectGroup*)collisionObjects
{
    BreakableGround *breakAble = [[BreakableGround alloc] initWithWorld:[self getWorld] dict:ground objectGroup:collisionObjects andParent:self];
    [self addChild:breakAble z:0];
    [breakAble release];
}

-(void)createTexturedRock:(id)rock
{
    Rock *texturedRock = [[Rock alloc] initWithWorld:[self getWorld] andDict:rock];
    [self addChild:texturedRock z:0];
    [texturedRock release];
}

-(void)createElevator:(id)elevator
{
    Elevator *anElevator = [[Elevator alloc] initWithDict:elevator andWorld:[self getWorld]];
    [self addChild:anElevator z:GroundZ-1];
    [anElevator release];
}

-(void)createPlayerClip:(id)ground
{
    PlayerClipGround *clipGround = [[PlayerClipGround alloc] initWithWorld:[self getWorld] andDict:ground isSolid:NO];
    [self addChild:clipGround];
    [clipGround release];
}

-(void)createThingySpriteAtLocation:(CGPoint)location dynamic:(BOOL)dyn
{
    Thingy *thingy = [[Thingy alloc] initWithWorld:[self getWorld] atLocation:location startDynamic:dyn];
    [self addChild:thingy z:[thingy getThingyZCount]-1];
    [thingy release];
}

-(void)createWormholeAtLocation:(CGPoint)location withPeonCount:(int)peons
{
    Wormhole *aHole = [[Wormhole alloc] initAtLocation:location andLayer:self andPeonCount:peons world:[self getWorld]];
    [self addChild:aHole z:-500];
    [aHole release];
}

-(void)createPodAtLocation:(CGPoint)location
{
    Pod *aPod = [[Pod alloc] initWithWorld:[self getWorld] atLocation:location andLayer:self];
    [self addChild:aPod z:GroundZ-2];
    [aPod release];
}

-(void)createBridgeSpriteWithDict:(id)dict
{
    Bridge *aBridge = [[Bridge alloc] initWithDict:(id)dict andWorld:[self getWorld]];
    [self addChild:aBridge z:GroundZ-1];
    [aBridge release];
}

-(void)createForceAreaWithDict:(id)dict objectGroup:(CCTMXObjectGroup*)spriteObjects
{
    ForceArea *force = [[ForceArea alloc] initWithDict:(id)dict andWorld:[self getWorld] objectGroup:spriteObjects andParent:self];
    [self addChild:force];
    [force release];
}

-(void)createSpriteTriggerWithDict:(id)dict
{
    SpriteTrigger *trigger = [[SpriteTrigger alloc] initWithDict:dict andWorld:[self getWorld]];
    [self addChild:trigger];
    [trigger release];
}

-(void)createCompositeSpriteWithDict:(id)dict objectGroup:(CCTMXObjectGroup*)spriteObjects
{
    CompositeSprite *comp = [[CompositeSprite alloc] initWithWorld:[self getWorld] andDict:dict objectGroup:spriteObjects];
    [self addChild:comp];
    [comp release];
}

-(void)createCartPlayerAtLocation:(CGPoint)location
{CCLOG(@"Must Be Overriden");}

@end
