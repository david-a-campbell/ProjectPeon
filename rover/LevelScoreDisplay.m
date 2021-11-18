//
//  LevelScoreDisplay.m
//  rover
//
//  Created by David Campbell on 7/24/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "LevelScoreDisplay.h"
#import "Constants.h"
#import "SaveManager.h"
#import "GameManager.h"

@implementation LevelScoreDisplay
@synthesize delegate;
-(id)init
{
    if ((self = [super init]))
    {
        [self setupImages];
    }
    return self;
}

-(void)dealloc
{
    [scoreLabel release];
    scoreLabel = nil;
    [timeLabel release];
    timeLabel = nil;
    [peonLabel release];
    peonLabel = nil;
    [bestTimeText release];
    bestTimeText = nil;
    [bestTimeLabel release];
    bestTimeLabel = nil;
    [super dealloc];
}

-(void)setupImages
{
    body = [CCMenuItemImage itemWithNormalImage:@"stageEnd_body.png" selectedImage:nil];
    [body setScale:2*SCREEN_SCALE];
    [body setAnchorPoint:ccp(0, 0)];
    [body setIsEnabled:NO];
    
    leftPanelTop = [CCSprite spriteWithSpriteFrameName:@"stageEnd_1.png"];
    leftPanelBottom = [CCSprite spriteWithSpriteFrameName:@"stageEnd_2.png"];
    [leftPanelTop setPosition:ccp(-37, 256)];
    [leftPanelBottom setPosition:ccp(-120, 256)];
    
    [leftPanelTop setScale:2*SCREEN_SCALE];
    [leftPanelBottom setScale:2*SCREEN_SCALE];
    
    CCSprite *nextLvl =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_next_1.png"];
    CCSprite *nextLvlSel =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_next_2.png"];
    CCSprite *planet =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_planet_1.png"];
    CCSprite *planetSel =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_planet_2.png"];
    CCSprite *replay =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_replay_1.png"];
    CCSprite *replaySel =  [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_replay_2.png"];
    CCSprite *video = [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_video_1.png"];
    CCSprite *videoSel = [CCSprite spriteWithSpriteFrameName:@"stageEnd_btn_video_2.png"];
    
    nextLevelBtn = [CCMenuItemSprite itemWithNormalSprite:nextLvl selectedSprite:nextLvlSel target:self selector:@selector(goToNextLevel)];
    planetSelectBtn = [CCMenuItemSprite itemWithNormalSprite:planet selectedSprite:planetSel target:self selector:@selector(goToPlanetSelect)];
    replayBtn = [CCMenuItemSprite itemWithNormalSprite:replay selectedSprite:replaySel target:self selector:@selector(replayLevel)];
    videoBtn = [CCMenuItemSprite itemWithNormalSprite:video selectedSprite:videoSel target:self selector:@selector(showVideoMenu)];
    
    [videoBtn setPosition:ccp(151, 52)];
    [nextLevelBtn setPosition:ccp(417+127, 52)];
    [planetSelectBtn setPosition:ccp(151+127, 52)];
    [replayBtn setPosition:ccp(284+127, 52)];
    [videoBtn setScale:2*SCREEN_SCALE];
    [nextLevelBtn setScale:2*SCREEN_SCALE];
    [planetSelectBtn setScale:2*SCREEN_SCALE];
    [replayBtn setScale:2*SCREEN_SCALE];
    
    scoreMenu = [CCMenu menuWithItems:videoBtn, nextLevelBtn, planetSelectBtn, replayBtn, nil];
    
    [scoreMenu addChild:body z:-10];
    [scoreMenu setAnchorPoint:ccp(0, 0)];
    [scoreMenu setPosition:ccp(-871, 151.5)];
    
    [self addChild:scoreMenu z:0];
    [self addChild:leftPanelBottom z:1];
    [self addChild:leftPanelTop z:3];
    
    peon = [CCSprite spriteWithSpriteFrameName:@"stageEnd_score_peon.png"];
    [peon setPosition:ccp((614+127)/(2*SCREEN_SCALE), 104.5/(2*SCREEN_SCALE))];
    [body addChild:peon];
    
    CCTexture2DPixelFormat currentFormat = [CCTexture2D defaultAlphaPixelFormat];
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA4444];
    scoreLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font110.fnt"] retain];
    timeLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font42.fnt"] retain];
    peonLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font42.fnt"] retain];
    bestTimeLabel = [[CCLabelBMFont labelWithString:@"" fntFile:@"font42.fnt"] retain];
    bestTimeText = [[CCLabelBMFont labelWithString:@"BEST" fntFile:@"font42.fnt"] retain];
    [scoreLabel setPosition:ccp((614+127)/(2*SCREEN_SCALE), 104.5/(2*SCREEN_SCALE))];
    [timeLabel setPosition:ccp(411/(2*SCREEN_SCALE), 169/(2*SCREEN_SCALE))];
    [peonLabel setPosition:ccp(218/(2*SCREEN_SCALE), 169/(2*SCREEN_SCALE))];
    [bestTimeLabel setPosition:ccp(418/(2*SCREEN_SCALE), 135/(2*SCREEN_SCALE))];
    [bestTimeText setPosition:ccp(349/(2*SCREEN_SCALE), 135/(2*SCREEN_SCALE))];
    [body addChild:scoreLabel];
    [body addChild:timeLabel];
    [body addChild:peonLabel];
    [body addChild:bestTimeLabel];
    [body addChild:bestTimeText];
    [scoreLabel setScale:0.5];
    [peonLabel setScale:0.5];
    [timeLabel setScale:0.5];
    [bestTimeLabel setScale:0.5*0.714];
    [bestTimeText setScale:0.5*0.714];
    [CCTexture2D setDefaultAlphaPixelFormat:currentFormat];  
}

-(void)showScore:(int)score peonCount:(int)pC totalPeons:(int)tP timerColor:(ColorStates)colorState tmerState:(TimerStates)tS timeElapsed:(int)time
{
    timerColor = colorState;
    timerState = tS;
    playerScore = score;
    peonCount = pC;
    totalPeons = tP;
    timeElapsed = time;
    int bestTime = [[SaveManager sharedManager] getTimeScoreForPlanet:[[GameManager sharedGameManager] currentPlanetNum] Level:[[GameManager sharedGameManager] currentLevelNum]];

    if (bestTime > timeElapsed || bestTime == 0)
    {
        bestTime = timeElapsed;
    }
    
    CCLOG(@"%i", bestTime);
    
    if (scoreHex != nil) {
        [scoreHex removeFromParentAndCleanup:YES];
    }

    if (playerScore >= 100)
    {
        scoreHex = [CCSprite spriteWithSpriteFrameName:@"stageEnd_score_ace.png"];
    }else if (playerScore >= 50)
    {
        scoreHex = [CCSprite spriteWithSpriteFrameName:@"stageEnd_score_pass.png"];
    }else {
        scoreHex = [CCSprite spriteWithSpriteFrameName:@"stageEnd_score_fail.png"];
    }
    [scoreHex setPosition:ccp((614+127)/(2*SCREEN_SCALE), 104.5/(2*SCREEN_SCALE))];
    [body addChild:scoreHex z:-1];
    
    if (peonCount == totalPeons)
    {
        [peon setOpacity:255];
    }else {
        [peon setOpacity:0];
    }
    
    int mins = (float)timeElapsed/60.0;
    int secs = timeElapsed-(mins*60);
    secs = mins > 100 ? 99:secs;
    NSString *secsString = secs>9?[NSString stringWithFormat:@"%i", secs] : [NSString stringWithFormat:@"%i%i", 0, secs];
    mins = mins > 99 ? 99:mins;    
    NSString *minsString = mins>9?[NSString stringWithFormat:@"%i", secs] : [NSString stringWithFormat:@"%i%i", 0, mins];
    
    int minsb = (float)bestTime/60.0;
    int secsb = bestTime-(minsb*60);
    secsb = minsb > 100 ? 99:secsb;
    NSString *secsStringb = secsb>9?[NSString stringWithFormat:@"%i", secsb] : [NSString stringWithFormat:@"%i%i", 0, secsb];
    minsb = minsb > 99 ? 99:minsb;    
    NSString *minsStringb = minsb>9?[NSString stringWithFormat:@"%i", secsb] : [NSString stringWithFormat:@"%i%i", 0, minsb];
    
    [scoreLabel setString:[NSString stringWithFormat:@"%i%%", playerScore]];
    [timeLabel setString:[NSString stringWithFormat:@"%@:%@", minsString, secsString]];
    [bestTimeLabel setString:[NSString stringWithFormat:@"%@:%@", minsStringb, secsStringb]];
    [peonLabel setString:[NSString stringWithFormat:@"%i/%i", peonCount, totalPeons]];
    
    [self setupTimerImage];
    [scoreMenu setTouchEnabled:NO];
    [nextLevelBtn setOpacity:0];
    [nextLevelBtn setIsEnabled:NO];
    [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:8], [CCCallFunc actionWithTarget:self selector:@selector(slideMenuIn)],nil]];
}

-(void)setupTimerImage
{
    if (timerImage != nil){
        [timerImage removeFromParentAndCleanup:YES];
    }
    NSString *colorStr = @"blank.png";
    NSString *stateStr = @"";
    NSString *clockEnd = @"clockEnd_";
    
    switch (timerState)
    {
        case kState5Fade:
            stateStr = @"5.png";
            break;
        case kState4Fade:
            stateStr = @"4.png";
            break;
        case kState3Fade:
            stateStr = @"3.png";
            break;
        case kState2Fade:
            stateStr = @"2.png";
            break;
        case kState1Fade:
            stateStr = @"1.png";
        default:
            break;
    }
    
    switch (timerColor) 
    {
        case kStateRed:
            colorStr = @"red_";
            break;
        case kStateGreen:
            colorStr = @"green_";
            break;
        case kStateYellow:
            colorStr = @"yellow_";
            break;
        case kStateClear:
            colorStr = @"blank.png";
            stateStr = @"";
            break;
        default:
            break;
    }
    NSString *fileName = [NSString stringWithFormat:@"%@%@%@", clockEnd, colorStr, stateStr];
    timerImage = [CCSprite spriteWithSpriteFrameName:fileName];
    [timerImage setPosition:ccp(333.5/(2*SCREEN_SCALE), 169/(2*SCREEN_SCALE))];
    [body addChild:timerImage];
}

-(void)slideMenuIn
{
    id leftTopMove = [CCMoveTo actionWithDuration:0.5 position:ccp(32, 256)];
    id moveEffectTop = [CCEaseOut actionWithAction:leftTopMove rate:10.0f];
    id leftBottomMove = [CCMoveTo actionWithDuration:0.5 position:ccp(115, 256)];
    id moveEffectBottom = [CCEaseOut actionWithAction:leftBottomMove rate:10.0f];
    id bodyMove = [CCMoveTo actionWithDuration:0.3 position:ccp(76, 151.5)];
    id moveEffectBody = [CCEaseOut actionWithAction:bodyMove rate:10.0f];
    
    [leftPanelTop runAction:moveEffectTop];
    [leftPanelBottom runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.3], moveEffectBottom, nil]];
    [scoreMenu runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.6], moveEffectBody, [CCCallFunc actionWithTarget:self selector:@selector(saveData)], nil]];
}

-(void)slideMenuOut
{
    id leftTopMove = [CCMoveTo actionWithDuration:0.5 position:ccp(-37, 256)];
    id moveEffectTop = [CCEaseIn actionWithAction:leftTopMove rate:10.0f];
    id leftBottomMove = [CCMoveTo actionWithDuration:0.5 position:ccp(-120, 256)];
    id moveEffectBottom = [CCEaseIn actionWithAction:leftBottomMove rate:10.0f];
    id bodyMove = [CCMoveTo actionWithDuration:0.5 position:ccp(-871, 151.5)];
    id moveEffectBody = [CCEaseIn actionWithAction:bodyMove rate:10.0f];
    
    [scoreMenu runAction:moveEffectBody];
    [leftPanelBottom runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.3], moveEffectBottom, nil]];
    [leftPanelTop runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.6], moveEffectTop, nil]];

}

-(void)showVideoMenu
{

}

-(void)saveData
{
    [[GameManager sharedGameManager] playSoundEffect:@"score.mp3"];
    [[SaveManager sharedManager] addScore:playerScore forLevel:[[GameManager sharedGameManager] currentLevelNum] onPlanet:[[GameManager sharedGameManager] currentPlanetNum]];
    [[SaveManager sharedManager] addTime:timeElapsed forLevel:[[GameManager sharedGameManager] currentLevelNum] onPlanet:[[GameManager sharedGameManager] currentPlanetNum]];
    
    [self presentNextLevelButton];
    [scoreMenu setTouchEnabled:YES];
}

-(void)goToNextLevel
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [scoreMenu setTouchEnabled:NO];
    [self slideMenuOut];
    [nextLevelBtn runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(loadNextLevel)],nil]];
}

-(void)loadNextLevel
{
    int thisPlanet = [[GameManager sharedGameManager] currentPlanetNum];
    int thisLevel = [[GameManager sharedGameManager] currentLevelNum];
    if (thisLevel >= [[SaveManager sharedManager] numberOfLevelsForPlanetNumber:thisPlanet])
    {
        [self returnToPlanetSelect];
    }else
    {
        [[GameManager sharedGameManager] runPlanet:thisPlanet level:thisLevel+1];
        [[GameManager sharedGameManager] setCurrentPlanetNum:thisPlanet];
        [[GameManager sharedGameManager] setCurrentLevelNum:thisLevel+1];
    }
}

-(void)presentNextLevelButton
{
    int thisPlanet = [[GameManager sharedGameManager] currentPlanetNum];
    int thisLevel = [[GameManager sharedGameManager] currentLevelNum];
    BOOL presentButton = NO;
    
    if (thisLevel < [[SaveManager sharedManager] numberOfLevelsForPlanetNumber:thisPlanet])
    {
        int highestLevelUnlocked = [[SaveManager sharedManager] getHighestLevelUnlockedForPlanet:thisPlanet];
        presentButton = (highestLevelUnlocked>thisLevel);
    }else
    {
        int highestPlanetUnlocked = [[SaveManager sharedManager] getHighestPlanetUnlocked];
        presentButton = (highestPlanetUnlocked>thisPlanet);
    }
    
    if (presentButton)
    {
        [nextLevelBtn runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.5f], [CCFadeTo actionWithDuration:1.0f opacity:255],nil]];
        [nextLevelBtn setIsEnabled:YES];
    }
}

-(void)goToPlanetSelect
{
    [[GameManager sharedGameManager] playSoundEffect:@"levelSelect.mp3"];
    [scoreMenu setTouchEnabled:NO];
    [self slideMenuOut];
    [[GameManager sharedGameManager] setLoadCurrentPlanetByDefault:YES];
    [planetSelectBtn runAction:[CCSequence actions:[CCDelayTime actionWithDuration:1.5], [CCCallFunc actionWithTarget:self selector:@selector(returnToPlanetSelect)],nil]];
}

-(void)returnToPlanetSelect
{
    [[GameManager sharedGameManager] runSceneWithName:MainMenuSceneID];
}

-(void)replayLevel
{
    [scoreMenu setTouchEnabled:NO];
    [self slideMenuOut];
    [delegate replayLevelSelected];
}

-(void)visit
{
    [super visit];
}

@end
