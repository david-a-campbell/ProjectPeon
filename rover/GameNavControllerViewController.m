//
//  GameNavControllerViewController.m
//  rover
//
//  Created by David Campbell on 9/19/12.
//  Copyright (c) 2012 Digital Fury. All rights reserved.
//

#import "GameNavControllerViewController.h"
#import "Constants.h"

#ifdef PROJECTPEON_IOS
@interface PeonGameContainer : UIViewController
@end
@implementation PeonGameContainer
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect safe = UIEdgeInsetsInsetRect(self.view.bounds, self.view.safeAreaInsets);
    CGFloat scale = MIN(safe.size.width / 1024.0, safe.size.height / 768.0);
    CGSize size = CGSizeMake(1024.0 * scale, 768.0 * scale);
    self.childViewControllers.firstObject.view.frame = CGRectMake(
        CGRectGetMidX(safe) - size.width / 2, CGRectGetMidY(safe) - size.height / 2,
        size.width, size.height);
}
@end
#endif

@interface GameNavControllerViewController ()

@end

@implementation GameNavControllerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
#ifdef PROJECTPEON_IOS
    self.view.backgroundColor = [UIColor blackColor];
#endif
	// Do any additional setup after loading the view.
}

#ifdef PROJECTPEON_IOS
- (id)initWithRootViewController:(UIViewController *)gameController {
    PeonGameContainer *container = [[[PeonGameContainer alloc] init] autorelease];
    [container addChildViewController:gameController];
    [container.view addSubview:gameController.view];
    [gameController didMoveToParentViewController:container];
    return [super initWithRootViewController:container];
}
- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)prefersHomeIndicatorAutoHidden { return YES; }
- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures { return UIRectEdgeAll; }
#endif

-(BOOL)shouldAutorotate
{
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_WILL_ROTATE object:nil];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
