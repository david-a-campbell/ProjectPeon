//
//  PlankObject.h
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "cocos2d.h"

@interface PlankObject :NSObject
@property (nonatomic, assign) CCSprite* plank;
@property (nonatomic, assign) CGPoint finalPosition;
-(void)runAction:(CCAction*) action;
-(void)removeFromParent;
@end
