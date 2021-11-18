//  GameObject.m
//  SpaceViking
//
#import "GameObject.h"
#import "UIImage+Extras.h"
#import "PRFilledPolygon.h"
#import "GameManager.h"

@implementation GameObject
@synthesize reactsToScreenBoundaries;
@synthesize screenSize;
@synthesize isActive;
@synthesize gameObjectType;

-(id) init {
    if((self=[super init])){
        CCLOG(@"GameObject init");
        screenSize = [CCDirector sharedDirector].winSize;
        isActive = TRUE;
        _canPlaySound = YES;
        gameObjectType = kObjectTypeNone;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseSchedulerAndActions) name:NOTIFICATION_PAUSE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeSchedulerAndActions) name:NOTIFICATION_UNPAUSE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sceneEnd) name:NOTIFICATION_SCENE_EXIT object:nil];
    }
    return self;
}

-(void)changeState:(CharacterStates)newState {
    //CCLOG(@"GameObject->changeState method should be overriden");
}

-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray*)listOfGameObjects {
    //CCLOG(@"updateStateWithDeltaTime method should be overriden");
}

-(CGRect)adjustedBoundingBox {
    //CCLOG(@"GameObect adjustedBoundingBox should be overriden");
    return [self boundingBox];
}
-(CCAnimation*)loadPlistForAnimationWithName:(NSString*)animationName andClassName:(NSString*)className
{
    NSString *fullFileName = [NSString stringWithFormat:@"%@.plist",className];
    NSMutableDictionary *plistDictionary = [[GameManager sharedGameManager] dictForPlist:fullFileName];
    
    return [self animationWithName:animationName inDict:plistDictionary];
}

-(NSMutableArray*)allAnimationsFromPlist:(NSString*)plistName
{
    NSMutableArray *array = [NSMutableArray array];
    NSMutableDictionary *plistDict = [[GameManager sharedGameManager] dictForPlist:plistName];
    
    for (NSString *key in [plistDict allKeys])
    {
        [array addObject:[self animationWithName:key inDict:plistDict]];
    }
    return array;
}

-(NSMutableDictionary*)animationDictFromPlist:(NSString*)plistName
{
    NSMutableDictionary *outDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *plistDict = [[GameManager sharedGameManager] dictForPlist:plistName];
    
    for (NSString *key in [plistDict allKeys])
    {
        [outDict setValue:[self animationWithName:key inDict:plistDict] forKey:key];
    }
    return outDict;
}

-(CCAnimation*)animationWithName:(NSString*)key inDict:(NSDictionary*)dict
{
    NSDictionary *animationSettings = [dict objectForKey:key];
    
    float animationDelay = [[animationSettings objectForKey:@"delay"] floatValue];
    
    NSString *animationFramePrefix = [animationSettings objectForKey:@"filenamePrefix"];
    NSString *animationFrames = [animationSettings objectForKey:@"animationFrames"];
    NSArray *animationFrameNumbers = [animationFrames componentsSeparatedByString:@","];
    NSMutableArray *frameArray = [NSMutableArray array];
    
    for (NSString *frameNumber in animationFrameNumbers)
    {
        NSString *frameName = [NSString stringWithFormat:@"%@%@.png", animationFramePrefix, frameNumber];
        [frameArray addObject: [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:frameName]];
    }
    return [CCAnimation animationWithSpriteFrames:frameArray delay:animationDelay];
}

-(ALuint)playSoundEffect:(NSString*)soundEffectKey
{
    if (_canPlaySound)
    {
        return [[GameManager sharedGameManager] playSoundEffect:soundEffectKey];
    }
    return 0;
}

-(ALuint)playSoundEffect:(NSString *)soundEffectKey withProbability:(float)probability
{
    if (_canPlaySound)
    {
        return [[GameManager sharedGameManager] playSoundEffect:soundEffectKey withProbability:probability];
    }
    return 0;
}

-(PRFilledPolygon*)getTexture:(NSString*)textureName withPoints:(NSMutableArray*)polygonPoints
{
    UIImage *textureImage = [UIImage imageNamed:textureName];
    textureImage = [textureImage imageByScalingProportionallyToSize:CGSizeMake(textureImage.size.width*SCREEN_SCALE, textureImage.size.height*SCREEN_SCALE)];
    CCTexture2D *texture = [[CCTexture2D alloc] initWithCGImage:[textureImage CGImage] resolutionType:kCCResolutioniPadRetinaDisplay];
    
    NSMutableArray *convertedPoints = [NSMutableArray array];
    
    for (int i = 0; i < [polygonPoints count]; i++)
    {
        CGPoint point = [[polygonPoints objectAtIndex:i] CGPointValue];
        [convertedPoints addObject:[NSValue valueWithCGPoint:ccp(point.x/(2*SCREEN_SCALE), point.y/(2*SCREEN_SCALE))]];
    }
    PRFilledPolygon *filledPolygon = [[[PRFilledPolygon alloc] initWithPoints:convertedPoints andTexture:texture] autorelease];
    [texture release];
    return filledPolygon;
}

-(void)setupTexture:(NSString*)textureName withPoints:(NSMutableArray*)polygonPoints
{
    PRFilledPolygon *filledPolygon = [self getTexture:textureName withPoints:polygonPoints];
    [self addChild:filledPolygon z:0];
}

-(NSMutableArray*)polygonPointsFromString:(NSString*)pointsString offset:(CGSize)offset flipY:(BOOL)flipY
{
    NSMutableArray *polygonPoints = [NSMutableArray array];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @", "];
    float fX, fY;
    int n;
    int i, k;
    int Ymult = flipY?-1:1;
    
    NSArray *pointsArray;
    
    if ([pointsString length])
    {
        pointsArray = [pointsString componentsSeparatedByCharactersInSet:characterSet];
        n = pointsArray.count;
        
        // build polygon verticies;
        for (i = 0, k = 0; i < n; ++k)
        {
            fX = [[pointsArray objectAtIndex:i] floatValue]-offset.width;
            ++i;
            fY = Ymult*[[pointsArray objectAtIndex:i] floatValue]-offset.height;
            ++i;
            
            [polygonPoints addObject:[NSValue valueWithCGPoint:ccp(fX, fY)]];
        }
    }
    return polygonPoints;
}

-(void)sceneEnd
{
    //Implement in subclass
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
