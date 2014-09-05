//
//  RCRequestVC.m
//  RestClient
//
//  Created by Bakuf on 9/3/14.
//  Copyright (c) 2014 Bakuf Soft. All rights reserved.
//

#import "RCRequestVC.h"
#import "BKConnectionManager.h"

@interface RCRequestVC () <BKConnectionManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate>{
    WSMethodType methodType;
    WSApplicationType applicationType;
    BOOL choosingMethod;
    UIButton *invisibleButton;
}

@property (weak, nonatomic) IBOutlet UITextField *txtBaseUrl;
@property (weak, nonatomic) IBOutlet UITextField *txtWebServiceName;

@property (weak, nonatomic) IBOutlet UIButton *btnApplicationType;
@property (weak, nonatomic) IBOutlet UIButton *btnMethodType;
@property (weak, nonatomic) IBOutlet UIButton *btnSendRequest;

@property (weak, nonatomic) IBOutlet UITextView *txtBody;
@property (weak, nonatomic) IBOutlet UITextView *txtRawResponse;
@property (weak, nonatomic) IBOutlet UITextView *txtParsedResponse;

@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) NSArray *dataArray;

@end

@implementation RCRequestVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setButtons];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    // Do any additional setup after loading the view from its nib.
}

- (void)keyboardWillShow:(NSNotification*)notif{
    if (invisibleButton == nil) {
        invisibleButton = [[UIButton alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [invisibleButton addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.view addSubview:invisibleButton];
}

- (void)hideKeyboard{
    for (UIView *view in self.view.subviews) {
        [view resignFirstResponder];
//        if ([view isKindOfClass:[UITextField class]] || [view isKindOfClass:[UITextView class]]) {
//            
//        }
    }
    [invisibleButton removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Buttons Actions

- (void)setButtons{
    [self.btnApplicationType addTarget:self action:@selector(applicationTouched) forControlEvents:UIControlEventTouchUpInside];
    [self.btnMethodType addTarget:self action:@selector(methodTouched) forControlEvents:UIControlEventTouchUpInside];
    [self.btnSendRequest addTarget:self action:@selector(sendRequest) forControlEvents:UIControlEventTouchUpInside];
}

- (void)applicationTouched{
    choosingMethod = NO;
    self.dataArray = @[@"none",
                       @"json",
                       @"x-www-form-urlencoded"];
    [self setPicker:self.dataArray[0]];
}

- (void)methodTouched{
    choosingMethod = YES;
    self.dataArray = @[@"POST",
                       @"GET",
                       @"PUT",
                       @"DELETE"];
    [self setPicker:self.dataArray[0]];
}

- (void)sendRequest{
    self.txtRawResponse.text = @"";
    self.txtParsedResponse.text = @"";
    BKConnectionManager *conn = [[BKConnectionManager alloc] initWithInfo:self.txtBody.text withUrl:self.txtBaseUrl.text inWS:self.txtWebServiceName.text withMethodType:methodType andApplicationType:applicationType delegate:self];
    conn.withHud = YES;
    conn.hudMessage = @"Sending Request";
    [conn sendRequest];
}

#pragma mark BKConnection Delegate Methods

- (void)WSdidGetResponse:(id)response inConnection:(BKConnectionManager *)connection{
    NSString *textResponse = @"";
    if ([response isKindOfClass:[NSDictionary class]]) {
        textResponse= [(NSDictionary*)response description];
    }
    if ([response isKindOfClass:[NSArray class]]) {
        textResponse= [(NSArray*)response description];
    }
    if ([response isKindOfClass:[NSString class]]) {
        textResponse = response;
    }
    
    self.txtRawResponse.text = connection.rawResponseOrErrorDescription;
    self.txtParsedResponse.text = textResponse;
}

- (void)WSdidFailResponseInConnection:(BKConnectionManager *)connection{
    self.txtRawResponse.text = connection.rawResponseOrErrorDescription;
}

#pragma mark ActionSheet and Picker Methods 

- (void)setPicker:(NSString*)previousSelection{
    self.pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 40, 0, 0)];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.backgroundColor = [UIColor whiteColor];
    self.pickerView.showsSelectionIndicator = YES;
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    numberToolbar.barStyle = UIBarStyleBlack;
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancelar" style:UIBarButtonItemStylePlain target:self action:@selector(dismissActionSheet)];
    leftButton.tintColor = [UIColor whiteColor];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]initWithTitle:@"Aceptar" style:UIBarButtonItemStylePlain target:self action:@selector(doneActionSheet)];
    
    numberToolbar.items = [NSArray arrayWithObjects:leftButton,
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],rightButton,nil];
    
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@""
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil];
    
    [self.actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [numberToolbar sizeToFit];
    [self.actionSheet addSubview:self.pickerView];
    [self.actionSheet addSubview:numberToolbar];
    [self.actionSheet showInView:self.view];
    [self.actionSheet setBounds:CGRectMake(0, 0, 320, 420)];
    
    if(previousSelection.length != 0 ){
        NSUInteger index = [self.dataArray indexOfObject:previousSelection];
        if (index != NSNotFound) {
            [self.pickerView selectRow:index inComponent:0 animated:NO];
        }
    }
}

- (void)dismissActionSheet{
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)doneActionSheet{
    int selectedIndex = [self.pickerView selectedRowInComponent:0];
    if (choosingMethod) {
        [self.btnMethodType setTitle:self.dataArray[selectedIndex] forState:UIControlStateNormal];
        methodType = selectedIndex;
    }else{
        [self.btnApplicationType setTitle:self.dataArray[selectedIndex] forState:UIControlStateNormal];
        applicationType = selectedIndex;
    }
    [self dismissActionSheet];
}

#pragma mark - Picker View Delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dataArray.count;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] init];
    CGRect frame = CGRectMake(0,0,265,70);
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = self.dataArray[row];
    label.frame = frame;
    
    return label;
}

@end
