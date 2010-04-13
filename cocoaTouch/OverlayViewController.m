//
//  overlayViewController.m
//  HedgewarsMobile
//
//  Created by Vittorio on 16/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OverlayViewController.h"
#import "SDL_uikitappdelegate.h"
#import "PascalImports.h"
#import "CGPointUtils.h"
#import "SDL_mouse.h"
#import "PopoverMenuViewController.h"
#import "CommodityFunctions.h"

@implementation OverlayViewController
@synthesize dimTimer, popoverController, popupMenu;


-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	return rotationManager(interfaceOrientation);
}


-(void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

/*
- (void)didRotate:(NSNotification *)notification {	
	if (orientation == UIDeviceOrientationLandscapeLeft) {
	}
    if (orientation == UIDeviceOrientationLandscapeRight) {
    }
	if (orientation == UIDeviceOrientationPortrait) {
	}
    if (orientation == UIDeviceOrientationPortrait) {
	}
}
*/

-(void) viewDidLoad {
    /*
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];	
    [[NSNotificationCenter defaultCenter] addObserver:self
							selector:@selector(didRotate:)
							name:UIDeviceOrientationDidChangeNotification
							object:nil];
    */
    isPopoverVisible = NO;
    self.view.alpha = 0;

    // needed for rotation to work on os < 3.2
    self.view.center = CGPointMake(self.view.frame.size.height/2.0, self.view.frame.size.width/2.0);
    self.view.transform = CGAffineTransformRotate(self.view.transform, (M_PI/2.0));
    self.view.frame = [[UIScreen mainScreen] applicationFrame];
    
    dimTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:6]
                                        interval:1000
                                          target:self
                                        selector:@selector(dimOverlay)
                                        userInfo:nil
                                         repeats:YES];
    
    // add timer too runloop, otherwise it doesn't work
    [[NSRunLoop currentRunLoop] addTimer:dimTimer forMode:NSDefaultRunLoopMode];
    // listen for dismissal of the popover (see below)x
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissPopover) name:@"dismissPopover" object:nil];
    // present the overlay after 2 seconds
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(showMenuAfterwards) userInfo:nil repeats:NO];
}

-(void) viewDidUnload {
	[dimTimer invalidate];
	self.dimTimer = nil;
    self.popoverController = nil;
    self.popupMenu = nil;
    [super viewDidUnload];
}

-(void) dealloc {
    [popupMenu release];
    [popoverController release];
    // dimTimer is autoreleased
    [super dealloc];
}

// draws the controller overlay after the sdl window has taken control
-(void) showMenuAfterwards {
    [[SDLUIKitDelegate sharedAppDelegate].uiwindow bringSubviewToFront:self.view];

	[UIView beginAnimations:@"showing overlay" context:NULL];
	[UIView setAnimationDuration:1];
	self.view.alpha = 1;
	[UIView commitAnimations];
}

// dim the overlay when there's no more input for a certain amount of time
-(IBAction) buttonReleased:(id) sender {
	HW_allKeysUp();
    [dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.7]];
}

// nice transition for dimming
-(void) dimOverlay {
    [UIView beginAnimations:@"overlay dim" context:NULL];
   	[UIView setAnimationDuration:0.6];
    self.view.alpha = 0.2;
	[UIView commitAnimations];
}

// set the overlay visible and put off the timer for enough time
-(void) activateOverlay {
    self.view.alpha = 1;
    [dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:1000]];
}

// issue certain action based on the tag of the button 
-(IBAction) buttonPressed:(id) sender {
    [self activateOverlay];
    if (isPopoverVisible) {
        [self dismissPopover];
    }
    UIButton *theButton = (UIButton *)sender;
    
    switch (theButton.tag) {
        case 0:
            HW_walkLeft();
            break;
        case 1:
            HW_walkRight();
            break;
        case 2:
            HW_aimUp();
            break;
        case 3:
            HW_aimDown();
            break;
        case 4:
            HW_shoot();
            break;
        case 5:
            HW_jump();
            break;
        case 6:
            HW_backjump();
            break;
        case 7:
            HW_tab();
            break;
        case 10:
            [self showPopover];
            break;
        default:
            NSLog(@"Nope");
            break;
    }
}

// present a further check before closing game
-(void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
	if ([actionSheet cancelButtonIndex] != buttonIndex)
	    HW_terminate(NO);
	else
        HW_pause();		
}

// show up a popover containing a popupMenuViewController; we hook it with setPopoverContentSize
// on iphone instead just use the tableViewController directly (and implement manually all animations)
-(IBAction) showPopover{
    isPopoverVisible = YES;
    Class popoverControllerClass = NSClassFromString(@"UIPopoverController");
    if (popoverControllerClass) {
#ifdef __IPHONE_3_2
        popupMenu = [[PopoverMenuViewController alloc] initWithStyle:UITableViewStylePlain];
        popoverController = [[popoverControllerClass alloc] initWithContentViewController:popupMenu];
        [popoverController setPopoverContentSize:CGSizeMake(220, 170) animated:YES];
        [popoverController setPassthroughViews:[NSArray arrayWithObject:self.view]];
        
        [popoverController presentPopoverFromRect:CGRectMake(960, 0, 220, 32)
                                           inView:self.view
                         permittedArrowDirections:UIPopoverArrowDirectionUp 
                                         animated:YES];
#endif
    } else {
        popupMenu = [[PopoverMenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
        popupMenu.view.backgroundColor = [UIColor clearColor];
        popupMenu.view.frame = CGRectMake(480, 0, 200, 170);
        [self.view addSubview:popupMenu.view];

        [UIView beginAnimations:@"showing popover" context:NULL];
        [UIView setAnimationDuration:0.35];
        popupMenu.view.frame = CGRectMake(280, 0, 200, 170);
        [UIView commitAnimations];
    }
    popupMenu.tableView.scrollEnabled = NO;
}

// on ipad just dismiss it, on iphone transtion on the right
-(void) dismissPopover {
    if (YES == isPopoverVisible) {
        isPopoverVisible = NO;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
#ifdef __IPHONE_3_2
            [popoverController dismissPopoverAnimated:YES];
#endif
        } else {
            [UIView beginAnimations:@"hiding popover" context:NULL];
            [UIView setAnimationDuration:0.35];
            popupMenu.view.frame = CGRectMake(480, 0, 200, 170);
            [UIView commitAnimations];
        
            [popupMenu.view performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.35];
            [popupMenu performSelector:@selector(release) withObject:nil afterDelay:0.35];
            
            //[dimTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:2.7]];
        }
        [self buttonReleased:nil];
    }
}


#pragma mark -
#pragma mark Custom touch event handling

#define kMinimumPinchDelta      50
#define kMinimumGestureLength	10
#define kMaximumVariance        3

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	UITouch *touch = [touches anyObject];
	int width = [[UIScreen mainScreen] bounds].size.width;
    
    if (isPopoverVisible) {
        [self dismissPopover];
    }
        
	switch ([touches count]) {
		case 1:
			gestureStartPoint = [touch locationInView:self.view];
			initialDistanceForPinching = 0;
			switch ([touch tapCount]) {
				case 1:
					NSLog(@"X:%d Y:%d", (int)gestureStartPoint.x, (int)gestureStartPoint.y );
					SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							      (int)gestureStartPoint.y, width - (int)gestureStartPoint.x);
					HW_click();
					break;
				case 2:
					HW_ammoMenu();
					break;
				default:
					break;
			}
			break;
		case 2:
			if (2 == [touch tapCount]) {
				HW_zoomReset();
			}
			
			// pinching
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			initialDistanceForPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
			break;
		default:
			break;
	}

}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	initialDistanceForPinching = 0;
	gestureStartPoint.x = 0;
	gestureStartPoint.y = 0;
	HW_allKeysUp();
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	// this can happen if the user puts more than 5 touches on the screen at once, or perhaps in other circumstances.
	[self touchesEnded:touches withEvent:event];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	NSArray *twoTouches;
	CGPoint currentPosition;
	UITouch *touch = [touches anyObject];
	int width = [[UIScreen mainScreen] bounds].size.width;

	switch ([touches count]) {
		case 1:
			currentPosition = [touch locationInView:self.view];
			// panning
			SDL_WarpMouseInWindow([SDLUIKitDelegate sharedAppDelegate].window, 
							(int)gestureStartPoint.y, width - (int)gestureStartPoint.x);
			// remember that we have x and y inverted
			/* temporarily disabling hog movements for camera panning testing
			CGFloat vertDiff = gestureStartPoint.x - currentPosition.x;
			CGFloat horizDiff = gestureStartPoint.y - currentPosition.y;
			CGFloat deltaX = fabsf(vertDiff);
			CGFloat deltaY = fabsf(horizDiff);
			
			if (deltaY >= kMinimumGestureLength && deltaX <= kMaximumVariance) {
				NSLog(@"Horizontal swipe detected, begX:%f curX:%f", gestureStartPoint.x, currentPosition.x);
				if (horizDiff > 0) HW_walkLeft();
				else HW_walkRight();
			} else if (deltaX >= kMinimumGestureLength && deltaY <= kMaximumVariance){
				NSLog(@"Vertical swipe detected, begY:%f curY:%f", gestureStartPoint.y, currentPosition.y);
				if (vertDiff < 0) HW_aimUp();
				else HW_aimDown();
			}
			*/
			break;
		case 2:
			twoTouches = [touches allObjects];
			UITouch *first = [twoTouches objectAtIndex:0];
			UITouch *second = [twoTouches objectAtIndex:1];
			CGFloat currentDistanceOfPinching = distanceBetweenPoints([first locationInView:self.view], [second locationInView:self.view]);
			
			if (0 == initialDistanceForPinching) 
				initialDistanceForPinching = currentDistanceOfPinching;

			if (currentDistanceOfPinching < initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomOut();
			else if (currentDistanceOfPinching > initialDistanceForPinching + kMinimumPinchDelta)
				HW_zoomIn();

			currentDistanceOfPinching = initialDistanceForPinching;
			break;
		default:
			break;
	}
}


@end
