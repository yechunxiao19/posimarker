//
//  PODocument.m
//  posimarker:mac
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "POKMLDocument.h"
#import "KMLd.h"

#import <zipzap.h>

#define KMLDocumentType  @"KML document"
#define KMZDocumentType  @"KML-Zip document"

@interface POKMLDocument ()
{
  KMLDocument *_kmlDocument;
}

@end

@implementation POKMLDocument

- (id)init
{
    self = [super init];
    if (self) {
    // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
  return @"POKMLDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
  [super windowControllerDidLoadNib:aController];
  [_outlineView reloadData];
  [_outlineView expandItem:[_outlineView itemAtRow:0]];
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
  return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
  NSData *kmlData = nil;
  if ([typeName isEqualToString:KMLDocumentType])
    kmlData = data;
  else if ([typeName isEqualToString:KMZDocumentType]) {
    ZZArchive *archive = [ZZArchive archiveWithData:data];
    for (ZZArchiveEntry *entry in archive.entries) {
      if ([entry.fileName isEqualToString:@"doc.kml"])
        kmlData = entry.data;
    }
  }
  
  KMLDocument *document = [KMLDocument documentWithData:data];
  if (document) {
    _kmlDocument = document;
    return YES;
  }
  return NO;
}

#pragma mark - Map maniputation

- (void)displayPlacemark:(KMLPlacemark *)placemark
{
  NSArray *overlays = placemark.overlays;
  NSArray *points = placemark.pointAnnotations;
  
  [_mapView addOverlays:overlays];
  [_mapView addAnnotations:points];
  
  
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
  
  CGFloat insetH = _mapView.frame.size.height * 0.2;
  CGFloat insetW = _mapView.frame.size.width * 0.2;
  
  [_mapView setVisibleMapRect:flyTo edgePadding:NSEdgeInsetsMake(insetH, insetW, insetH, insetW)
                     animated:YES];
}

#pragma mark - OutlineView Datasource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item==nil) {
    return 1;
  }
  else if([item isKindOfClass:[KMLContainer class]]){
    KMLContainer *container = item;
    return [container.elements count];
  }
  return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
  if (item==nil) {
    return _kmlDocument;
  }
  else if ([item isKindOfClass:[KMLContainer class]]) {
    KMLContainer *container = item;
    return [container.elements objectAtIndex:index];
  }
  return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  if (item==nil) return YES;
  return [item isKindOfClass:[KMLContainer class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
  if (item==nil) {
    return _kmlDocument.name ? _kmlDocument.name : @"Root Document";
  }
  else if ([item isKindOfClass:[KMLFolder class]]) {
    KMLFolder *folder = item;
    return folder.name ? folder.name : @"Unnamed Folder";
  }
  else if ([item isKindOfClass:[KMLDocument class]]) {
    KMLDocument *document = item;
    return document.name ? document.name : @"Unnamed Document";
  }
  else if ([item isKindOfClass:[KMLPlacemark class]]) {
    KMLPlacemark *placemark = item;
    return placemark.name ? placemark.name : @"Unnamed Placemark";
  }
  return nil;
}

#pragma mark - OutlineViewDelegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  id item = [_outlineView itemAtRow:_outlineView.selectedRow];
  if ([item isKindOfClass:[KMLPlacemark class]]) {
    [self displayPlacemark:item];
  }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  NSString *title = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
  if (title) {
    if (item==_kmlDocument) {
      NSTableCellView * headerView = [_outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
      headerView.textField.stringValue = title;
      return headerView;
    }
    else {
      NSTableCellView * dataView = [_outlineView makeViewWithIdentifier:@"DataCell" owner:self];
      dataView.textField.stringValue = title;
      if ([item isKindOfClass:[KMLFolder class]]) {
        dataView.imageView.image = [NSImage imageNamed:NSImageNameFolder];
      }
      else if ([item isKindOfClass:[KMLDocument class]]) {
        dataView.imageView.image = [NSImage imageNamed:NSImageNameMultipleDocuments];
      }
      else if ([item isKindOfClass:[KMLPlacemark class]]) {
        dataView.imageView.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
      }
      else {
        dataView.imageView.image = nil;
      }
      return dataView;
    }
  }
  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
  return item!=_kmlDocument;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
  return item==_kmlDocument;
}

#pragma mark - Mapview Delegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
  if ([overlay class]==[MKPolyline class]) {
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    polylineRenderer.lineWidth = 2.0;
    polylineRenderer.strokeColor = [NSColor orangeColor];
    return polylineRenderer;
  }
  if ([overlay class]==[MKPolygon class]) {
    MKPolygonRenderer *polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
    polygonRenderer.lineWidth = 2.0;
    polygonRenderer.strokeColor = [NSColor orangeColor];
    polygonRenderer.fillColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.3];
    return polygonRenderer;
  }
  return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
  MKPinAnnotationView *pinView = (MKPinAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
  if (pinView==nil) pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
  else pinView.annotation = annotation;
  pinView.canShowCallout = YES;
  pinView.animatesDrop = YES;
  return pinView;
}

@end
