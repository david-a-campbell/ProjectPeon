//
//  shocksBarSVG.cpp
//  rover
//
//  Created by David Campbell on 6/2/13.
//  Copyright (c) 2013 Digital Fury. All rights reserved.
//

#include "shocksBarSVG.h"

void shocksBarSVG::createImage()
{
    onGroupBegin();
    onId("bar");
    onPathBegin();
    onPathRect(0,0,158.00,5.00);
    onPathFillColor(3604403967u);
    onPathEnd();
    onGroupEnd();
    _minX = 0.00;
    _minY = 0.00;
    _width = 158.00;
    _height = 5.00;
}