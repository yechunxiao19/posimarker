//
//  POViewController.h
//  posimarker:ios
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "POKMLDocument.h"

@interface POViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,MKMapViewDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) POKMLDocument *KmlDoc;

@end
