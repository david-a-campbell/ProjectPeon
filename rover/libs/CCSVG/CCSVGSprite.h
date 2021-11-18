#import "cocos2d.h"
#import "punkSVG.h"

@class CCSVGSource;


@interface CCSVGSprite : CCNode <CCBlendProtocol>


#pragma mark

@property (atomic, retain) CCSVGSource *source;
@property (nonatomic, assign) float opacity;
@property (nonatomic, assign) ccColor3B	color;
@property (nonatomic, assign) BOOL flipX;
@property (nonatomic, assign) BOOL flipY;

#pragma mark

+ (id)spriteWithFile:(NSString *)file;

+ (id)spriteWithSource:(CCSVGSource *)source;

+ (id)spriteWithPunk:(punkSVG*)punk;

- (id)initWithFile:(NSString *)file;

- (id)initWithSource:(CCSVGSource *)source;

- (id)initWithPunk:(punkSVG*)punk;

@end
