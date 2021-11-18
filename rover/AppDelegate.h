//
//  AppDelegate.h
//  rover
//
//  Created by David Campbell on 3/3/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GameNavControllerViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, CCDirectorDelegate> {
	UIWindow			*window;
	CCDirectorIOS	*director_;	
    CCGLView *glView;
	GameNavControllerViewController *navController_;
}
@property (readonly) CCDirectorIOS *director;
@property (nonatomic, retain) UIWindow *window;
//@property (readonly) UINavigationController *navController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
@end
