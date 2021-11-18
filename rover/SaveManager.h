//
//  SaveManager.h
//  rover
//
//  Created by David Campbell on 5/29/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CommonProtocols.h"
@class PlayerCart;

@interface SaveManager : NSObject
{
    NSMutableArray *savedData;
    NSManagedObjectContext *context;
}

@property (nonatomic, assign) id <cartCreationDelegate> creationDelegate;
@property(readwrite) CGPoint offset;
+(SaveManager*)sharedManager;
-(int)numberOfSavedCarts;
-(UIImage*)imageForIndex:(int)index;
-(void)loadCartAtIndex:(int)index;
-(void)saveCart:(PlayerCart*)cart andImage:(UIImage*)image;
-(void)saveCart;
-(void)loadSavedData;
-(void)releaseSavedData;
-(void)deleteCartAtIndex:(int)index;

//Progress methods
-(int)getHighestPlanetUnlocked;
-(int)getHighestLevelUnlockedForPlanet:(int)planetNum;
-(int)getPercentageScoreForPlanet:(int)planetNum Level:(int)levelNum;
-(int)getTimeScoreForPlanet:(int)planetNum Level:(int)levelNum;
-(void)addScore:(int)score forLevel:(int)levelNum onPlanet:(int)planetNum;
-(void)addTime:(int)time forLevel:(int)levelNum onPlanet:(int)planetNum;
-(void)forceLockState:(BOOL)unlocked forLevel:(int)levelNum planet:(int)planetNum;

//PlyerSettings Methods
-(void)setShowToolTipsState:(BOOL)value;
-(BOOL)getShowToolTipsState;
-(void)setShowTutorialState:(BOOL)value;
-(BOOL)getShowTutorialState;
-(void)setIsRetinaEnabled:(BOOL)value;
-(BOOL)isRetinaEnabled;
-(void)setUseTouchControl:(BOOL)value;
-(BOOL)useTouchControl;
-(void)setMusicVolume:(float)musicVolume;
-(float)getMusicVolume;
-(void)setSfxVolume:(float)sfxVolume;
-(float)getSfxVolume;

//Purchses
-(BOOL)hasBooster50Unlocked;
-(BOOL)hasMotor50Unlocked;
-(BOOL)hasAnyPurchases;
-(void)setHasBooster50Unlocked:(BOOL)value;
-(void)setHasMotor50Unlocked:(BOOL)value;

//Utility
-(int)numberOfLevelsForPlanetNumber:(int)planetNum;
-(int)numberOfPlanets;
-(CGPoint)convertToCreationSpace:(CGPoint)location;
-(CGPoint)convertToActionSpace:(CGPoint)location;
@end
