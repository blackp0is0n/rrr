

#import "MapViewController.h"
#import "SWRevealViewController.h"
#import "DetailTaskController.h"
@implementation MapViewController


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    _activeTasksArray = [[NSMutableArray alloc] init];
    _nonActiveTasksArray = [[NSMutableArray alloc] init];
	[super viewDidLoad];
	_presentDate = [[NSDate alloc] init];
	self.title = NSLocalizedString(@"Tasks", nil);
    
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
        style:UIBarButtonItemStyleDone target:revealController action:@selector(revealToggle:)];
    self.navigationItem.leftBarButtonItem = revealButtonItem;

    
    
    UIBarButtonItem * topRightButton = [[UIBarButtonItem alloc] initWithTitle:@"Date" style:UIBarButtonItemStyleDone target:self action:@selector(rightButtonPressed:)];
    self.navigationItem.rightBarButtonItem = topRightButton;
    
    NSDateFormatter *titleFormat = [[NSDateFormatter alloc] init];
    [titleFormat setDateFormat:@"d MMMM, yyyy"];
    NSString *titleDate = [titleFormat stringFromDate:_presentDate];
    [self setAnnotationsToDate:_presentDate];
    
    self.title = NSLocalizedString(titleDate, nil);
    
    if (self.noTasksLabel == nil){
        self.noTasksLabel = [[UILabel alloc] init];
        [self.noTasksLabel setText:@"No tasks for this Day"];
        [self.noTasksLabel setTextColor:[UIColor grayColor]];
        self.noTasksLabel.frame = CGRectMake(self.view.frame.size.width/2-80, 70.0f, 160.0f, 30.0f);
        [self.view addSubview:self.noTasksLabel];
    }
    [self.noTasksLabel setHidden:NO];
    [self.myTableView setHidden:YES];
}


-(void)createTasksConnection:(NSString*)date key:(NSString*)key{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL
                                                                        URLWithString:@"http://api.logave.com/task/gettask?"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15.0];
    request.HTTPMethod = @"POST";
    NSString * param = [NSString stringWithFormat:@"key=%@&date=%@",key,date];
    request.HTTPBody = [param dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(!connection){
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Connection Error" message:@"Server not available now." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    } else {
        _receivedData = [[NSMutableData data] init];
    }
}


-(void)setUserKey:(NSString *)userKey{
    _userKey = userKey;
}
-(NSString*)getUserKey{
    return _userKey;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Please, check your Internet Connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}



- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (_receivedData!=nil) {
        NSError *e = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:_receivedData options:NSJSONReadingMutableContainers error:&e];
        NSLog(@"%@",json);
        NSLog(@"Key is:%@\nBurn MF",[self getUserKey]);
        NSString *answer = json[@"status_message"];
        [_activeTasksArray removeAllObjects];
        [_nonActiveTasksArray removeAllObjects];
        NSString *task = json[@"data"][@"task"];
        [self setUserKey:json[@"data"][@"key"]];

        if([answer isEqual:@"OK"]){
            [self setUserKey:json[@"data"][@"key"]];
            if (![task isEqual:@"No tasks"]) {
                [self.noTasksLabel setHidden:YES];
                [self.myTableView setHidden:NO];
                for(int i = 0;i<[json[@"data"][@"task"] count];i++){
                    NSString *tID = json[@"data"][@"task"][i][@"id"];
                    NSString *mID = json[@"data"][@"task"][i][@"manager_id"];
                    NSString *courID = json[@"data"][@"task"][i][@"courier_id"];
                    NSString *getName = json[@"data"][@"task"][i][@"name"];
                    NSString *getSName = json[@"data"][@"task"][i][@"sname"];
                    NSString *getPhone = json[@"data"][@"task"][i][@"phone"];
                    NSString *tIsActive = json[@"data"][@"task"][i][@"active"];
                    NSString *address = json[@"data"][@"task"][i][@"address"];
                    NSString *taskDescription = json[@"data"][@"task"][i][@"description"];
                    NSString *taskDate = json[@"data"][@"task"][i][@"date"];
                    Task *myTask = [[Task alloc] init];
                    myTask.taskID = tID;
                    myTask.managerID = mID;
                    myTask.taskDescription = taskDescription;
                    myTask.taskAddress = address;
                    myTask.courierID = courID;
                    myTask.name = getName;
                    myTask.sname = getSName;
                    myTask.phone = getPhone;
                    myTask.key = [self getUserKey];
                    if([tIsActive isEqualToString:@"1"]){
                        myTask.taskIsActive = @"YES";
                    } else {
                        myTask.taskIsActive = @"NO";
                    }
                    myTask.date = taskDate;
                    if ([myTask.taskIsActive isEqualToString:@"YES"]) {
                        [_activeTasksArray addObject:myTask];
                    } else {
                        [_nonActiveTasksArray addObject:myTask];
                    }
                }
            } else {
                [_activeTasksArray removeAllObjects];
                [_nonActiveTasksArray removeAllObjects];
                [self.myTableView setHidden:YES];
                [self.noTasksLabel setHidden:NO];
            }
            [self updateSections];
        }
    }
    
}

-(void) updateSections {
    NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.myTableView]);
    NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.myTableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)setAnnotationsToDate:(NSDate*)date{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *titleFormat = [[NSDateFormatter alloc] init];
    [titleFormat setDateFormat:@"d MMMM, yyyy"];
    NSString *titleDate = [titleFormat stringFromDate:date];
    
    NSString *selectedDate = [format stringFromDate:date];
    self.title = NSLocalizedString(titleDate, nil);
    [self createTasksConnection:selectedDate key:[self getUserKey]];
}

-(void)rightButtonPressed:(id) sender{
    RMDateSelectionViewController *myDatePicker = [RMDateSelectionViewController dateSelectionController];
    [myDatePicker setSelectButtonAction:^(RMDateSelectionViewController *controller, NSDate *date) {
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"d MMMM, yyyy"];
        NSString *selectedDate = [format stringFromDate:date];
        self.title = NSLocalizedString(selectedDate, nil);
        
        NSLog(@"Successfully selected date: %@", date);
        _presentDate  = date;
        [self setAnnotationsToDate:_presentDate];
    }];
    myDatePicker.titleLabel.text = @"Date picker.\n\nPlease choose a date and press 'Select' or 'Cancel'.";
    
    myDatePicker.datePicker.datePickerMode = UIDatePickerModeDate;
    myDatePicker.datePicker.date = _presentDate;
    
    myDatePicker.disableBouncingWhenShowing = true;
    myDatePicker.disableMotionEffects = false;
    myDatePicker.disableBlurEffects = true;
    
    /* [myDatePicker setCancelButtonAction:^(RMDateSelectionViewController *controller) {
     NSLog(@"Date selection was canceled");
     }];*/
    [self presentViewController:myDatePicker animated:YES completion:nil];
}





- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:
(NSInteger)section{
    if(section == 0){
        return _activeTasksArray.count;
    } else {
        return _nonActiveTasksArray.count;
    }
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 55;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:
(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                             cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:
                UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    NSString *stringForCell;
    NSString *detailText;
    UILabel *addFriendButton = [[UILabel alloc] init];
    
    addFriendButton.frame = CGRectMake(150.0f, 5.0f, 130.0f, 30.0f);
    [cell addSubview:addFriendButton];
    if (indexPath.section == 0) {
        Task *myTask= [_activeTasksArray objectAtIndex:indexPath.row];
        NSString *titleForTaskRow = myTask.taskDescription;
        stringForCell = titleForTaskRow;
        [addFriendButton setText:@"Not completed"];
        [addFriendButton setTextColor:[UIColor redColor]];
        detailText = [@"Task id:" stringByAppendingString:myTask.taskID];
    } else if (indexPath.section == 1){
        Task *myTask= [_nonActiveTasksArray objectAtIndex:indexPath.row];
        NSString *titleForTaskRow = myTask.taskDescription;
        stringForCell = titleForTaskRow;
        [addFriendButton setText:@"Completed"];
        [addFriendButton setTextColor:[UIColor greenColor]];
        detailText = [@"Task id:" stringByAppendingString:myTask.taskID];
    }
    

    [cell.textLabel setText:stringForCell];
    [cell.detailTextLabel setTextColor:[UIColor grayColor]];
    [cell.detailTextLabel setText:detailText];
    return cell;
}



// Default is 1 if not implemented
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:
(NSInteger)section{

    return nil;
}

#pragma mark - TableView delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:
(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Section:%ld Row:%ld selected and its data is %@",
          (long)indexPath.section,(long)indexPath.row,cell.textLabel.text);
    DetailTaskController *stubController = [[DetailTaskController alloc] init];
    stubController.controller = self;
    if(indexPath.section == 0){
        stubController.presentTask = [_activeTasksArray objectAtIndex:indexPath.row];
    } else {
        stubController.presentTask = [_nonActiveTasksArray objectAtIndex:indexPath.row];
    }
    stubController.title = @"Task details";
    stubController.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:stubController animated:YES];
}

@end