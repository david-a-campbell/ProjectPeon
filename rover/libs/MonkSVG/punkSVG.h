//
//  File.h
//  MonkSVG-OpenGL-Test-iOS
//
//  Created by David Campbell on 5/17/13.
//  Copyright (c) 2013 Zero Vision. All rights reserved.
//

#import <openvg/mkOpenVG_SVG.h>

using namespace MonkSVG;

class punkSVG : public OpenVG_SVGHandler
{
    public:
        virtual void createImage() = 0;
};

