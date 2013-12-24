//
//  PODocument.h
//  posimarker:mac
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MapKit/MapKit.h>

@interface POKMLDocument : NSDocument <NSOutlineViewDataSource, NSOutlineViewDelegate, MKMapViewDelegate>

@property(nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property(nonatomic, weak) IBOutlet MKMapView *mapView;

@end
