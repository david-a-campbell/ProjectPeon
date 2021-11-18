//
//  LevelSelectLayer.m
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "LevelSelectLayer.h"
#import "Constants.h"
#import "SaveManager.h"
#import "GameManager.h"

@implementation LevelSelectLayer

-(id)init
{
    if ((self = [super init]))
    {        
        int planetToLoad = [[GameManager sharedGameManager] planetToShow];
        
        hexLayer = [[LevelSelectMenu alloc] initWithPlanetNum:planetToLoad];
        [hexLayer setDelegate:self];
        parallaxNode = [CCParallaxNode node];

        [self setupParallaxLayersForPlanet:planetToLoad];
        [self addChild:parallaxNode z:0];
        [self setAccelerometerEnabled:YES];
        currentOffset = ccp(0, 0);
    }
    return self;
}

-(void)dealloc
{
    [hexLayer release];
    hexLayer = nil;
    [super dealloc];
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration 
{
    float accelerationY = -[acceleration x];
    float accelerationX = [acceleration y];
    UIInterfaceOrientation currentOrientation =  [[UIApplication sharedApplication] statusBarOrientation];
    if (currentOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        accelerationY *= -1;
        accelerationX *= -1;        
    }
    
    accelerationY *= 0.8;
    accelerationX *= 0.8;
    if (accelerationY < -1) { accelerationY = -1;}
    else if (accelerationY > 1) { accelerationY = 1;}
    
    if (accelerationX < -1) { accelerationX = -1;}
    else if (accelerationX > 1) { accelerationX = 1;}
    
    CGPoint position = ccp(originalPosition.x + accelerationX*128, originalPosition.y + accelerationY*128 -64 +AdOffset);
    currentOffset = ccp(position.x - originalPosition.x, position.y - originalPosition.y);
    [self stopAllActions];
    [self runAction:[CCMoveTo actionWithDuration:0.2 position:position]];
}

-(void)setupParallaxLayersForPlanet:(int)planetNumber
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) 
    {
        tileMapNode = [CCTMXTiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"planet%iMenuTileMap.tmx", planetNumber]];
    }
    [parallaxNode setPosition: ccp(0, 0)];
    
    for (int x = 0; x<5; x++)
    {
        CCTMXLayer* layer = [tileMapNode layerNamed:[NSString stringWithFormat:@"BehindHex%i", x]];
        if (layer != nil)
            [self setupLayer:layer];
    }

    [parallaxNode addChild:hexLayer z:5 parallaxRatio:ccp(0, 0) positionOffset:ccp(0,0)];
    
    for (int x = 0; x<5; x++)
    {
        CCTMXLayer* layer = [tileMapNode layerNamed:[NSString stringWithFormat:@"InFrontOfHex%i", x]];
        if (layer != nil)
            [self setupLayer:layer];
    }

    CCTMXObjectGroup *spriteGroup = [tileMapNode objectGroupNamed:ObjectGroupSprites];
    if (spriteGroup != nil)
    {
        [self processSpriteGroup:spriteGroup];
    }
    
    CCTMXObjectGroup *layerPlaceholderGroup = [tileMapNode objectGroupNamed:ObjectGroupLayerPlaceholder];
    if (layerPlaceholderGroup != nil)
    {
        [self processLayerPlaceholderGroup:layerPlaceholderGroup];
    }
}

-(void)planetSelected:(int)planetNum
{
    [parallaxNode removeAllChildrenWithCleanup:YES];
    [self setupParallaxLayersForPlanet:planetNum];
}

-(void)processLayerPlaceholderGroup:(CCTMXObjectGroup*)layerPlaceHolderGroup
{
    NSMutableArray *placeholderArray = [layerPlaceHolderGroup objects];
    for (id placeholder in placeholderArray)
    {
        NSString* layerFileName = [placeholder valueForKey:PlaceholderFileName];
        CCLOG(@"%@", layerFileName);
        if (layerFileName != nil && ![layerFileName isEqualToString:@""])
        {
            CCSprite *layerSprite = [CCSprite spriteWithFile:layerFileName];
            float x = [[placeholder valueForKey:@"x"] floatValue];
            float y = [[placeholder valueForKey:@"y"] floatValue];
            float height = [[placeholder valueForKey:@"height"] floatValue];
            float width = [[placeholder valueForKey:@"width"] floatValue];
            x = (x+width/2);
            y = (y+height/2);
            layerSprite.position = ccp(x,y);
            float xParallax = 1;
            float yParallax = 1;
            int zOrder = 0;
            if([placeholder valueForKey:ParallaxRatioX] != nil)
            {
                xParallax = [[placeholder valueForKey:ParallaxRatioX] floatValue];
            }
            if([placeholder valueForKey:ParallaxRatioY] != nil)
            {
                yParallax = [[placeholder valueForKey:ParallaxRatioY] floatValue];
            }
            if ([placeholder valueForKey:ZOrder] != nil)
            {
                zOrder = [[placeholder valueForKey:ZOrder] intValue];
            }
            [layerSprite setScale:2.0*(SCREEN_SCALE)];
            [parallaxNode addChild:layerSprite z:zOrder parallaxRatio:ccp(xParallax,yParallax) positionOffset:ccp(x,y)];
        }
    }
}

-(void)setupLayer:(CCTMXLayer*)layer
{
    [layer retain];
    [layer removeFromParentAndCleanup:NO];
    [layer setAnchorPoint:CGPointMake(0.0f, 0.0f)];
    
    float parallaxRatioX = 1;
    float parallaxRatioY = 1;
    int zOrder = [layer zOrder];
    
    for (NSString* propertyName in [layer properties])
    {
        if ([propertyName isEqualToString:ParallaxRatioX]) 
        {
            parallaxRatioX = [[layer propertyNamed:propertyName] floatValue];
        }else if([propertyName isEqualToString:ParallaxRatioY]) {
            parallaxRatioY = [[layer propertyNamed:propertyName] floatValue];
        }else if([propertyName isEqualToString:ZOrder]) {
            zOrder = [[layer propertyNamed:propertyName] floatValue];
        }
    }
    [parallaxNode addChild:layer z:zOrder parallaxRatio:ccp(parallaxRatioX, parallaxRatioY) positionOffset:ccp(0,0)];
    [layer setScale:2.0*(SCREEN_SCALE)];
    [layer release];
}

-(void)processSpriteGroup:(CCTMXObjectGroup*)spriteGroup
{
    NSMutableArray *spriteArray = [spriteGroup objects];
    for (id sprite in spriteArray)
    {
        float x = [[sprite valueForKey:@"x"] floatValue];
        float y = [[sprite valueForKey:@"y"] floatValue];

        if ([[sprite valueForKey:@"type"] isEqualToString:CartPlayerSprite])
        {
            originalPosition = ccp(-x,-y);
            [self setPosition: ccp(originalPosition.x+currentOffset.x, originalPosition.y+currentOffset.y)];
        }
    }
}

@end
