//
//  WeatherManager.h
//  WeatherForecast
//
//  Created by Zoro on 15/11/3.
//  Copyright © 2015年 Zoro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ReactiveCocoa.h"
#import "WeatherCondition.h"
@import CoreLocation;

@interface WeatherManager : NSObject <CLLocationManagerDelegate>

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) CLLocation *currentLocation;
@property (nonatomic, strong, readonly) WeatherCondition *currentCondition;
@property (nonatomic, strong, readonly) NSArray *hourlyForecast;
@property (nonatomic, strong, readonly) NSArray *dailyForecast;

- (void)findCurrentLocation:(BOOL)firstUpdate;

@end
