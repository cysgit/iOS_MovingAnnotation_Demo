//
//  Util.m
//  test
//
//  Created by yi chen on 3/24/15.
//  Copyright (c) 2015 yi chen. All rights reserved.
//

#import "Util.h"

@implementation Util

+ (CLLocationDirection)calculateCourseFromMapPoint:(MAMapPoint)p1 to:(MAMapPoint)p2
{
    //20级坐标y轴向下，需要反过来。
    MAMapPoint dp = MAMapPointMake(p2.x - p1.x, p1.y - p2.y);
    
    if (dp.y == 0)
    {
        return dp.x < 0? 270.f:0.f;
    }
    
    double dir = atan(dp.x/dp.y) * 180.f / M_PI;
    
    if (dp.y > 0)
    {
        if (dp.x < 0)
        {
            dir = dir + 360.f;
        }
        
    }else
    {
        dir = dir + 180.f;
    }
    
    return dir;
}

+ (CLLocationDirection)calculateCourseFromCoordinate:(CLLocationCoordinate2D)coord1 to:(CLLocationCoordinate2D)coord2
{
    MAMapPoint p1 = MAMapPointForCoordinate(coord1);
    MAMapPoint p2 = MAMapPointForCoordinate(coord2);
    
    return [self calculateCourseFromMapPoint:p1 to:p2];
}

+ (CLLocationDirection)fixNewDirection:(CLLocationDirection)newDir basedOnOldDirection:(CLLocationDirection)oldDir
{
    //the gap between newDir and oldDir would not exceed 180.f degrees
    CLLocationDirection turn = newDir - oldDir;
    if(turn > 180.f)
    {
        return newDir - 360.f;
    }
    else if (turn < -180.f)
    {
        return newDir + 360.f;
    }
    else
    {
        return newDir;
    }
    
}

@end
