//
//  LevelSelectLayer.h
//  rover
//
//  Created by David Campbell on 6/16/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "cocos2d.h"
#import "LevelSelectMenu.h"


@interface LevelSelectLayer : CCLayer <levelMenuDelegate>
{
    CCParallaxNode *parallaxNode;
    LevelSelectMenu* hexLayer;
    CCTMXTiledMap *tileMapNode;
    CGPoint originalPosition;
    CGPoint currentOffset;
}
@end
