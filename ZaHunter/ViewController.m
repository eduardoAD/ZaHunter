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


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate>
@property CLLocationManager *myLocationManager;
@property CLPlacemark *currentLocation;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property NSArray *pizzaArray;
@property double numberTotalTime;
@property (strong, nonatomic) IBOutlet UILabel *footerLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.myLocationManager = [[CLLocationManager alloc] init];
    [self.myLocationManager requestWhenInUseAuthorization];
    self.myLocationManager.delegate = self;

    self.footerLabel.text = @"";
    [self.myLocationManager startUpdatingLocation];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
            if (distanceOne < distanceTwo){
                return NSOrderedAscending;
            }
            else{
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
        [self calculateWalkingTime];
        [self.tableView reloadData];
        [self addAnnotations];
        [self zoomIn];
    }];
}

- (void)calculateWalkingTime{
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    self.numberTotalTime = 0.0;
    double muggleTime = 50;

    for (MKMapItem *destination in self.pizzaArray) {
        MKDirectionsRequest *request = [MKDirectionsRequest new];
        request.source = source;
        request.destination = destination;
        request.transportType = MKDirectionsTransportTypeWalking;
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error)
         {
             MKRoute *route = response.routes.firstObject;
             self.numberTotalTime += route.expectedTravelTime/60 + muggleTime;
             //NSLog(@"%.2f minutes", self.numberTotalTime);
             self.footerLabel.text = [NSString stringWithFormat:@"%.2f minutes", self.numberTotalTime];
         }];
        source = destination;
    }
}

- (void)addAnnotations{
    for (MKMapItem *mapItem in self.pizzaArray) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc]init];
        annotation.coordinate = mapItem.placemark.coordinate;
        annotation.title = mapItem.name;
        float distance = [mapItem.placemark.location distanceFromLocation:self.currentLocation.location];
        annotation.subtitle = [NSString stringWithFormat:@"%.2f meters", distance];

        [self.mapView addAnnotation:annotation];
    }
}

- (void)zoomIn{
    CLLocation *location = self.currentLocation.location;

    CLLocationCoordinate2D zoom;
    zoom.latitude = location.coordinate.latitude;
    zoom.longitude = location.coordinate.longitude;

    MKCoordinateSpan span;
    span.latitudeDelta = .05;
    span.longitudeDelta = .05;

    MKCoordinateRegion region;
    region.center = zoom;
    region.span = span;
    [self.mapView setRegion:region animated:YES];
    [self.mapView regionThatFits:region];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if (annotation == mapView.userLocation) {
        return nil;
    }
    MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MyPinID"];
    pin.canShowCallout = YES;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    pin.image = [UIImage imageNamed:@"PieceOfPizza"];
    
    return pin;
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
