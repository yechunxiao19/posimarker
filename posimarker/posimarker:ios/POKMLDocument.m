//
//  POKMLDocument.m
//  posimarker
//
//  Created by Susan Ye on 12/24/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#import "POKMLDocument.h"

#define KMLDocumentType  @"KML document"
#define KMZDocumentType  @"KML-Zip document"

@interface POKMLDocument()

@end

@implementation POKMLDocument

@synthesize kmlDocument = _kmlDocument;

-(id)initWithFileURL:(NSURL *)url{
    
    self = [super initWithFileURL:url];
    if (self) {
        
    }
    return self;
}


- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError{
    
    NSData *data;
    if ([contents isKindOfClass:[NSData class]]) {
        data = contents;
    }

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

@end
