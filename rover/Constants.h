#import "CCDirector.h"
//  Constants.h

#define UnlockScore 50.0f
#define GroundZ 500
#define GroundHeight 128.0f
#define AdOffset -45.0f

//Notifications
#define NOTIFICATION_WILL_RESIGN_ACTIVE @"Will Resign Active"
#define NOTIFICATION_DID_BECOME_ACTIVE  @"Did become Active"
#define NOTIFICATION_BEGIN_GAMEPLAY @"Begin Gameplay"
#define NOTIFICATION_TRIGGER_SPRITE @"Trigger Sprite"
#define NOTIFICATION_END_GAMEPLAY @"End Gameplay"
#define NOTIFICATION_SAVE_CART_COMPLETE @"Save Cart Complete"
#define NOTIFICATION_DELETE_CART_COMPLETE @"Delete Cart Complete"
#define NOTIFICATION_FADE_SAVE_BACKING @"Fade Save Backing"
#define NOTIFICATION_LEVEL_COMPLETE @"Level Complete"
#define NOTIFICATION_SCENE_EXIT @"Scene Exit"
#define NOTIFICATION_CONTROL_TYPE_CHANGED @"Control Type Changed"
#define NOTIFICATION_PAUSE @"Pause"
#define NOTIFICATION_UNPAUSE @"UnPause"
#define NOTIFICATION_RESET_GAMEPLAY @"Reset Gameplay"
#define NOTIFICATION_PURCHASED_ITEM @"Purchased Item"
#define NOTIFICATION_WILL_ROTATE @"Device Will Rotate"

typedef enum {
    kLinkTypeFacebook,
    kLinkTypeTwitter,
    kLinkTypeGameSite
} LinkTypes;


typedef enum
{
    kPopupTypeLevelSelect,
    kPopupTypeGamePlay,
    kPopupTypeCartCreation,
    kPopupSettings,
    kPopupTitleSettings,
    kPopupGameInfo,
    kPopupStore
} PopupType;

// Debug Enemy States with Labels
// 0 for OFF, 1 for ON
#define ENEMY_STATE_DEBUG 0

// Audio Items
#define AUDIO_MAX_WAITTIME 150

// Audio Constants
#define SFX_NOTLOADED NO
#define SFX_LOADED YES

#define PLAYSOUNDEFFECT(...) \
[[GameManager sharedGameManager] playSoundEffect:@#__VA_ARGS__]

#define STOPSOUNDEFFECT(...) \
[[GameManager sharedGameManager] stopSoundEffect:__VA_ARGS__]

// Background Music
// Menu Scenes
#define BACKGROUND_TRACK_MAIN_MENU @"VikingPreludeV1.mp3"

// GameLevel1 (Ole Awakens)
#define BACKGROUND_TRACK_OLE_AWAKES @"SpaceDesertV2.mp3"

// Physics Puzzle Level
#define BACKGROUND_TRACK_PUZZLE @"VikingPreludeV1.mp3"

// Physics MineCart Level
#define BACKGROUND_TRACK_MINECART @"DrillBitV2.mp3"

// Physics Escape Level
#define BACKGROUND_TRACK_ESCAPE @"EscapeTheFutureV3.mp3"

#define ACCEL_MULTIPLIER 3
#define DUST_PROBABILITY 25
#define DUST_MAX 5
#define WINWIDTH [[CCDirector sharedDirector] winSizeInPixels].width
#define SCREEN_SCALE WINWIDTH/2048.0
#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] > 1.0)

typedef enum
{
    kGroundCat =            0b1000000000000000,
    kLayer1Cat =            0b0000000000000001,
    kLayer2Cat =            0b0000000000000010,
    kLayer3Cat =            0b0000000000000100,

    kThingyCat =            0b0010000000000000,
    kPodCat =               0b0000000010000000,
    kRampCat =              0b0000000100000000,
    kCollideNoneCat =       0b1111111111111111,
}CollisionCategory;

typedef enum
{
    kPodMask    =            0b1111111011111111,
    kRampMask   =            0b1111111101111111,
    kThingyGhostMask =       0b1001111111111000,
    kRampOnlyMask =          0b0000000100000000,
    
    kCollideAllMask =        0b1011111111111111,
    kCollideWithNone =       0b0000000000000000,
    kDontCollideWithGround = 0b0011111111111111,
}CollisionMask;

typedef enum 
{
    toolTypeNone = 0,
    toolTypeBar = 1,
    toolTypeWheel = 2,
    toolTypeMotor = 3,
    toolTypeShock = 4,
    toolTypeBooster = 5,
    toolTypeDelete = 6,
    toolTypeSave = 7,
    toolTypeShop = 8,
    toolTypeMotor50 = 9,
    toolTypeBooster50 = 10,
    toolTypeEdit = 11
} ToolType;

#define MIN_BAR_LENGTH 64
#define MIN_WHEEL_LENGTH 32
#define MAX_WHEEL_LENGTH 175
#define MAX_CART_PARTS 70
#define MAX_BRIDGE_ANGLE 20

//Layer Constants followed by acceptable values in comment
#define ParallaxRatioY @"ParallaxRatioY" // Integers or Floating point 1.0, 2.2,-1... (negative numbers will cause movement in opposite direction)
#define ParallaxRatioX @"ParallaxRatioX"
#define ZOrder @"ZOrder" //will override the automatic zOrder of a layer - Integers only
#define Texture @"Texture"
#define Scale @"Scale"
#define MotionY @"MotionY"
#define MotionX @"MotionX"
#define ForceX @"ForceX"
#define ForceY @"ForceY"
#define ForceAmount @"ForceAmount"
#define IsLiquid @"IsLiquid"
#define Use8888 @"Use8888"

//Object Group Constants (to be set as name of object layer)
#define ObjectGroupCollisions @"ObjectGroupCollisions"
#define ObjectGroupLayerPlaceholder @"ObjectGroupLayerPlaceholder"
#define ObjectGroupSprites @"ObjectGroupSprites"
#define ObjectGroupSensors @"ObjectGroupSensors"

//Sprites - Load these in by adding the values below to Tiled's object types and then selecting them when you create an object 
#define VikingPlayerSprite @"VikingPlayerSprite"
#define CartPlayerSprite @"CartPlayerSprite"
#define DiggerSprite @"DiggerSprite"
#define ThingySprite @"ThingySprite"
#define PlaceholderFileName @"PlaceholderFileName" //to be used with layer placeholder Object groups only
#define PlayerClip @"PlayerClip" //any collision area with this as its type will not be "jumpable"
#define TexturedGround @"TexturedGround"
#define TexArea @"TexturedArea"
#define BreakGround @"BreakGround"
#define TexturedRock @"TexturedRock"
#define TexturedMorphGround @"TexturedMorphGround"
#define BridgeSprite @"BridgeSprite"
#define ElevatorSprite @"ElevatorSprite"
#define WormholeSprite @"WormholeSprite"
#define PodSprite @"PodSprite"
#define ForceSprite @"ForceSprite"
#define SplashZoneSprite @"SplashZoneSprite"
#define TriggerSprite @"TriggerSprite"
#define CompSprite @"CompositeSprite"

#define NoSceneInitialized @"NoSceneInitialized"
#define MainMenuSceneID @"MainMenuScene"
#define TitleSceneID @"TitleScene"

//StoreItems
#define PRODUCT_BOOST_50 @"Booster50UpgradeID"
#define PRODUCT_MOTOR_50 @"Motor50UpgradeID"

