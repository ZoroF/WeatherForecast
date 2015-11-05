//
//  WeatherCondition.h
//  WeatherForecast
//
//  Created by Zoro on 15/11/3.
//  Copyright © 2015年 Zoro. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface WeatherCondition : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSNumber *humidity;
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *tempHigh;
@property (nonatomic, strong) NSNumber *tempLow;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSString *sunrise;
@property (nonatomic, strong) NSString *sunset;
@property (nonatomic, strong) NSString *conditionDescription;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSNumber *windBearing;
@property (nonatomic, strong) NSNumber *windSpeed;
@property (nonatomic, strong) NSString *icon;

- (NSString *)imageName;

@end
