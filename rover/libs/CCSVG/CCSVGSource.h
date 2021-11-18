#import "cocos2d.h"
#import "punkSVG.h"

struct SVGSourceColor
{
    float red;
    float green;
    float blue;
    float opacity;
};

@interface CCSVGSource : NSObject

#pragma mark

+ (void)setTessellationIterations:(NSUInteger)numberOfTesselationIterations;


#pragma mark

@property (readwrite, assign) CGRect contentRect;

@property (readwrite, assign) CGSize contentSize;

@property (readonly, assign) BOOL hasTransparentColors;

@property (nonatomic, assign) float opacity;

@property (nonatomic, assign) ccColor3B	color;

@property (nonatomic, readonly) SVGSourceColor SVGColor;


#pragma mark

- (id)initWithData:(NSData *)data;

- (id)initWithFile:(NSString *)name;

- (id)initWithPunk:(punkSVG*)punk;

#pragma mark

- (void)draw;

- (void)optimize;

-(BOOL)colorIsWhite;

@end
