//  GameManager.m

#import "GameManager.h"
#import "cocos2d.h"
#import "MainMenuScene.h"
#import "BaseGameScene.h"
#import "CCTMXMapInfo+TMXParserExt.h"
#import "SaveManager.h"
#import "AppDelegate.h"

@implementation GameManager
static GameManager* _sharedGameManager = nil;                      // 1
@synthesize isMusicON;
@synthesize isSoundEffectsON;
@synthesize hasPlayerDied;
@synthesize currentLevelNum, currentPlanetNum;

+(GameManager*)sharedGameManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedGameManager = [[GameManager alloc] init];
    });
    return _sharedGameManager;
}

+(id)alloc
{
    @synchronized ([GameManager class])                            // 5
    {
        NSAssert(_sharedGameManager == nil,
                 @"Attempted to allocated a second instance of the Game Manager singleton"); // 6
        _sharedGameManager = [super alloc];
        return _sharedGameManager;                                 // 7
    }
    return nil;  
}

-(BOOL)waitForAudioManager
{
    // Wait to make sure soundEngine is initialized
    if ([CDAudioManager sharedManagerState] != kAMStateInitialised && [CDAudioManager sharedManagerState] != kAMStateUninitialised)
    {
        int waitCycles = 0;
        while (waitCycles < AUDIO_MAX_WAITTIME)
        {
            [NSThread sleepForTimeInterval:0.1f];
            if ([CDAudioManager sharedManagerState] == kAMStateInitialised || [CDAudioManager sharedManagerState] == kAMStateUninitialised)
                break;
            
            waitCycles = waitCycles + 1;
        }
    }
    return [CDAudioManager sharedManagerState] == kAMStateInitialised;
}

-(void)stopBackgroundMusic
{
    [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
}

-(void)playBackgroundTrack:(NSString*)trackFileName
{
    if ([self waitForAudioManager])
    {
        if ([[SimpleAudioEngine sharedEngine] isBackgroundMusicPlaying])
            [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
        
        [[SimpleAudioEngine sharedEngine] preloadBackgroundMusic:trackFileName];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:trackFileName loop:NO];
    }
}

-(void)playRandomTrackForCurrentScene
{
    NSArray *tracks = [self getMusicTracksForScene:[self shortSceneName:currentSceneName]];
    if (![tracks count]){return;}
    if ([tracks count] == 1)
    {
        [self playBackgroundTrack:[tracks objectAtIndex:0]];
        return;
    }
    
    int random = arc4random_uniform([tracks count]);
    while ([currentTrackName isEqualToString:[tracks objectAtIndex:random]])
    {
        random = arc4random_uniform([tracks count]);
    }
    [self playBackgroundTrack:[tracks objectAtIndex:random]];
    currentTrackName = [tracks objectAtIndex:random];
}

-(void)stopSoundEffect:(ALuint)soundEffectID
{
    if ([CDAudioManager sharedManagerState] == kAMStateInitialised)
        [[SimpleAudioEngine sharedEngine] stopEffect:soundEffectID];
}

-(ALuint)playSoundEffect:(NSString*)soundEffectKey
{
    ALuint soundID = 0;
    if ([CDAudioManager sharedManagerState] ==kAMStateInitialised)
        soundID = [[SimpleAudioEngine sharedEngine] playEffect:soundEffectKey];
    
    return soundID;
}

-(ALuint)playSoundEffect:(NSString *)soundEffectKey withProbability:(float)probability
{
    probability = probability*100;
    int random = arc4random_uniform(100);
    if (random<=probability)
    {
        return [self playSoundEffect:soundEffectKey];
    }
    return 0;
}

-(NSArray *)getSoundEffectsListForScene:(NSString*)scene
{
    return [[self soundEffectsByScene] objectForKey:scene];
}

-(NSArray *)getMusicTracksForScene:(NSString*)scene
{
    return [[self musicTracksByScene] objectForKey:scene];
}

-(NSMutableDictionary *)soundEffectsByScene
{
    if (![_soundEffectsByScene count])
    {
        _soundEffectsByScene = [[self dictForPlist:@"SoundEffects.plist"] retain];
    }
    return _soundEffectsByScene;
}

-(NSMutableDictionary *)musicTracksByScene
{
    if (![_musicTracksByScene count])
    {
        _musicTracksByScene = [[self dictForPlist:@"MusicTracks.plist"] retain];
    }
    return _musicTracksByScene;
}

-(void)loadAudioForSceneWithID:(NSString*)sceneName
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if ([self waitForAudioManager])
    {
        NSArray *soundEffectsToLoad = [self getSoundEffectsListForScene:sceneName];
        if (soundEffectsToLoad == nil) {return;}
        
        for(NSString *sound in soundEffectsToLoad)
            [[SimpleAudioEngine sharedEngine] preloadEffect:sound];
    }
    [pool release];
}

-(void)unloadAudioForSceneWithID:(NSString*)sceneName
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    if ([sceneName isEqualToString: NoSceneInitialized]){return;}
    
    NSArray *soundEffectsToUnload = [self getSoundEffectsListForScene:sceneName];
    if (soundEffectsToUnload == nil){return;}
    
    for(NSString *sound in soundEffectsToUnload)
        [[SimpleAudioEngine sharedEngine] unloadEffect:sound];
    [pool release];
}

-(void)initAudioAsync
{
    [CDSoundEngine setMixerSampleRate:CD_SAMPLE_RATE_MID];
    [CDAudioManager initAsynchronously:kAMM_FxPlusMusicIfNoOtherAudio];
    while ([CDAudioManager sharedManagerState] != kAMStateInitialised) 
    {
        [NSThread sleepForTimeInterval:0.1];
    }
    [[CDAudioManager sharedManager] setBackgroundMusicCompletionListener:self selector:@selector(playRandomTrackForCurrentScene)];
    [[CDAudioManager sharedManager] setResignBehavior:kAMRBStopPlay autoHandle:YES];
}

-(void)setupAudioEngine
{
    NSOperationQueue *queue = [[NSOperationQueue new] autorelease];
    NSInvocationOperation *asyncSetupOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(initAudioAsync) object:nil];
    [queue addOperation:asyncSetupOperation];
    [asyncSetupOperation autorelease];
    
    float musicVolume = [[SaveManager sharedManager] getMusicVolume];
    float sfxVolume = [[SaveManager sharedManager] getSfxVolume];
    [[SimpleAudioEngine sharedEngine] setBackgroundMusicVolume:musicVolume];
    [[SimpleAudioEngine sharedEngine] setEffectsVolume:sfxVolume];
}


//NON-SOUND RELATED STUFF-------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------

-(id)init {                                                        // 8
    self = [super init];
    if (self != nil) {
        // Game Manager initialized
        CCLOG(@"Game Manager Singleton, init");
        isMusicON = YES;
        isSoundEffectsON = YES;
        hasPlayerDied = NO;
        currentSceneName = NoSceneInitialized;
        _isPaused = NO;
        currentTrackName = @"";
        [self setAppNeedsRestart:NO];
    }
    return self;
}


-(void)runSceneWithName:(NSString*)sceneName
{    
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    if ([sceneName isEqualToString:currentSceneName]) {return;}
    
    Class classForScene = NSClassFromString(sceneName);
    CCScene *sceneToRun = (CCScene*)[classForScene node];
    if (sceneToRun == nil) 
    {
        //Probably put error message here stating that the scene was unavailable
        [self runSceneWithName:TitleSceneID];
        return;
    }
    NSString *oldSceneName = [currentSceneName retain];
    [currentSceneName release];
    currentSceneName = nil;
    currentSceneName = [sceneName retain];
    
    [self performSelectorInBackground:@selector(loadAudioForSceneWithID:) withObject:[self shortSceneName:sceneName]];
    if ([[CCDirector sharedDirector] runningScene] == nil)
    {
        [[CCDirector sharedDirector] pushScene:sceneToRun];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1 scene:sceneToRun]];
    }
    [self performSelectorInBackground:@selector(unloadAudioForSceneWithID:) withObject:[self shortSceneName:oldSceneName]];
    [oldSceneName release];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    if (![sceneName isEqualToString:TitleSceneID])
    {
        [self playRandomTrackForCurrentScene];
    }
}

-(void)runPlanet:(int)pNum level:(int)lNum
{
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    BaseGameScene *sceneToRun = [[[BaseGameScene alloc] initWithPlanet:pNum andLevel:lNum] autorelease];
    
    NSString *oldSceneName = [currentSceneName retain];
    [currentSceneName release];
    currentSceneName = nil;
    currentSceneName = [[NSString stringWithFormat:@"Planet%iLevel%iScene", pNum, lNum] retain];
    
    [self performSelectorInBackground:@selector(loadAudioForSceneWithID:) withObject:[self shortSceneName:currentSceneName]];
    
    if ([[CCDirector sharedDirector] runningScene] == nil) {
        [[CCDirector sharedDirector] pushScene:sceneToRun];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1 scene:sceneToRun]];
    }
    [self performSelectorInBackground:@selector(unloadAudioForSceneWithID:) withObject:[self shortSceneName:oldSceneName]];
    [oldSceneName release];
    [[CCTextureCache sharedTextureCache] removeUnusedTextures];
    
    [self playRandomTrackForCurrentScene];
}

-(NSString*)shortSceneName:(NSString*)sceneName
{
    if ([sceneName rangeOfString:@"Planet"].location != NSNotFound)
    {
        __block NSString *shortName = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Planet\\d+" options:NSRegularExpressionCaseInsensitive error:nil];
        [regex enumerateMatchesInString:sceneName options:0 range:NSMakeRange(0, [sceneName length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
        {
             shortName = [sceneName substringWithRange:[match range]];
        }];
        return shortName;
    }
    return sceneName;
}

-(void)openSiteWithLinkType:(LinkTypes)linkTypeToOpen
{
    NSURL *urlToOpen = nil;
    NSURL *faceBookApp = [NSURL URLWithString:@"fb://profile/ProjectPeon"];
    NSURL *twitterApp = [NSURL URLWithString:@"twitter://user?screen_name=ProjectPeon"];
    
    switch (linkTypeToOpen)
    {
        case kLinkTypeFacebook:
            if ([[UIApplication sharedApplication] canOpenURL:faceBookApp])
            {
                urlToOpen = faceBookApp;
            }else
            {
                urlToOpen = [NSURL URLWithString:@"http://www.facebook.com/ProjectPeon"];
            }
            break;
        case kLinkTypeTwitter:
            if ([[UIApplication sharedApplication] canOpenURL:twitterApp])
            {
                urlToOpen = twitterApp;
            }else
            {
                urlToOpen = [NSURL URLWithString:@"http://www.twitter.com/ProjectPeon"];
            }
            break;
        case kLinkTypeGameSite:
            urlToOpen = [NSURL URLWithString:@"http://www.ProjectPeon.com"];
            break;
        default:
            break;
    }
    
    if (![[UIApplication sharedApplication] openURL:urlToOpen])
    {
        CCLOG(@"%@%@",@"Failed to open url:",[urlToOpen description]);
    }    
}

-(NSMutableDictionary*)dictForPlist:(NSString*)plistName
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:plistName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath])
    {
        plistPath = [[NSBundle mainBundle] pathForResource:[plistName stringByReplacingOccurrencesOfString:@".plist" withString:@""] ofType:@"plist"];
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

-(void)setIsPaused:(BOOL)isPaused
{
    _isPaused = isPaused;
    if (_isPaused)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PAUSE object:nil];
    }else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_UNPAUSE object:nil];
    }
}

-(void)resignActive
{
    [[CCDirector sharedDirector] pause];
    [[CDAudioManager sharedManager] applicationWillResignActive];
}

-(void)becomeActive
{
    [[CCDirector sharedDirector] resume];
    [[CDAudioManager sharedManager] applicationDidBecomeActive];
}

-(CGPoint)currentTmxMaping
{
    NSString *inName = [NSString stringWithFormat:@"planet%iLevel%i", currentPlanetNum, currentLevelNum];
    NSMutableDictionary *dict = [self dictForPlist:@"tmxMappings.plist"];
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString: @" "];
    NSArray *components = [[dict valueForKey:inName] componentsSeparatedByCharactersInSet:characterSet];
    return ccp([[components objectAtIndex:0] intValue], [[components objectAtIndex:1] intValue]);
}

-(void)dealloc
{
    [self setSoundEffectsByScene:nil];
    [self setMusicTracksByScene:nil];
    [currentSceneName release];
    currentSceneName = nil;
    [super dealloc];
}

-(int)planetToShow
{
    int planetToLoad;
    if (!_loadCurrentPlanetByDefault)
    {
        planetToLoad = [[SaveManager sharedManager] getHighestPlanetUnlocked];
        if (planetToLoad > [[SaveManager sharedManager] numberOfPlanets])
        {
            planetToLoad = 1;
        }
    }else
    {
        planetToLoad = currentPlanetNum;
        _loadCurrentPlanetByDefault = NO;
    }
    
    return planetToLoad;
}

-(NSString*)currentPlanetName
{
    switch (currentPlanetNum)
    {
        case 1:
            return @"Earth";
            break;
        case 2:
            return @"Moon";
            break;
        case 3:
            return @"Mars";
            break;
        default:
            return [NSString stringWithFormat:@"%i", currentPlanetNum];
            break;
    }
}

@end
