//
//  wheelHubSVG.cpp
//  rover
//
//  Created by David Campbell on 6/1/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "wheelHubSVG.h"

void wheelHubSVG::createImage()
{
    onGroupBegin();
    onId("wheelHub");
    onPathBegin();
    setRelative( false );
    onPathMoveTo(76.58,30.98);
    setRelative( true );
    onPathCubic(25.18,0.00,45.59,20.41,45.59,45.59);
    setRelative( true );
    onPathCubic(0.00,25.18,-20.41,45.60,-45.59,45.60);
    setRelative( true );
    onPathCubic(-25.18,0.00,-45.60,-20.41,-45.60,-45.60);
    setRelative( true );
    onPathCubic(0.00,-11.64,4.36,-22.26,11.54,-30.31);
    setRelative( false );
    onPathCubic(50.87,36.88,63.03,30.98,76.58,30.98);
    setRelative( true );
    onPathClose();
    onPathFillColor(2597250815u);
    onId("blueCircle");
    onPathFillOpacity(0.75);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(121.15,86.17);
    setRelative( true );
    onPathCubic(0.35,-1.63,0.60,-3.26,0.78,-4.89);
    setRelative( true );
    onPathCubic(-43.94,47.52,-87.81,11.90,-87.81,11.90);
    setRelative( true );
    onPathCubic(5.39,13.74,17.35,24.61,32.86,27.95);
    setRelative( false );
    onPathCubic(91.59,126.44,115.84,110.79,121.15,86.17);
    setRelative( true );
    onPathClose();
    onPathFillColor(1717987071u);
    onId("shadow");
    onPathFillOpacity(0.40);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(120.06,90.30);
    setRelative( true );
    onPathCubic(0.16,-0.52,0.32,-1.04,0.47,-1.57);
    setRelative( true );
    onPathCubic(-15.86,-1.84,-39.06,-0.23,-49.32,7.49);
    setRelative( true );
    onPathCubic(-11.15,8.40,-23.17,8.25,-32.47,5.81);
    setRelative( true );
    onPathCubic(1.08,1.61,2.28,3.16,3.57,4.63);
    setRelative( true );
    onPathCubic(9.92,4.43,24.07,6.90,37.08,-4.77);
    setRelative( true );
    onPathCubic(12.82,-11.51,28.87,-12.76,40.65,-11.57);
    setRelative( false );
    onPathCubic(120.05,90.31,120.06,90.30,120.06,90.30);
    setRelative( true );
    onPathClose();
    onPathFillColor(1717987071u);
    onId("reflection");
    onPathFillOpacity(0.10);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(3.23,78.11);
    setRelative( true );
    onPathCubic(0.00,-41.15,33.35,-74.50,74.50,-74.50);
    setRelative( true );
    onPathCubic(39.46,0.00,71.75,30.68,74.33,69.48);
    setRelative( false );
    onPathCubic(150.51,32.47,117.08,0.00,76.06,0.00);
    setRelative( false );
    onPathCubic(34.05,0.00,0.00,34.05,0.00,76.06);
    setRelative( true );
    onPathCubic(0.00,35.67,24.56,65.61,57.69,73.82);
    setRelative( false );
    onPathCubic(26.28,141.13,3.23,112.32,3.23,78.11);
    setRelative( true );
    onPathClose();
    onPathFillColor(4294967295u);
    onId("tireShine");
    onPathFillOpacity(0.15);
    onPathEnd();
    onPathBegin();
    setRelative( false );
    onPathMoveTo(68.47,37.50);
    setRelative( true );
    onPathCubic(16.83,0.00,30.48,13.65,30.48,30.48);
    setRelative( true );
    onPathCubic(0.00,16.83,-13.65,30.48,-30.48,30.48);
    setRelative( true );
    onPathCubic(-16.83,0.00,-30.48,-13.65,-30.48,-30.48);
    setRelative( true );
    onPathCubic(0.00,-9.04,3.93,-17.16,10.18,-22.74);
    setRelative( false );
    onPathCubic(53.56,40.42,60.67,37.50,68.47,37.50);
    setRelative( true );
    onPathClose();
    onPathFillColor(4294967295u);
    onId("whiteCircle");
    onPathFillOpacity(0.60);
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 153.06;
    _height = 152.89;
}