//
//  TracingPoint.h
//  test
//
//  Created by yi chen on 3/19/15.
//  Copyright (c) 2015 yi chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface TracingPoint : NSObject

/*!
 @brief 轨迹经纬度
 */
@property (nonatomic) CLLocationCoordinate2D coordinate;

/*!
 @brief 方向，有效范围0~359.9度
 */
@property (nonatomic) CLLocationDirection course;

@end
