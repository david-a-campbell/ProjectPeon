//
//  PunkParallax.h
//  rover
//
//  Created by David Campbell on 6/6/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "CCNode.h"
#import "ccArray.h"

@interface PunkParallax : CCNode
{
	ccArray				*_parallaxArray;
	CGPoint				_lastPosition;
}


@property (nonatomic,readwrite) ccArray *parallaxArray;
@property (nonatomic, readwrite) ccArray *motionArray;
@property (nonatomic, assign) CGPoint mapSize;


-(void) addChild: (CCNode*)node z:(NSInteger)z parallaxRatio:(CGPoint)c positionOffset:(CGPoint)positionOffset  motionOffset:(CGPoint)motion;
-(void) addChild: (CCNode*) child z:(NSInteger)z parallaxRatio:(CGPoint)ratio positionOffset:(CGPoint)offset;
@end
