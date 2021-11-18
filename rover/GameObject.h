//  GameObject.h
//  SpaceViking
//
#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Constants.h"
#import "CommonProtocols.h"
#import "GameManager.h"
@class PRFilledPolygon;

//@interface GameObject : CCSVGSprite
@interface GameObject : CCSprite
{
    BOOL isActive;
    BOOL reactsToScreenBoundaries;
    CGSize screenSize;
    GameObjectType gameObjectType;
}
@property (readwrite) BOOL isActive;
@property (readwrite) BOOL reactsToScreenBoundaries;
@property (nonatomic, assign) BOOL canPlaySound;
@property (readwrite) CGSize screenSize;
@property (readwrite) GameObjectType gameObjectType;
-(void)changeState:(CharacterStates)newState; 
-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray*)listOfGameObjects; 
-(CGRect)adjustedBoundingBox;
-(void)setupTexture:(NSString*)textureName withPoints:(NSMutableArray*)polygonPoints;
-(PRFilledPolygon*)getTexture:(NSString*)textureName withPoints:(NSMutableArray*)polygonPoints;
-(NSMutableArray*)polygonPointsFromString:(NSString*)pointsString offset:(CGSize)offset flipY:(BOOL)flipY;
-(CCAnimation*)loadPlistForAnimationWithName:(NSString*)animationName andClassName:(NSString*)className;
-(NSMutableArray*)allAnimationsFromPlist:(NSString*)plistName;
-(NSMutableDictionary*)animationDictFromPlist:(NSString*)plistName;
-(ALuint)playSoundEffect:(NSString*)soundEffectKey;
-(ALuint)playSoundEffect:(NSString *)soundEffectKey withProbability:(float)probability;
-(void)sceneEnd;
@end
