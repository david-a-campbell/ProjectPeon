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
#ifdef PROJECTPEON_MAC
#import "PeonMac.h"
#import "PeonViewport.h"
#endif

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
#ifdef PROJECTPEON_MAC
        [self scheduleUpdate];
#else
        [self setAccelerometerEnabled:YES];
#endif
        currentOffset = ccp(0, 0);
    }
    return self;
}

#ifdef PROJECTPEON_MAC
-(BOOL)parallaxMousePosition:(CGPoint *)position
{
    NSView *view = (NSView *)[[CCDirector sharedDirector] view];
    NSWindow *window = view.window;
    if (!window.isKeyWindow) return NO;
    NSPoint point = [view convertPoint:window.mouseLocationOutsideOfEventStream fromView:nil];
    if (!CGRectContainsPoint(PeonGameViewport(view.bounds, [[CCDirector sharedDirector] winSize]), point)) return NO;
    *position = [[CCDirector sharedDirector] convertToGL:point];
    return YES;
}

-(void)update:(ccTime)dt
{
    BOOL popupVisible = NO;
    for (CCNode *node in [[CCDirector sharedDirector] runningScene].children)
        if ([node isKindOfClass:[PopupMenu class]]) popupVisible = YES;
    CGFloat x = 0, y = 0;
    if (!popupVisible) {
        x = (PeonKeyDown(2) || PeonKeyDown(124)) - (PeonKeyDown(0) || PeonKeyDown(123));
        y = (PeonKeyDown(13) || PeonKeyDown(126)) - (PeonKeyDown(1) || PeonKeyDown(125));
    }
    if (x || y) {
        parallaxTarget.x = MAX(-64, MIN(64, parallaxTarget.x + x*100*dt));
        parallaxTarget.y = MAX(-48, MIN(48, parallaxTarget.y + y*100*dt));
    } else {
        CGPoint mouse;
        CGSize size = [[CCDirector sharedDirector] winSize];
        if (!popupVisible && [self parallaxMousePosition:&mouse]) {
            parallaxTarget = ccp((mouse.x / size.width * 2 - 1) * 64,
                                 (mouse.y / size.height * 2 - 1) * 48);
            parallaxTarget.x = MAX(-64, MIN(64, parallaxTarget.x));
            parallaxTarget.y = MAX(-48, MIN(48, parallaxTarget.y));
        } else {
            parallaxTarget = CGPointZero;
        }
    }
    CGFloat blend = 1 - expf(-10*dt);
    parallaxNode.position = ccpAdd(parallaxNode.position, ccpMult(ccpSub(parallaxTarget, parallaxNode.position), blend));
}
#endif

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
    // Both device families use the original game maps.
    {
#ifdef PROJECTPEON_MAC
        tileMapNode = [CCTMXTiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"planet%iMenuWide.tmx", planetNumber]];
#else
        tileMapNode = [CCTMXTiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"planet%iMenuTileMap.tmx", planetNumber]];
#endif
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
    [parallaxNode addChild:layer z:zOrder parallaxRatio:ccp(parallaxRatioX, parallaxRatioY) positionOffset:
#ifdef PROJECTPEON_MAC
     ccp(-512,0)
#else
     ccp(0,0)
#endif
     ];
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
