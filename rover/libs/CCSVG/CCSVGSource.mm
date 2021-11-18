//
//  CCSVGSource.m
//  CCSVG
//
//  Created by Luke Lutman on 12-05-22.
//  Copyright (c) 2012 Zinc Roe Design. All rights reserved.
//

#import <openvg/mkOpenVG_SVG.h>
#import <MonkVG/openvg.h>
#import <MonkVG/vgext.h>
#import "CCSVGSource.h"
#import "CCFileUtils.h"

@interface CCSVGSource ()

@property (nonatomic, readwrite, assign) BOOL isOptimized;

@property (nonatomic, readwrite, assign) MonkSVG::OpenVG_SVGHandler::SmartPtr svg;
@property (nonatomic, readwrite, assign) punkSVG* punk;

@end


@implementation CCSVGSource


#pragma mark

+ (void)initialize {
    [self setTessellationIterations:4];
}

+ (void)setTessellationIterations:(NSUInteger)numberOfTesselationIterations {
    vgSeti(VG_TESSELLATION_ITERATIONS_MNK, numberOfTesselationIterations);
}


#pragma mark

@synthesize contentRect = contentRect_;

@synthesize contentSize = contentSize_;

@synthesize isOptimized = isOptimized_;

@synthesize svg = svg_;
@synthesize punk = punk_;

- (BOOL)hasTransparentColors {
    if (svg_)
    {
        return svg_->hasTransparentColors();
    }else
    {
        return punk_->hasTransparentColors();
    }
}


#pragma mark

- (id)initWithPunk:(punkSVG*)punk
{
    if ((self = [super init]))
    {
        isOptimized_ = NO;
        _opacity = 255;
        _color.r = 255;
        _color.g = 255;
        _color.b = 255;
        if (punk)
        {
            punk->createImage();
            punk_ = punk;
            contentRect_ = CGRectMake(punk_->minX(), punk_->minY(), punk_->width(), punk_->height());
            contentSize_ = CGSizeMake(punk_->width(), punk_->height());
        }
    }
    return self;
}

- (id)init {
    if ((self = [super init]))
    {
        isOptimized_ = NO;
        _opacity = 255;
        _color.r = 255;
        _color.g = 255;
        _color.b = 255;
        svg_ = boost::static_pointer_cast<MonkSVG::OpenVG_SVGHandler>(MonkSVG::OpenVG_SVGHandler::create());
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    if ((self = [self init])) {
        
        MonkSVG::SVG parser;
        parser.initialize(svg_);
        parser.read((char *)data.bytes);
        
        contentRect_ = CGRectMake(svg_->minX(), svg_->minY(), svg_->width(), svg_->height());
        contentSize_ = CGSizeMake(svg_->width(), svg_->height());
        
    }
    return self;
}

- (id)initWithFile:(NSString *)name
{	
	NSString *path;
    
    NSBundle* bundle = [CCFileUtils sharedFileUtils].bundle;
	path = [bundle pathForResource:name ofType:nil];
    NSAssert1(path, @"Missing SVG file: %@", name);
	
	NSData *data;
	data = [NSData dataWithContentsOfFile:path];
    NSAssert1(data, @"Invalid SVG file: %@", name);
	
	return [self initWithData:data];
}

-(void)setOpacity:(float)opacity
{
    _opacity = opacity;
//    if (punk_)
//    {
//        punk_->setOpacity(opacity/255);
//    }
}

-(void)setColor:(ccColor3B)color
{
    _color = color;
//    if (punk_)
//    {
//        punk_->setTint(color.r/255, color.g/255, color.b/255);
//    }
}

- (void)dealloc
{
    delete punk_;
    [super dealloc];
}


#pragma mark

- (void)draw {
    //GL_NO_ERROR
//    [self optimize]; // FIXME: optimizing seems to be broken in GLES 2.0.
    if (svg_)
    {
        svg_->draw();
    }else
    {
        punk_->draw();
    }

}

- (void)optimize {
    
    if (!isOptimized_) {
        
        VGfloat matrix[9];
        vgGetMatrix(matrix);
        
        vgLoadIdentity();
        svg_->optimize();
        vgLoadMatrix(matrix);
        
        isOptimized_ = YES;
        
    }
}

-(BOOL)colorIsWhite
{
    return [self SVGColor].red == 1 && [self SVGColor].green == 1 && [self SVGColor].blue == 1;
}

-(SVGSourceColor)SVGColor
{
    SVGSourceColor returnColor;
    returnColor.red = _color.r/255;
    returnColor.green = _color.g/255;
    returnColor.blue = _color.b/255;
    returnColor.opacity = _opacity/255;
    return returnColor;
}

@end
