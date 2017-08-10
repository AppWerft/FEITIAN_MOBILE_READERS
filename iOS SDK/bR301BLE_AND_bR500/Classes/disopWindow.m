//
//  disopWindow.m
//  call_lib
//
//  Created by test on 3/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "disopWindow.h"

#import "ft301u.h"


enum{
    dropListViewForSelected = 101,
    dropListViewForRun = 102,
    alertViewForConpany = 1001,
    tableViewForListDevice = 1002,
};

int touchInDropCount = 0;

#define CONSOLE_MAX_CHARACTER_COUNT 10000
#define LOGVIEW_MAX_CHARACTER_COUNT 10000

@implementation disopWindow

@synthesize powerOn;
@synthesize powerOff;
@synthesize sendCommand;
@synthesize runCommand;
@synthesize listData;
@synthesize showInfoData;


#pragma mark system

-(IBAction) backgroundClick:(id)sender
{
	[commandText resignFirstResponder];
}

- (IBAction)textFieldDone:(id)sender{
	[sender resignFirstResponder];
}


-(void) initFun
{
    [DeviceType setDeviceType:BR301BLE_AND_BR500];
    if (showInfoView != nil) {
        [self showInfoViewButtonPressed];
    }
    listData = [[NSArray alloc]initWithObjects:@"0084000004",@"0084000008",nil];

    //initialization
    NSString* text = [NSString string];
    text = NSLocalizedString(@"POWER_ON", nil);
    [powerOn setTitle:text forState:UIControlStateNormal];
    
    text = NSLocalizedString(@"POWER_OFF", nil);
    [powerOff setTitle:text forState:UIControlStateNormal];
    

     ATR_Label.text = NSLocalizedString(@"ATR_LABEL", nil);
    APDU_Label.text = NSLocalizedString(@"APDU", nil);

    
    text = NSLocalizedString(@"SEND_COMMAND", nil);
    [self.sendCommand setTitle:text forState:UIControlStateNormal];
    
    text = NSLocalizedString(@"RUN_COMMAND", nil);
    [self.runCommand setTitle:text forState:UIControlStateNormal];
    
    powerOn.enabled = YES;
    [powerOn setBackgroundImage:[UIImage imageNamed:@"ON.png"] forState:UIControlStateNormal];
    powerOff.enabled = NO;
    [powerOff setBackgroundImage:[UIImage imageNamed:@"OFF.png"] forState:UIControlStateNormal];
    sendCommand.enabled = NO;
    [sendCommand setBackgroundImage:[UIImage imageNamed:@"SEND_OFF.png"] forState:UIControlStateNormal];
    
    runCommand.enabled = NO;
    commandText.enabled = NO;
    dropList.enabled = NO;
    
    //drop list 
    [dropList setBackgroundImage:[UIImage imageNamed:@"DROPLIST_OFF.png"] forState:UIControlStateNormal];
    commandText.text = @"";
    
    text = NSLocalizedString(@"DIS_REV_INFO", nil);
    [self.runCommand setTitle:text forState:UIControlStateNormal];
    disTextView.text = text;
}

-(void) disAccDig
{

    self.view.backgroundColor = [UIColor clearColor];
    NSString* imageName = NSLocalizedString(@"BACK_BACKGROUND", nil);
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:imageName]];
   
    [dropList setHidden:NO];
    [infoBut setHidden:NO];
    [sendCommand setHidden:NO];

    [powerOn setHidden:NO];
    [powerOff setHidden:NO];

    [cardState setHidden:NO];
    
    [cardState setHidden:NO];
    
    [commandText setHidden:NO];
    [ATR_Label setHidden:NO];
    [disTextView setHidden:NO];
    
    [APDU_Label setHidden:NO];
    [disResp setHidden:NO];
    [apduInput setHidden:NO];
   
}
//Create seed file in sandbox
-(void)createFileSaveSeedBuffer
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docmentDirectory = [directoryPaths objectAtIndex:0];
    NSString *seedFilePath = [docmentDirectory stringByAppendingPathComponent:@"seed.txt"];
    NSString *flashFilePath = [docmentDirectory stringByAppendingPathComponent:@"flash.txt"];
    //Create file
    if (![fileManager fileExistsAtPath:seedFilePath] ) {
        [fileManager createFileAtPath:seedFilePath contents:nil attributes:nil];
    }
    //create flash data
    if (![fileManager fileExistsAtPath:flashFilePath]) {
        [fileManager createFileAtPath:flashFilePath contents:nil attributes:nil];
    }
}

//Get data from file
-(NSData *)readFileContent:(NSString *)fileName
{
    NSData* fileData = nil;
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docmentDirectory = [directoryPaths objectAtIndex:0];
    NSString *filePath = [docmentDirectory stringByAppendingPathComponent:fileName];
    
    fileData = [[NSData alloc] initWithContentsOfFile:filePath];
//    [NSData dataWithContentsOfFile:filePath];
    return fileData;
    
}
#pragma mark -
#pragma mark ReaderInterfaceDelegate Methods
BOOL cardIsAttached=FALSE;
/*Update UI**/
-(void)changeCardState
{
    [cardState setOn:cardIsAttached];
    if (cardIsAttached == FALSE) {
        //After card removed, power off and clear text view
        disTextView.text = @"";
    }
    
}

- (void) cardInterfaceDidDetach:(BOOL)attached
{
    cardIsAttached = attached;
    //Get card slot status, and update UI
    [self performSelectorOnMainThread:@selector(changeCardState) withObject:nil waitUntilDone:YES];
    
}

- (void) readerInterfaceDidChange:(BOOL)attached
{
    NSLog(@"%@ %d",NSStringFromSelector(_cmd),attached);
    
    //Update UI
    if (attached) {
        [self performSelectorOnMainThread:@selector(disAccDig) withObject:nil waitUntilDone:YES];
    }
    else{
        [_listDeviceButton setTitle:@"Select Device" forState:UIControlStateNormal];
        [self performSelectorOnMainThread:@selector(disPowerOff) withObject:nil waitUntilDone:YES];
    }
    
}

 #pragma mark -

- (void )viewDidUnLoad{
    
    
}
SCARDCONTEXT gContxtHandle;
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {

    //1. init UI
//    [self redirectSTD:STDOUT_FILENO];
//    [self redirectSTD:STDERR_FILENO];
    disTextView.backgroundColor = [UIColor lightGrayColor];
    disTextView.font = [UIFont fontWithName:@"Arial" size:12];
    
    showInfoView = nil;
    [self initFun];
    [self disAccDig];
    [self createFileSaveSeedBuffer];

    
    _readInf = [[ReaderInterface alloc]init];
    [_readInf setDelegate:self];
    
    [cardState setEnabled:false];
     SCardEstablishContext(SCARD_SCOPE_SYSTEM,NULL,NULL,&gContxtHandle);
    [super viewDidLoad];
}


#pragma mark - display Reader and SDK version
-(void) show_iR301_Info
{
    char firmwareRevision[32]={0};
    char hardwareRevision[32]={0};
    char libVersion[32]={0};
    long returnValue = 0;

    NSString *title= NSLocalizedString(@"DEVI_INFOR", nil);
    NSString *company =  NSLocalizedString(@"FACT_INFOR", nil);
    NSString *softversion= NSLocalizedString(@"SOFT_VER", nil);
    FtGetLibVersion(libVersion);
    NSString *SDKVersion =[NSString stringWithFormat:@"%@%s",NSLocalizedString(@"SDK_VER", nil),libVersion];
    NSString *fix  = [NSString string];
    returnValue = FtGetDevVer(0,firmwareRevision, hardwareRevision);
    if (returnValue == SCARD_S_SUCCESS) {
       fix =[NSString stringWithFormat:@"%@%s",NSLocalizedString(@"FIX_VER", nil),firmwareRevision];
    }else{
        fix = @"";
    }
   
    
    showInfoData = [[NSArray alloc] initWithObjects:title,@"",company,softversion,SDKVersion,fix,nil];
    
    
}

#pragma mark - Display INFO
-(IBAction) showInfo
{
    clearView =[[UIView alloc] init];
    clearView.frame = self.view.bounds;
    clearView.backgroundColor = [UIColor grayColor];
    clearView.alpha = 0.5;
    
    showInfoView = [[UIView alloc] init];
    showInfoView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"op_bg_detail_en.png"]];
    CGRect frame = CGRectMake(40, 70.0f, self.view.frame.size.width-80, self.view.frame.size.height-140);
    showInfoView.frame = frame;
    showInfoView.layer.masksToBounds = YES;
    showInfoView.layer.cornerRadius = 6.0;
    showInfoView.layer.borderWidth = 1.0;
    showInfoView.layer.borderColor = [[UIColor whiteColor] CGColor];
    
    frame = CGRectMake(20.0f, 40.0f, showInfoView.frame.size.width-40, showInfoView.frame.size.height-80);
    [self show_iR301_Info];
    UITableView *selectFileList = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] ;
    selectFileList.tag = alertViewForConpany;
    [selectFileList setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    selectFileList.backgroundColor = [UIColor clearColor];
    selectFileList.allowsSelection = NO;
    [selectFileList setDelegate:self];
    [selectFileList setDataSource:self];
    [showInfoView addSubview:selectFileList];
    
    UIButton *showInfoDoButton = [ UIButton buttonWithType:UIButtonTypeRoundedRect];
    showInfoDoButton.frame = CGRectMake(20.0f, selectFileList.frame.size.height+20,selectFileList.frame.size.width, 30.0f);
    [showInfoDoButton setTitle:@"OK" forState:UIControlStateNormal];

    showInfoDoButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"OK.png"]];
    showInfoDoButton.contentMode = UIViewContentModeScaleToFill;
    showInfoDoButton.alpha = 0.8;
    [showInfoDoButton.titleLabel setTextColor:[UIColor blackColor]];
    showInfoDoButton.layer.cornerRadius = 6;
    [showInfoDoButton addTarget:self action:@selector(showInfoViewButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [showInfoView addSubview:showInfoDoButton];
    [self.view addSubview:clearView];
    [self.view addSubview:showInfoView];
    
}

#pragma mark - relase button
-(void)showInfoViewButtonPressed
{
    [showInfoView removeFromSuperview];
    [clearView removeFromSuperview];
    showInfoView  = nil;
    clearView  = nil;
    showInfoView=nil;
    clearView = nil;
}


-(IBAction)limitCharacter:(id)sender
{
	const char *buf = [[commandText text] UTF8String];
    NSString* AlertWarning = NSLocalizedString(@"AlertWarning", nil);
    NSString *AlertMessage = NSLocalizedString(@"AlertMessage", nil);
    NSString *AlertOK = NSLocalizedString(@"AlertOK", nil);
	for (int i = 0; i < [commandText.text length]; i++) 
	{		
		if ((buf[i] > 0x46 || buf[i] < 0x30) || buf[i] == 0x40) {
			UIAlertView *WaringStr = [[UIAlertView alloc] initWithTitle:AlertWarning
																message:AlertMessage 
															   delegate:nil 
													  cancelButtonTitle:AlertOK
													  otherButtonTitles:nil];
			[WaringStr show];
			break;
		}
	}
}

#pragma mark - Scan bluetooth device, get list
-(NSMutableArray *)listDeviceList:(id)sender
{
    LONG iRet = 0;
    char mszReaders[128] = "";
    DWORD pcchReaders = -1;
    
    iRet = SCardListReaders(gContxtHandle, NULL, mszReaders, &pcchReaders);
    if(iRet != SCARD_S_SUCCESS)
    {
        NSLog(@"SCardListReaders error %08x",iRet);
        return nil;
    }
    
    DWORD index = 0;
    NSMutableArray *deviceListArray = [[NSMutableArray alloc] init];
    for (int i = 0; i< pcchReaders; i++) {
        
        if (i == 0) {
            [deviceListArray addObject:[NSString stringWithFormat:@"%s",(char*)&mszReaders[0]]];
            i += strlen((char*)&mszReaders[0]);
            continue;
        }
        
        for (int j = index; j < pcchReaders; j++) {
            if (mszReaders[j] == '\0') {
                [deviceListArray addObject:[NSString stringWithFormat:@"%s",(char*)&mszReaders[j+1]]];
                index = j+1;
                i += (int)strlen((char*)&mszReaders[j+1]);
                break;
            }
        }
        
    }
    
    NSLog(@"device list %@",[deviceListArray description]);
    return deviceListArray;
}

#pragma mark - Power ON

-(IBAction) powerOnFun:(id)sender
{
    disTextView.text = @"";
	LONG iRet = 0;
    DWORD dwActiveProtocol = -1;
   char mszReaders[128] = "";
//    DWORD dwReaders = -1;
//    iRet = SCardListReaders(gContxtHandle, NULL, mszReaders, &dwReaders);
//    if(iRet != SCARD_S_SUCCESS)
//    {
//        NSLog(@"SCardListReaders error %08x",iRet);
//        return;
//    }
    if ([_currentDeviceName length] != 0) {
        memcpy(mszReaders, _currentDeviceName.UTF8String, _currentDeviceName.length);
    }
    iRet = SCardConnect(gContxtHandle,mszReaders,SCARD_SHARE_SHARED,SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1,&gCardHandle,&dwActiveProtocol);
	if (iRet != 0) {
        
        ATR_Label.text = NSLocalizedString(@"ATR_LABEL", nil);

        disTextView.text = NSLocalizedString(@"SEND_LABEL", nil);
        NSString* disText = disTextView.text;
        
        disText =NSLocalizedString(@"CONN_LABEL_NO", nil);
        disTextView.text = disText;
        
        powerOn.enabled = YES;

	}
	else {
        unsigned char patr[33];
        DWORD len = sizeof(patr);
        iRet = SCardGetAttrib(gCardHandle,NULL, patr, &len);
        if(iRet != SCARD_S_SUCCESS)
        {
            NSLog(@"SCardGetAttrib error %08x",iRet);
        }
        
		NSMutableData *tmpData = [NSMutableData data];
        [tmpData appendBytes:patr length:len];
        
        NSString* dataString= [NSString stringWithFormat:@"%@",tmpData];
        NSRange begin = [dataString rangeOfString:@"<"];
        NSRange end = [dataString rangeOfString:@">"];
        NSRange range = NSMakeRange(begin.location + begin.length, end.location- begin.location - 1);
        dataString = [dataString substringWithRange:range];

        ATR_Label.text = [NSString stringWithFormat:@"ATR:%@",dataString];
        disTextView.text = [NSLocalizedString(@"SEND_LABEL", nil) stringByAppendingString:@"\n"];
    
        DWORD pcchReaderLen;
        DWORD pdwState;
        DWORD pdwProtocol;
        len = sizeof(patr);
        pcchReaderLen = sizeof(mszReaders);
     
        iRet =  SCardStatus(gCardHandle,mszReaders,&pcchReaderLen,&pdwState,&pdwProtocol,patr,&len);
        if(iRet != SCARD_S_SUCCESS)
        {
            NSLog(@"SCardStatus error %08x",iRet);
        }

        NSString* disText = disTextView.text;
        disText = [[disText stringByAppendingString:NSLocalizedString(@"CONN_LABEL_OK", nil)]stringByAppendingString:@"\n"];
        disTextView.text = disText;

        powerOn.enabled = NO;
        [powerOn setBackgroundImage:[UIImage imageNamed:@"OFF.png"] forState:UIControlStateNormal];
        
        self.powerOff.enabled = YES;
        [powerOff setBackgroundImage:[UIImage imageNamed:@"ON.png"] forState:UIControlStateNormal];
        
        //active command
        powerOff.enabled = YES;
        [powerOff setBackgroundImage:[UIImage imageNamed:@"ON.png"] forState:UIControlStateNormal];
        sendCommand.enabled =YES;
        [sendCommand setBackgroundImage:[UIImage imageNamed:@"SEND_ON.png"] forState:UIControlStateNormal];
        runCommand.enabled = YES;
        commandText.enabled = YES;
        dropList.enabled = YES;
        [dropList setBackgroundImage:[UIImage imageNamed:@"DROPLIST_ON.png"] forState:UIControlStateNormal];
        [dropList setTitle:@"" forState:nil];
    }
    
}

#pragma mark - Send APDU
-(IBAction) sendCommandFun:(id)sender
{
    
	LONG iRet = 0;
	unsigned  int capdulen;
	unsigned char capdu[512];
	unsigned char resp[512];
	unsigned int resplen = sizeof(resp) ;

	NSString* tempBuf = [NSString string];
    
    if(powerOn.enabled == YES) 
        return;
  
    if(([commandText.text length] == 0 )  && [sender isKindOfClass:[UIButton class]] )
    {   
        NSString* disText = disTextView.text;
        disText = [[disText stringByAppendingString:NSLocalizedString(@"SEND_APDU", nil)]stringByAppendingString:@"\n"];
        disTextView.text = disText;
              
        disText = disTextView.text;
        disText = [[disText stringByAppendingString:NSLocalizedString(@"REC_APDU", nil)]stringByAppendingString:@"\n"];
        disTextView.text = disText;
        [self moveToDown];
        
        return;
    }
    else
    {
        if([commandText.text length] < 5 )
        {
            disTextView.text = @"Invalid APDU.";
            return;
        }
    }

    
    if([sender isKindOfClass:[NSString class]])
    {
        tempBuf = (NSString*) sender;
    }else
    {
        tempBuf = [commandText text];
    }
    NSString* comand = [tempBuf stringByAppendingString:@"\n"];
    const char *buf = [tempBuf UTF8String];
	NSMutableData *data = [NSMutableData data];
	uint32_t len = strlen(buf);
	
    //to hex
	char singleNumberString[3] = {'\0', '\0', '\0'};
	uint32_t singleNumber = 0;
	for(uint32_t i = 0 ; i < len; i+=2)
	{
		if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1])) )
		{
			singleNumberString[0] = buf[i];
			singleNumberString[1] = buf[i + 1];
			sscanf(singleNumberString, "%x", &singleNumber);
			uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
			[data appendBytes:(void *)(&tmp) length:1];
		}
		else
		{
			break;
		}
	}
     for (int kkk=0; kkk<1; kkk++) {
	[data getBytes:capdu];
    resplen = sizeof(resp);
	capdulen = [data length];
    SCARD_IO_REQUEST pioSendPci;
    iRet=SCardTransmit(gCardHandle,&pioSendPci, (unsigned char*)capdu, capdulen,NULL,resp, &resplen);
	if (iRet != 0) {
        
		NSLog(@"ERROR SCardTransmit ret %08X.", iRet);
		NSMutableData *tmpData = [NSMutableData data];
		[tmpData appendBytes:resp length:capdulen*2];
        if(powerOn.enabled == NO){ 

            NSString* sending = NSLocalizedString(@"SEND_DATA", nil);
            NSString* sendComand = [NSString stringWithFormat:
                                    @"%@：%@",sending,comand];
            NSString* disText = disTextView.text;
            disText = [disText stringByAppendingString:sendComand];
            
            NSString* returnData = NSLocalizedString(@"RETURN_DATA", nil);
            NSString* errMSG = [NSString stringWithFormat:
                                    @"%@：%08X",@"ERROR SCardTransmit ret ",iRet];
            
            returnData = [returnData stringByAppendingString:errMSG];
            returnData = [returnData stringByAppendingString:@"\n"];
            disText = [disText stringByAppendingString:returnData];
            disTextView.text = disText;
            [self moveToDown];
            
            disText = disTextView.text;
            disTextView.text = disText;
        }

		sendCommand.enabled = YES;
	}
	else {         

		NSMutableData *tmpData = [NSMutableData data];
		[tmpData appendBytes:capdu length:capdulen*2];
        
        NSString* sending = NSLocalizedString(@"SEND_DATA", nil);
        NSString* sendComand = [NSString stringWithFormat:
                                @"%@：%@",sending,comand];
        NSString* disText = disTextView.text;
        disText = [disText stringByAppendingString:sendComand];
        disTextView.text = disText;
         
        NSMutableData *RevData = [NSMutableData data];
        [RevData appendBytes:resp length:resplen];
        
        NSString* recData = [NSString stringWithFormat:@"%@", RevData];
        NSRange begin = [recData rangeOfString:@"<"];
        NSRange end = [recData rangeOfString:@">"];
        NSRange start = NSMakeRange(begin.location + begin.length, end.location - begin.location-1);
        recData = [recData substringWithRange:start];
        recData = [recData stringByAppendingString:@"\n"];
        
        NSString* returnData = NSLocalizedString(@"RETURN_DATA", nil);
        
        recData = [NSString stringWithFormat:@"%@：%@",returnData,recData];
        disText = disTextView.text;
        disText = [disText stringByAppendingString:recData];
        disTextView.text = disText;
        [self moveToDown];

		sendCommand.enabled = YES;
	}
          }
   
    [self moveToDown];
     
       
}
#pragma mark  - Power OFF
-(void) disPowerOff
{

    ATR_Label.text =  NSLocalizedString(@"ATR_LABEL", nil);
    disTextView.text = [NSLocalizedString(@"SEND_LABEL_CLOSE", nil) stringByAppendingString:@"\n"];
    disTextView.text = [disTextView.text stringByAppendingString:NSLocalizedString(@"CLOSE_CONN_OK", nil)];
    
    self.powerOn.enabled = YES;
    [self.powerOn setBackgroundImage: [UIImage imageNamed:@"ON.png"] forState:UIControlStateNormal];
    
    powerOff.enabled = NO;
    [self.powerOff setBackgroundImage: [UIImage imageNamed:@"OFF.png"] forState:UIControlStateNormal];
    sendCommand.enabled = NO;
    [sendCommand setBackgroundImage:[UIImage imageNamed:@"SEND_OFF.png"] forState:UIControlStateNormal];

    commandText.enabled = NO;
    commandText.text = @"";
    runCommand.enabled = NO;
    dropList.enabled = NO;
    [dropList setBackgroundImage:[UIImage imageNamed:@"DROPLIST_OFF.png"] forState:UIControlStateNormal];
}

#pragma mark - Power OFF
-(IBAction) powerOffFun:(id)sender
{
    disTextView.text = @"";
	LONG iRet = 0;
    iRet = SCardDisconnect(gCardHandle,SCARD_UNPOWER_CARD);
	if (iRet != 0) {
		disTextView.text = [NSString stringWithFormat:@"ERROR PowerOff ret %d.\n", iRet];
		powerOff.enabled = YES;
		powerOn.enabled = YES;
	}
	else 
    {
        [self disPowerOff];
	}
}

-(void) moveToDown{
    NSRange range;
    range = NSMakeRange ([[disTextView text]length], 0);
    [disTextView scrollRangeToVisible: range];
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


#pragma mark - drop list
-(IBAction)runBtnPressed:(id)sender
{    
    touchInDropCount++;
    if(touchInDropCount%2)
    {
        if([self.view viewWithTag:dropListViewForRun])
        {
            ((UITableView*)[self.view viewWithTag:dropListViewForRun]).hidden = NO;
        }
        else
        {
            UITableView* listView;
            CGRect fr = runCommand.frame;             
            listView=[[UITableView alloc]initWithFrame:
                      CGRectMake(10,188 + fr.size.height ,300,78)];
            listView.dataSource = self;
            
            listView.delegate=self;
            
            listView.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:listView];
            listView.tag = dropListViewForRun; 
        
        }
    }
    else
    {
        ((UITableView*)[self.view viewWithTag:dropListViewForRun]).hidden = YES;
        
    }
        
}

#pragma mark- UITableViewDataSource Methods
-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
    {
        static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:
                                 SimpleTableIdentifier];
        if (cell == nil) {  
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier: SimpleTableIdentifier];
        }
        if (tableView.tag == alertViewForConpany) {
            cell.backgroundColor = [UIColor clearColor];
            if (indexPath.row == 0) {
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
            }
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
            cell.textLabel.text = [showInfoData objectAtIndex:indexPath.row];
            
        }else if(tableView.tag == tableViewForListDevice){
            cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:7];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.text = [_gdeviceListArray objectAtIndex:indexPath.row];
        }else{
            cell.textLabel.text = [listData objectAtIndex:indexPath.row];
        }

        return cell;
    }
// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == alertViewForConpany) {
        return showInfoData.count;
    }else if(tableView.tag == tableViewForListDevice){
        
        return [_gdeviceListArray count];
        
    }else{
        return listData.count;
    }
}
#pragma mark- UITableViewDelegate Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.tag == alertViewForConpany) {
        return 25;
    }else if (tableView.tag == tableViewForListDevice){
        
        return 25;
        
    }else{
        return 35;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == alertViewForConpany) {
        return;
    }
    
    if (tableView.tag == tableViewForListDevice) {
//        _listDeviceTextFeild.text = [_gdeviceListArray objectAtIndex:indexPath.row];
        _currentDeviceName = [_gdeviceListArray objectAtIndex:indexPath.row];
        [_listDeviceButton setTitle:_currentDeviceName forState:UIControlStateNormal];
        
        tableView.hidden = YES;
//         ((UITableView*)[self.view viewWithTag:dropListViewForRun]).hidden = YES;
        return;
    }
    touchInDropCount++;
    if(dropListViewForRun == tableView.tag)
    {
        runCommand.enabled = YES;
        tableView.hidden = YES;
        NSString* command = [listData objectAtIndex:indexPath.row];
        commandText.text = command;
        [self sendCommandFun:command];
    }
    else if(dropListViewForSelected == tableView.tag)
    {
        dropList.enabled = YES;
        commandText.text = [listData objectAtIndex:indexPath.row];
        tableView.hidden = YES;
    }
    
}

#pragma mark - Write UID
-(IBAction)writeUID:(id)sender
{

    NSData *fileData = [self readFileContent:@"seed.txt"];
    if ([fileData length] == 0) {
        disTextView.text = @"seed is nil.";
        return;
    }
    
    unsigned char seedBuffer[64] = {0};
    unsigned int seedLength = 0;
    [fileData getBytes:seedBuffer length:fileData.length];
    seedLength =(unsigned int)fileData.length;
    
    LONG iRet = FtGenerateDeviceUID(gContxtHandle,seedLength,seedBuffer);
    if(iRet != 0 ){
        disTextView.text = @"writeUID ERROR.";
    }else {
        disTextView.text = @"writeUID Successful.";
    }
}

#pragma mark - Read UID
-(IBAction)readUID:(id)sender
{
    char buffer[20] = {0};
    unsigned int length = sizeof(buffer);
    LONG iRet = FtGetDeviceUID(gContxtHandle,&length, buffer);
    if(iRet != 0 ){
        disTextView.text = @"readUID ERROR.";
    }else {
        NSData *temp = [NSData dataWithBytes:buffer length:length];
        disTextView.text = [NSString stringWithFormat:@"%@\n", temp];
    }
}

#pragma mark - Erase UID
-(IBAction)eraseUID:(id)sender
{
    NSData *fileData = [self readFileContent:@"seed.txt"];
    if ([fileData length] == 0) {
        disTextView.text = @"seed is nil.";
        return;
    }
    
    unsigned char seedBuffer[64] = {0};
    unsigned int seedLength = 0;
    [fileData getBytes:seedBuffer length:fileData.length];
    seedLength =(unsigned int)fileData.length;
    
    LONG iRet = 0;//FtEscapeDeviceUID(gContxtHandle,seedLength,seedBuffer);
    if(iRet != 0 ){
        disTextView.text = @"eraseUID ERROR.";
    }else {
        disTextView.text = @"eraseUID Successful.";
    }
}

#pragma mark - Read flash
-(IBAction)readFlash:(id)sender
{
    unsigned char buffer[1000] = {0};
    unsigned int length = 30;
    LONG iRet = FtReadFlash(gContxtHandle,0,length, buffer);
    if(iRet != 0 ){
        disTextView.text = @"readFlash ERROR.";
    }else {
        NSData *temp = [NSData dataWithBytes:buffer length:length];
        disTextView.text = [NSString stringWithFormat:@"%@\n", temp];
    }
}

#pragma mark - Write flash
-(IBAction)writeFlash:(id)sender
{
//    NSData *fileData = [self readFileContent:@"flash.txt"];
//    if ([fileData length] == 0) {
//        disTextView.text = @"flash data is nil.";
//        return;
//    }
//    
//    unsigned char buffer[1024] = {0};
//    unsigned int length = 0;
//    
//    [fileData getBytes:buffer length:fileData.length];
//    length = (unsigned int)fileData.length;
//    
//    LONG iRet = FtWriteFlash(gContxtHandle,0,length, buffer);
    LONG iRet = 0 ;
    static BOOL w_flag = FALSE;
    unsigned char buffer[255] ={0};
    w_flag = !w_flag;
    if (w_flag) {
        for (int i=0; i< 255; i++) {
            buffer[i]= i;
        }
        iRet = FtWriteFlash(0, 0 ,255, buffer);
    }
    else {
        iRet = FtWriteFlash(0, 0,20, buffer);
    }
    
    if(iRet != 0 ){
        disTextView.text = @"writeFlash ERROR.";
    }else {
        disTextView.text = @"writeFlash Successful.";
    }
}

#pragma mark - get card slot status
-(IBAction) testSCardStatus:(id)sender
{
    
    DWORD dwState;
    LONG rv = 0;
    rv = SCardStatus(gContxtHandle, NULL, NULL, &dwState, NULL, NULL, NULL );
    if (rv != 0) {       
        disTextView.text = [NSString stringWithFormat:@"SCardStatus return ERROR %4x",rv];
    }
    
    switch (dwState) {
        case SCARD_ABSENT:
             disTextView.text = @"The card has absent.";
            break;
        case SCARD_PRESENT:
            disTextView.text = @"The card has present.";
            break;
        case SCARD_SWALLOWED:
            disTextView.text = @"The Card not powered.";
            break;
            
        default:
            break;
    }
}

#pragma mark - Get serial number
-(IBAction)getSerialNumber:(id)sender
{
   char buffer[20] = {0};
    unsigned int length = sizeof(buffer);
    LONG iRet = 0;//FtGetDeviceHID(gContxtHandle,&length, buffer);
    if(iRet != 0 ){
        disTextView.text = @"Get device HID ERROR.";
    }else {
        NSData *temp = [NSData dataWithBytes:buffer length:length];
        disTextView.text = [NSString stringWithFormat:@"%@\n", temp];
    }
}

-(void)showSelectDeviceListTableView
{
    CGRect frame = CGRectMake(_listDeviceButton.frame.origin.x, _listDeviceButton.frame.origin.y+25.0f, _listDeviceButton.frame.size.width, 100);
    UITableView *deviceList = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain] ;
    deviceList.tag = tableViewForListDevice;
    deviceList.layer.borderWidth = 1.0f;
    deviceList.layer.borderColor = [UIColor blueColor].CGColor;
    [deviceList setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    deviceList.backgroundColor = [UIColor whiteColor];
    [deviceList setDelegate:self];
    [deviceList setDataSource:self];
    [self.view addSubview:deviceList];
}

-(IBAction)listDeviceButtonPressed:(id)sender
{
    _gdeviceListArray =  [self listDeviceList:nil];
    if ([_gdeviceListArray count] != 0) {
        [self showSelectDeviceListTableView];
    }
}

#pragma mark - Import info to textview
- (void)redirectNotificationHandle:(NSNotification *)nf{
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSRange visibleRange;
    
    NSString * _consoleText = disTextView.text;
    _consoleText = [_consoleText stringByAppendingString:str];
    if (_consoleText.length > CONSOLE_MAX_CHARACTER_COUNT) {
        visibleRange.location = _consoleText.length - CONSOLE_MAX_CHARACTER_COUNT;
        visibleRange.length = CONSOLE_MAX_CHARACTER_COUNT;
        _consoleText = [_consoleText substringWithRange:visibleRange];
    }
    [[nf object] readInBackgroundAndNotify];
    disTextView.text = _consoleText;
    visibleRange.location = _consoleText.length - 10;
    visibleRange.length = 10;
    [disTextView scrollRangeToVisible:visibleRange];
    
}

- (void)redirectSTD:(int )fd{
    NSPipe * pipe = [NSPipe pipe] ;
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify];
}



@end

