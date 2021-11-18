//
//  LevelScoreDisplay.h
//  rover
//
//  Created by David Campbell on 7/24/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "CommonProtocols.h"

@protocol scoreDisplayDelegate
-(void)replayLevelSelected;
@end

@interface LevelScoreDisplay : CCLayer
{
    int playerScore;
    int peonCount;
    int totalPeons;
    int timeElapsed;
    ColorStates timerColor;
    TimerStates timerState;
    
    CCLabelAtlas *scoreLabel;
    CCLabelAtlas *timeLabel;
    CCLabelAtlas *peonLabel;
    CCLabelAtlas *bestTimeLabel;
    CCLabelAtlas *bestTimeText;
    
    CCMenu *scoreMenu;
    CCMenuItemImage *body;
    CCSprite *scoreHex;
    CCSprite *leftPanelTop;
    CCSprite *leftPanelBottom;
    CCSprite *peon;
    CCSprite *timerImage;
    CCMenuItemSprite *nextLevelBtn;
    CCMenuItemSprite *planetSelectBtn;
    CCMenuItemSprite *replayBtn;
    CCMenuItemSprite *videoBtn;
}

-(void)showScore:(int)score peonCount:(int)pC totalPeons:(int)tP timerColor:(ColorStates)colorState tmerState:(TimerStates)tS timeElapsed:(int)time;

@property (nonatomic, assign) id<scoreDisplayDelegate> delegate;

@end
