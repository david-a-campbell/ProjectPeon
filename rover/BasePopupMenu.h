//
//  BasePopupMenu.h
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "popupMenuDelegate.h"
#import "Constants.h"

@interface BasePopupMenu : NSObject

@property(nonatomic, assign) id<popupMenuDelegate> popupDelegate;
@property(nonatomic, retain) NSMutableArray *nodeArray;
-(int)numberOfPlanks;
-(id)initWithDelegate:(id<popupMenuDelegate>)delegate;
-(void)removeFromParent;
-(void)setOpacity:(float)opacity;
-(void)addToNode:(CCNode*)node;
-(void)runAction:(id)action;
-(void)setHandlerPriority:(int)priority;
-(void)stopAllActions;
-(void)setTouchEnabled:(BOOL)enabled;
@end
