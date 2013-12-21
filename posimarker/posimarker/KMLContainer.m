//
//  KMLDocument.m
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "KMLContainer.h"
#import <RXMLElement.h>


@implementation KMLContainer

- (instancetype)initWithRootXMLElement:(RXMLElement *)rootXMLElement
{
  self = [super initWithIndentifier:[rootXMLElement attribute:@"id"]];
  if (self) {
    RXMLElement *nameElement = [rootXMLElement child:@"name"];
    RXMLElement *descriptionElement = [rootXMLElement child:@"description"];
    if (nameElement) _name = nameElement.text;
    if (descriptionElement) _description = descriptionElement.text;
  }
  return self;
}


#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])
- (NSMutableArray *)parseWithRootXMLElement:(RXMLElement *)rootXMLElement
{
  NSMutableArray *elements = [[NSMutableArray alloc] init];
  
  [rootXMLElement iterate:@"*" usingBlock:^(RXMLElement * element) {
    NSString *elementName = element.tag;
    if (ELTYPE(Style)) {
      [elements addObject:[self KMLStyleElementWithXMLElement:element]];
    }
    else if(ELTYPE(Folder)) {
      [elements addObject:[self KMLFolderWithXMLElement:element]];
    }
    else if(ELTYPE(Document)) {
      [elements addObject:[self KMLDocumentWithXMLElement:element]];
    }
    else if(ELTYPE(Placemark)) {
      
    }
  }];
  return elements;
}

- (KMLStyle *)KMLStyleElementWithXMLElement:(RXMLElement *)element
{
  KMLStyle *style = [[KMLStyle alloc] initWithIndentifier:[element attribute:@"id"]];
  [element iterate:@"*" usingBlock:^(RXMLElement * ele) {
    NSString *elementName = ele.tag;
    if (ELTYPE(LineStyle)) {
      RXMLElement *colorElement = [ele child:@"color"];
      RXMLElement *widthElement = [ele child:@"width"];
      if (colorElement) style.strokeColorString = colorElement.text;
      if (widthElement) style.strokeWidth = (CGFloat)[widthElement.text doubleValue];
    }
    else if (ELTYPE(PolyStyle)) {
      RXMLElement *colorElement = [ele child:@"color"];
      RXMLElement *outlineElement = [ele child:@"outline"];
      RXMLElement *fillElement = [ele child:@"fill"];
      if (colorElement) style.fillColorString = colorElement.text;
      if (outlineElement) style.stroke = [outlineElement.text boolValue];
      if (fillElement) style.fill = [fillElement.text boolValue];
    }
  }];
  
  style.upperElement = self;
  return style;
}

- (KMLFolder *)KMLFolderWithXMLElement:(RXMLElement *)element
{
  KMLFolder *folder = [[KMLFolder alloc] initWithRootXMLElement:element];
  folder.upperElement = self;
  return folder;
}

- (KMLDocument *)KMLDocumentWithXMLElement:(RXMLElement *)element
{
  KMLDocument *document = [[KMLDocument alloc] initWithRootXMLElement:element];
  document.upperElement = self;
  return document;
}

@end

#pragma mark - KMLDocument

@implementation KMLDocument

@end

#pragma mark - KMLFolder

@implementation KMLFolder


@end
