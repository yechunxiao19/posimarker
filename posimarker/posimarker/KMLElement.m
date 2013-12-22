//
//  KMLElement.m
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "KMLElement.h"
#import "KMLMacros.h"
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

- (void)parseXMLElement:(RXMLElement *)element
{
  [element iterate:@"*" usingBlock:^(RXMLElement * ele) {
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

- (void)parseXMLElement:(RXMLElement *)element
{
  RXMLElement *coordinatesElement = [element child:@"coordinates"];
  if (coordinatesElement) {
    _coordinates = [KMLGeometry coordinatesWithString:coordinatesElement.text];
  }
}

+ (NSArray *)coordinatesWithString:(NSString *)coordinatesString
{
  NSMutableArray *coordinates = [[NSMutableArray alloc] init];
  NSArray *coordiantesComponents = [coordinatesString componentsSeparatedByString:[NSCharacterSet newlineCharacterSet]];
  NSCharacterSet *skipCharacters = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
  
  CGFloat longtitude;
  CGFloat latitude;
  CGFloat altitude;
  
  for (NSString *component in coordiantesComponents) {
    NSScanner *scanner = [[NSScanner alloc] init];
    scanner.charactersToBeSkipped = skipCharacters;
    if ([scanner scanDouble:&longtitude]) {
      if ([scanner scanDouble:&latitude]) {
        if (![scanner scanDouble:&altitude]) altitude = 0.0;
        CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longtitude)
                                                             altitude:altitude
                                                   horizontalAccuracy:0
                                                     verticalAccuracy:0
                                                            timestamp:nil];
        [coordinates addObject:location];
      }
    }
  }
  return coordinates;
}

+ (CLLocation *)coordinateWithString:(NSString *)string timeStamp:(NSDate *)date
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
    return [[KMLMultiGeometry alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(LineString)) {
    return [[KMLLinearRing alloc] initWithXMLElement:element];
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
@end

#pragma mark -

#pragma mark KMLPoint

@implementation KMLPoint
- (void)parseXMLElement:(RXMLElement *)element
{
  [super parseXMLElement:element];
  if ([self.coordinates count]) {
    _location = [self.coordinates objectAtIndex:0];
  }
}
@end

#pragma mark KMLLinearRing

@implementation KMLLinearRing

@end


#pragma mark KMLLineString

@implementation KMLLineString

@end

#pragma mark KMLPolygon

@implementation KMLPolygon

- (void)parseXMLElement:(RXMLElement *)xmlElement
{
  __block NSMutableArray *innerBoundries = [[NSMutableArray alloc] init];
  
  [xmlElement iterate:@"*" usingBlock:^(RXMLElement *element) {
    NSString *elementName = element.tag;
    if (ELTYPE(outerBoundaryIs)) {
      _outerBoundary = [[KMLLinearRing alloc] initWithXMLElement:element];
    }
    else if (ELTYPE(innerBoundaryIs)) {
      KMLLinearRing *ring = [[KMLLinearRing alloc] initWithXMLElement:element];
      if (ring) [innerBoundries addObject:ring];
    }
  }];
  if ([innerBoundries count]) {
    _innerBoundariesArray = innerBoundries;
  }
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
        CLLocation *location = [KMLGeometry coordinateWithString:element.text
                                timeStamp:date];
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