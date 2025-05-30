//
//  GMSCoordinateBounds+GoogleMaps.h
//  Google Maps SDK for iOS
//
//  Copyright 2013 Google LLC
//
//  Usage of this SDK is subject to the Google Maps/Google Earth APIs Terms of
//  Service: https://cloud.google.com/maps-platform/terms
//


#import "GMSCoordinateBounds.h"
#import "GMSProjection.h"

@class GMSPath;

NS_ASSUME_NONNULL_BEGIN

@interface GMSCoordinateBounds (GoogleMaps)

/** Inits with bounds that encompass `region`. */
- (id)initWithRegion:(GMSVisibleRegion)region;

/** Inits with bounds that encompass `path`. */
- (id)initWithPath:(GMSPath *)path;

/** Returns a `GMSCoordinateBounds` representing the current bounds extended to include `path`. */
- (GMSCoordinateBounds *)includingPath:(GMSPath *)path;

@end

NS_ASSUME_NONNULL_END
