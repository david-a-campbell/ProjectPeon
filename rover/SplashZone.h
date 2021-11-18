//
//  SplashZone.h
//  rover
//
//  Created by David Campbell on 9/24/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface SplashZone : Box2DSprite
{
    b2World *world;
}
@property (nonatomic, retain) NSMutableArray *splashEmitters;
@property (nonatomic, retain) id dictionary;
-(id)initWithWorld:(b2World *)theWorld andDict:(id)dict;
@end
