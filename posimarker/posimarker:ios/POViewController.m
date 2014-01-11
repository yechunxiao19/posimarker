//
//  POViewController.m
//  posimarker:ios
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "POViewController.h"
#import "KMLd.h"
#import "POKMLDocument.h"

@interface POViewController (){
   POKMLDocument *_KmlDoc;
}

@end

@implementation POViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *fileName = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"kml"];
//    NSString *fileName=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/example.kml"];
    
    NSURL *fileURL = [NSURL fileURLWithPath:fileName];
    _KmlDoc = [[POKMLDocument alloc] initWithFileURL:fileURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        [_KmlDoc openWithCompletionHandler:^(BOOL success) {
            if(success){
                NSLog(@"load OK");
                [self initTableView];
            }
            else{
                NSLog(@"failed to load!");
            }
        }];
    }
    
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height/3*2)];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    self.mapView.mapType = MKMapTypeStandard;
    [self.view addSubview:self.mapView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [_KmlDoc closeWithCompletionHandler:nil];
}

#pragma mark -
#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id item = [_KmlDoc.kmlDocument.elements objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[KMLPlacemark class]]) {
        [self displayPlacemark:item];
    }
}

#pragma mark -
#pragma mark UITableView Datasource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    return _KmlDoc.kmlDocument.elements.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    }
    cell.textLabel.text = [[_KmlDoc.kmlDocument.elements objectAtIndex:indexPath.row] name];

    return cell;
}

- (void)initTableView{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height/3 *2, self.view.bounds.size.width, self.view.bounds.size.height/3)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

#pragma mark - Map maniputation

- (void)displayPlacemark:(KMLPlacemark *)placemark
{
    NSArray *overlays = placemark.overlays;
    NSArray *points = placemark.pointAnnotations;
    
    [self.mapView addOverlays:overlays];
    [self.mapView addAnnotations:points];
    
    
    MKMapRect flyTo = MKMapRectNull;
    for (id<MKOverlay> overlay in overlays) {
        if (MKMapRectIsNull(flyTo))
            flyTo = [overlay boundingMapRect];
        else
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
    }
    
    for (id<MKAnnotation> point in points) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(point.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    CGFloat insetH = self.mapView.frame.size.height * 0.2;
    CGFloat insetW = self.mapView.frame.size.width * 0.2;
    
    [self.mapView setVisibleMapRect:flyTo edgePadding:UIEdgeInsetsMake(insetH, insetW, insetH, insetW)
                       animated:YES];
}


#pragma mark - Mapview Delegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay class]==[MKPolyline class]) {
        MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.lineWidth = 2.0;
        polylineRenderer.strokeColor = [UIColor orangeColor];
        return polylineRenderer;
    }
    if ([overlay class]==[MKPolygon class]) {
        MKPolygonRenderer *polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.lineWidth = 2.0;
        polygonRenderer.strokeColor = [UIColor orangeColor];
        polygonRenderer.fillColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        return polygonRenderer;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if (pinView==nil) pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    else pinView.annotation = annotation;
    pinView.canShowCallout = YES;
    pinView.animatesDrop = YES;
    return pinView;
}

@end
