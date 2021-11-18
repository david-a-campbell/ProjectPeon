//
//  CartCreationLayer.h
//  rover
//
//  Created by David Campbell on 3/6/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "Constants.h"
#import "CommonProtocols.h"
#import "SaveMenu.h"
#import "LevelScoreDisplay.h"
#import "popupMenuDelegate.h"

@class GameTimer;
@class FuelGauge;
@class ShockImageSet;

@interface CartCreationLayer : CCLayer <popupMenuDelegate, saveMenuDelegate, scoreDisplayDelegate>
{
    BOOL cartCreationEnabled;
    ToolType selectedTool;
    CGPoint touchStartLocation;
    CGPoint touchEndLocation;
    CGPoint touchMovedLocation;
    CGPoint lastValidCircleTouchLocation;
    CGPoint lastValidTouchLocation;
    CCLayer *layerToFollow;
    GameTimer *timer;
    FuelGauge *fuelGauge;
    CCMenu *tabMenu;
    CCMenuItemSprite *tabMenuSprite;
    
    //MenuItemStateSprites
    CCSprite *startButton;
    CCSprite *startButtonSel;
    CCSprite *barButton;
    CCSprite *barButtonSel;
    CCSprite *barButtonDis;
    CCSprite *shockButton;
    CCSprite *shockButtonSel;
    CCSprite *shockButtonDis;
    CCSprite *wheelButton;
    CCSprite *wheelButtonSel;
    CCSprite *wheelButtonDis;
    CCSprite *boosterButton;
    CCSprite *boosterButtonSel;
    CCSprite *boosterButtonDis;
    CCSprite *motorButton;
    CCSprite *motorButtonSel;
    CCSprite *motorButtonDis;
    CCSprite *deleteButton;
    CCSprite *deleteButtonSel;
    CCSprite *deleteButtonDis;
    CCSprite *saveButton;
    CCSprite *saveButtonSel;
    CCSprite *saveButtonDis;
    CCSprite *shopButton;
    CCSprite *shopButtonSel;
    CCSprite *shopButtonDis;
    CCSprite *editButton;
    CCSprite *editButtonSel;
    CCSprite *editButtonDis;
    CCMenuItemImage *createMenuBackground;

    //MenuItemSprites
    CCMenuItemSprite *startBtnSprite;
    CCMenuItemToggle *barBtnSprite;
    CCMenuItemSprite *shockBtnSprite;
    CCMenuItemSprite *wheelBtnSprite;
    CCMenuItemSprite *boosterBtnSprite;
    CCMenuItemSprite *booster50BtnSprite;
    CCMenuItemSprite *motorBtnSprite;
    CCMenuItemSprite *motor50BtnSprite;
    CCMenuItemSprite *deleteBtnSprite;
    CCMenuItemSprite *deleteAllBtnSprite;
    CCMenuItemSprite *saveBtnSprite;
    CCMenuItemSprite *shopBtnSprite;
    CCMenuItemSprite *editBtnSprite;
    
    CCMenu *toolMenu;
    CCMenu *deleteSubMenu;
    CCMenu *motorSubMenu;
    CCMenu *boosterSubMenu;
    CCSprite *tempMotor;
    CCSprite *tempMotor50;
    CCSprite *currentMotor;
    CCSprite *currentMotorHub;
    CCSprite *tempMotorHub;
    CCSprite *tempMotorHub50;
    CCSprite *tempWheel;
    CCSprite *tempBar;
    ShockImageSet *shockImageSet;
    CCSprite *tempBooster;
    CCSprite *tempBooster50;
    CCSprite *currentBooster;
    
    float tempMotorOriginalHeight;
    float tempBarOriginalLength;
    float tempWheelOriginalHeight;
    float BoltBoxOriginalHeight;
    float BoltBoxOriginalWidth;
    float BoltBoxAdjustedWidth;
    float longPressCounter;
    CGPoint deleteAllMenuUp;
    CGPoint deleteAllMenuDown;
    CGPoint motorMenuUp;
    CGPoint motorMenuDown;
    CGPoint boosterMenuUp;
    CGPoint boosterMenuDown;
    CGPoint toolMenuUp;
    CGPoint toolMenuDown;
    BOOL isDeleteAllMenuUp;
    BOOL isMotorMenuUp;
    BOOL isBoosterMenuUp;
    PopupType popupTypeToShow;
    ToolType longPressType;
    ToolType currentMotorType;
    ToolType currentBoosterType;
    id<cartCreationDelegate> cartCreationDelegate;
    
    CartPart *editingPart;
    UITouch *moveEditTouch;
    UITouch *rotateEditTouch;
    UITouch *creationTouch;
    float rotateEditAngleStart;
    float rotateEditAngleMove;
    NSMutableArray *editingShocks;
    NSMutableArray *editingShockImages;
}

@property (nonatomic, assign)SaveMenu *saveMenu;
@property (nonatomic, retain)LevelScoreDisplay *levelScoreDisplay;

-(void)DissableCartCreation;
-(id)initwithLayerToFollow:(CCLayer*)layer andDelegate:(id<cartCreationDelegate>) theDelegate  topLayer:(CCLayer *)topLayer;
-(void)selectToolType:(ToolType)type;
-(void)slideToolMenuIn;
@end
