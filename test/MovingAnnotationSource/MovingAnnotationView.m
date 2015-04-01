
//
//  MovingAnnotationView.m
//  test
//
//  Created by yi chen on 14-9-3.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import "MovingAnnotationView.h"
#import "CACoordLayer.h"
#import "Util.h"

#define TurnAnimationDuration 0.1

#define MapXAnimationKey @"mapx"
#define MapYAnimationKey @"mapy"
#define RotationAnimationKey @"transform.rotation.z"

@interface MovingAnnotationView()

@property (nonatomic, strong) NSMutableArray * animationList;

@end

@implementation MovingAnnotationView
{
    MAMapPoint currDestination;
    MAMapPoint lastDestination;
    
    CLLocationDirection lastDirection;
    
    BOOL isAnimatingX, isAnimatingY;
}

#pragma mark - Animation
+ (Class)layerClass
{
    return [CACoordLayer class];
}

- (void)addTrackingAnimationForPoints:(NSArray *)points duration:(CFTimeInterval)duration
{
    if (![points count])
    {
        return;
    }
    
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    
    //preparing
    NSUInteger num = 2*[points count] + 1;
    NSMutableArray * xvalues = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray *yvalues = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray *rvalues = [NSMutableArray arrayWithCapacity:num];
    
    NSMutableArray * times = [NSMutableArray arrayWithCapacity:num];
    NSMutableArray * rtimes = [NSMutableArray arrayWithCapacity:num];
    
    double sumOfDistance = 0.f;
    double * dis = malloc(([points count]) * sizeof(double));
    
    //the first point is set by the destination of last animation.
    MAMapPoint preLoc;
    CLLocationDirection preDir;
    if (!([self.animationList count] > 0 || isAnimatingX || isAnimatingY))
    {
        lastDestination = MAMapPointMake(mylayer.mapx, mylayer.mapy);
    }
    preLoc = lastDestination;
    
    MAMapPoint firstPoint = MAMapPointForCoordinate(((TracingPoint *)[points firstObject]).coordinate);
    double transitDir = [Util calculateCourseFromMapPoint:preLoc to:firstPoint];
    preDir = [Util fixNewDirection:transitDir basedOnOldDirection:lastDirection];
    
    [xvalues addObject:@(preLoc.x)];
    [yvalues addObject:@(preLoc.y)];
    [times addObject:@(0.f)];
    
    [rvalues addObject:@(preDir * DegToRad)];
    [rtimes addObject:@(0.f)];
    
    //set the animation points.
    for (int i = 0; i<[points count]; i++)
    {
        TracingPoint * tp = points[i];
        
        //position
        MAMapPoint p = MAMapPointForCoordinate(tp.coordinate);
        [xvalues addObjectsFromArray:@[@(p.x), @(p.x)]];//stop for turn
        [yvalues addObjectsFromArray:@[@(p.y), @(p.y)]];

        //angle
        double currDir = [Util fixNewDirection:tp.course basedOnOldDirection:preDir];
        [rvalues addObjectsFromArray:@[@(preDir * DegToRad), @(currDir * DegToRad)]];
        
        //distance
        dis[i] = MAMetersBetweenMapPoints(p, preLoc);
        sumOfDistance = sumOfDistance + dis[i];
        dis[i] = sumOfDistance;
        
        //record pre
        preLoc = p;
        preDir = currDir;
    }
    
    //set the animation times.
    double preTime = 0.f;
    double turnDuration = TurnAnimationDuration/duration;
    for (int i = 0; i<[points count]; i++)
    {
        double turnEnd = dis[i]/sumOfDistance;
        double turnStart = (preTime > turnEnd - turnDuration) ? (turnEnd + preTime) * 0.5 : turnEnd - turnDuration;
        
        [times addObjectsFromArray:@[@(turnStart), @(turnEnd)]];
        [rtimes addObjectsFromArray:@[@(turnStart), @(turnEnd)]];

        preTime = turnEnd;
    }
    
    //record the destination.
    TracingPoint * last = [points lastObject];
    lastDestination = MAMapPointForCoordinate(last.coordinate);
    lastDirection = last.course;

    free(dis);
    
    // add animation.
    CAKeyframeAnimation *xanimation = [CAKeyframeAnimation animationWithKeyPath:MapXAnimationKey];
    xanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    xanimation.values   = xvalues;
    xanimation.keyTimes = times;
    xanimation.duration = duration;
    xanimation.delegate = self;
    xanimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *yanimation = [CAKeyframeAnimation animationWithKeyPath:MapYAnimationKey];
    yanimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    yanimation.values   = yvalues;
    yanimation.keyTimes = times;
    yanimation.duration = duration;
    yanimation.delegate = self;
    yanimation.fillMode = kCAFillModeForwards;
    
    CAKeyframeAnimation *ranimation = [CAKeyframeAnimation animationWithKeyPath:RotationAnimationKey];
    ranimation.values = rvalues;
    ranimation.keyTimes = rtimes;
    ranimation.duration = duration;
    ranimation.delegate = self;
    ranimation.fillMode = kCAFillModeForwards;
    
    [self pushBackAnimation:xanimation];
    [self pushBackAnimation:yanimation];
    [self pushBackAnimation:ranimation];
    
    mylayer.mapView = [self mapView];

}

- (void)pushBackAnimation:(CAPropertyAnimation *)anim
{
    [self.animationList addObject:anim];

    if ([self.layer animationForKey:anim.keyPath] == nil)
    {
        [self popFrontAnimationForKey:anim.keyPath];
    }
}

- (void)popFrontAnimationForKey:(NSString *)key
{
    [self.animationList enumerateObjectsUsingBlock:^(CAKeyframeAnimation * obj, NSUInteger idx, BOOL *stop)
     {
         if ([obj.keyPath isEqualToString:key])
         {
             [self.layer addAnimation:obj forKey:obj.keyPath];
             [self.animationList removeObject:obj];

             if ([key isEqualToString:MapXAnimationKey])
             {
                 isAnimatingX = YES;
             }
             else if([key isEqualToString:MapYAnimationKey])
             {
                 isAnimatingY = YES;
             }
             else if([key isEqualToString:RotationAnimationKey])
             {
                 double endDir = ((NSNumber *)[obj.values lastObject]).doubleValue;
                 
                 self.layer.transform = CATransform3DMakeRotation(endDir, 0, 0, 1);
                 //动画结束时状态不会恢复到起始状态。
             }
             *stop = YES;
         }
     }];
}


#pragma mark - Animation Delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([anim isKindOfClass:[CAKeyframeAnimation class]])
    {
        CAKeyframeAnimation * keyAnim = ((CAKeyframeAnimation *)anim);
        if ([keyAnim.keyPath isEqualToString:MapXAnimationKey])
        {
            isAnimatingX = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapx = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.x = mylayer.mapx;
            
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapXAnimationKey];
        }
        else if ([keyAnim.keyPath isEqualToString:MapYAnimationKey])
        {
            isAnimatingY = NO;

            CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
            mylayer.mapy = ((NSNumber *)[keyAnim.values lastObject]).doubleValue;
            currDestination.y = mylayer.mapy;
            [self updateAnnotationCoordinate];

            [self popFrontAnimationForKey:MapYAnimationKey];
        }
        else if([keyAnim.keyPath isEqualToString:RotationAnimationKey])
        {
            [self popFrontAnimationForKey:RotationAnimationKey];
        }

    }
}

- (void)updateAnnotationCoordinate
{
    if (! (isAnimatingX || isAnimatingY) )
    {
        self.annotation.coordinate = MACoordinateForMapPoint(currDestination);
    }
}

#pragma mark - Property

- (NSMutableArray *)animationList
{
    if (_animationList == nil)
    {
        _animationList = [NSMutableArray array];
    }
    return _animationList;
}

- (MAMapView *)mapView
{
    return (MAMapView*)(self.superview.superview);
}

#pragma mark - Override

- (void)setCenterOffset:(CGPoint)centerOffset
{
    CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
    mylayer.centerOffset = centerOffset;
    [super setCenterOffset:centerOffset];
}

#pragma mark - Life Cycle

- (id)initWithAnnotation:(id<MAAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self)
    {
        CACoordLayer * mylayer = ((CACoordLayer *)self.layer);
        MAMapPoint mapPoint = MAMapPointForCoordinate(annotation.coordinate);
        mylayer.mapx = mapPoint.x;
        mylayer.mapy = mapPoint.y;
        
        mylayer.centerOffset = self.centerOffset;
        
        isAnimatingX = NO;
        isAnimatingY = NO;
    }
    return self;
}


@end
