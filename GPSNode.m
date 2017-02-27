#import "GPSNode.h"
#import "GPSManager.h"

@interface GPSNode ()
@property (nonatomic, readwrite) CLLocationSpeed speed;
@property (nonatomic, readwrite) CLLocationDirection course;
@property (nonatomic) NSTimeInterval previousFrameTime;
@end

@implementation GPSNode

- (instancetype)initWithLocation:(CLLocation *)location bearing:(double)bearing
{
    self = [super init];
    if (self) {
        GPSManager *gpsManager = [GPSManager getInstance];
        _deviceHeight = 1.5;
        _interpolateMotionUsingHeading = NO;
        
        if ([gpsManager getCurrentLocation] != nil) {
            [self setLocation:location bearing:bearing];
        }
    }
    
    return self;
}

- (instancetype)initWithLocation:(CLLocation *)location
{
    return [self initWithLocation:location bearing:0];
}

/// Sets location and bearing of GPS node and updates its position.
- (void)setLocation:(CLLocation *)location bearing:(double)bearing
{
    _location = location;
    _bearing = bearing;
    
    [self updateWorldPosition];
}

/// Sets GPS nodes locations and updates postion.
- (void)setLocation:(CLLocation *)location
{
    _location = location;
    
    [self updateWorldPosition];
}

/// Sets GPS nodes bearing and updates postion.
- (void)setBearing:(double)bearing
{
    _bearing = bearing;
    
    [self updateWorldPosition];
}

/// Sets devices height and updates postion.
- (void)setDeviceHeight:(double)deviceHeight
{
    _deviceHeight = deviceHeight;
    
    [self updateWorldPosition];
}

/// Translate the unit vector pointing North to position vector of object by bearing rotation then distance scale.
- (ARVector3 *)calculateTranslationVectorWithBearing:(double)bearing distance:(double)distance
{
    ARVector3 *northVec = [ARVector3 vectorWithValuesX:-1 y:0 z:0];
    northVec = [[ARQuaternion quaternionWithDegrees:bearing axisX:0 y:-1 z:0] multiplyByVector:northVec];
    northVec = [northVec multiplyByScalar:distance];
    
    return northVec;
}

/// Updates GPS nodes position in GPS Manager world.
- (void)updateWorldPosition
{
    CLLocation *currentPos = [[GPSManager getInstance] getCurrentLocation];
    double distanceToObject = [_location distanceFromLocation:currentPos];
    double bearingToObject = [GPSManager bearingFrom:_location to:currentPos];
    
    self.course = currentPos.course;
    self.speed = currentPos.speed;
    
    // Translate unit vector pointing north to position vector of object by bearing rotation then distance scale.
    ARVector3 *translationVec = [self calculateTranslationVectorWithBearing:bearingToObject distance:distanceToObject];
    
    // Set node origin at floor height relative to the device.
    translationVec.y = -_deviceHeight;
    
    self.position = translationVec;
    self.orientation = [ARQuaternion quaternionWithDegrees:self.bearing axisX:0 y:-1 z:0];
}

/// ARRenderer delegate method.
- (void)preRender
{
    if (self.interpolateMotionUsingHeading) {
        
        // Check speed and course values are valid
        if (self.speed > 0 && self.course > 0) {
            
            NSTimeInterval currentFrameTime = [ARRenderer getInstance].currentFrameTime;
            NSTimeInterval timeDelta = currentFrameTime - self.previousFrameTime;
            
            // Don't let the object translate too far on the first frame or at low frame rates.
            if (timeDelta < 1) {
                ARVector3 *translationVec = [self calculateTranslationVectorWithBearing:self.course distance:timeDelta * self.speed];
                
                [self translateByVector:[translationVec negate]];
            }
            
            self.previousFrameTime = currentFrameTime;
        }
    }
    
    [super preRender];
}

@end
