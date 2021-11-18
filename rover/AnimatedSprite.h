//
//  AnimatedSprite.h
//  rover
//
//  Created by David Campbell on 7/11/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "GameCharacter.h"

@interface AnimatedSprite : GameCharacter
{
    BOOL repeats;
    NSString *animationToRun;
    float timeToMove;
    CGPoint moveByPoint;
    int triggerId;
    BOOL startsOn;
    float rotation;
    BOOL flipY;
    BOOL flipX;
    float moveDelay;
}
@property (nonatomic, retain) NSMutableDictionary *animations;
@property (nonatomic, assign) CGPoint originalPosition;
-(id)initWithDict:(id)dict;
@end
