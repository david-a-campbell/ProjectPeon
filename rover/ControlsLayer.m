//
//  ControlsLayer.m
//  rover
//
//  Created by David Campbell on 6/29/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "ControlsLayer.h"
#import "GameManager.h"
#import "SaveManager.h"

@implementation ControlsLayer

-(id)init
{
    if (self = [super init])
    {
        joystickTouch = nil;
        buttonBecameActive = NO;
        [self setupJoystick];
        [self dissableControls];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchToCurrentMode) name: NOTIFICATION_CONTROL_TYPE_CHANGED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameWasPaused) name: NOTIFICATION_PAUSE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameWasUnPaused) name: NOTIFICATION_UNPAUSE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameWasPaused) name:NOTIFICATION_WILL_RESIGN_ACTIVE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gameWasUnPaused) name:NOTIFICATION_DID_BECOME_ACTIVE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeJoystick) name:NOTIFICATION_WILL_ROTATE object:nil];
    }
    return self;
}

-(void)enableControls
{
    [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:YES];
    [self setAccelerometerEnabled:YES];
    [self setTouchEnabled:YES];
    [self scheduleUpdate];
    controlsEnabled = YES;
    [self switchToCurrentMode];
}

-(void)dissableControls
{
    [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:NO];
    [self setAccelerometerEnabled:NO];
    [self setTouchEnabled:NO];
    [self unscheduleUpdate];
    controlsEnabled = NO;
    [self switchToCurrentMode];
}

-(void)setupJoystick
{
    joystickBase = [[SneakyJoystickSkinnedBase alloc] init];
    joystickBase.backgroundSprite = [CCSprite spriteWithSpriteFrameName:@"controlJoystick.png"];
    joystickBase.thumbSprite = [CCSprite spriteWithSpriteFrameName:@"controlButton1.png"];
    joystick = [[SneakyJoystick alloc] initWithRect:CGRectZero];
    joystickBase.joystick = joystick;
    //Do this after setting the joystick to set the radius properly
    [joystick setJoystickRadius:142.5f/2.0f-30.0f];
    [joystickBase.backgroundSprite setOpacity:0];
    [joystickBase.thumbSprite setOpacity:0];
    [joystickBase setPosition:ccp(-1024, -768)];
    
    buttonBase = [[SneakyButtonSkinnedBase alloc] init];
    buttonBase.defaultSprite = [CCSprite spriteWithSpriteFrameName:@"controlBoost1.png"];
    buttonBase.activatedSprite = [CCSprite spriteWithSpriteFrameName:@"controlBoost2.png"];
    buttonBase.pressSprite = [CCSprite spriteWithSpriteFrameName:@"controlBoost2.png"];
    button = [[SneakyButton alloc] initWithRect:CGRectMake(0, 0, 117.5, 117.5)];
    button.isToggleable = NO;
    button.isHoldable = YES;
    buttonBase.button = button;
    [buttonBase setPosition:ccp(-1024, -768)];
    [buttonBase.defaultSprite setOpacity:0];
    [buttonBase.activatedSprite setOpacity:0];
    [buttonBase.pressSprite setOpacity:0];
    
    [joystickBase.backgroundSprite setScale:SCREEN_SCALE];
    [joystickBase.thumbSprite setScale:SCREEN_SCALE];
    [buttonBase.defaultSprite setScale:SCREEN_SCALE];
    [buttonBase.activatedSprite setScale:SCREEN_SCALE];
    [buttonBase.pressSprite setScale:SCREEN_SCALE];
    
    [self addChild:buttonBase];
    [self addChild:joystickBase];
}

-(void)switchToCurrentMode
{
    currentMovement = ccp(0, 0);
    useTouch = [[SaveManager sharedManager] useTouchControl];
    
    if (controlsEnabled && useTouch)
    {
        [buttonBase.defaultSprite setOpacity:255];
        [buttonBase.activatedSprite setOpacity:255];
        [buttonBase.pressSprite setOpacity:255];
        [buttonBase setPosition:ccp(874, 150)];
    }else
    {
        [buttonBase.defaultSprite setOpacity:0];
        [buttonBase.activatedSprite setOpacity:0];
        [buttonBase.pressSprite setOpacity:0];
        [joystickBase.backgroundSprite setOpacity:0];
        [joystickBase.thumbSprite setOpacity:0];
        [buttonBase setPosition:ccp(-1024, -768)];
        [joystickBase setPosition:ccp(-1024, -768)];
    }
}

-(void)gameWasPaused
{
    if (controlsEnabled)
    {
        [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:NO];
        [self removeJoystick];
    }
}

-(void)gameWasUnPaused
{
    if (controlsEnabled && ![[GameManager sharedGameManager] isPaused])
    {
        [[[CCDirector sharedDirector] view] setMultipleTouchEnabled:YES];
    }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    if ([[GameManager sharedGameManager] isPaused]) {return;}
    if (!useTouch)
    {        
        float accelerationY = acceleration.y;
        
        UIInterfaceOrientation currentOrientation =  [[UIApplication sharedApplication] statusBarOrientation];
        if (currentOrientation == UIInterfaceOrientationLandscapeRight)
        {
            accelerationY *= -1;
        }
        
        accelerationY = accelerationY*ACCEL_MULTIPLIER;
        
        if (accelerationY < -1)
        {
            accelerationY = -1;
        } else if (accelerationY > 1)
        {
            accelerationY = 1;
        }
        
        if (accelerationY > -0.2 && accelerationY < 0.2)
        {
            //Apply dead zone
            accelerationY = 0;
        }else
        {
            //Recalculate and shift due to dead zone
            accelerationY *= 1.2;
            accelerationY = (accelerationY > 0)? accelerationY-0.2 : accelerationY+0.2;
        }
        
        currentMovement = ccp(0, accelerationY);
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    if ([[GameManager sharedGameManager] isPaused]) {return YES;}
    if (!useTouch)
    {
        [_actionLayer buttonPressBegan];
    }else
    {
        if ([joystickBase.backgroundSprite opacity] != 255)
        {
            joystickTouch = touch;
            CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
            [joystickBase setPosition:touchLocation];
            [joystickBase.backgroundSprite setOpacity:255];
            [joystickBase.thumbSprite setOpacity:255];
            [joystick ccTouchBegan:touch withEvent:event];
        }
    }
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if ([[GameManager sharedGameManager] isPaused]) {return;}
    if (useTouch)
    {
        if (touch == joystickTouch)
        {
            [joystick ccTouchMoved:touch withEvent:event];
        }
    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!useTouch)
    {
        [_actionLayer buttonPressEnded];
    }else
    {
        if (touch == joystickTouch)
        {
            [self removeJoystick];
        }
    }
}

-(void)removeJoystick
{
    [joystickBase.backgroundSprite setOpacity:0];
    [joystickBase.thumbSprite setOpacity:0];
    [joystickBase setPosition:ccp(-1024, -768)];
    [joystick ccTouchEnded:joystickTouch withEvent:nil];
    joystickTouch = nil;
}

- (void)registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:3 swallowsTouches:NO];
}

-(void)update:(ccTime)delta
{
    if ([[GameManager sharedGameManager] isPaused]){return;}
    
    if (useTouch)
    {
        if ([button active] && !buttonBecameActive)
        {
            [_actionLayer buttonPressBegan];
            buttonBecameActive = YES;
        }else if(![button active] && buttonBecameActive)
        {
            [_actionLayer buttonPressEnded];
            buttonBecameActive = NO;
        }
        currentMovement = ccp(0, joystick.velocity.x);
    }
    [_actionLayer movementDidOccur:currentMovement];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
    [joystickBase release];
    [buttonBase release];
    [joystick release];
    [button release];
    joystickBase = nil;
    buttonBase = nil;
    joystick = nil;
    button = nil;
    [super dealloc];
}
@end
