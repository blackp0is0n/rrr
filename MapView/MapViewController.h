

#import <UIKit/UIKit.h>
#import "RMDateSelectionViewController.h"

@interface MapViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>{
    NSMutableArray *myData;
}
@property (strong, nonatomic) IBOutlet UITableView *myTableView;

@property (strong,nonatomic) NSDate *presentDate;
@property (strong,nonatomic)NSMutableData *receivedData;
@property(nonatomic,strong)NSString *userKey;
@property(nonatomic,strong)NSMutableArray *activeTasksArray;
@property(nonatomic,strong)NSMutableArray *nonActiveTasksArray;
@property(nonatomic,strong)UILabel *noTasksLabel;

-(void)setAnnotationsToDate:(NSDate*)date;
-(void)updateSections;
-(void)createTasksConnection:(NSString*)date key:(NSString*)key;
@end