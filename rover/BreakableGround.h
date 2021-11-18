//
//  BreakableGround.h
//  rover
//
//  Created by David Campbell on 7/5/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Ground.h"

@interface BreakableGround : Ground
{
    float delay;
    BOOL hasBroken;
    int breakID;
}
@property (nonatomic, retain) NSMutableArray *emitterArray;
@property (nonatomic, assign) BOOL ignoreRocks;
-(id)initWithWorld:(b2World*)theWorld dict:(id)dict objectGroup:(CCTMXObjectGroup*)collisionObjects andParent:(CCNode*)parent;
-(void)makeGroundBreak;
-(void)resetGround;
@end
