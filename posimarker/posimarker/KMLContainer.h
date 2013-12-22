//
//  KMLDocument.h
//  posimarker
//
//  Created by Chase Zhang on 12/21/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMLElement.h"

@class RXMLElement;

@interface KMLContainer : KMLElement

@property NSString *name;
@property NSString *description;

@property NSArray *elements;
@property(nonatomic) NSDictionary *styles;

+ (id)containerWithXMLElement:(RXMLElement *)element;
@end

@interface KMLFolder : KMLContainer

@end

@interface KMLDocument : KMLContainer

@end
