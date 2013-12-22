//
//  KMLDocument.m
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "KMLContainer.h"
#import "KMLMacros.h"

#import <RXMLElement.h>

@implementation KMLContainer

- (void)parseXMLElement:(RXMLElement *)XMLElement
{
  NSMutableArray *elements = [[NSMutableArray alloc] init];
  NSMutableDictionary *styles = [[NSMutableDictionary alloc] init];
  
  [XMLElement iterate:@"*" usingBlock:^(RXMLElement * element) {
    NSString *elementName = element.tag;
    if (ELTYPE(Style)) {
      KMLStyle *style = [[KMLStyle alloc]initWithXMLElement:element];
      style.parentElement = self;
      if(style.identifier)[styles setObject:style forKey:style.identifier];
    }
    else {
      KMLElement *ele = [KMLContainer containerWithXMLElement:element];
      if (ele==nil) ele = [KMLGeometry geometryWithXMLElement:element];
      
      if (ele) {
        ele.parentElement = self;
        [elements addObject:ele];
      }
    }
  }];
  _elements = elements;
}

+ (id)containerWithXMLElement:(RXMLElement *)element
{
  NSString *elementName = element.tag;
  if (ELTYPE(Document)) {
    return [[KMLDocument alloc] initWithXMLElement:element];
  }
  else if (ELTYPE(Folder))
  {
    return [[KMLFolder alloc]initWithXMLElement:element];
  }
  else if (ELTYPE(Placemark)) {
    return [[KMLPlacemark alloc] initWithXMLElement:element];
  }
  else return nil;
}

@end

#pragma mark - KMLDocument

@implementation KMLDocument

- (void)parseXMLElement:(RXMLElement *)element
{
  NSMutableDictionary *styles;
  [super parseXMLElement:element];
  for (KMLElement *kmlElement in self.elements) {
    if (ELCLASS(kmlElement, KMLStyle))
      [styles setObject:kmlElement forKey:kmlElement.identifier];
  }
}

@end

#pragma mark - KMLFolder

@implementation KMLFolder
@end
