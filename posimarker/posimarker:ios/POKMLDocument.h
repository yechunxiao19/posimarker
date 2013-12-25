//
//  POKMLDocument.h
//  posimarker
//
//  Created by Susan Ye on 12/24/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMLd.h"

#import <zipzap.h>

@interface POKMLDocument : UIDocument{
    KMLDocument *kmlDocument;
}

@property (strong, nonatomic) KMLDocument *kmlDocument;

@end
