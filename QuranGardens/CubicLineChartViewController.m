//
//  CubicLineChartViewController.m
//  ChartsDemo
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

#import "CubicLineChartViewController.h"
#import "DateValueFormatter.h"
#import "NSString+Localization.h"

@import Charts;

@interface CubicLineSampleFillFormatter : NSObject <IChartFillFormatter>
{
}
@end

@implementation CubicLineSampleFillFormatter

- (CGFloat)getFillLinePositionWithDataSet:(LineChartDataSet *)dataSet dataProvider:(id<LineChartDataProvider>)dataProvider
{
    return -10.f;
}

@end

@interface CubicLineChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet LineChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;

@end

@implementation CubicLineChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleFilled", @"label": @"Toggle Filled"},
                     @{@"key": @"toggleCircles", @"label": @"Toggle Circles"},
                     @{@"key": @"toggleCubic", @"label": @"Toggle Cubic"},
                     @{@"key": @"toggleHorizontalCubic", @"label": @"Toggle Horizontal Cubic"},
                     @{@"key": @"toggleStepped", @"label": @"Toggle Stepped"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     @{@"key": @"toggleData", @"label": @"Toggle Data"},
                     ];
    
    _chartView.delegate = self;
    
    [_chartView setViewPortOffsetsWithLeft:0.f top:20.f right:0.f bottom:0.f];
    //_chartView.backgroundColor = [UIColor colorWithRed:104/255.f green:241/255.f blue:175/255.f alpha:1.f];

    _chartView.chartDescription.enabled = NO;
    
    _chartView.dragEnabled = YES;
    [_chartView setScaleEnabled:YES];
    _chartView.pinchZoomEnabled = YES;
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.maxHighlightDistance = 300.0;
    //_chartView.chartDescription.text = @"Daily Score chart";
    
    _chartView.xAxis.enabled = YES;
    
    _chartView.layer.cornerRadius = 10.0;
    _chartView.layer.borderColor = [UIColor clearColor].CGColor;
    _chartView.layer.masksToBounds = YES;
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionTopInside;
    xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
    xAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
    xAxis.drawAxisLineEnabled = YES;
    xAxis.drawGridLinesEnabled = YES;
    xAxis.centerAxisLabelsEnabled = YES;
    xAxis.granularity = 3600.0;
    xAxis.valueFormatter = [[DateValueFormatter alloc] init];
    
    ChartYAxis *yAxis = _chartView.leftAxis;
    yAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.f];
    [yAxis setLabelCount:6 force:NO];
    yAxis.labelTextColor = UIColor.whiteColor;
    yAxis.labelPosition = YAxisLabelPositionInsideChart;
    yAxis.drawGridLinesEnabled = YES;
    yAxis.axisLineColor = UIColor.whiteColor;
    
    _chartView.rightAxis.enabled = YES;
    _chartView.legend.enabled = NO;
    
    _sliderX.value = [self getStoredDays];
    _sliderY.value = 100.0;
    [self slidersValueChanged:nil];
    
    [_chartView animateWithXAxisDuration:2.0 yAxisDuration:2.0];
}

- (float)getStoredDays {
    float result = [[NSUserDefaults standardUserDefaults] floatForKey:self.chartTitle];
    if (result < 1.f) {
        if (self.scores != nil && self.scores.count > 0) {
            return (float) self.scores.count;
        } else {
            return 0.f;
        }
    }
    
    return result;
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setFloat:_sliderX.value forKey:self.chartTitle];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = [self.chartTitle localize];//[@"Daily Score Chart" localize];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateChartData
{
    if (self.shouldHideData)
    {
        _chartView.data = nil;
        return;
    }
    
    [self setDataCount:_sliderX.value range:_sliderY.value];
}

- (void)setDataCount:(int)count range:(double)range
{
    
    self.sliderX.maximumValue = (float)self.scores.count;
    self.sliderX.minimumValue = 1;
    NSMutableArray *yVals1 = [[NSMutableArray alloc] init];
    
    NSMutableArray<NSDate *> * ordered = self.scores.allKeys.mutableCopy;

    [ordered sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDate *d1 = (NSDate *)obj1;
        NSDate *d2 = (NSDate *)obj2;
        return [d1 compare:d2];
    }];
    if (count < ordered.count) {
        ordered = [ordered subarrayWithRange:NSMakeRange(ordered.count - count, count)].mutableCopy;
    }
    
    for (NSDate *date in ordered) {
       [yVals1 addObject:[[ChartDataEntry alloc] initWithX:date.timeIntervalSince1970 y:self.scores[date].doubleValue]];
        NSLog(@"date %@ score: %f", date, self.scores[date].doubleValue);
    }
    
    LineChartDataSet *set1 = nil;
    if (_chartView.data.dataSetCount > 0)
    {
        set1 = (LineChartDataSet *)_chartView.data.dataSets[0];
        set1.values = yVals1;
        [_chartView.data notifyDataChanged];
        [_chartView notifyDataSetChanged];
    }
    else
    {
        set1 = [[LineChartDataSet alloc] initWithValues:yVals1 label:@"DataSet 1"];
        set1.mode = LineChartModeCubicBezier;
        set1.cubicIntensity = 0.2;
        set1.drawCirclesEnabled = NO;
        set1.lineWidth = 1.8;
        set1.circleRadius = 4.0;
        [set1 setCircleColor:UIColor.whiteColor];
        set1.highlightColor = [UIColor colorWithRed:244/255.f green:117/255.f blue:117/255.f alpha:1.f];
        [set1 setColor:UIColor.whiteColor];
        set1.fillColor = UIColor.whiteColor;
        set1.fillAlpha = 1.f;
        set1.drawHorizontalHighlightIndicatorEnabled = NO;
        set1.fillFormatter = [[CubicLineSampleFillFormatter alloc] init];
        
        LineChartData *data = [[LineChartData alloc] initWithDataSet:set1];
        [data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:9.f]];
        [data setDrawValues:NO];
        
        _chartView.data = data;
    }
}

- (void)optionTapped:(NSString *)key
{
    if ([key isEqualToString:@"toggleFilled"])
    {
        for (id<ILineChartDataSet> set in _chartView.data.dataSets)
        {
            set.drawFilledEnabled = !set.isDrawFilledEnabled;
        }
        
        [_chartView setNeedsDisplay];
        return;
    }
    
    if ([key isEqualToString:@"toggleCircles"])
    {
        for (id<ILineChartDataSet> set in _chartView.data.dataSets)
        {
            set.drawCirclesEnabled = !set.isDrawCirclesEnabled;
        }
        
        [_chartView setNeedsDisplay];
        return;
    }
    
    if ([key isEqualToString:@"toggleCubic"])
    {
        for (id<ILineChartDataSet> set in _chartView.data.dataSets)
        {
            set.mode = set.mode == LineChartModeCubicBezier ? LineChartModeLinear : LineChartModeCubicBezier;
        }
        
        [_chartView setNeedsDisplay];
        return;
    }
    
    if ([key isEqualToString:@"toggleStepped"])
    {
        for (id<ILineChartDataSet> set in _chartView.data.dataSets)
        {
            set.mode = set.mode == LineChartModeStepped ? LineChartModeLinear : LineChartModeStepped;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleHorizontalCubic"])
    {
        for (id<ILineChartDataSet> set in _chartView.data.dataSets)
        {
            set.mode = set.mode == LineChartModeCubicBezier ? LineChartModeHorizontalBezier : LineChartModeCubicBezier;
        }
        
        [_chartView setNeedsDisplay];
        return;
    }
    
    [super handleOption:key forChartView:_chartView];
}

#pragma mark - Actions

- (IBAction)slidersValueChanged:(id)sender
{
    _sliderTextX.text = [@((int)_sliderX.value) stringValue];
    _sliderTextY.text = [@((int)_sliderY.value) stringValue];
    
    [self updateChartData];
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
