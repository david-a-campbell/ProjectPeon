//
//  popupMenuDelegate.h
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"

@protocol popupMenuDelegate <NSObject>
-(void)popupDidDismiss:(PopupType)type;
@optional
-(void)goToCartCreation;
-(void)relaunch;
-(void)goToSettings;
-(void)returnToTitle;
-(void)returnToLevelSelect;
-(void)showPreviousMenu;
-(void)setVolumeChanged;
-(void)showTutorial;
@end
