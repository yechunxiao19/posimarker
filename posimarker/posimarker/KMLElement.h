//
//  KMLElement.h
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#pragma mark - KMLELement
@class RXMLElement;
@interface KMLElement : NSObject

@property(nonatomic, weak) KMLElement *parentElement;
@property(nonatomic, readonly) NSString *identifier;

- (instancetype)initWithIndentifier:(NSString *)identifier;
- (instancetype)initWithXMLElement:(RXMLElement *)element;
- (void)parseXMLElement:(RXMLElement *)element;

@end

#pragma mark -
#pragma mark KMLStyle

@interface KMLStyle : KMLElement

@property(nonatomic) NSString *fillColorString;
@property(nonatomic) NSString *strokeColorString;
@property(nonatomic) CGFloat strokeWidth;
@property(nonatomic) BOOL fill;
@property(nonatomic) BOOL stroke;

@end


#pragma mark KMLGeometry

@interface KMLGeometry : KMLElement

@property(nonatomic) NSArray *coordinates;
+ (id)geometryWithXMLElement:(RXMLElement *)element;

@end

#pragma mark KMLMultiGeometry

@interface KMLMultiGeometry : KMLGeometry

@property(nonatomic) NSArray *subGeometries;

@end

#pragma mark KMLPlacemark

@interface KMLPlacemark : KMLElement

@property(nonatomic) NSString *name;
@property(nonatomic) NSString *description;
@property(nonatomic) NSString *styleURL;
@property(nonatomic) KMLStyle *style;
@property(nonatomic) KMLGeometry *geometry;

@end

#pragma mark -
#pragma mark KMLPoint

@interface KMLPoint : KMLGeometry

@property(nonatomic) CLLocation *location;

@end

#pragma mark KMLLinearRing

@interface KMLLinearRing : KMLGeometry

@end

#pragma mark KMLLineString

@interface KMLLineString : KMLGeometry

@end

#pragma mark KMLPolygon

@interface KMLPolygon : KMLGeometry

@property(nonatomic) KMLLinearRing *outerBoundary;
@property(nonatomic) NSArray *innerBoundariesArray;

@end


#pragma mark -
#pragma mark GXTrack

@interface GXTrack : KMLGeometry

- (void)iterateTrackWithBlock:(void (^)(CLLocation *l))block;

@end

@interface GXMultiTrack : KMLGeometry

@property(nonatomic) NSArray *subTracks;

@end
