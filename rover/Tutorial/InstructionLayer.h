//
//  InstructionLayer.h
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
@class AnimatedSprite;

@protocol InstructionLayerProtocol <NSObject>
@optional
-(void)instructionsWillBeRemoved;
@end

@interface InstructionLayer : CCLayer
{
    AnimatedSprite *buildAnim;
    AnimatedSprite *catchAnim;
    AnimatedSprite *driveAnim;
    CCSprite *background;
    CCMenuItemToggle *checkBox;
    CCMenu *menu;
    BOOL checkState;
    BOOL isFading;
}
@property (nonatomic, assign) id<InstructionLayerProtocol> delegate;
@end
