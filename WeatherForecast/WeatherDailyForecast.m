//
//  WeatherDailyForecast.m
//  WeatherForecast
//
//  Created by Zoro on 15/11/3.
//  Copyright © 2015年 Zoro. All rights reserved.
//

#import "WeatherDailyForecast.h"

@implementation WeatherDailyForecast

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
    paths[@"tempHigh"] = @"temp.max";
    paths[@"tempLow"] = @"temp.min";
    return paths;
}

@end
