#import <KudanAR/KudanAR.h>
#import <CoreLocation/CoreLocation.h>

/**
 A node used for placing content in the real world. Children of this node will be placed at the coordinate specified during initiation. GPSNodes must be added to the GPSManager world to function correctly.
 */
@interface GPSNode : ARNode
#pragma mark - Properties
/**
 The real world location of the node.
 */
@property (nonatomic) CLLocation *location;

/**
 The direction the node is facing expressed as a bearing relative to true north.
 */
@property (nonatomic) double bearing;

/**
 The height of the device in metres from the ground used to correctly position objects at floor level.
 
 The default of this is set to 1.5 during the object's init
 */
@property (nonatomic) double deviceHeight;

/**
 Whether the node's motion is interpolated between location updates of device movement. Accuracy depends on the precision of the device GPS.
 
 The default is set to NO.
 */
@property (nonatomic) BOOL interpolateMotionUsingHeading;

/**
 The direction the device is heading during motion.
 */
@property (nonatomic, readonly) CLLocationDirection course;

/**
 The speed of the device during motion.
 */
@property (nonatomic, readonly) CLLocationSpeed speed;

#pragma mark - Init methods
/**
 Initiates the node using a latitude, a longitude and a bearing.
 
 @param location The real world location of the node.
 @param bearing The bearing of the node relative to true north.
 */
- (instancetype)initWithLocation:(CLLocation *)location bearing:(double)bearing NS_DESIGNATED_INITIALIZER;

/**
 Initiates the node using a latitude and a longitude. The default bearing of 0 will be used.
 
 The node will face true north.
 
 @param location The real world location of the node.
 */
- (instancetype)initWithLocation:(CLLocation *)location;

/**
 This class must be initialised either via the designated or convenience initalisers
 
 @return unavailable
 */
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - instance methods
/**
 Updates the location of the node relative to the device. Called during a change in device motion by the GPSManager.
 */
- (void)updateWorldPosition;

@end
