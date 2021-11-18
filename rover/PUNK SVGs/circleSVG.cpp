//
//  circleSVG.cpp
//  rover
//
//  Created by David Campbell on 6/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "circleSVG.h"

void circleSVG::createImage()
{
    onGroupBegin();
    onId("circle");
    onPathBegin();
    setRelative( false );
    onPathMoveTo(172.50,13.00);
    setRelative( false );
    onPathCubic(260.59,13.00,332.00,84.41,332.00,172.50);
    setRelative( true );
    onPathCubic(0.00,88.09,-71.41,159.50,-159.50,159.50);
    setRelative( false );
    onPathCubic(84.41,332.00,13.00,260.59,13.00,172.50);
    setRelative( false );
    onPathCubic(13.00,84.41,84.41,13.00,172.50,13.00);
    setRelative( true );
    onPathClose();
    onPathFillColor(4294967295u);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(172.50,155.00);
    setRelative( true );
    onPathCubic(9.66,0.00,17.50,7.84,17.50,17.50);
    setRelative( true );
    onPathSCubic(-7.84,17.50,-17.50,17.50);
    setRelative( true );
    onPathSCubic(-17.50,-7.84,-17.50,-17.50);
    setRelative( true );
    onPathCubic(0.00,-4.83,1.96,-9.21,5.13,-12.37);
    setRelative( false );
    onPathCubic(163.29,156.96,167.67,155.00,172.50,155.00);
    setRelative( true );
    onPathClose();
    onPathFillColor(3134914559u);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(294.48,50.52);
    setRelative( true );
    onPathCubic(-67.36,-67.36,-176.59,-67.36,-243.95,0.00);
    setRelative( true );
    onPathCubic(-67.37,67.37,-67.36,176.59,0.00,243.95);
    setRelative( true );
    onPathCubic(67.37,67.36,176.59,67.36,243.95,0.00);
    setRelative( false );
    onPathCubic(361.84,227.11,361.84,117.89,294.48,50.52);
    setRelative( true );
    onPathClose();
    setRelative( false );
    onPathMoveTo(75.83,290.07);
    setRelative( true );
    onPathLineTo(10.88,-19.52);
    setRelative( true );
    onPathLineTo(-12.27,-12.27);
    setRelative( true );
    onPathLineTo(-19.52,10.88);
    setRelative( false );
    onPathCubic(8.67,213.04,8.76,131.54,55.20,75.51);
    setRelative( true );
    onPathLineTo(19.25,10.73);
    setRelative( true );
    onPathLineTo(12.27,-12.27);
    setRelative( false );
    onPathLineTo(76.02,54.77);
    setRelative( false );
    onPathCubic(132.08,8.72,213.35,8.81,269.31,55.05);
    setRelative( false );
    onPathLineTo(258.77,73.97);
    setRelative( true );
    onPathLineTo(12.27,12.27);
    setRelative( true );
    onPathLineTo(18.92,-10.54);
    setRelative( true );
    onPathCubic(46.24,55.96,46.33,137.23,0.27,193.29);
    setRelative( true );
    onPathLineTo(-19.19,-10.69);
    setRelative( true );
    onPathLineTo(-12.27,12.27);
    setRelative( true );
    onPathLineTo(10.73,19.24);
    setRelative( false );
    onPathCubic(213.46,336.24,131.96,336.33,75.83,290.07);
    setRelative( true );
    onPathClose();
    onPathFillColor(2107028479u);
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 345.00;
    _height = 345.00;
}