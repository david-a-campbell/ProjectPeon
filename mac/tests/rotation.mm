#import "CartCreationLayer.h"
#import "CartPart.h"
#import "ShockAbsorber.h"
#import "Box2DHelpers.h"

#import "Platforms/Mac/CCGLView.h"

// Model-only fixtures exercise the production editor geometry without sprites.
@interface RotationPart : NSObject
@property CGPoint start, end;
@property GameObjectType gameObjectType;
@property BOOL isInForeground;
@end
@implementation RotationPart
@end
@interface ShockAbsorber (ZeroLengthTest)
- (void)setupJoint;
@end
@interface RotationOrigin : NSObject
@end
@implementation RotationOrigin
- (CGPoint)position { return CGPointZero; }
@end
@interface BoosterCapture : NSObject
@property CGPoint start, end;
@property GameObjectType type;
@property NSUInteger creations;
@end
@implementation BoosterCapture
- (void)createBarWithStart:(CGPoint)start andEnd:(CGPoint)end {
    [self createBoosterWithStart:start andEnd:end andType:kBarPartType];
}
- (void)createWheelWithStart:(CGPoint)start andEnd:(CGPoint)end {
    [self createBoosterWithStart:start andEnd:end andType:kWheelPartType];
}
- (void)createMotorWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type {
    [self createBoosterWithStart:start andEnd:end andType:type];
}
- (void)createShockWithStart:(CGPoint)start andEnd:(CGPoint)end {
    [self createBoosterWithStart:start andEnd:end andType:kShockPartType];
}
- (void)createBoosterWithStart:(CGPoint)start andEnd:(CGPoint)end andType:(GameObjectType)type {
    self.start=start; self.end=end; self.type=type; self.creations++;
}
@end
@interface CartCreationLayer (RotationTest)
- (void)createBoosterEnded;
- (void)createBarEnded;
- (void)createWheelEnded;
- (void)createMotorEnded;
- (void)createShockEndedStart:(CGPoint)start end:(CGPoint)end;
- (void)editBoosterEnded;
@end
@interface RotationEditor : CartCreationLayer
@property BOOL paused;
@property NSUInteger refreshes;
- (void)prepare:(RotationPart *)part shock:(RotationPart *)shock;
- (void)useTool:(ToolType)tool;
- (void)clearSelection;
- (void)capturePlacement:(BoosterCapture *)capture type:(ToolType)type;
- (void)captureEdit:(BoosterCapture *)capture;
@end
@implementation RotationEditor
- (void)prepare:(RotationPart *)part shock:(RotationPart *)shock {
    editingPart=(CartPart *)part;
    editingShocks=[NSMutableArray arrayWithObject:shock];
    moveEditTouch=(UITouch *)[NSObject new];
    layerToFollow=(CCLayer *)[RotationOrigin new];
    touchStartLocation=touchMovedLocation=ccp(500,400);
    cartCreationEnabled=YES;
    selectedTool=toolTypeEdit;
}
- (BOOL)shouldAllowCartCreation { return cartCreationEnabled && !self.paused; }
- (void)editPartMoved { self.refreshes++; }
- (void)useTool:(ToolType)tool { selectedTool=tool; }
- (void)clearSelection { moveEditTouch=nil; }
- (void)capturePlacement:(BoosterCapture *)capture type:(ToolType)type {
    cartCreationDelegate=(id<cartCreationDelegate>)capture;
    currentBoosterType=type;
    touchStartLocation=touchEndLocation=ccp(450,400);
    currentMotorType=type;
    switch(type) {
        case toolTypeBar: [self createBarEnded]; break;
        case toolTypeWheel: [self createWheelEnded]; break;
        case toolTypeMotor: case toolTypeMotor50: [self createMotorEnded]; break;
        case toolTypeShock: [self createShockEndedStart:touchStartLocation end:touchEndLocation]; break;
        default: [self createBoosterEnded]; break;
    }
}
- (void)captureEdit:(BoosterCapture *)capture {
    cartCreationDelegate=(id<cartCreationDelegate>)capture;
    touchEndLocation=touchMovedLocation;
    [self editBoosterEnded];
}
@end
@interface PeonView : CCGLView
- (CartCreationLayer *)rotationEditor;
@end
@interface RotationInputView : PeonView
@property(assign) RotationEditor *editor;
@end
@implementation RotationInputView
- (CartCreationLayer *)rotationEditor { return self.editor; }
- (NSOpenGLContext *)openGLContext { return nil; }
- (NSPoint)convertPoint:(NSPoint)point fromView:(NSView *)view { return point; }
@end
@interface RotationEvent : NSObject
@property NSPoint locationInWindow;
@property NSEventModifierFlags modifierFlags;
@property CGFloat rotation, scrollingDeltaX, scrollingDeltaY;
@property(retain) NSSet *touches;
@end
@implementation RotationEvent
- (NSSet *)touchesMatchingPhase:(NSTouchPhase)phase inView:(NSView *)view { return self.touches ?: [NSSet set]; }
@end
static void near(CGPoint actual, CGPoint expected) {
    NSCAssert(ccpDistance(actual,expected)<0.02,@"Unexpected rotation: (%f,%f) != (%f,%f)",actual.x,actual.y,expected.x,expected.y);
}
int main(int argc, const char **argv) {
    @autoreleasepool {
        for (NSNumber *type in @[@(kBarPartType), @(kShockPartType), @(kBoosterPartType), @(kBooster50PartType), @(kWheelPartType), @(kMotorPartType), @(kMotor50PartType)]) {
            RotationPart *part=[RotationPart new]; part.gameObjectType=(GameObjectType)type.intValue;
            part.start=ccp(450,400); part.end=ccp(550,400);
            RotationPart *shock=[RotationPart new]; shock.start=ccp(300,300); shock.end=part.end;
            RotationEditor *editor=[RotationEditor alloc]; [editor prepare:part shock:shock];
            BOOL center=part.gameObjectType==kBarPartType || part.gameObjectType==kShockPartType;
            [editor rotateFromMacByDegrees:90];
            near(part.start,center ? ccp(500,350) : ccp(450,400));
            near(part.end,center ? ccp(500,450) : ccp(450,500));
            near(shock.end,part.end); near(shock.start,ccp(300,300));
            [editor rotateFromMacByDegrees:-90];
            near(part.start,ccp(450,400)); near(part.end,ccp(550,400));
            NSCAssert(editor.refreshes==2,@"Preview must refresh for both directions");
            editor.paused=YES; [editor rotateFromMacByDegrees:45];
            editor.paused=NO; [editor useTool:toolTypeBar]; [editor rotateFromMacByDegrees:45];
            [editor useTool:toolTypeEdit]; [editor rotateFromMacByDegrees:NAN];
            [editor clearSelection]; [editor rotateFromMacByDegrees:45];
            near(part.end,ccp(550,400)); NSCAssert(editor.refreshes==2,@"Inactive editor rotated");
        }
        for (NSNumber *type in @[@(kBoosterPartType), @(kBooster50PartType)]) {
            RotationPart *booster=[RotationPart new]; booster.gameObjectType=(GameObjectType)type.intValue;
            booster.start=booster.end=ccp(450,400);
            RotationPart *attachment=[RotationPart new]; attachment.end=ccp(460,400);
            RotationEditor *zeroEditor=[RotationEditor alloc]; [zeroEditor prepare:booster shock:attachment];
            [zeroEditor rotateFromMacByDegrees:90];
            near(booster.start,ccp(450,400)); near(booster.end,ccp(450,401));
            near(attachment.end,ccp(450,410));
            BoosterCapture *saved=[BoosterCapture new]; [zeroEditor captureEdit:saved];
            near(saved.start,ccp(450,400)); near(saved.end,ccp(450,401));
            NSCAssert(saved.type==booster.gameObjectType,@"Editing changed booster type");
            [zeroEditor rotateFromMacByDegrees:-90]; near(booster.end,ccp(451,400));
        }
        for (NSNumber *tool in @[@(toolTypeBooster), @(toolTypeBooster50)]) {
            BoosterCapture *placed=[BoosterCapture new];
            RotationEditor *placementEditor=[RotationEditor alloc];
            [placementEditor capturePlacement:placed type:(ToolType)tool.intValue];
            near(placed.start,ccp(450,400)); near(placed.end,ccp(451,400));
        }
        puts("Zero-direction standard/upgraded boosters: placement, rotation, anchor and committed direction PASS");
        for (NSNumber *tool in @[@(toolTypeWheel), @(toolTypeMotor), @(toolTypeMotor50), @(toolTypeBar), @(toolTypeShock)]) {
            BoosterCapture *placed=[BoosterCapture new];
            RotationEditor *placementEditor=[RotationEditor alloc];
            [placementEditor capturePlacement:placed type:(ToolType)tool.intValue];
            BOOL rejected=tool.intValue==toolTypeBar || tool.intValue==toolTypeShock;
            NSCAssert(placed.creations==(rejected ? 0 : 1),@"Zero-length placement protection failed for tool %d",tool.intValue);
            if (!rejected) {
                near(placed.start,ccp(450,400)); near(placed.end,ccp(450+MIN_WHEEL_LENGTH,400));
            }
        }
        puts("All seven part types: valid directions or rejected zero-length placement PASS");
        ShockAbsorber *savedSpring=[ShockAbsorber alloc];
        savedSpring.start=savedSpring.end=ccp(450,400);
        [savedSpring setupJoint];
        NSCAssert(!savedSpring.setupSuccessful && savedSpring.joint==nullptr,@"Saved zero-length spring was accepted");
        b2World springWorld(b2Vec2(0,0));
        RotationPart *cartOwner=[RotationPart new]; cartOwner.gameObjectType=kPlayerCartType;
        RotationPart *roundPart=[RotationPart new]; roundPart.gameObjectType=kWheelPartType;
        for (int index=0;index<2;index++) {
            b2BodyDef body; body.type=b2_dynamicBody; body.userData=cartOwner;
            body.position=b2Vec2(450/pixelsToMeterRatio(),400/pixelsToMeterRatio());
            b2Body *wheel=springWorld.CreateBody(&body);
            b2CircleShape circle; circle.m_radius=20/pixelsToMeterRatio();
            wheel->CreateFixture(&circle,1)->SetUserData(roundPart);
        }
        ShockAbsorber *snappedSpring=[ShockAbsorber alloc]; snappedSpring.world=&springWorld;
        snappedSpring.start=ccp(450,400); snappedSpring.end=ccp(451,400);
        [snappedSpring setupJoint];
        NSCAssert(!snappedSpring.setupSuccessful && springWorld.GetJointCount()==0,@"Coincident snapped pivots created a zero-length spring");
        springWorld.GetBodyList()->SetTransform(b2Vec2(480/pixelsToMeterRatio(),400/pixelsToMeterRatio()),0);
        ShockAbsorber *validSpring=[ShockAbsorber alloc]; validSpring.world=&springWorld;
        validSpring.start=ccp(450,400); validSpring.end=ccp(480,400);
        [validSpring setupJoint];
        NSCAssert(validSpring.setupSuccessful && springWorld.GetJointCount()==1,@"Valid distinct spring attachments were rejected");
        puts("Saved and snapped zero-length spring attachments rejected before physics creation PASS");
        RotationPart *bar=[RotationPart new]; bar.gameObjectType=kBarPartType;
        bar.start=ccp(450,140); bar.end=ccp(550,140);
        RotationPart *shock=[RotationPart new]; shock.end=bar.end;
        RotationEditor *editor=[RotationEditor alloc]; [editor prepare:bar shock:shock];
        [editor rotateFromMacByDegrees:90];
        near(bar.start,ccp(450,140)); near(bar.end,ccp(550,140)); near(shock.end,bar.end);
        NSCAssert(editor.refreshes==0,@"Rotation through the floor must be rejected");
        puts("Mac rotation: pivots, degrees, reverse motion, attached shocks, floor limit and editing guards PASS");
        // Exercise the native input handlers, including changing Shift during
        // one continuous press and ignoring trackpad rotation.
        RotationPart *inputPart=[RotationPart new]; inputPart.gameObjectType=kBarPartType;
        inputPart.start=ccp(450,400); inputPart.end=ccp(550,400);
        RotationEditor *inputEditor=[RotationEditor alloc]; [inputEditor prepare:inputPart shock:[RotationPart new]];
        RotationInputView *view=[RotationInputView alloc]; view.editor=inputEditor;
        RotationEvent *event=[RotationEvent new]; event.rotation=20; event.scrollingDeltaX=20;
        [view rotateWithEvent:(NSEvent *)event]; [view scrollWheel:(NSEvent *)event];
        NSCAssert(inputEditor.refreshes==0 && [view valueForKey:@"pointer"]==nil,@"Hover gesture must not start editing");
        UITouch *press=[UITouch new]; press.location=press.previousLocation=ccp(500,400);
        [view setValue:press forKey:@"pointer"];
        [view setValue:[NSValue valueWithPoint:ccp(500,400)] forKey:@"previousRotationPoint"];
        event.locationInWindow=ccp(510,410); [view mouseDragged:(NSEvent *)event];
        near(press.location,ccp(510,410));
        event.modifierFlags=NSEventModifierFlagShift; [view flagsChanged:(NSEvent *)event];
        event.locationInWindow=ccp(530,410); [view mouseDragged:(NSEvent *)event];
        near(press.location,ccp(510,410)); NSCAssert(inputEditor.refreshes==1,@"Shift added mid-drag must rotate");
        event.modifierFlags=0; [view flagsChanged:(NSEvent *)event];
        event.locationInWindow=ccp(535,415); [view mouseDragged:(NSEvent *)event];
        near(press.location,ccp(515,415)); NSCAssert(inputEditor.refreshes==1,@"Shift release must resume movement without jumping");
        [view rotateWithEvent:(NSEvent *)event]; [view scrollWheel:(NSEvent *)event];
        NSCAssert(inputEditor.refreshes==1,@"Trackpad gestures must not rotate a held part");
        NSCAssert([view valueForKey:@"pointer"]==press,@"Disabled gestures dropped the pressed part");
        [view mouseUp:(NSEvent *)event];
        NSCAssert([view valueForKey:@"pointer"]==nil,@"Mouse release must finish the transaction");
        puts("Mac input: Shift enter/exit mid-drag, disabled trackpad gestures and no movement jumps PASS");
        // Fixtures intentionally bypass the scene/sprite lifecycle.
        exit(0);
    }
}
