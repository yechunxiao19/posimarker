//
//  KMLElement.m
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "KMLElement.h"
#import "KMLMacros.h"

#import <MapKit/MapKit.h>
#import <ISO8601DateFormatter.h>
#import <RXMLElement.h>

#pragma mark KMLELement

@implementation KMLElement
- (instancetype)initWithIndentifier:(NSString *)identifier
{
  self = [super init];
  if (self) {
    _identifier = identifier;
  }
  return self;
}

- (instancetype)initWithXMLElement:(RXMLElement *)element
{
  self = [self initWithIndentifier:[element attribute:@"id"]];
  if (self) {
    [self parseXMLElement:element];
  }
  return self;
}

- (void)parseXMLElement:(RXMLElement *)element
{
  @throw [NSException exceptionWithName:@"NotImplemented"
                                 reason:@"this method needs override"
                               userInfo:nil];
}

+ (KMLElement *)elementWithXMLElement:(RXMLElement *)element
{
  NSString *elementName = element.tag;
  if (ELTYPE(Style)) {
    return [[KMLStyle alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(Placemark)) {
    return [[KMLPlacemark alloc] initWithXMLElement:element];
  }
  else {
    return [[KMLGeometry alloc] initWithXMLElement:element];
  }
}

@end

#pragma mark -
#pragma mark KMLStyle

@implementation KMLStyle

- (void)parseXMLElement:(RXMLElement *)XMLElement
{
  [XMLElement iterate:@"*" usingBlock:^(RXMLElement * ele) {
    NSString *elementName = ele.tag;
    if (ELTYPE(LineStyle)) {
      RXMLElement *colorElement = [ele child:@"color"];
      RXMLElement *widthElement = [ele child:@"width"];
      if (colorElement) self.strokeColorString = colorElement.text;
      if (widthElement) self.strokeWidth = (CGFloat)widthElement.textAsDouble;
    }
    else if (ELTYPE(PolyStyle)) {
      RXMLElement *colorElement = [ele child:@"color"];
      RXMLElement *outlineElement = [ele child:@"outline"];
      RXMLElement *fillElement = [ele child:@"fill"];
      if (colorElement) self.fillColorString = colorElement.text;
      if (outlineElement) self.stroke = [outlineElement.text boolValue];
      if (fillElement) self.fill = [fillElement.text boolValue];
    }
  }];
}

@end

#pragma mark KMLGeometry

@implementation KMLGeometry

- (void)dealloc
{
  if (_coordinates) {
    free(_coordinates);
  }
}

- (void)parseXMLElement:(RXMLElement *)element
{
  RXMLElement *coordinatesElement = [element child:@"coordinates"];
  if (coordinatesElement) {
    [KMLGeometry coordinatesWithString:coordinatesElement.text
                             coordsOut:&_coordinates
                                 count:&_coordiantesCount];
  }
}


+ (void)coordinatesWithString:(NSString *)coordinatesString coordsOut:(CLLocationCoordinate2D **)coordsOut count:(NSUInteger *)count
{
  
  NSUInteger read = 0, space = 10;
  CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * space);
  
  NSArray *coordiantesComponents = [coordinatesString componentsSeparatedByCharactersInSet:
                                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  
  
  for (NSString *component in coordiantesComponents) {
    
    if (read == space) {
      space += 20;
      coords = realloc(coords, sizeof(CLLocationCoordinate2D) * space);
    }
    
    double longtitude;
    double latitude;
    NSScanner *scanner = [NSScanner scannerWithString:component];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@","];
    if ([scanner scanDouble:&longtitude]) {
      if ([scanner scanDouble:&latitude]) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longtitude);
        
        if (CLLocationCoordinate2DIsValid(coordinate))
          coords[read++] = coordinate;
      }
    }
  }
  *coordsOut = coords;
  *count = read;
}

+ (CLLocation *)locationWithString:(NSString *)string timeStamp:(NSDate *)date
{
  
  CGFloat longtitude;
  CGFloat latitude;
  CGFloat altitude;
  
  NSCharacterSet *skipCharacters = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
  
  NSScanner *scanner = [[NSScanner alloc] init];
  scanner.charactersToBeSkipped = skipCharacters;
  if ([scanner scanDouble:&longtitude]) {
    if ([scanner scanDouble:&latitude]) {
      if (![scanner scanDouble:&altitude]) altitude = 0.0;
      CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longtitude)
                                                           altitude:altitude
                                                 horizontalAccuracy:0
                                                   verticalAccuracy:0
                                                          timestamp:date];
      return location;
    }
  }
  return nil;
}


+ (id)geometryWithXMLElement:(RXMLElement *)element
{
  NSString *elementName = element.tag;
  if (ELTYPE(Point)) {
    return [[KMLPoint alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(LinearRing)) {
    return [[KMLLinearRing alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(Polygon)) {
    return [[KMLPolygon alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(LineString)) {
    return [[KMLLineString alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(multiGeometry)) {
    return [[KMLMultiGeometry alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(gx:Track)) {
    return [[GXTrack alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(gx:multiTrack)) {
    return [[GXMultiTrack alloc] initWithXMLElement:element];
  }
  return nil;
}

- (MKShape *)shape
{
  return [self pointAnnotation];
}

- (MKPointAnnotation *)pointAnnotation
{
  if (_coordiantesCount) {
    CLLocationCoordinate2D coordinate = _coordinates[0];
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    return annotation;
  }
  return nil;
}

@end


#pragma mark KMLMultiGeometry
@implementation KMLMultiGeometry

- (void)parseXMLElement:(RXMLElement *)element
{
  NSMutableArray *_geometries = [[NSMutableArray alloc] init];
  [element iterate:@"*" usingBlock:^(RXMLElement *element) {
    KMLGeometry * geometry = [KMLGeometry geometryWithXMLElement:element];
    if (geometry) [_geometries addObject:geometry];
  }];
  _subGeometries = _geometries;
}

- (NSArray *)shapes
{
  NSMutableArray *shapes = nil;
  if ([_subGeometries count]) {
    shapes = [[NSMutableArray alloc] init];
    for (KMLGeometry *geometry in _subGeometries) {
      if (ELCLASS(geometry, KMLMultiGeometry)) {
        [shapes addObjectsFromArray:[(KMLMultiGeometry *)geometry shapes]];
      }
      else {
        MKShape *shape = geometry.shape;
        if (shape)[shapes addObject:shape];
      }
    }
  }
  return shapes;
}

- (NSArray *)pointAnnotations
{
  NSMutableArray *points = nil;
  if ([_subGeometries count]) {
    points = [[NSMutableArray alloc] init];
    for (KMLGeometry *geometry in _subGeometries) {
      if (ELCLASS(geometry, KMLMultiGeometry)) {
        [points addObjectsFromArray:[(KMLMultiGeometry *)geometry pointAnnotations]];
      }
      else {
        MKPointAnnotation *point = geometry.pointAnnotation;
        if (point) [points addObject:point];
      }
    }
  }
  return points;
}

- (MKShape *)shape
{
  return nil;
}

- (MKPointAnnotation *)pointAnnotation
{
  return nil;
}

@end


#pragma mark KMLPlacemark

@implementation KMLPlacemark
- (void)parseXMLElement:(RXMLElement *)element
{
  [element iterate:@"*" usingBlock:^(RXMLElement *element) {
    NSString *elementName = element.tag;
    if (ELTYPE(Name)) {
      _name = element.text;
    }
    else if (ELTYPE(description)) {
      _description = element.text;
    }
    else if (ELTYPE(styleUrl)) {
      _styleURL = element.text;
    }
    else if (ELTYPE(Style)) {
      _style = [[KMLStyle alloc]initWithXMLElement:element];
    }
    else {
      KMLGeometry *geometry = [KMLGeometry geometryWithXMLElement:element];
      if (geometry) _geometry = geometry;
    }
  }];
}

- (NSArray *)shapes
{
  if (ELCLASS(_geometry, KMLMultiGeometry)) {
     return [(KMLMultiGeometry *)_geometry shapes];
  }
  else {
    MKShape *shape = _geometry.shape;
    shape.title = _name;
    if (shape) return @[shape];
  }
  return nil;
}

- (NSArray *)overlays
{
  NSMutableArray *overlays = [[NSMutableArray alloc] init];
  NSArray *shapes = self.shapes;
  for (id shape in shapes) {
    if ([shape conformsToProtocol:@protocol(MKOverlay)]) {
      [overlays addObject:shape];
    }
  }
  return overlays;
}

- (NSArray *)pointAnnotations
{
  if (ELCLASS(_geometry, KMLMultiGeometry)) {
    return [(KMLMultiGeometry *)_geometry pointAnnotations];
  }
  else {
    MKPointAnnotation *point = _geometry.pointAnnotation;
    point.title = _name;
    if(point) return @[point];
  }
  return nil;
}

@end

#pragma mark -

#pragma mark KMLPoint

@implementation KMLPoint
- (void)parseXMLElement:(RXMLElement *)element
{
  [super parseXMLElement:element];
  if (self.coordiantesCount) {
    CLLocationCoordinate2D coordinate = self.coordinates[0];
    self.location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
  }
}
@end

#pragma mark KMLLinearRing

@implementation KMLLinearRing

- (MKShape *)shape
{
  return [MKPolygon polygonWithCoordinates:self.coordinates count:self.coordiantesCount];
}

@end


#pragma mark KMLLineString

@implementation KMLLineString

- (MKShape *)shape
{
  return [MKPolyline polylineWithCoordinates:self.coordinates count:self.coordiantesCount];
}

@end

#pragma mark KMLPolygon

@implementation KMLPolygon

- (void)parseXMLElement:(RXMLElement *)xmlElement
{
  __block NSMutableArray *innerBoundries = [[NSMutableArray alloc] init];
  
  [xmlElement iterate:@"*" usingBlock:^(RXMLElement *element) {
    NSString *elementName = element.tag;
    if (ELTYPE(outerBoundaryIs)) {
      _outerBoundary = [[KMLLinearRing alloc] initWithXMLElement:[element child:@"LinearRing"]];
    }
    else if (ELTYPE(innerBoundaryIs)) {
      KMLLinearRing *ring = [[KMLLinearRing alloc] initWithXMLElement:[element child:@"LinearRing"]];
      if (ring) [innerBoundries addObject:ring];
    }
  }];
  if ([innerBoundries count]) {
    _innerBoundariesArray = innerBoundries;
  }
}

- (MKShape *)shape
{
  NSMutableArray *innerPolygons = nil;
  if (_innerBoundariesArray) {
    innerPolygons = [[NSMutableArray alloc] init];
    for (KMLLinearRing *ring in _innerBoundariesArray) {
      [innerPolygons addObject:ring.shape];
    }
  }
  if (_outerBoundary) {
    return [MKPolygon polygonWithCoordinates:_outerBoundary.coordinates
                                       count:_outerBoundary.coordiantesCount
                            interiorPolygons:innerPolygons];
  }
  return nil;
}

@end

#pragma mark -
#pragma mark GXTrack

@interface GXTrack ()
{
  RXMLElement *_trackElement;
}

@end

@implementation GXTrack

- (void)parseXMLElement:(RXMLElement *)element
{
  _trackElement = element;
}

- (void)iterateTrackWithBlock:(void (^)(CLLocation *))block
{
  if (_trackElement==nil) return;
  __block NSDate *date;
  __block ISO8601DateFormatter *formmater;
  [_trackElement iterate:@"*" usingBlock:^(RXMLElement *element) {
    NSString *elementName = element.tag;
    if (ELTYPE(when)) {
      date = [formmater dateFromString:element.text];
    }
    else if (ELTYPE(gx:coord)) {
      if (date) {
        CLLocation *location = [KMLGeometry locationWithString:element.text timeStamp:date];
        if (location) block(location);
      }
    }
  }];
}

@end

#pragma CXMultiTrack

@implementation GXMultiTrack

- (void)parseXMLElement:(RXMLElement *)xmlElement
{
  __block NSMutableArray *tracks = [[NSMutableArray alloc] init];
  [xmlElement iterate:@"*" usingBlock:^(RXMLElement *element) {
    KMLGeometry *geometry = [KMLGeometry geometryWithXMLElement:element];
    if (geometry) {
      [tracks addObject:geometry];
    }
  }];
  _subTracks = tracks;
}

@end