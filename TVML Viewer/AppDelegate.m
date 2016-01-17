//
//  AppDelegate.m
//  TVML Viewer
//
//  Created by Doug DeJulio on 11/7/15.
//  Copyright © 2015 AISB. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    TVApplicationControllerContext *appControllerContext = [[TVApplicationControllerContext alloc] init];

    NSURL *jsURL = [[NSBundle mainBundle] URLForResource:@"app" withExtension:@"js" subdirectory:@"stuff"];
    appControllerContext.javaScriptApplicationURL = jsURL;
    NSURL *rootURL = [appControllerContext.javaScriptApplicationURL URLByDeletingLastPathComponent];

    NSMutableDictionary *myLaunchOptions = [launchOptions mutableCopy];
    if (!myLaunchOptions) {
        myLaunchOptions = [[NSMutableDictionary alloc] init];
    }
    myLaunchOptions[@"BASEURL"] = [rootURL absoluteString];
    appControllerContext.launchOptions = myLaunchOptions;
    
    [TVElementFactory registerViewElementClass: [TVViewElement class] forElementName: @"toy"];
    [[TVInterfaceFactory sharedInterfaceFactory] setExtendedInterfaceCreator: self];

    self.appController = [[TVApplicationController alloc] initWithContext:appControllerContext window: self.window delegate: self];
    
    return YES;
}

- (NSURL *) URLForResource:(NSString *)resourceName {
    // Not 100% sure what this method is really for yet.  So let's
    // log how it's used to see if we can't figure it out.
    NSLog(@"URL for Resource: %@", resourceName);
    return NULL;
}

- (UIView *) viewForElement:(TVViewElement *)element existingView:(UIView *)existingView {
    // If it's an element we know how manage, handle it.
    // Turns out there's no need for a custom element class for common cases.
    if ([element.elementName isEqualToString: @"toy"]) {
        // If a view is passed in, return it back out.
        if (existingView) {
            return existingView;
        }
        // No view passed in, let's create one.
        UITextView *newView = [[UITextView alloc] init];
        NSString *value;
        if ((value = element.attributes[@"value"])) {
            newView.text = value;
        } else {
            NSError *error;
            NSDictionary *attributes;
            //NSString *htmlText = @"<p>The value was <em>not</em> set.</p>";
            NSData *htmlData = [NSData dataWithContentsOfURL: [NSURL URLWithString:@"http://www.aisb.org/~ddj/text.html"]];
            NSMutableAttributedString *value = [NSMutableAttributedString alloc];
            value = [value initWithData:htmlData options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:&attributes error:&error];
            newView.attributedText = value;
            //newView.text = @"No value attribute set.";
        }
        // Let's make it purple-on-yellow to make the bounds obvious.
        newView.backgroundColor = [UIColor yellowColor];
        newView.textColor = [UIColor purpleColor];
        return newView;
    }
    
    // Otherwise, punt.
    return NULL;
}

- (UIViewController *) viewControllerForElement:(TVViewElement *)element existingViewController:(UIViewController *)existingViewController {
    // For now, just punt.  No controller, no delegate, bye bye.
    /*
        Thought: is this the controller the best place to put the association
        between element objects and their view objects?  Doing so could
        actually let us use completely unmodified element and view classes!
     */
    return NULL;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationCachesDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "org.aisb.TVML_Viewer" in the application's caches directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TVML_Viewer" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationCachesDirectory] URLByAppendingPathComponent:@"TVML_Viewer.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
