#import "CCSVGCache.h"
#import "CCSVGSprite.h"
#import "CCSVGSource.h"

#include <MonkVG/openvg.h>
#include <MonkVG/vgu.h>
#include <mkSVG.h>
#include <openvg/mkOpenVG_SVG.h>
#import "Constants.h"


#pragma mark

@implementation CCSVGSprite {
    ccBlendFunc blendFunc_;
}


#pragma mark

@synthesize source = source_;


#pragma mark

-(id)init
{
    if (self = [super init])
    {
        [self setSource:nil];
    }
    return self;
}

+ (id)spriteWithFile:(NSString *)name {
    return [[[self alloc] initWithFile:name] autorelease];
}

+ (id)spriteWithSource:(CCSVGSource *)source
{
    return [[[self alloc] initWithSource:source] autorelease];
}

+ (id)spriteWithPunk:(punkSVG*)punk
{
    return [[[self alloc] initWithPunk:punk] autorelease];
}

- (id)initWithPunk:(punkSVG*)punk
{
    if (punk)
    {
        CCSVGSprite *sprite = [self initWithSource:[[[CCSVGSource alloc] initWithPunk:punk] autorelease]];
        return sprite;
    }else
    {
        CCSVGSprite *sprite = [super init];
        return sprite;
    }
}

-(void)setOpacity:(float)opacity
{
    [[self source] setOpacity:opacity];
}

-(float)opacity
{
    return [[self source] opacity];
}

-(void) setColor:(ccColor3B)color3
{
    [[self source] setColor:color3];
}

-(ccColor3B)color
{
    return [[self source] color];
}

- (id)initWithFile:(NSString *)name {
    return [self initWithSource:[[CCSVGCache sharedSVGCache] addFile:name]];
}

- (id)initWithSource:(CCSVGSource *)source {
    if ((self = [super init])) {
        self.anchorPoint = ccp(0.5, 0.5);
        self.blendFunc = (ccBlendFunc){ GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA };
        if (source)
        {
            [self setSource:source];
            self.contentSize = source.contentSize;
        }
    }
    return self;
}

- (void)dealloc {
    [source_ release];
    [super dealloc];
}


#pragma mark

- (void)draw
{
    if (![self source])
    {
        return;
    }
    
    BOOL doBlend = self.source.hasTransparentColors;
    
    SVGSourceColor s = [[self source] SVGColor];
    
    if(s.opacity != 1.0f || doBlend)
    {
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }else
    {
        glDisable(GL_BLEND);
    }
    
    // transform
    CGAffineTransform transform;
    transform = CGAffineTransformIdentity;
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1.0f, -1.0f));
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0f, self.contentSize.height));
//    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(2*SCREEN_SCALE, 2*SCREEN_SCALE));
    
    if ([self flipX])
    {
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(-1.0f, 1.0f));
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(self.contentSize.width, 0.0f));
    }
    if ([self flipY])
    {
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1.0f, -1.0f));
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0f, self.contentSize.height));
    }
    
    transform = CGAffineTransformConcat(transform, self.nodeToWorldTransform);
    
    // matrix
    VGfloat matrix[9] = {
        transform.a, transform.c, transform.tx, // a, c, tx
        transform.b, transform.d, transform.ty, // b, d, ty
        0, 0, 1,                                // 0, 0, 1
    };
    vgLoadMatrix(matrix);

    // draw
    [self.source draw];
    
    // apply the transform used for drawing children
    [self transformAncestors];
    
    // enable blending
    if (!doBlend) {
        glEnable(GL_BLEND);
    } else
    {
        glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    }
}


#pragma mark - CCBlendProtocol

- (ccBlendFunc)blendFunc {
    return blendFunc_;
}

- (void)setBlendFunc:(ccBlendFunc)blendFunc {
    blendFunc_ = blendFunc;
}

-(void)setParent:(CCNode *)parent
{
    [super setParent:parent];
    
    if (![self source])
    {
        NSLog(@"%@ HAS NO SOURCE!", NSStringFromClass([self class]));
    }
}

@end
