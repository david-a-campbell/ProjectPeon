//
//  GameTimer.m
//  rover
//
//  Created by David Campbell on 5/20/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "GameTimer.h"

@implementation GameTimer
@synthesize greenTime, yellowTime, redTime, colorState;
@synthesize green5, green4, green3, green2, green1, green0, yellow5, yellow4, yellow3, yellow2, yellow1, yellow0, red5, red4, red3, red2, red1, red0, clear, auraGlow, state, elapsedTime;
-(void)dealloc
{
    [ticker release];
    [aura release];
    [timer release];
    timer = nil;
    aura = nil;
    ticker = nil;
    
    [self setGreen0:nil];
    [self setGreen1:nil];
    [self setGreen2:nil];
    [self setGreen3:nil];
    [self setGreen4:nil];
    [self setGreen5:nil];
    [self setYellow0:nil];
    [self setYellow1:nil];
    [self setYellow2:nil];
    [self setYellow3:nil];
    [self setYellow4:nil];
    [self setYellow5:nil];
    [self setRed0:nil];
    [self setRed1:nil];
    [self setRed2:nil];
    [self setRed3:nil];
    [self setRed4:nil];
    [self setRed5:nil];
    [self setClear:nil];
    [self setAuraGlow:nil];
    [super dealloc];
}

-(id)initAtLocation: (CGPoint)location withTime:(float)time
{
    if ((self = [super init]))
    {
        bestTime = time;
        [self setupImages];
        [self setPosition:location]; 
        [self initAnimations];
        timer = [[CCProgressTimer alloc] init];
        [self addChild:timer];
        [self setGreenTime:bestTime*0.40];
        [self setYellowTime:bestTime*0.40];
        [self setRedTime:bestTime*0.20];
        [self scheduleUpdate];
        state = kStateStopped;
        colorState = kStateGreen;
        [self setOpacity:0];
    }
    return self;
}

-(void)setupImages
{
    [self setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"clock_frame.png"]];
    ticker = [[CCSprite alloc] init];
    aura = [[CCSprite alloc] init];
    
    [ticker setPosition:ccp([self boundingBox].size.width/2, [self boundingBox].size.width/2)];
    [aura setPosition:ccp([self boundingBox].size.width/2, [self boundingBox].size.width/2)];
    [self addChild:ticker];
    [self addChild:aura z:-1];

    [ticker setOpacity:0];
    [aura setOpacity:0];
    [self setScale:SCREEN_SCALE];
}

-(void)initAnimations
{
    [self setGreen5:[self loadPlistForAnimationWithName:@"green5" andClassName:NSStringFromClass([self class])]];
    [self setGreen4:[self loadPlistForAnimationWithName:@"green4" andClassName:NSStringFromClass([self class])]];
    [self setGreen3:[self loadPlistForAnimationWithName:@"green3" andClassName:NSStringFromClass([self class])]];
    [self setGreen2:[self loadPlistForAnimationWithName:@"green2" andClassName:NSStringFromClass([self class])]];
    [self setGreen1:[self loadPlistForAnimationWithName:@"green1" andClassName:NSStringFromClass([self class])]];
    [self setGreen0:[self loadPlistForAnimationWithName:@"green0" andClassName:NSStringFromClass([self class])]];
    
    [self setYellow5:[self loadPlistForAnimationWithName:@"yellow5" andClassName:NSStringFromClass([self class])]];
    [self setYellow4:[self loadPlistForAnimationWithName:@"yellow4" andClassName:NSStringFromClass([self class])]];
    [self setYellow3:[self loadPlistForAnimationWithName:@"yellow3" andClassName:NSStringFromClass([self class])]];
    [self setYellow2:[self loadPlistForAnimationWithName:@"yellow2" andClassName:NSStringFromClass([self class])]];
    [self setYellow1:[self loadPlistForAnimationWithName:@"yellow1" andClassName:NSStringFromClass([self class])]];
    [self setYellow0:[self loadPlistForAnimationWithName:@"yellow0" andClassName:NSStringFromClass([self class])]];
    
    [self setRed5:[self loadPlistForAnimationWithName:@"red5" andClassName:NSStringFromClass([self class])]];
    [self setRed4:[self loadPlistForAnimationWithName:@"red4" andClassName:NSStringFromClass([self class])]];
    [self setRed3:[self loadPlistForAnimationWithName:@"red3" andClassName:NSStringFromClass([self class])]];
    [self setRed2:[self loadPlistForAnimationWithName:@"red2" andClassName:NSStringFromClass([self class])]];
    [self setRed1:[self loadPlistForAnimationWithName:@"red1" andClassName:NSStringFromClass([self class])]];
    [self setRed0:[self loadPlistForAnimationWithName:@"red0" andClassName:NSStringFromClass([self class])]];
    
    [self setAuraGlow:[self loadPlistForAnimationWithName:@"auraGlow" andClassName:NSStringFromClass([self class])]];
    [self setClear:[self loadPlistForAnimationWithName:@"clear" andClassName:NSStringFromClass([self class])]];
}

-(void)update:(ccTime)dt
{
    if(state == kStateStopped || colorState == kStateClear)
    {
        return;
    }
    
    float percentage = [timer percentage];
    
    if (percentage > 4)
    {
        [self changeTimerState:kState5Fade];
    }else if(percentage > 3)
    {
        [self changeTimerState:kState4Fade];
    }else if(percentage > 2)
    {
        [self changeTimerState:kState3Fade];
    }else if(percentage > 1)
    {
        [self changeTimerState:kState2Fade];
    }else if(percentage > 0)
    {
        [self changeTimerState:kState1Fade];
    }/*else {
        [self changeTimerState:kState0Fade];
    }*/
}

-(void)changeTimerState:(TimerStates)newState
{
    if (state == newState)
    {
        return;
    }
    state = newState;
    [ticker stopAllActions];
    //[ticker runAction:[CCFadeOut actionWithDuration:1.0f]];
    switch (colorState)
    {
        case kStateGreen:
            switch (newState)
            {
                case kState5Fade:
                {
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green5]]];
                }
                    break;
                case kState4Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green4]]];
                    break;
                case kState3Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green3]]];
                    break;
                case kState2Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green2]]];
                    break;
                case kState1Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green1]]];
                    break;
                case kState0Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:green0]]];
                    break;
                default:
                    break;
            }
            break;
        case kStateYellow:
            switch (newState)
            {
                case kState5Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow5]]];
                    break;
                case kState4Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow4]]];
                    break;
                case kState3Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow3]]];
                    break;
                case kState2Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow2]]];
                    break;
                case kState1Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow1]]];
                    break;
                case kState0Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:yellow0]]];
                    break;
                default:
                    break;
            }
            break;
        case kStateRed:
            switch (newState)
            {
                case kState5Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red5]]];
                    break;
                case kState4Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red4]]];
                    break;
                case kState3Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red3]]];
                    break;
                case kState2Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red2]]];
                    break;
                case kState1Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red1]]];
                    break;
                case kState0Fade:
                    [ticker runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:red0]]];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

-(void)endFadeInTimer
{
    [self makeTickerGreen];
    state = kStateReadyToGo;
    [ticker setOpacity:255];
    CCProgressFromTo *phase1 = [CCProgressFromTo actionWithDuration:greenTime from:5 to:0];
    CCProgressFromTo *phase2 = [CCProgressFromTo actionWithDuration:yellowTime from:5 to:0];
    CCProgressFromTo *phase3 = [CCProgressFromTo actionWithDuration:redTime from:5 to:0];
    
    CCCallFunc *turnRed = [CCCallFunc actionWithTarget:self selector:@selector(makeTickerRed)];
    CCCallFunc *turnYellow = [CCCallFunc actionWithTarget:self selector:@selector(makeTickerYellow)]; 
    CCCallFunc *turnClear = [CCCallFunc actionWithTarget:self selector:@selector(makeTickerClear)];  
    id sequence = [CCSequence actions:phase1, turnYellow, phase2, turnRed ,phase3, turnClear, nil];
    [timer runAction: sequence];
    elapsedTime = 0;
    [self schedule:@selector(timerUpdate) interval:1.0];
}

-(void)timerUpdate
{
    elapsedTime++;
    if (elapsedTime >= 7000)
    {
        elapsedTime = 7000;
    }
}

-(void)startTimer
{
    CCCallFunc *func = [CCCallFunc actionWithTarget:self selector:@selector(endFadeInTimer)];
    CCFadeTo *fade = [CCFadeTo actionWithDuration:1 opacity:255];
    id sequence = [CCSequence actions:fade, func, nil];
    [self runAction:sequence];
}

-(void)resetTimer
{
    state = kStateStopped;
    [self stopAllActions];
    [timer stopAllActions];
    [self unschedule:@selector(timerUpdate)];
    [aura stopAllActions];
    [ticker stopAllActions];
    [self setOpacity:0];
    [ticker setOpacity:0];
    [aura setOpacity:0];
}
-(void)makeTickerClear
{
    [ticker stopAllActions];
    colorState = kStateClear;
    [ticker runAction:[CCAnimate actionWithAnimation:clear]];

    [aura runAction:[CCAnimate actionWithAnimation:auraGlow]];
    CCFadeTo *fadeIn = [CCFadeTo actionWithDuration:0.7 opacity:70];
    CCFadeTo *fadeOut = [CCFadeTo actionWithDuration:0.7 opacity:230];
    CCSequence *pulseSequence = [CCSequence actionOne:fadeIn two:fadeOut];
    CCRepeatForever *repeat = [CCRepeatForever actionWithAction:pulseSequence];
    [aura runAction:repeat];

}

-(void)makeTickerRed
{
    colorState = kStateRed;
}

-(void)makeTickerYellow
{
    colorState = kStateYellow;
}

-(void)makeTickerGreen
{
    colorState = kStateGreen;
}

-(void)pauseSchedulerAndActions
{
    [timer pauseSchedulerAndActions];
    [super pauseSchedulerAndActions];
}

-(void)resumeSchedulerAndActions
{
    [timer resumeSchedulerAndActions];
    [super resumeSchedulerAndActions];
}

-(int)getTimeScore
{
    int timeScore = 0;
    switch (colorState) {
        case kStateGreen:
            {
                timeScore = 100;
            }
            break;
        case kStateYellow:
            {
                timeScore = 74 + ([timer percentage]/5)*25;
            }
            break;
        case kStateRed:
            {
                timeScore = 50 + ([timer percentage]/5)*24;                
            }
            break;
        case kStateClear:
            {
                timeScore = 49;
            }
            break;
        default:
            break;
    }
    return timeScore;
}

@end
