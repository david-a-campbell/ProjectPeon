//
//  ToolTipMenu.m
//  rover
//
//  Created by David Campbell on 6/18/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "ToolTipMenu.h"
#import "GameManager.h"
#import "SaveManager.h"
#import "CCLabelBMFont.h"
#import "PlankObject.h"

static ToolTipMenu *_currentDisplay;

@implementation ToolTipMenu

+(void)displayTipForTool:(ToolType)type
{
    if (![[SaveManager sharedManager] getShowToolTipsState])
    {
        return;
    }
    [ToolTipMenu dismissToolTip];
    _currentDisplay = [[ToolTipMenu alloc] initForToolType:type];
    CCScene *runningScene = [[CCDirector sharedDirector] runningScene];
    [runningScene addChild:_currentDisplay z:1000000];
    [_currentDisplay release];
}

+(void)displayWithMessage:(NSString *)string plankCount:(int)planks
{
    [ToolTipMenu dismissToolTip];
    _currentDisplay = [[ToolTipMenu alloc] initWithMessage:string plankCount:planks];
    CCScene *runningScene = [[CCDirector sharedDirector] runningScene];
    [runningScene addChild:_currentDisplay z:1000000];
    [_currentDisplay release];
}

+(void)dismissToolTip
{
    if (_currentDisplay)
    {
        [_currentDisplay removeFromParentAndCleanup:YES];
        _currentDisplay = nil;
    }
}

-(id)initForToolType:(ToolType)type
{
    if (self = [super init])
    {
        plankCount = 0;
        contentString = nil;
        toolType = type;
        offsetY = 50;
        commonY = 49.473f;
        isClosing = NO;
        checkState = YES;
        [self setTouchEnabled:YES];
        [self setupImagesWithCheckbox:YES];
        [self animateOpen];
    }
    return self;
}

-(id)initWithMessage:(NSString*)message plankCount:(int)planks
{
    if (self = [super init])
    {
        contentString = [message retain];
        offsetY = 0;
        commonY = 49.473f;
        isClosing = NO;
        plankCount = planks;
        [self setTouchEnabled:YES];
        [self setupImagesWithCheckbox:NO];
        [self animateOpen];
    }
    return self;
}

-(void)checkStateChange
{
    checkState = !checkState;
    [[SaveManager sharedManager] setShowToolTipsState:checkState];
}

-(void)setupImagesWithCheckbox:(BOOL)hasCheckbox
{
    [self setAnchorPoint:ccp(0.5, 0.5)];
    [self setPosition:ccp(512, 384)];
    
    top = [CCSprite spriteWithFile:@"toolTip_1.png"];
    bottom = [CCSprite spriteWithFile:@"toolTip_3.png"];
    background = [CCSprite spriteWithFile:@"darkOverlayOpaque.png"];
    backgroundBacking = [CCSprite spriteWithFile:@"darkOverlay93.png"];
    
    CCMenuItemImage *on = [CCMenuItemImage itemWithNormalImage:@"checkbox_2.png" selectedImage:@"checkbox_2.png"];
    CCMenuItemImage *off = [CCMenuItemImage itemWithNormalImage:@"checkbox_1.png" selectedImage:@"checkbox_1.png"];
    
    [top setScale:2*SCREEN_SCALE];
    [bottom setScale:2*SCREEN_SCALE];
    [background setScale:2*SCREEN_SCALE];
    [backgroundBacking setScale:2*SCREEN_SCALE];

    [top setPosition:ccp(0, 24-15 +offsetY)];
    [bottom setPosition:ccp(0, -23.5+7 +offsetY)];
    [background setPosition:ccp(0, 0)];
    [backgroundBacking setPosition:ccp(0, 0)];
    [top setOpacity:0];
    [bottom setOpacity:0];
    [background setOpacity:0];
    [backgroundBacking setOpacity:0];
    
    [self addChild:top z:1];
    [self addChild:bottom z:0];
    [self addChild:background z:-10];
    [self addChild:backgroundBacking z:-11];
    
    plankArray = [[NSMutableArray alloc] init];
    
    for (int count = 0; count < [self numberOfPlanks]; count++)
    {
        CCSprite *plank = [CCSprite spriteWithFile:@"toolTip_2.png"];
        [plank setScale:2*SCREEN_SCALE];
        [plank setPosition:ccp(0, 0)];
        [plank setOpacity:0];
        [self addChild:plank z:-1];
        
        PlankObject *plankObject = [[PlankObject alloc] init];
        [plankObject setPlank:plank];
        [plankObject setFinalPosition:ccp(0, [self plankHeightForPosition:count])];
        [plankArray addObject:plankObject];
        [plankObject release];
    }
    
    if (hasCheckbox)
    {
        checkBox = [CCMenuItemToggle itemWithTarget:self selector:@selector(checkStateChange) items:on, off, nil];
        [checkBox setScale:2*SCREEN_SCALE];
        [checkBox setOpacity:0];
        menu = [CCMenu menuWithItems:checkBox, nil];
        [menu setPosition:ccp(0, [[plankArray objectAtIndex:[plankArray count]-3] finalPosition].y)];
        [self addChild:menu z:2];
    }
}

-(void)setupContent
{
    partArray = [[NSMutableArray alloc] init];
    switch (toolType)
    {
        case toolTypeBooster:
            [self setupContentForBooster];
            break;
        case toolTypeMotor:
            [self setupContentForMotor];
            break;
        case toolTypeShock:
            [self setupContentForShock];
            break;
        case toolTypeBar:
            [self setupContentForBar];
            break;
        case toolTypeWheel:
            [self setupContentForWheel];
            break;
        case toolTypeDelete:
            [self setupContentForDelete];
            break;
        case toolTypeEdit:
            [self setupContentForEdit];
            break;
        default:
            [self setupContentForString];
            break;
    }
}

-(void)setupContentForString
{
    text = [self labelWithText:contentString];
    [text setPosition:ccp(0, offsetY)];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForBooster
{
    CCSprite *fuel = [CCSprite spriteWithFile:@"boostMeter_tip.png"];
    CCSprite *booster = [CCSprite spriteWithFile:@"createMenu_btn_booster_tip.png"];
    CCSprite *boosterUpgrade = [CCSprite spriteWithFile:@"createMenu_btn_boosterUpgrade_tip.png"];
    [fuel setPosition:[self adjustForOrigin:ccp(40, 728)]];
    [booster setPosition:[self adjustForOrigin:ccp(270, commonY)]];
    [boosterUpgrade setPosition:[self adjustForOrigin:ccp(270, 165)]];
    [fuel setScale:SCREEN_SCALE];
    [booster setScale:2*SCREEN_SCALE];
    [boosterUpgrade setScale:2*SCREEN_SCALE];
    [self addChild:fuel];
    [self addChild:booster];
    [self addChild:boosterUpgrade];
    [partArray addObject:fuel];
    [partArray addObject:booster];
    [partArray addObject:boosterUpgrade];
    
    text = [self labelWithText:@"Boosters turn your cart into a rocket cart!\n\nBooster Fuel recharges, but more rockets will burn it faster. Need more fuel? Check the store for upgrades!\n\nTo activate boosters touch anywhere while driving."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForMotor
{
    CCSprite *motor = [CCSprite spriteWithFile:@"createMenu_btn_wheel_tip.png"];
    CCSprite *motorUpgrade = [CCSprite spriteWithFile:@"createMenu_btn_wheelUpgrade_tip.png"];
    [motor setPosition:[self adjustForOrigin:ccp(372 , commonY)]];
    [motorUpgrade setPosition:[self adjustForOrigin:ccp(372, 165)]];
    [motor setScale:2*SCREEN_SCALE];
    [motorUpgrade setScale:2*SCREEN_SCALE];
    [self addChild:motor];
    [self addChild:motorUpgrade];
    [partArray addObject:motor];
    [partArray addObject:motorUpgrade];
    
    text = [self labelWithText:@"Motorized wheels are the power of your cart. They are light and float well.\n\nNeed more power? Check the store for upgrades!\n\nTilt your device to move."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForShock
{
    CCSprite *shock = [CCSprite spriteWithFile:@"createMenu_btn_shock_tip.png"];
    [shock setPosition:[self adjustForOrigin:ccp(468, commonY)]];
    [shock setScale:2*SCREEN_SCALE];
    [self addChild:shock];
    [partArray addObject:shock];
    
    text = [self labelWithText:@"Springs can be used to attach objects to other objects.\n\nSprings are extremely light and will not affect the weight of your cart."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForBar
{
    CCSprite *bar = [CCSprite spriteWithFile:@"createMenu_btn_bar_tip.png"];
    [bar setPosition:[self adjustForOrigin:ccp(568, commonY)]];
    [bar setScale:2*SCREEN_SCALE];
    [self addChild:bar];
    [partArray addObject:bar];
    
    text = [self labelWithText:@"Bars build the body of your cart. They are solid and do not float well.\n\nBars attached to one another become a solid object."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForWheel
{
    CCSprite *wheel = [CCSprite spriteWithFile:@"createMenu_btn_circle_tip.png"];
    [wheel setPosition:[self adjustForOrigin:ccp(668 , commonY)]];
    [wheel setScale:2*SCREEN_SCALE];
    [self addChild:wheel];
    [partArray addObject:wheel];
    
    text = [self labelWithText:@"Circles swivel on other objects. Circles are light and float well.\n\nUnlike wheels, circles are unpowered.\n\n"];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForDelete
{
    CCSprite *del = [CCSprite spriteWithFile:@"createMenu_btn_delete_tip.png"];
    CCSprite *delAll = [CCSprite spriteWithFile:@"createMenu_btn_deleteAll_tip.png"];
    [del setPosition:[self adjustForOrigin:ccp(876 , commonY)]];
    [delAll setPosition:[self adjustForOrigin:ccp(876, 165)]];
    [del setScale:2*SCREEN_SCALE];
    [delAll setScale:2*SCREEN_SCALE];
    [self addChild:del];
    [self addChild:delAll];
    [partArray addObject:del];
    [partArray addObject:delAll];
    
    text = [self labelWithText:@"Tap & Move your finger around the screen to accurately highlight an object to be deleted. Release to delete highlighted object.\n\nTap & Hold the delete button to reveal the Delete All option."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)setupContentForEdit
{
    CCSprite *edit = [CCSprite spriteWithFile:@"createMenu_btn_edit_tip.png"];
    [edit setPosition:[self adjustForOrigin:ccp(784 , commonY)]];
    [edit setScale:2*SCREEN_SCALE];
    [self addChild:edit];
    [partArray addObject:edit];
    
    text = [self labelWithText:@"The edit tool allows you to tap and drag parts to new locations.\n\nUse a second finger to rotate the selected part."];
    [text setPosition:ccp(0, [self textOffset])];
    [text setScale:SCREEN_SCALE];
    [self addChild:text z:2];
}

-(void)animateOpen
{
    CGPoint topPosition = ccp(0, [[plankArray objectAtIndex:0] finalPosition].y +9+24-15);
    CGPoint bottomPosition = ccp(0, [[plankArray objectAtIndex:[plankArray count]-1] finalPosition].y -9-23.5+7);
    
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:255];
    CCFadeTo *fadePlanks = [CCFadeTo actionWithDuration:0.4 opacity:255];
    CCFadeTo *backGroundFade = [CCFadeTo actionWithDuration:0.2 opacity:100];
    CCFadeTo *backBackFade = [CCFadeTo actionWithDuration:0.2 opacity:200];
    
    id topSequence = [CCSequence actions:[[fade copy] autorelease], [CCMoveTo actionWithDuration:0.2 position:topPosition], nil];
    [top runAction:topSequence];
    
    id bottomSequence = [CCSequence actions:[[fade copy] autorelease], [CCMoveTo actionWithDuration:0.2 position:bottomPosition], nil];
    [bottom runAction:bottomSequence];
    
    [background runAction:backGroundFade];
    [backgroundBacking runAction:backBackFade];
    
    for (PlankObject *plankObject in plankArray)
    {
        CGPoint final = [plankObject finalPosition];
        id spawn = [CCSpawn actions:[[fadePlanks copy] autorelease], [CCMoveTo actionWithDuration:0.2 position:final], nil];
        id sequence = [CCSequence actions:[CCDelayTime actionWithDuration:0.2], spawn, nil];
        [plankObject runAction:sequence];
    }

    [checkBox runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.3], [CCFadeTo actionWithDuration:0.1 opacity:255], nil]];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.4], [CCCallFunc actionWithTarget:self selector:@selector(changeMenuPriority)], [CCCallFunc actionWithTarget:self selector:@selector(setupContent)], nil]];
}

-(void)animateClosed
{
    isClosing = YES;
    CCFadeTo *fade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    CCFadeTo *backGroundFade = [CCFadeTo actionWithDuration:0.2 opacity:0];
    for (CCSprite *sprite in partArray)
    {
        [sprite runAction:[[fade copy] autorelease]];
    }
    for (PlankObject *plankObject in plankArray)
    {
        [plankObject runAction:[[fade copy] autorelease]];
    }
    
    id sequence = [CCSequence actions:backGroundFade,[CCCallFunc actionWithTarget:[ToolTipMenu class] selector:@selector(dismissToolTip)], nil];
    [top runAction:fade];
    [text runAction:[[fade copy] autorelease]];
    [bottom runAction:[[fade copy] autorelease]];
    [checkBox runAction:[[fade copy] autorelease]];
    [background runAction:sequence];
    [backgroundBacking runAction:[[fade copy] autorelease]];
}

-(int)numberOfPlanks
{
    if (plankCount)
    {
        return plankCount;
    }
    
    int numberOfPlanks = 15;
    switch (toolType)
    {
        case toolTypeBooster:
            numberOfPlanks = 18;
            break;
        case toolTypeMotor:
            numberOfPlanks = 16;
            break;
        case toolTypeShock:
            numberOfPlanks = 14;
            break;
        case toolTypeBar:
            numberOfPlanks = 14;
            break;
        case toolTypeWheel:
            numberOfPlanks = 14;
            break;
        case toolTypeDelete:
            numberOfPlanks = 17;
            break;
        default:
            break;
    }
    return numberOfPlanks;
}

-(float)textOffset
{
    return fabs((top.position.y) - (menu.position.y))/2.0f + (menu.position.y) + 7;
}

-(float)plankHeightForPosition:(int)position
{
    float height = -1 * (position*18 + 9);
    height = height+(18*[self numberOfPlanks])/2.0f;
    return height +offsetY;
}

-(float)getMenuHeight
{
    return ccpDistance([top position], [bottom position]) + 48;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    CGRect boundingBox = CGRectMake(0, 0, 623, [self getMenuHeight]);
    touchLocation = ccp(touchLocation.x + 623/2.0f, touchLocation.y + [self getMenuHeight]/2.0f);
    
    if (!isClosing)
    {
        if(!CGRectContainsPoint(boundingBox, touchLocation))
        {
            [self animateClosed];
        }
    }
    //Must return yes to swallow touches
    return YES;
}

- (void)registerWithTouchDispatcher
{
    //Must have negative priority to block ccmenuItems behind
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-2000 swallowsTouches:YES];
}

-(void)changeMenuPriority
{
    [menu setHandlerPriority:-2001];
}

-(CGPoint)adjustForOrigin:(CGPoint)point
{
    return ccp(point.x -512, point.y -384);
}

-(id)labelWithText:(NSString*)someText
{
    float factor = 4*SCREEN_SCALE;
    if (SCREEN_SCALE == 1)
    {
        factor = 1;
    }
    return [CCLabelBMFont labelWithString:someText fntFile:@"font42.fnt" width:500*factor alignment:kCCTextAlignmentLeft];
}

-(void)dealloc
{
    if (contentString)
    {
        [contentString release];
        contentString = nil;
    }
    [partArray release];
    partArray = nil;
    [plankArray release];
    plankArray = nil;
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    [super dealloc];
}

@end
