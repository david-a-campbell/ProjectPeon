//
//  shocksBoxSVG.cpp
//  rover
//
//  Created by David Campbell on 6/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "shocksBoxSVG.h"

void shocksBoxSVG::createImage()
{
    onGroupBegin();
    onId("shocks");
    onPathBegin();
    setRelative( false );
    onPathMoveTo(0.00,7.84);
    setRelative( false );
    onPathCubic(0.00,8.24,0.33,8.57,0.74,8.57);
    setRelative( true );
    onPathHorizontalLine(4.59);
    setRelative( true );
    onPathCubic(0.41,0.00,0.73,-0.33,0.73,-0.73);
    setRelative( false );
    onPathVerticalLine(0.73);
    setRelative( false );
    onPathCubic(6.06,0.33,5.73,0.00,5.33,0.00);
    setRelative( false );
    onPathHorizontalLine(0.74);
    setRelative( false );
    onPathCubic(0.33,0.00,0.00,0.33,0.00,0.73);
    setRelative( false );
    onPathVerticalLine(7.84);
    setRelative( true );
    onPathClose();
    onPathFillColor(3014898687u);
    onId("shocksBox1");
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 6.06;
    _height = 8.57;
}