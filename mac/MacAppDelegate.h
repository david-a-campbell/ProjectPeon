#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(retain) NSWindow *window;
@property(retain) NSTextField *levelTitleLabel;
@property(retain) NSManagedObjectContext *managedObjectContext;
@property(retain) NSManagedObjectModel *managedObjectModel;
@property(retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
@end
