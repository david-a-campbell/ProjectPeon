//  GameManager.h
//  SpaceViking
//
#import <Foundation/Foundation.h>
#import "Constants.h"
#import "SimpleAudioEngine.h"
#import "CDAudioManager.h"
@class CCScene;

@interface GameManager : NSObject
{
    BOOL isMusicON;
    BOOL isSoundEffectsON;
    BOOL hasPlayerDied;
    NSString* currentSceneName;
    NSString* currentTrackName;
}
@property (readwrite) BOOL isMusicON;
@property (readwrite) BOOL isSoundEffectsON;
@property (nonatomic, readwrite) BOOL isPaused;
@property (readwrite) BOOL hasPlayerDied;
@property (readwrite) int currentPlanetNum;
@property (readwrite) int currentLevelNum;
@property (nonatomic, retain) NSMutableDictionary *soundEffectsByScene;
@property (nonatomic, retain) NSMutableDictionary *musicTracksByScene;
@property (nonatomic, assign) BOOL appNeedsRestart;
@property (nonatomic, assign) BOOL loadCurrentPlanetByDefault;

+(GameManager*)sharedGameManager;
-(void)openSiteWithLinkType:(LinkTypes)linkTypeToOpen ;
// Chapter 8
-(void)setupAudioEngine;
-(ALuint)playSoundEffect:(NSString*)soundEffectKey;
-(void)stopSoundEffect:(ALuint)soundEffectID;
-(ALuint)playSoundEffect:(NSString *)soundEffectKey withProbability:(float)probability;
-(void)playBackgroundTrack:(NSString*)trackFileName;
-(void)runSceneWithName:(NSString*)sceneName;
-(void)runPlanet:(int)pNum level:(int)lNum;
-(void)resignActive;
-(void)becomeActive;
-(NSMutableDictionary*)dictForPlist:(NSString*)plistName;
-(CGPoint)currentTmxMaping;
-(void)stopBackgroundMusic;
-(void)playRandomTrackForCurrentScene;
-(int)planetToShow;
-(NSString*)currentPlanetName;

@end
