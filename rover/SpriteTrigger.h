//
//  SpriteTrigger.h
//  rover
//
//  Created by David Campbell on 7/12/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "Box2DSprite.h"

@interface SpriteTrigger : Box2DSprite
{
    b2World *world;
    int triggerId;
    BOOL canSendNotifications;
}
-(id)initWithDict:(id)dict andWorld:(b2World*)theWorld;
-(void)resetTrigger;
@end
