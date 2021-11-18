//
//  GameTimer.h
//  rover
//
//  Created by David Campbell on 5/20/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "GameObject.h"



@interface GameTimer : GameObject
{
    CCSprite *ticker;
    CCSprite *aura;
    CCProgressTimer *timer;

    float bestTime;
}
@property (assign) float greenTime;
@property (assign) float yellowTime;
@property (assign) float redTime;
@property (readonly) TimerStates state;
@property (readonly) ColorStates colorState;
@property (readonly) int elapsedTime;
-(int)getTimeScore;

@property (nonatomic, retain) CCAnimation *green5;
@property (nonatomic, retain) CCAnimation *green4;
@property (nonatomic, retain) CCAnimation *green3;
@property (nonatomic, retain) CCAnimation *green2;
@property (nonatomic, retain) CCAnimation *green1;
@property (nonatomic, retain) CCAnimation *green0;
@property (nonatomic, retain) CCAnimation *yellow5;
@property (nonatomic, retain) CCAnimation *yellow4;
@property (nonatomic, retain) CCAnimation *yellow3;
@property (nonatomic, retain) CCAnimation *yellow2;
@property (nonatomic, retain) CCAnimation *yellow1;
@property (nonatomic, retain) CCAnimation *yellow0;
@property (nonatomic, retain) CCAnimation *red5;
@property (nonatomic, retain) CCAnimation *red4;
@property (nonatomic, retain) CCAnimation *red3;
@property (nonatomic, retain) CCAnimation *red2;
@property (nonatomic, retain) CCAnimation *red1;
@property (nonatomic, retain) CCAnimation *red0;
@property (nonatomic, retain) CCAnimation *clear;
@property (nonatomic, retain) CCAnimation *auraGlow;

-(id)initAtLocation: (CGPoint)location withTime:(float)time;
-(void)startTimer;
-(void)resetTimer;
-(void)pauseSchedulerAndActions;
-(void)resumeSchedulerAndActions;
@end
