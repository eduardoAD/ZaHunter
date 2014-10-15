//
//  ViewController.m
//  ZaHunter
//
//  Created by Eduardo Alvarado Díaz on 10/15/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@interface ViewController () <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *myLocationManager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property NSArray *pizzaArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myLocationManager = [[CLLocationManager alloc] init];
    [self.myLocationManager requestWhenInUseAuthorization];
    self.myLocationManager.delegate = self;

    [self.myLocationManager startUpdatingLocation];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.pizzaArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];

    MKMapItem *item = [self.pizzaArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [item name];

    return cell;
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if(location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000){
            [self reverseGeocode:location];
            NSLog(@"location: %@",location);
            [self.myLocationManager stopUpdatingLocation];
            break;
        }
    }
}

- (void)reverseGeocode:(CLLocation *)location{
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@ %@ \n%@",placemark.subThoroughfare,placemark.thoroughfare,placemark.locality];
        NSLog(@"Found you: %@",address);
        [self findPizzaNear:placemark.location];
    }];
}

- (void)findPizzaNear:(CLLocation *)location{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        self.pizzaArray = response.mapItems;
        [self.tableView reloadData];
    }];
}







- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to Get Your Location"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [errorAlert show];
    NSLog(@"Error: %@",error);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
