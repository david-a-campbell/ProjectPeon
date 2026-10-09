#import "SaveManager.h"
#import "CartSave.h"
#import "Constants.h"
BOOL PeonKeyDown(unsigned short code) { return NO; }
@interface TestPart : NSObject
@property CGPoint start;
@property CGPoint end;
@property int gameObjectType;
@property int cartPartModifier;
@property BOOL isReadyForRemoval;
@end
@implementation TestPart
@end
@interface TestCart : NSObject
@property(retain) NSArray *components;
@end
@implementation TestCart
@end
@interface TestBuilder : NSObject
@property int count;
@end
@implementation TestBuilder
- (void)deleteAllCartParts { self.count=0; }
- (void)check:(CGPoint)start end:(CGPoint)end {
    NSCAssert(start.x==10.25+self.count && start.y==20.5, @"Start coordinate changed");
    NSCAssert(end.x==30.75 && end.y==40.125, @"End coordinate changed");
    self.count++;
}
- (void)createBarWithStart:(CGPoint)s andEnd:(CGPoint)e { [self check:s end:e]; }
- (void)createWheelWithStart:(CGPoint)s andEnd:(CGPoint)e { [self check:s end:e]; }
@end
int main(int argc,const char **argv) {
    @autoreleasepool {
        [NSValueTransformer setValueTransformer:[[[ImageToDataTransformer alloc] init] autorelease] forName:@"ImageToDataTransformer"];
        NSManagedObjectModel *model=[[[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:@(argv[1])]] autorelease];
        NSPersistentStoreCoordinator *coordinator=[[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
        NSError *error=nil;
        NSCAssert([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:@(argv[2])] options:nil error:&error],@"Store failed: %@",error);
        NSManagedObjectContext *context=[[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
        context.persistentStoreCoordinator=coordinator;
        SaveManager *manager=[[[SaveManager alloc] init] autorelease];
        [manager setValue:context forKey:@"context"];
        manager.offset=CGPointMake(100,200);
        NSCAssert(manager.hasBooster50Unlocked && manager.hasMotor50Unlocked && manager.hasAnyPurchases,@"Paid upgrades not available by default");
        puts("All paid upgrades available offline with fresh and reopened saves: PASS");
        if([@(argv[3]) isEqual:@"write"]) {
            NSManagedObject *purchases=[manager performSelector:@selector(getPurchasesObject)];
            NSCAssert([[purchases valueForKey:@"hasBooster50"] boolValue] && [[purchases valueForKey:@"hasMotor50"] boolValue],@"New purchase records are locked");
            // Simulate an old save with no purchases; it must still unlock on reopen.
            [purchases setValue:@NO forKey:@"hasBooster50"];
            [purchases setValue:@NO forKey:@"hasMotor50"];
            TestPart *bar=[[[TestPart alloc] init] autorelease], *wheel=[[[TestPart alloc] init] autorelease];
            bar.start=CGPointMake(10.25,20.5); bar.end=CGPointMake(30.75,40.125); bar.gameObjectType=kBarPartType;
            wheel.start=CGPointMake(11.25,20.5); wheel.end=bar.end; wheel.gameObjectType=kWheelPartType;
            TestCart *cart=[[[TestCart alloc] init] autorelease]; cart.components=@[bar,wheel];
            NSBitmapImageRep *rep=[[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:8 pixelsHigh:8 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:32 bitsPerPixel:32] autorelease];
            memset(rep.bitmapData,255,256);
            NSImage *image=[[[NSImage alloc] initWithSize:NSMakeSize(8,8)] autorelease]; [image addRepresentation:rep];
            [manager saveCart:(id)cart andImage:image];
            NSCAssert(!context.hasChanges,@"Save did not persist");
            puts("Cart save: PASS");
        } else {
            [manager loadSavedData];
            NSCAssert(manager.numberOfSavedCarts==1,@"Saved cart missing after restart");
            NSCAssert([manager imageForIndex:0].CGImage!=NULL,@"Thumbnail missing");
            TestBuilder *builder=[[[TestBuilder alloc] init] autorelease]; manager.creationDelegate=(id)builder;
            [manager loadCartAtIndex:0]; NSCAssert(builder.count==2,@"Parts missing");
            [manager deleteCartAtIndex:0]; [manager loadSavedData];
            NSCAssert(manager.numberOfSavedCarts==0,@"Delete failed");
            puts("Cart reload after process restart, thumbnail, ordered geometry and deletion: PASS");
        }
    }
    return 0;
}
