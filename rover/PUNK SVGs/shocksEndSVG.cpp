//
//  shocksEnd.cpp
//  rover
//
//  Created by David Campbell on 6/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "shocksEndSVG.h"

void shocksEndSVG::createImage()
{
    onGroupBegin();
    onPathBegin();
    onPathRect(7.61,1.43,3.56,7.15);
    onPathFillColor(543864063u);
    onId("stem");
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(5.00,0.00);
    setRelative( true );
    onPathCubic(2.76,0.00,5.00,2.24,5.00,5.00);
    setRelative( true );
    onPathSCubic(-2.24,5.00,-5.00,5.00);
    setRelative( true );
    onPathCubic(-2.76,0.00,-5.00,-2.24,-5.00,-5.00);
    setRelative( true );
    onPathCubic(0.00,-1.59,0.74,-3.01,1.90,-3.93);
    setRelative( false );
    onPathCubic(2.76,0.40,3.83,0.00,5.00,0.00);
    setRelative( true );
    onPathClose();
    onPathFillColor(3435973631u);
    onId("end");
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(4.28,8.34);
    setRelative( false );
    onPathLineTo(1.75,6.05);
    setRelative( true );
    onPathLineTo(0.72,-3.34);
    setRelative( false );
    onPathLineTo(5.72,1.66);
    setRelative( true );
    onPathLineTo(2.53,2.29);
    setRelative( true );
    onPathLineTo(-0.72,3.34);
    setRelative( false );
    onPathLineTo(4.28,8.34);
    setRelative( true );
    onPathClose();
    onPathFillColor(543864063u);
    onId("bolt");
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 11.16;
    _height = 10.00;
}