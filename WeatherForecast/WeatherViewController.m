//
//  WeatherViewController.m
//  WeatherForecast
//
//  Created by Zoro on 15/11/3.
//  Copyright © 2015年 Zoro. All rights reserved.
//

#import "WeatherViewController.h"
#import "WeatherManager.h"
#import "Reachability.h"
#import "MJRefresh.h"
#import <LBBlurredImage/UIImageView+LBBlurredImage.h>
@import Charts;

@interface WeatherViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, ChartViewDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *blurredImageView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) LineChartView *hourlyChartView;
@property (nonatomic, strong) LineChartView *dailyChartView;

@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, strong) NSDateFormatter *hourlyFormatter;
@property (nonatomic, strong) NSDateFormatter *dailyFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) BOOL isNetError;

@end

@implementation WeatherViewController

#pragma mark - chart
- (void)setDataCount:(int)count range:(double)range {
    
}

#pragma mark - reachability
- (void)reachabilityChanged:(NSNotification *)note {
    Reachability *curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateUIWithReachabilty:curReach];
}

- (void)updateUIWithReachabilty:(Reachability *)reachability {
    if (reachability == self.internetReachability) {
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        if (netStatus != NotReachable) {
            self.isNetError = NO;
//            if (!self.isFetching) {
//                self.isFetching = YES;
//                [self.tableView.header beginRefreshing];
//                [[WeatherManager sharedManager] findCurrentLocation:NO];
//            }
        } else {
            self.isNetError = YES;
            self.isFetching = NO;
            [self.tableView.header endRefreshing];
        }
    }
}

#pragma mark - transform
//将时间戳转换成NSDate
+ (NSDate *)changeSpToTime:(NSString *)spString{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:[spString intValue]];
    return confromTimesp;
}

//将时间戳转换成NSDate,加上时区偏移
+ (NSDate *)zoneChange:(NSString *)spString{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:[spString intValue]];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:confromTimesp];
    NSDate *localeDate = [confromTimesp dateByAddingTimeInterval: interval];
    return localeDate;
}

//华氏度转摄氏度
+ (NSNumber *)temperatureFahrenheitToCelsius:(NSNumber *)fahrenheit {
    return [NSNumber numberWithFloat:(fahrenheit.floatValue - 32) * 5 / 9];
}

#pragma mark - init
- (id)init {
    if (self = [super init]) {
        _hourlyFormatter = [[NSDateFormatter alloc] init];
        _hourlyFormatter.dateFormat = @"HH:mm";
        
        _dailyFormatter = [[NSDateFormatter alloc] init];
        _dailyFormatter.dateFormat = @"MM/dd EEEE";
        
        _timeFormatter = [[NSDateFormatter alloc] init];
        _timeFormatter.dateFormat = @"MM/dd HH:mm EEEE";
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    
    self.backgroundImageView.frame = bounds;
    self.blurredImageView.frame = bounds;
    self.tableView.frame = bounds;
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isError"] && object == [WeatherManager sharedManager]) {
        if ([WeatherManager sharedManager].isError == YES) {
            [self.tableView.header endRefreshing];
            self.isFetching = NO;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return MIN([[WeatherManager sharedManager].hourlyForecast count], 6) + 1;
    }
    return MIN([[WeatherManager sharedManager].dailyForecast count], 6) + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"每小时预报"];
        }
        else {
            WeatherCondition *weather = [WeatherManager sharedManager].hourlyForecast[indexPath.row - 1];
            [self configureHourlyCell:cell weather:weather];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self configureHeaderCell:cell title:@"每日预报"];
        }
        else {
            WeatherCondition *weather = [WeatherManager sharedManager].dailyForecast[indexPath.row - 1];
            [self configureDailyCell:cell weather:weather];
        }
    }
    
    return cell;
}

- (void)configureHeaderCell:(UITableViewCell *)cell title:(NSString *)title {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = @"";
    cell.imageView.image = nil;
}

- (void)configureHourlyCell:(UITableViewCell *)cell weather:(WeatherCondition *)weather {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.hourlyFormatter stringFromDate:[WeatherViewController changeSpToTime:weather.date]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f°", [WeatherViewController temperatureFahrenheitToCelsius:weather.temperature].floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)configureDailyCell:(UITableViewCell *)cell weather:(WeatherCondition *)weather {
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    cell.textLabel.text = [self.dailyFormatter stringFromDate:[WeatherViewController changeSpToTime:weather.date]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.0f° / %.0f°",
                                 [WeatherViewController temperatureFahrenheitToCelsius:weather.tempHigh].floatValue,
                                 [WeatherViewController temperatureFahrenheitToCelsius:weather.tempLow].floatValue];
    cell.imageView.image = [UIImage imageNamed:[weather imageName]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger cellCount = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    return self.screenHeight / (CGFloat)cellCount;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat height = scrollView.bounds.size.height;
    CGFloat position = MAX(scrollView.contentOffset.y, 0.0);
    CGFloat percent = MIN(position / height, 1.0);
    self.blurredImageView.alpha = percent;
}

#pragma mark - viewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    UIImage *background = [UIImage imageNamed:@"bg"];
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:background];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.backgroundImageView];
    
    self.blurredImageView = [[UIImageView alloc] init];
    self.blurredImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.blurredImageView.alpha = 0;
    [self.blurredImageView setImageToBlur:background blurRadius:10 completionBlock:nil];
    [self.view addSubview:self.blurredImageView];
    
    // table view
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.2];
    //self.tableView.pagingEnabled = YES;
    [self.view addSubview:self.tableView];
    
    CGRect headerFrame = [UIScreen mainScreen].bounds;
    CGFloat inset = 20;
    CGFloat temperatureHeight = 110;
    CGFloat hiloHeight = 40;
    CGFloat iconHeight = 30;
    CGRect sunRiseFrame = CGRectMake(inset,
                                     headerFrame.size.height - iconHeight,
                                     (headerFrame.size.width - 2 * inset) / 2,
                                     iconHeight);
    CGRect sunSetFrame = CGRectMake(headerFrame.size.width / 2,
                                    sunRiseFrame.origin.y,
                                    sunRiseFrame.size.width,
                                    iconHeight);
    CGRect windSpeedFrame = CGRectMake(inset,
                                       sunRiseFrame.origin.y - iconHeight,
                                       sunRiseFrame.size.width,
                                       iconHeight);
    CGRect humidityFrame = CGRectMake(sunSetFrame.origin.x,
                                      windSpeedFrame.origin.y,
                                      windSpeedFrame.size.width,
                                      iconHeight);
    CGRect hiloFrame = CGRectMake(inset,
                                  windSpeedFrame.origin.y - hiloHeight,
                                  headerFrame.size.width - 2 * inset,
                                  hiloHeight);
    CGRect temperatureFrame = CGRectMake(inset,
                                         hiloFrame.origin.y - temperatureHeight,
                                         headerFrame.size.width - 2 * inset,
                                         temperatureHeight);
    CGRect iconFrame = CGRectMake(inset,
                                  temperatureFrame.origin.y - iconHeight,
                                  iconHeight,
                                  iconHeight);
    
    CGRect conditionsFrame = iconFrame;
    conditionsFrame.size.width = self.view.bounds.size.width - 2 * inset - iconHeight - 10;
    conditionsFrame.origin.x = iconFrame.origin.x + iconHeight + 10;
    
    UIView *header = [[UIView alloc] initWithFrame:headerFrame];
    header.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = header;
    
    // top
    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, 50)];
    cityLabel.backgroundColor = [UIColor clearColor];
    cityLabel.textColor = [UIColor whiteColor];
    cityLabel.text = @"加载中...";
    cityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
    cityLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:cityLabel];
    
    UILabel *updateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 80)];
    updateTimeLabel.backgroundColor = [UIColor clearColor];
    updateTimeLabel.textColor = [UIColor whiteColor];
    updateTimeLabel.text = @"发布时间：00/00 00:00 星期一";
    updateTimeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    updateTimeLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:updateTimeLabel];
    
    // bottom left
    UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:temperatureFrame];
    temperatureLabel.backgroundColor = [UIColor clearColor];
    temperatureLabel.textColor = [UIColor whiteColor];
    temperatureLabel.text = @"0°";
    temperatureLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:120];
    [header addSubview:temperatureLabel];
    
    UILabel *hiloLabel = [[UILabel alloc] initWithFrame:hiloFrame];
    hiloLabel.backgroundColor = [UIColor clearColor];
    hiloLabel.textColor = [UIColor whiteColor];
    hiloLabel.text = @"0° / 0°";
    hiloLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28];
    [header addSubview:hiloLabel];
    
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    [header addSubview:iconView];
    
    UILabel *conditionsLabel = [[UILabel alloc] initWithFrame:conditionsFrame];
    conditionsLabel.backgroundColor = [UIColor clearColor];
    conditionsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    conditionsLabel.textColor = [UIColor whiteColor];
    [header addSubview:conditionsLabel];
    
    UILabel *windSpeedLabel = [[UILabel alloc] initWithFrame:windSpeedFrame];
    windSpeedLabel.backgroundColor = [UIColor clearColor];
    windSpeedLabel.textColor = [UIColor whiteColor];
    windSpeedLabel.text = @"风速：0m/s";
    windSpeedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    [header addSubview:windSpeedLabel];
    
    UILabel *humidityLabel = [[UILabel alloc] initWithFrame:humidityFrame];
    humidityLabel.backgroundColor = [UIColor clearColor];
    humidityLabel.textColor = [UIColor whiteColor];
    humidityLabel.text = @"湿度：0%";
    humidityLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    [header addSubview:humidityLabel];
    
    UILabel *sunRiseLabel = [[UILabel alloc] initWithFrame:sunRiseFrame];
    sunRiseLabel.backgroundColor = [UIColor clearColor];
    sunRiseLabel.textColor = [UIColor whiteColor];
    sunRiseLabel.text = @"日出：00:00";
    sunRiseLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    [header addSubview:sunRiseLabel];
    
    UILabel *sunSetLabel = [[UILabel alloc] initWithFrame:sunSetFrame];
    sunSetLabel.backgroundColor = [UIColor clearColor];
    sunSetLabel.textColor = [UIColor whiteColor];
    sunSetLabel.text = @"日落：00:00";
    sunSetLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    [header addSubview:sunSetLabel];
    
    [[RACObserve([WeatherManager sharedManager], currentCondition)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(WeatherCondition *newCondition) {
         self.isFetching = NO;
         
         temperatureLabel.text = [NSString stringWithFormat:@"%.0f°",[WeatherViewController temperatureFahrenheitToCelsius:newCondition.temperature].floatValue];
         conditionsLabel.text = [newCondition.condition capitalizedString];
         cityLabel.text = [newCondition.locationName capitalizedString];
         updateTimeLabel.text = [NSString stringWithFormat:@"发布时间：%@", [self.timeFormatter stringFromDate:[WeatherViewController changeSpToTime:newCondition.date]]];
         windSpeedLabel.text = [NSString stringWithFormat:@"风速：%.1fm/s", newCondition.windSpeed.floatValue];
         humidityLabel.text = [NSString stringWithFormat:@"湿度：%.0f%%", newCondition.humidity.floatValue];
         sunRiseLabel.text = [NSString stringWithFormat:@"日出：%@", [self.hourlyFormatter stringFromDate:[WeatherViewController changeSpToTime:newCondition.sunrise]]];
         sunSetLabel.text = [NSString stringWithFormat:@"日落：%@", [self.hourlyFormatter stringFromDate:[WeatherViewController changeSpToTime:newCondition.sunset]]];
         
         iconView.image = [UIImage imageNamed:[newCondition imageName]];
         
         [self.tableView.header endRefreshing];
     }];
    
    RAC(hiloLabel, text) = [[RACSignal combineLatest:@[
                                                       RACObserve([WeatherManager sharedManager], currentCondition.tempHigh),
                                                       RACObserve([WeatherManager sharedManager], currentCondition.tempLow)]
                                              reduce:^(NSNumber *hi, NSNumber *low) {
                                                  return [NSString  stringWithFormat:@"%.0f° / %.0f°",
                                                          [WeatherViewController temperatureFahrenheitToCelsius:hi].floatValue,
                                                          [WeatherViewController temperatureFahrenheitToCelsius:low].floatValue];
                                              }]
                            deliverOn:RACScheduler.mainThreadScheduler];
    
    [[RACObserve([WeatherManager sharedManager], hourlyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast) {
         [self.tableView reloadData];
     }];
    
    [[RACObserve([WeatherManager sharedManager], dailyForecast)
      deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *newForecast) {
         [self.tableView reloadData];
     }];
    
    [[WeatherManager sharedManager] addObserver:self
                                     forKeyPath:@"isError"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
    
    // mjrefresh
    MJRefreshNormalHeader *refreshHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        if (YES == self.isNetError) {
            [self.tableView.header endRefreshing];
        } else if (NO == self.isFetching) {
            self.isFetching = YES;
            [[WeatherManager sharedManager] findCurrentLocation:FALSE];
        }
    }];
    refreshHeader.stateLabel.textColor = [UIColor whiteColor];
    refreshHeader.lastUpdatedTimeLabel.textColor = [UIColor whiteColor];
    self.tableView.header = refreshHeader;
    [self.tableView.header beginRefreshing];
    
    self.isFetching = YES;
    self.isNetError = NO;
    [[WeatherManager sharedManager] findCurrentLocation:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    // network
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    [self updateUIWithReachabilty:self.internetReachability];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
