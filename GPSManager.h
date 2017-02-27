#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <KudanAR/KudanAR.h>

/**
 A manager class singleton for placing nodes at real world locations. The GPSManager world is aligned to true north.
 */
@interface GPSManager : NSObject <CLLocationManagerDelegate, ARRendererDelegate>

/**
 The location manager responsible for updating the location of the manager world.
 */
@property (nonatomic, strong) CLLocationManager *locationManager;


/**
 Indicates if the GPSManager has been initialised
 */
@property (nonatomic, readonly) BOOL initialised;

/**
 Maths method for calculating the bearing between two locations.
 @param source The start location.
 @param dest The end location.
 */
+ (double)bearingFrom:(CLLocation *)source to:(CLLocation *)dest;

/**
 Returns GPSManager singleton.
 */
+ (GPSManager *)getInstance;

/**
 Returns the most recent update of the device location.
 */
- (CLLocation *)getCurrentLocation;

/**
 Initialises GPSManager, this involves setting a new world
 */
- (void)initialise;

/**
 Deinitialises GPSManager by stopping location manager updates and subsequently removing its reference to the location manager.
 The *world* node is also set to nil.
 */
- (void)deinitialise;

/**
 Starts GPSManager and ARGyroManager, makes the *world* visible and adds GPSManager to ARRenderer delegate.
 
 If GPSManager is not initialised, it will run through initialisation first
 */
- (void)start;

/**
 Stops GPSManager, ARGyroManager and removes GPSManager from ARRenderer delegate
 */
- (void)stop;

/**
 GPSManager's world. GPSNodes should be added to this object
 */
@property (nonatomic) ARWorld *world;

@end
