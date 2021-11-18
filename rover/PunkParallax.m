//
//  PunkParallax.h
//  rover
//
//  Created by David Campbell on 6/6/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#import "PunkParallax.h"
#import "CGPointExtension.h"
#import "Constants.h"
#import "CCSprite.h"

@interface PunkNodeObject : NSObject
{
	CGPoint	_ratio;
	CGPoint _offset;
    CGPoint _originalOffset;
    CGPoint _motionOffset;
	CCNode *_child;	// weak ref
}
@property (nonatomic,readwrite) CGPoint ratio;
@property (nonatomic, readwrite) CGPoint offset;
@property (nonatomic, readwrite) CGPoint motionOffset;
@property (nonatomic, readwrite) CGPoint originalOffset;
@property (nonatomic,readwrite,assign) CCNode *child;
+(id) pointWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
-(id) initWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
@end

@implementation PunkNodeObject

+(id) pointWithCGPoint:(CGPoint)ratio offset:(CGPoint)offset
{
	return [[[self alloc] initWithCGPoint:ratio offset:offset] autorelease];
}
-(id) initWithCGPoint:(CGPoint)ratio offset:(CGPoint)offset
{
	if( (self=[super init])) {
		_ratio = ratio;
		_offset = offset;
	}
	return self;
}
@end

@implementation PunkParallax

@synthesize parallaxArray = _parallaxArray;

-(id) init
{
	if( (self=[super init]) ) {
		_parallaxArray = ccArrayNew(5);
        _motionArray = ccArrayNew(5);
		_lastPosition = CGPointMake(0,0);
        [self scheduleUpdate];
	}
	return self;
}

- (void) dealloc
{
	if( _parallaxArray ) {
		ccArrayFree(_parallaxArray);
		_parallaxArray = nil;
	}
    if (_motionArray) {
        ccArrayFree(_motionArray);
        _motionArray = nil;
    }
	[super dealloc];
}

-(void) addChild:(CCNode*)child z:(NSInteger)z tag:(NSInteger)tag
{
	NSAssert(NO,@"ParallaxNode: use addChild:z:parallaxRatio:positionOffset instead");
}

-(void) addChild: (CCNode*) child z:(NSInteger)z parallaxRatio:(CGPoint)ratio positionOffset:(CGPoint)offset
{
    [self addChild:child z:z parallaxRatio:ratio positionOffset:offset motionOffset:ccp(0, 0)];
}

-(void) addChild: (CCNode*) child z:(NSInteger)z parallaxRatio:(CGPoint)ratio positionOffset:(CGPoint)offset motionOffset:(CGPoint)motion
{
	NSAssert( child != nil, @"Argument must be non-nil");
	PunkNodeObject *obj = [PunkNodeObject pointWithCGPoint:ratio offset:offset];
    
	obj.child = child;
    obj.motionOffset = motion;
    obj.originalOffset = offset;
	ccArrayAppendObjectWithResize(_parallaxArray, obj);
    
	CGPoint pos = _lastPosition;
    float x = pos.x * obj.ratio.x / _scaleX + obj.offset.x;
    float y = pos.y * obj.ratio.y / _scaleY + obj.offset.y;

    obj.child.position = ccp(x,y);

    if (motion.x != 0 || motion.y != 0)
    {
        offset = [self dupOffsetForMotion:motion size:obj.child.boundingBox.size original:offset];

        CCSprite *dupSprite = [CCSprite spriteWithTexture:[(CCSprite*)child texture]];
        [[dupSprite texture] setAliasTexParameters];
        [dupSprite setAnchorPoint:child.anchorPoint];
        [dupSprite setScale:[child scale]];
        
        PunkNodeObject *dup = [PunkNodeObject pointWithCGPoint:ratio offset:offset];
        dup.child = dupSprite;
        dup.motionOffset = motion;
        dup.originalOffset = offset;
        
        ccArrayAppendObjectWithResize(_parallaxArray, dup);
        ccArrayAppendObjectWithResize(_motionArray, obj);
        ccArrayAppendObjectWithResize(_motionArray, dup);
        
        x = pos.x * dup.ratio.x / _scaleX + dup.offset.x;
        y = pos.y * dup.ratio.y / _scaleY + dup.offset.y;
        dup.child.position = ccp(x,y);
        
        [super addChild:dupSprite z:z tag:child.tag];
    }
    
	[super addChild:child z:z tag:child.tag];
}

-(CGPoint)dupOffsetForMotion:(CGPoint)motion size:(CGSize)size original:(CGPoint)original
{
    CGPoint offsetAmount = ccp(0, 0);
    if (motion.x != 0)
        offsetAmount.x = (motion.x)<0 ? size.width : -size.width;   
    if (motion.y != 0)
        offsetAmount.y = (motion.y)<0 ? size.height : -size.height;
    
    CGPoint returnAmount = ccp(original.x+offsetAmount.x, original.y+offsetAmount.y);
    return returnAmount;
}

-(void) removeChild:(CCNode*)node cleanup:(BOOL)cleanup
{
	for( unsigned int i=0;i < _parallaxArray->num;i++) {
		PunkNodeObject *point = _parallaxArray->arr[i];
		if( [point.child isEqual:node] ) {
			ccArrayRemoveObjectAtIndex(_parallaxArray, i);
			break;
		}
	}
    
    for( unsigned int i=0;i < _motionArray->num;i++) {
		PunkNodeObject *point = _motionArray->arr[i];
		if( [point.child isEqual:node] ) {
			ccArrayRemoveObjectAtIndex(_motionArray, i);
			break;
		}
	}
    
	[super removeChild:node cleanup:cleanup];
}

-(void) removeAllChildrenWithCleanup:(BOOL)cleanup
{
	ccArrayRemoveAllObjects(_parallaxArray);
    ccArrayRemoveAllObjects(_motionArray);
	[super removeAllChildrenWithCleanup:cleanup];
}

-(void)setPosition:(CGPoint)position
{
    if (CGPointEqualToPoint(position, _lastPosition))
    {
        return;
    }
    
    CGPoint pos = position;
    for(unsigned int i=0; i < _parallaxArray->num; i++)
    {
        PunkNodeObject *obj = _parallaxArray->arr[i];
        
        float x = pos.x * obj.ratio.x / _scaleX + obj.offset.x;
        float y = pos.y * obj.ratio.y / _scaleY + obj.offset.y;
        
        obj.child.position = ccp(x,y);
    }
    _lastPosition = position;
}

-(void)update:(ccTime)delta
{
    for(unsigned int i=0; i < _motionArray->num; i++)
    {
        PunkNodeObject *obj = _motionArray->arr[i];
        float xShift = obj.motionOffset.x * delta;
        float yShift = obj.motionOffset.y * delta;
        [obj setOffset:ccp(obj.offset.x+xShift, obj.offset.y+yShift)];
        
        float xLimit = obj.child.boundingBox.size.width;
        float xUpperLimit = obj.originalOffset.x + xLimit;
        float xLowerLimit = obj.originalOffset.x - xLimit;
        
        if (obj.offset.x > xUpperLimit || obj.offset.x < xLowerLimit)
            [obj setOffset:ccp(obj.originalOffset.x, obj.offset.y)];
        
        float yLimit = obj.child.boundingBox.size.height;
        float yUpperLimit = obj.originalOffset.y + yLimit;
        float yLowerLimit = obj.originalOffset.y - yLimit;
        
        if (obj.offset.y > yUpperLimit || obj.offset.y < yLowerLimit)
            [obj setOffset:ccp(obj.offset.x, obj.originalOffset.y)];
        
        CGPoint pos = _lastPosition;
        float x = pos.x * obj.ratio.x / _scaleX + obj.offset.x;
        float y = pos.y * obj.ratio.y / _scaleY + obj.offset.y;
        obj.child.position = ccp(x,y);
    }
}

@end
