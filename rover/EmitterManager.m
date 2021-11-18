//
//  EmitterManager.m
//  rover
//
//  Created by David Campbell on 7/7/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "EmitterManager.h"
#import "Constants.h"

static EmitterManager* _sharedManager = nil;

@implementation EmitterManager

+(EmitterManager*)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[EmitterManager alloc] init];
    });
    return _sharedManager;
}

+(id)alloc
{
    @synchronized ([EmitterManager class])
    {
        NSAssert(_sharedManager == nil,
                 @"Attempted to allocate a second instance of the Emitter Manager singleton");
        _sharedManager = [super alloc];
        return _sharedManager;
    }
    return nil;
}

-(id)init
{
    if (self = [super init])
    {
        [self setGroundEmitters:[CCArray array]];
        [self setSplashEmitters:[CCArray array]];
    }
    return self;
}

-(CCParticleSystemQuad *)getGroundEmitter:(NSString *)name
{
    CCArray *removeArray = [CCArray array];
    for(CCParticleSystemQuad *emitter in _groundEmitters)
    {
        if (![emitter active] || ![emitter parent])
        {
            [removeArray addObject:emitter];
        }
    }
    [_groundEmitters removeObjectsInArray:removeArray];
    
    if ([_groundEmitters count] >= DUST_MAX)
    {
        return nil;
    }
    
    CCParticleSystemQuad *dustEmitter = [CCParticleSystemQuad particleWithFile:name];
    [_groundEmitters addObject:dustEmitter];
    return dustEmitter;
}

-(CCParticleSystemQuad *)getSpashEmitter:(NSString *)name
{
    CCArray *removeArray = [CCArray array];
    for(CCParticleSystemQuad *emitter in _splashEmitters)
    {
        if (![emitter active] || ![emitter parent])
        {
            [removeArray addObject:emitter];
        }
    }
    [_splashEmitters removeObjectsInArray:removeArray];
    
    if ([_splashEmitters count] >= DUST_MAX)
    {
        return nil;
    }
    
    CCParticleSystemQuad *splashEmitter = [CCParticleSystemQuad particleWithFile:name];
    [_splashEmitters addObject:splashEmitter];
    return splashEmitter;
}

-(void)dealloc
{
    [self setGroundEmitters:nil];
    [self setSplashEmitters:nil];
    [super dealloc];
}

@end
