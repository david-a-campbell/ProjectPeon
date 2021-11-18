//
//  barSVG.cpp
//  rover
//
//  Created by David Campbell on 6/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "barSVG.h"


void barSVG::createImage()
{
    onGroupBegin();
    onId("bar_1_");
    onPathBegin();
    setRelative( false );
    onPathMoveTo(5.00,16.75);
    setRelative( true );
    onPathCubic(-2.34,0.00,-4.25,-1.91,-4.25,-4.25);
    setRelative( false );
    onPathVerticalLine(5.00);
    setRelative( true );
    onPathCubic(0.00,-2.34,1.91,-4.25,4.25,-4.25);
    setRelative( true );
    onPathHorizontalLine(740.00);
    setRelative( true );
    onPathCubic(2.34,0.00,4.25,1.91,4.25,4.25);
    setRelative( true );
    onPathVerticalLine(7.50);
    setRelative( true );
    onPathCubic(0.00,2.34,-1.91,4.25,-4.25,4.25);
    setRelative( false );
    onPathHorizontalLine(5.00);
    setRelative( true );
    onPathClose();
    onPathFillColor(4294967295u);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(745.00,1.50);
    setRelative( true );
    onPathCubic(1.93,0.00,3.50,1.57,3.50,3.50);
    setRelative( true );
    onPathVerticalLine(7.50);
    setRelative( true );
    onPathCubic(0.00,1.93,-1.57,3.50,-3.50,3.50);
    setRelative( false );
    onPathHorizontalLine(5.00);
    setRelative( true );
    onPathCubic(-1.93,0.00,-3.50,-1.57,-3.50,-3.50);
    setRelative( false );
    onPathVerticalLine(5.00);
    setRelative( true );
    onPathCubic(0.00,-1.93,1.57,-3.50,3.50,-3.50);
    setRelative( false );
    onPathHorizontalLine(745.00);
    setRelative( false );
    onPathMoveTo(745.00,0.00);
    setRelative( false );
    onPathHorizontalLine(5.00);
    setRelative( false );
    onPathCubic(2.24,0.00,0.00,2.24,0.00,5.00);
    setRelative( true );
    onPathVerticalLine(7.50);
    setRelative( true );
    onPathCubic(0.00,2.76,2.24,5.00,5.00,5.00);
    setRelative( true );
    onPathHorizontalLine(740.00);
    setRelative( true );
    onPathCubic(2.76,0.00,5.00,-2.24,5.00,-5.00);
    setRelative( false );
    onPathVerticalLine(5.00);
    setRelative( false );
    onPathCubic(750.00,2.24,747.76,0.00,745.00,0.00);
    setRelative( false );
    onPathLineTo(745.00,0.00);
    setRelative( true );
    onPathClose();
    onPathFillColor(2107028479u);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(687.37,4.50);
    setRelative( false );
    onPathHorizontalLine(62.63);
    setRelative( true );
    onPathCubic(-3.52,0.00,-6.38,1.90,-6.38,4.25);
    setRelative( true );
    onPathCubic(0.00,2.35,2.86,4.25,6.38,4.25);
    setRelative( true );
    onPathHorizontalLine(624.74);
    setRelative( true );
    onPathCubic(3.52,0.00,6.38,-1.90,6.38,-4.25);
    setRelative( false );
    onPathCubic(693.75,6.40,690.90,4.50,687.37,4.50);
    setRelative( false );
    onPathLineTo(687.37,4.50);
    setRelative( true );
    onPathClose();
    onPathFillColor(3134914559u);
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 750.00;
    _height = 17.50;
}