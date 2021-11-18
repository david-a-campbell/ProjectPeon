//
//  LoadingLayer.h
//  rover
//
//  Created by David Campbell on 8/4/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"

@interface LoadingLayer : CCLayer
{
    CCLabelAtlas *scoreLabel;
    CCLabelAtlas *levelLabel;
    CCSprite *screen;
    UIImageView *activityIndicatorView;
}
-(id)initWithPlanetNum:(int)planetNum LevelNumber:(int)levelNum;
-(void)showActivityIndicator;
-(CCSequence*)fadeOutSequence;
@end
