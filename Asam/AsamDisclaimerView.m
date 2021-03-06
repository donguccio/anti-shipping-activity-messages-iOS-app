#import "AsamDisclaimerView.h"

@interface AsamDisclaimerView()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *exitButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *agreeButton;

- (IBAction)closeAsamApp:(id)sender;
- (IBAction)dismissDisclaimer:(id)sender;

@end

@implementation AsamDisclaimerView

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) { // iOS 7+
        self.exitButton.tintColor = [UIColor whiteColor];
        self.agreeButton.tintColor = [UIColor whiteColor];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return  (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (IBAction)dismissDisclaimer:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closeAsamApp:(id)sender {
    exit(0);
}

@end
