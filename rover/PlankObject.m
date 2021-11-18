//
//  PlankObject.m
//  rover
//
//  Created by David Campbell on 6/25/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PlankObject.h"

@implementation PlankObject
-(void)runAction:(CCAction*) action
{
    [_plank runAction:action];
}

-(void)removeFromParent
{
    [_plank removeFromParentAndCleanup:YES];
}
@end
