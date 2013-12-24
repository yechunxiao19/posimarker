//
//  KMLMacros.h
//  posimarker
//
//  Created by Chase Zhang on 12/22/13.
//  Copyright (c) 2013 posi. All rights reserved.
//

#ifndef posimarker_KMLMacros_h
#define posimarker_KMLMacros_h

#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])

#define ELCLASS(instance, typeName) [instance isKindOfClass:NSClassFromString(@#typeName)]

#endif
