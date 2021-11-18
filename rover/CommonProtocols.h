//  CommonProtocols.h
//  SpaceViking
@class PlayerCart;
@class CartPart;

typedef enum {
    kDirectionLeft = 0,
    kDirectionRight = 1,
    kDirectionForward = 2
} GameDirection;

typedef enum {
    kDirectionVertical,
    kDirectionHorizontal,
    kDirectionDiagonalUp,
    kDirectionDiagonalDown
} ElevatorDirection; // 1

typedef enum {
    kStateSpawning,
    kStateIdle,
    kStateCrouching,
    kStateStandingUp,
    kStateWalking,
    kStateAttacking,
    kStateJumping,
    kStateBreathing,
    kStateTakingDamage,
    kStateDead,
    kStateTraveling,
    kStateRotating, 
    kStateDrilling,
    kStateAfterJumping,
    kStateFalling,
    kStateSpinning,
    kStateFloating,
    kStateDoorClosed,
    kStateAwaitingCart,
    kStateMovingTo,
    kStateMovingBack,
    kStateMovementStopped,
    kStateForceStopped,
    kStateForceApplied,
    kStateForceWaiting
} CharacterStates; // 1

typedef enum
{
    kStateStopped,
    kState5Fade,
    kState4Fade,
    kState3Fade,
    kState2Fade,
    kState1Fade,
    kState0Fade,
    kStateReadyToGo
} TimerStates;

typedef enum
{
    kStateGreen,
    kStateYellow,
    kStateRed,
    kStateClear
} ColorStates;

typedef enum {
    kObjectTypeNone,
    kPowerUpTypeHealth,
    kVikingType,
    kVikingCartType,
    kGroundType,
    kBreakableGroundType,
    kRockType,
    kMorphGroundType,
    kBridgeType,
    kElevatorType,
    kPlayerClipType,
    kPlayerCartType,
    kBarPartType,
    kWheelPartType,
    kBoosterPartType,
    kBooster50PartType,
    kMotorPartType,
    kMotor50PartType,
    kShockPartType,
    kThingyBasic,
    kWormholeType,
    kPodType,
    kForceAreaType,
    kTexturedArea,
    kSpriteTrigger,
    kCompositeSpriteType,
    kSplashZoneType
} GameObjectType;

typedef enum
{
    kStandardPart,
    kTitanium,
    kAluminium,
    kCarbonFiber,
    kMediumSpeedMediumTorque,
    kHighTorqueSlowSpeed,
    kHighSpeedLowTorque,
    kLowTension,
    KHighTension,
    kTransfersRotation,
    kMedBurstMedRecharge,
    kShortBurstLowRecharge,
    kLongBurstLongRecharge
}CartPartModifier;

@protocol GameplayLayerDelegate
-(void)createObjectOfType:(GameObjectType)objectType 
               withHealth:(int)initialHealth
               atLocation:(CGPoint)spawnLocation 
               withZValue:(int)ZValue;

-(void)createPhaserWithDirection:(GameDirection)phaserDirection 
                     andPosition:(CGPoint)spawnPosition;
@end

@protocol cartCreationDelegate <NSObject>
-(void)createBarWithStart:(CGPoint)start andEnd:(CGPoint)end;
-(void)createWheelWithStart:(CGPoint)start andEnd:(CGPoint)end;
-(void)createMotorWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type;
-(void)createShockWithStart:(CGPoint)start andEnd:(CGPoint)end;
-(void)createBoosterWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type;
-(void)deletePartStarted:(CGPoint)start;
-(CartPart*)deletePartAtLocation:(CGPoint)location outputShocks:(NSMutableArray *)outShocks;
-(void)deletePartMoved:(CGPoint)moved;
-(void)deletePartCanceled;
-(void)deletePartEnded;
-(void)deleteAllCartParts;
-(void)startAction;
-(void)stopAction;
-(void)resetAction;
-(void)saveCart;
-(float)getMapTime;
-(BOOL)cartHasParts;
-(int)getPeonCount;
-(int)getPodPeonCount;
-(PlayerCart*)getPlayerCart;
-(void)highlightCart;
-(void)unhighlightCart;
-(int)numberOfCartParts;
@end