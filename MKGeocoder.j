@import "MKPlacemark.j"
@import "MKMapView.j"

@implementation MKGeocoder : CPObject
{
    Object          _geocoder;
    CPInvocation    _geocodeInvocation;
    BOOL            geocoding @accessors(readonly);
}

- (id)init
{
    self = [super init];

    _geocoder = nil;
    geocoding = NO;

    _geocodeInvocation = [[CPInvocation alloc] initWithMethodSignature:nil];
    [_geocodeInvocation setTarget:self];
    [_geocodeInvocation setSelector:@selector(_geocodeWithRequest:completionHandler:)];

    [self loadGoogleAPI];

    return self;
}

- (id)loadGoogleAPI
{
    var loader = [MKMapView GoogleAPIScriptLoader];

    [loader addCompletionFunction:function()
    {
        [self _buildGeocoder];
    }];

    [loader load];
}

- (void)_buildGeocoder
{
    _geocoder = new google.maps.Geocoder();
}

- (void)geocodeAddressString:(CPString)anAddress inRegion:(id/*MKCoordinateRegion*/)region completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var request = {address:anAddress};
    if (region)
    {
        var bounds = LatLngBoundsFromMKCoordinateRegion(region);
        request['bounds'] = bounds;
    }

    [self geocodeWithRequest:request completionHandler:completionHandler];
}

- (void)reverseGeocodeLocation:(id/*CLLocationCoordinate2D*/)location completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    var latLng = LatLngFromCLLocationCoordinate2D(location);
    [self geocodeWithRequest:{latLng:latLng} completionHandler:completionHandler];
}

- (void)geocodeWithRequest:(Object)properties completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    if (_geocoder)
        [self _geocodeWithRequest:properties completionHandler:completionHandler];
    else
    {
        [_geocodeInvocation setArgument:properties atIndex:2];
        [_geocodeInvocation setArgument:completionHandler atIndex:3];

        [[MKMapView GoogleAPIScriptLoader] invoqueWhenLoaded:_geocodeInvocation ignoreMultiple:NO];
    }
}

- (void)_geocodeWithRequest:(Object)properties completionHandler:(Function /*(placemarks, error)*/)completionHandler
{
    geocoding = YES;
    _geocoder.geocode(properties, function(results, status)
    {
        var placemarks,
            error;

        if (status == google.maps.GeocoderStatus.OK)
        {
            error = nil;
            placemarks = [CPArray array];
            [results enumerateObjectsUsingBlock:function(result, idx)
            {
                var placemark = [[MKPlacemark alloc] initWithJSON:result];
                [placemarks addObject:placemark];
            }];
        }
        else
        {
            error = status;
            placemarks = nil;
        }

        completionHandler(placemarks, error);
        geocoding = NO;
    });
}

@end