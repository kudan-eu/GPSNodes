#import "GPSManager.h"
#import "GPSNode.h"

@interface GPSManager ()
@property (nonatomic, strong) CLLocation *previouslyUsedLocation;
@property (nonatomic, readwrite) BOOL initialised;
@end

NSString * const GPSWorldName = @"GPSWorld";

@implementation GPSManager

double DegreesToRadians(double degrees) {return degrees * M_PI / 180.0;};
double RadiansToDegrees(double radians) {return radians * 180.0 / M_PI;};

/**
 Maths method for calculating the bearing between two locations.
 @param source The start location.
 @param dest The end location.
 */
+ (double)bearingFrom:(CLLocation *)source to:(CLLocation *)dest
{
    double lat1 = DegreesToRadians(source.coordinate.latitude);
    double lon1 = DegreesToRadians(source.coordinate.longitude);
    
    double lat2 = DegreesToRadians(dest.coordinate.latitude);
    double lon2 = DegreesToRadians(dest.coordinate.longitude);
    
    double dLon = lon2 - lon1;
    
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double radiansBearing = atan2(y, x);
    
    return fmod( RadiansToDegrees( radiansBearing ) + 180, 360 );
}

+ (GPSManager *)getInstance
{
    static dispatch_once_t once;
    static GPSManager *manager;
    dispatch_once(&once, ^ {
        manager = [[GPSManager alloc] init];
        manager.initialised = NO;
    });
    return manager;
}

- (void)initialise
{
    // init instance variables.
    self.world = [ARWorld nodeWithName:GPSWorldName];
    self.previouslyUsedLocation = [CLLocation new];
    
    // Create the location manager on the main thread to ensure delegate methods always get called.
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_block_t block = ^{
        self.locationManager = [CLLocationManager new];
    };
    
    if ([NSThread isMainThread]) {
        block();
    }
    else {
        dispatch_sync(main, block);
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if (status == kCLAuthorizationStatusNotDetermined && [self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.delegate = self;
    
    // Init gyro manager and setup its reference frame.
    ARGyroManager *gyroManager = [ARGyroManager getInstance];
    [gyroManager initialise];
    gyroManager.gyroReferenceFrame = CMAttitudeReferenceFrameXTrueNorthZVertical;
    
    // Set up manager.
    self.world.visible = NO;
    self.initialised = YES;
}

- (void)deinitialise
{
    self.initialised = NO;
    [self stop];
    self.locationManager = nil;
    self.world = nil;
}

- (void)start
{
    if (!self.initialised) {
        [self initialise];
    }
    [self.locationManager startUpdatingLocation];
    
    self.world.visible = YES;
    
    [[ARGyroManager getInstance] start];
    [[ARRenderer getInstance] addDelegate:self];
}

- (void)stop
{
    [self.locationManager stopUpdatingLocation];
    
    self.world.visible = NO;
    
    [[ARGyroManager getInstance] stop];
    [[ARRenderer getInstance] removeDelegate:self];
}

/// ARRenderer delegate method called before rendering each frame, here we make sure that our orientation matches that of ARGyroManager
- (void)rendererPreRender
{
    [self updateNode];
}

/// Updates world orientation using ARGyroManager's world orientation
- (void)updateNode
{
    self.world.orientation = [ARGyroManager getInstance].world.orientation;
}

/// Location manager delegate method, updates GPSNodes' positions in camera if the user has moved from their previous location.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    double updateTimeInterval = 15.0;
    
    if (fabs(howRecent) < updateTimeInterval && [self.previouslyUsedLocation distanceFromLocation:location] != 0) {
        // If the event is recent and different to previous position.
        
        self.previouslyUsedLocation = location;
        
        // Update GPSNode positions relative to the camera.
        for (ARNode *node in self.world.children) {
            
            if ([node respondsToSelector:@selector(updateWorldPosition)] == YES) {
                [node performSelector:@selector(updateWorldPosition)];
            }
        }
    }
}

/// Location manager delegate method, called if location manager fails
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    [manager stopUpdatingLocation];
}

/// Returns the most recent update of the device location.
- (CLLocation *)getCurrentLocation
{
    return self.locationManager.location;
}

@end
