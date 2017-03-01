//
//  Util.h
//  test
//
//  Created by yi chen on 3/24/15.
//  Copyright (c) 2015 yi chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>

#define RadToDeg 57.2957795130823228646477218717336654663086 //180.f / M_PI
#define DegToRad 0.0174532925199432954743716805978692718782 // M_PI / 180.f

@interface Util : NSObject

+ (CLLocationDirection)calculateCourseFromMapPoint:(MAMapPoint)point1 to:(MAMapPoint)point2;

+ (CLLocationDirection)calculateCourseFromCoordinate:(CLLocationCoordinate2D)coord1 to:(CLLocationCoordinate2D)coord2;
+ (CLLocationDirection)fixNewDirection:(CLLocationDirection)newDir basedOnOldDirection:(CLLocationDirection)oldDir;

@end
