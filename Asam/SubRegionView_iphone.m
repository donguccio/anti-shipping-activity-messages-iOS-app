#import "SubRegionView_iphone.h"
#import "AppDelegate.h"
#import "AsamUtility.h"
#import "AsamFetch.h"
#import "AsamResultViewController_iphone.h"
#import "DSActivityView.h"
#import <MapKit/MapKit.h>
#import "Asam.h"

@interface SubRegionView_iphone() <MKMapViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSMutableArray *selectedSubRegions;

- (void)filterSubregions;
- (void)queryAsam:(id)sender;
- (void)reset;
- (void)dismissView;
- (void)showActionSheet;
- (void)populateSubregions;
- (void)prepareNavBar;
- (void)segmentAction:(UISegmentedControl*)sender;
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;

@end

@implementation SubRegionView_iphone

#pragma
#pragma mark - View Life Cycles
- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedSubRegions = [[NSMutableArray alloc] init];
    [self prepareNavBar];
    [self populateSubregions];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.numberOfTapsRequired = 0;
    lpgr.numberOfTouchesRequired = 1;
    lpgr.minimumPressDuration = 0.1;
    [self.mapView addGestureRecognizer:lpgr];
}

- (void)viewDidUnload{
    self.mapView = nil;
    self.selectedSubRegions = nil;
    self.segmentedControl = nil;
    [super viewDidUnload];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    MKMapPoint mapPoint = MKMapPointForCoordinate(touchMapCoordinate);
    for (id <MKOverlay> overlay in self.mapView.overlays) {
        if ([overlay isKindOfClass:[MKPolygon class]]) {
            MKPolygon *poly = (MKPolygon*)overlay;
            id view = [self.mapView viewForOverlay:poly];
            if ([view isKindOfClass:[MKPolygonView class]]) {
                MKPolygonView *polyView = (MKPolygonView*) view;
                CGPoint polygonViewPoint = [polyView pointForMapPoint:mapPoint];
                BOOL mapCoordinateIsInPolygon = NO;
                if (polyView.path == nil) { // iOS 7 bug workaround.
                    CGMutablePathRef pathReference = CGPathCreateMutable();
                    MKMapPoint *polygonPoints = poly.points;
                    for (int p = 0; p < poly.pointCount; p++) {
                        MKMapPoint mp = polygonPoints[p];
                        if (p == 0) {
                            CGPathMoveToPoint(pathReference, NULL, mp.x, mp.y);
                        }
                        else {
                            CGPathAddLineToPoint(pathReference, NULL, mp.x, mp.y);
                        }
                    }
                    CGPoint mapPointAsCGP = CGPointMake(mapPoint.x, mapPoint.y);
                    mapCoordinateIsInPolygon = CGPathContainsPoint(pathReference, nil, mapPointAsCGP, NO);
                    CGPathRelease(pathReference);
                }
                else {
                    mapCoordinateIsInPolygon = CGPathContainsPoint(polyView.path, nil, polygonViewPoint, NO);
                }
                if (mapCoordinateIsInPolygon) {
                    if (![self.selectedSubRegions containsObject:poly.title]) {
                        [self.selectedSubRegions addObject:poly.title];
                        polyView.strokeColor = [UIColor orangeColor];
                        polyView.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
                        break;
                    }
                    else {
                        [self.selectedSubRegions removeObject:poly.title];
                        polyView.strokeColor=[UIColor orangeColor];
                        polyView.fillColor=[[UIColor yellowColor] colorWithAlphaComponent:0.2];
                        break;
                    }
                }
            }
        }
        
    }
    if (self.selectedSubRegions.count > 0) {
        self.segmentedControl.enabled = YES;
    }
    else {
        self.segmentedControl.enabled = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma
#pragma mark - Map Views
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if ([overlay isKindOfClass:[MKPolygon class]]) {
		MKPolygonView *polyView = [[MKPolygonView alloc] initWithOverlay:overlay];
		polyView.lineWidth = 2;
        polyView.strokeColor = [UIColor orangeColor];
		polyView.fillColor = [[UIColor yellowColor] colorWithAlphaComponent:0.2];
        polyView.opaque = TRUE;
		return polyView;
	}
	return nil;
}

#pragma
#pragma mark - Helper method to populate subregions 
- (void)populateSubregions {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"subregions" ofType:@"csv"];
	NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray *pointStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	for (int idx = 0; idx < pointStrings.count; idx++) {
		NSString *currentPointString = [pointStrings objectAtIndex:idx];
		NSArray *latLonSubArr = [currentPointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        NSString *index = [latLonSubArr objectAtIndex:0];
        NSUInteger c = latLonSubArr.count - 1 ;
        CLLocationCoordinate2D pointsToUse[c / 2];
        for (int i = 0; i < c; i++) {
            if (i == 0) {
                double latt = 0.0;
                double lonn = 0.0;
                for (int j = 0; j < c; j++) {
                    
                    // Build the midpoint.
                    if (!(j % 2)) {
                        latt += [[latLonSubArr objectAtIndex:j + 1] doubleValue];
                    }
                    else {
                        lonn += [[latLonSubArr objectAtIndex:j + 1] doubleValue];
                    }
                }
            }
            if (!(i % 2)) {
                double lat = [[latLonSubArr objectAtIndex:i + 1] doubleValue];
                double lon = [[latLonSubArr objectAtIndex:i + 2] doubleValue];
                pointsToUse[i / 2] = CLLocationCoordinate2DMake(lat,lon);
            }
        }
        MKPolygon *poly=[MKPolygon polygonWithCoordinates:pointsToUse count:(c / 2)];
        poly.title = index;
        [self.mapView addOverlay:poly];
    }
    self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
}


- (void)prepareNavBar {
    NSString *title = @"";
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) { // < iOS 7
        title = @"Subregions";
    }
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleBordered target:nil action:nil];
    backButton.tintColor = [UIColor blackColor];
    self.navigationItem.backBarButtonItem = backButton;
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Reset", @"Query", @"Selected Regions"]];
    self.segmentedControl.tag = 3;
    [self.segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.segmentedControl.momentary = YES;
    self.segmentedControl.opaque = TRUE;
    [self.segmentedControl sizeToFit];
    [self.segmentedControl setWidth:110.0 forSegmentAtIndex:2];
    self.segmentedControl.tintColor = [UIColor blackColor];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
        [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    }
    
    UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl];
    self.navigationItem.rightBarButtonItem = segmentBarItem;
    self.segmentedControl.enabled = NO;
}

- (void)filterSubregions {
    if (self.selectedSubRegions.count == 0) {
        return;
    }
    NSArray *sortedSubregionIds = [[NSArray alloc] initWithArray:self.selectedSubRegions];
    sortedSubregionIds = [sortedSubregionIds sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *subregionIds = [[NSMutableString alloc] init];
    for (int i = 0; i < sortedSubregionIds.count; i++) {
        if (i < sortedSubregionIds.count - 1) {
            [subregionIds appendFormat:@"%@, ", [sortedSubregionIds objectAtIndex:i]];
        }
        else {
            [subregionIds appendString:[sortedSubregionIds objectAtIndex:i]];
        }
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Selected Subregions" message:subregionIds delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alert show];
}

- (void)queryAsam:(id)sender {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:[appDelegate persistentStoreCoordinator]];
    
    NSMutableArray *subRegionParams = [NSMutableArray array];
    for (int i = 0; i < self.selectedSubRegions.count; i++) {
        [subRegionParams addObject:[NSPredicate predicateWithFormat:@"geographicalSubregion == %@",[self.selectedSubRegions objectAtIndex:i]]];
    }
    NSString *joinedString = [subRegionParams componentsJoinedByString:@" OR "];
    NSPredicate *subRegionsPredicate = [NSPredicate predicateWithFormat:joinedString];
    NSArray *resultArray = nil;
    if ([sender isEqualToString:@"All"]) {
        resultArray  = [context fetchObjectsForEntityName:@"Asam" withPredicate:subRegionsPredicate];
    }
    else {
        NSString *formattedDays =  [AsamUtility subtractDaysWithParamfromToday:sender];
        NSPredicate *daysPredicate = [NSPredicate predicateWithFormat:@"dateofOccurrence >=%@", [AsamUtility getDateFromString:formattedDays]];
        NSArray *preds = @[daysPredicate, subRegionsPredicate];
        NSPredicate *finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:preds];
        resultArray = [context fetchObjectsForEntityName:@"Asam" withPredicate:finalPredicate];
    }
    
    if (resultArray.count == 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"0 ASAM found" message:@"Try different query." delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];
        [message show];
        return;
    }
    else {
        AsamResultViewController_iphone *asamResultViewController_iphone = [[AsamResultViewController_iphone alloc] initWithNibName:@"AsamResultViewController_iphone" bundle:nil];
        asamResultViewController_iphone.asamArray = resultArray;
        
        [self.navigationController pushViewController:asamResultViewController_iphone animated:YES];
    }
}

- (void)segmentAction:(UISegmentedControl*)sender {
    switch ([sender selectedSegmentIndex]) {
        case 0:
            [self reset];
            break;
            
        case 1:
            [self showActionSheet];
            break;
            
        case 2:
            [self filterSubregions];
            break;
            
        default:
            break;
    }
}

- (void)reset {
    if (self.segmentedControl.enabled == NO) {
        return;
    }
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.selectedSubRegions removeAllObjects];
    self.segmentedControl.enabled = NO;
    [self populateSubregions];
}

- (void)dismissView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma
#pragma mark - Private methods (UIActionSheet) impl.
- (void)showActionSheet {
    if (self.selectedSubRegions.count == 0) {
        return;
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select the number of days to query:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Last 60 days", @"Last 90 days", @"Last 180 days", @"Last 1 Year", @"All", nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        [DSBezelActivityView activityViewForView:self.view withLabel:@"Fetching Asam(s)..." width:160];
        dispatch_async(dispatch_get_main_queue(), ^{
            switch(buttonIndex) {
                case 0:
                    [self queryAsam:@"60"];
                    break;
                    
                case 1:
                    [self queryAsam:@"90"];
                    break;
                    
                case 2:
                    [self queryAsam:@"180"];
                    break;
                    
                case 3:
                    [self queryAsam:@"365"];
                    break;
                    
                case 4:
                    [self queryAsam:@"All"];
                    break;
                    
                default:
                    break;
            }
        });
        dispatch_async(mainQueue, ^{
            [DSBezelActivityView removeViewAnimated:YES];
        });
    });
}

@end
