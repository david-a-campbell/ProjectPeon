//
//  Ground.h
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"
#import "PRTriangulator.h"
@class PRFilledPolygon;

@interface Ground : Box2DSprite
{
    b2World *world;
    id<PRTriangulator> triangulator;
    BOOL isSolid;
}
@property (nonatomic, retain) NSMutableArray *dustEmitters;
@property (nonatomic, retain) id dictionary;
@property (nonatomic, retain) PRFilledPolygon *filledPolygon1;
@property (nonatomic, retain) PRFilledPolygon *filledPolygon2;

-(id)initWithWorld:(b2World*)theWorld andDict:(id)dict isSolid:(BOOL)isSolid;
-(void)setupBody;
-(void)setupTriangulatedFixtures;

@end
