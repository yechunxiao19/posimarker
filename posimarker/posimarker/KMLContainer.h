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

@property(nonatomic, weak) KMLContainer *upperContainer;

- (instancetype)initWithRootXMLElement:(RXMLElement *)rootXMLElement;

@end

@interface KMLFolder : KMLContainer

@end

@interface KMLDocument : KMLContainer

@property NSDictionary *styles;

@end