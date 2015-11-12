//
//  WeatherManager.m
//  WeatherForecast
//
//  Created by Zoro on 15/11/3.
//  Copyright © 2015年 Zoro. All rights reserved.
//

#import "WeatherManager.h"
#import "WeatherClient.h"
#import "TSMessage.h"
#import "RACEXTScope.h"

@interface WeatherManager ()

@property (nonatomic, strong, readwrite) WeatherCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;
@property (nonatomic, assign, readwrite) BOOL isError;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WeatherClient *client;

@end

@implementation WeatherManager

+ (instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    @weakify(self);
    
    if (self = [super init]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 100;
        [_locationManager requestWhenInUseAuthorization];
        
        _client = [[WeatherClient alloc] init];
        
        [[[[RACObserve(self, currentLocation) ignore:nil]
           flattenMap:^(CLLocation *newLocation) {
               @strongify(self);
               return [RACSignal merge:@[
                                         [self updateCurrentConditions],
                                         [self updateDailyForecast],
                                         [self updateHourlyForecast]
                                         ]];
           }] deliverOn:RACScheduler.mainThreadScheduler] subscribeError:^(NSError *error) {
             [TSMessage showNotificationWithTitle:@"Error"
                                         subtitle:@"Opps!获取最新天气时出了点问题，请检查网络设置。"
                                             type:TSMessageNotificationTypeError];
               @strongify(self);
               self.isError = YES;
         }];
    }
    return self;
}

- (void)findCurrentLocation:(BOOL)firstUpdate {
    if (firstUpdate) {
        self.isFirstUpdate = YES;
    }
    self.isError = NO;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    if (location.horizontalAccuracy > 0) {
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

- (RACSignal *)updateCurrentConditions {
    @weakify(self);
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WeatherCondition *condition) {
        @strongify(self);
        self.currentCondition = condition;
    }];
}

- (RACSignal *)updateHourlyForecast {
    @weakify(self);
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        @strongify(self);
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    @weakify(self);
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        @strongify(self);
        self.dailyForecast = conditions;
    }];
}

@end
