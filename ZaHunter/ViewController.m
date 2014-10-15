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
@property CLPlacemark *currentLocation;
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

    float distance = [item.placemark.location distanceFromLocation:self.currentLocation.location];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f meters", distance];

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
        self.currentLocation = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@, %@ at %@",
                             self.currentLocation.subThoroughfare,
                             self.currentLocation.thoroughfare,
                             self.currentLocation.locality];
        NSLog(@"Found you: %@",address);
        [self findPizzaNear:self.currentLocation.location];
    }];
}

- (void)findPizzaNear:(CLLocation *)location{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(.1, .1));
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *allPizzaItems = response.mapItems;
        allPizzaItems = [allPizzaItems sortedArrayUsingComparator:^NSComparisonResult(MKMapItem *objectOne, MKMapItem *objectTwo) {
            float distanceOne = [objectOne.placemark.location distanceFromLocation:self.currentLocation.location];
            float distanceTwo = [objectTwo.placemark.location distanceFromLocation:self.currentLocation.location];
            if (distanceOne < distanceTwo)
            {
                return NSOrderedAscending;
            }
            else
            {
                return NSOrderedDescending;
            }
        }];

        NSRange fourPizzaItems;
        if (allPizzaItems.count >= 4){
            fourPizzaItems = NSMakeRange(0, 4);
        }
        else{
            fourPizzaItems = NSMakeRange(0, allPizzaItems.count);
        }
        allPizzaItems = [allPizzaItems subarrayWithRange:fourPizzaItems];

        self.pizzaArray = allPizzaItems;
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
