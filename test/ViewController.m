//
//  ViewController.m
//  test
//
//  Created by yi chen on 14-8-20.
//  Copyright (c) 2014年 yi chen. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import "MovingAnnotationView.h"
#import "TracingPoint.h"
#import "Util.h"

@interface ViewController ()<MAMapViewDelegate>

@property (nonatomic, strong) MAMapView * map;

@property (nonatomic, strong) MAPointAnnotation * car;

@end

@implementation ViewController
{
    NSMutableArray * _tracking;
    CFTimeInterval _duration;
}

#pragma mark - trackings

- (void)initRoute
{
    _duration = 8.0;
    
    NSUInteger count = 14;
    CLLocationCoordinate2D * coords = malloc(count * sizeof(CLLocationCoordinate2D));
    
    coords[0] = CLLocationCoordinate2DMake(39.93563,  116.387358);
    coords[1] = CLLocationCoordinate2DMake(39.935564,   116.386414);
    coords[2] = CLLocationCoordinate2DMake(39.935646,  116.386038);
    coords[3] = CLLocationCoordinate2DMake(39.93586, 116.385791);
    coords[4] = CLLocationCoordinate2DMake(39.93586, 116.385791);
    coords[5] = CLLocationCoordinate2DMake(39.937983, 116.38474);
    coords[6] = CLLocationCoordinate2DMake(39.938616, 116.3846);
    coords[7] = CLLocationCoordinate2DMake(39.938888, 116.386971);
    coords[8] = CLLocationCoordinate2DMake(39.938855, 116.387047);
    coords[9] = CLLocationCoordinate2DMake(39.938172,  116.387132);
    coords[10] = CLLocationCoordinate2DMake(39.937604, 116.387218);
    coords[11] = CLLocationCoordinate2DMake(39.937489, 116.387132);
    coords[12] = CLLocationCoordinate2DMake(39.93614,  116.387283);
    coords[13] = CLLocationCoordinate2DMake(39.935622,  116.387347);

    [self showRouteForCoords:coords count:count];
    [self initTrackingWithCoords:coords count:count];
    
    if (coords) {
        free(coords);
    }

}

- (void)showRouteForCoords:(CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    //show route
    MAPolyline *route = [MAPolyline polylineWithCoordinates:coords count:count];
    [self.map addOverlay:route];
    
    NSMutableArray * routeAnno = [NSMutableArray array];
    for (int i = 0 ; i < count; i++)
    {
        MAPointAnnotation * a = [[MAPointAnnotation alloc] init];
        a.coordinate = coords[i];
        a.title = @"route";
        [routeAnno addObject:a];
    }
    [self.map addAnnotations:routeAnno];
    [self.map showAnnotations:routeAnno animated:NO];

}

- (void)initTrackingWithCoords:(CLLocationCoordinate2D *)coords count:(NSUInteger)count
{
    _tracking = [NSMutableArray array];
    for (int i = 0; i<count - 1; i++)
    {
        TracingPoint * tp = [[TracingPoint alloc] init];
        tp.coordinate = coords[i];
        tp.course = [Util calculateCourseFromCoordinate:coords[i] to:coords[i+1]];
        [_tracking addObject:tp];
    }
    
    TracingPoint * tp = [[TracingPoint alloc] init];
    tp.coordinate = coords[count - 1];
    tp.course = ((TracingPoint *)[_tracking lastObject]).course;
    [_tracking addObject:tp];
}


#pragma mark - Action

- (void)mov
{
    /* Step 3. */
    
    /* Find annotation view for car annotation. */
    MovingAnnotationView * carView = (MovingAnnotationView *)[self.map viewForAnnotation:self.car];
    
    /* 
     Add multi points animation to annotation view.
     The coordinate of car annotation will be updated to the last coords after animation is over.
     */
    [carView addTrackingAnimationForPoints:_tracking duration:_duration];
}

- (void)initBtn
{
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0, self.view.frame.size.height * 0.2, 60, 20);
    btn.backgroundColor = [UIColor grayColor];
    [btn setTitle:@"move" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(mov) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:btn];
}

#pragma mark - Map Delegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    /* Step 2. */
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        MovingAnnotationView *annotationView = (MovingAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MovingAnnotationView alloc] initWithAnnotation:annotation
                                                             reuseIdentifier:pointReuseIndetifier];
        }
        
        if ([annotation.title isEqualToString:@"Car"])
        {
            UIImage *imge  =  [UIImage imageNamed:@"userPosition"];
            annotationView.image =  imge;
            CGPoint centerPoint=CGPointZero;
            [annotationView setCenterOffset:centerPoint];
        }
        else if ([annotation.title isEqualToString:@"route"])
        {
            annotationView.image = [UIImage imageNamed:@"trackingPoints.png"];
        }

        return annotationView;
    }
    
    return nil;
}

- (MAPolylineRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.lineWidth   = 3.f;
        polylineRenderer.strokeColor = [UIColor colorWithRed:0 green:0.47 blue:1.0 alpha:0.9];
        
        return polylineRenderer;
    }
    
    return nil;
}

#pragma mark - Initialization

- (void)initAnnotation
{
    [self initRoute];
    
    /* Step 1. */
    //show car
    self.car = [[MAPointAnnotation alloc] init];
    TracingPoint * start = [_tracking firstObject];
    self.car.coordinate = start.coordinate;
    self.car.title = @"Car";
    [self.map addAnnotation:self.car];
    
}

- (MAMapView *)map
{
    if (!_map)
    {
        _map = [[MAMapView alloc] initWithFrame:self.view.frame];
        [_map setDelegate:self];
        
        //加入annotation旋转动画后，暂未考虑地图旋转的情况。
        _map.rotateCameraEnabled = NO;
        _map.rotateEnabled = NO;
    }
    return _map;
}

#pragma mark life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.map];
    
    [self initBtn];
    [self initAnnotation];
}


@end
