//
//  WeatherClient.h
//  
//
//  Created by Zoro on 15/11/3.
//
//

#import <Foundation/Foundation.h>
#import "ReactiveCocoa.h"
@import CoreLocation;

@interface WeatherClient : NSObject

- (RACSignal *)fetchJSONFromURL:(NSURL *)url;
- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate;
- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate;
- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate;

@end
