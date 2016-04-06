//
//  BDVRViewController.m
//  BDVRClientSample
//
//  Created by Baidu on 13-9-24.
//  Copyright (c) 2013年 Baidu. All rights reserved.
//

#import "BDVRViewController.h"
#import "BDVoiceRecognitionClient.h"
#import "BDVRSettingViewController.h"
#import "BDVRSConfig.h"
#import "BDVRCustomRecognitonViewController.h"
#import "BDVRUIPromptTextCustom.h"

#import "MyViewController.h"
//#error 请修改为您在百度开发者平台申请的API_KEY和SECRET_KEY
#define API_KEY @"f3frh9kQcz8zNdRYGViYveri" // 请修改为您在百度开发者平台申请的API_KEY
#define SECRET_KEY @"jSF3herra8qtYYAZoYGO86Io019DqdcY" // 请修改您在百度开发者平台申请的SECRET_KEY

//#error 请修改为您在百度开发者平台申请的APP ID
#define APPID @"7119968" // 请修改为您在百度开发者平台申请的APP ID
@interface BDVRViewController ()
{
    CALayer *_layer;
    CAAnimationGroup *_animaTionGroup;
    CADisplayLink *_disPlayLink;
    
}

@end

@implementation BDVRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return NO;
}



#pragma mark - Button Action

- (void)setButtonUnenabledWithType:(int)type
{
	settingButton.enabled = NO;
	voiceRecognitionButton.enabled = NO;
    voiceRecognitionSDKUIButton.enabled = NO;
	
	switch (type)
	{
		case EDemoButtonTypeSetting:
		{
			settingButton.enabled = YES;
			break;
		}
		case EDemoButtonTypeVoiceRecognition:
		{
			voiceRecognitionButton.enabled = YES;
			break;
		}
        case EDemoButtonTypeSDKUI:
		{
			voiceRecognitionSDKUIButton.enabled = YES;
			break;
		}
		default:
			break;
	}
	
}

- (void)setAllButtonEnabled
{
	settingButton.enabled = YES;
	voiceRecognitionButton.enabled = YES;
}
/*
- (IBAction)settingAction
{
    // 进入设置界面，配置相应的功能开关
	BDVRSettingViewController *tmpVRSettingViewController = [[BDVRSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *tmpNavController = [[UINavigationController alloc] initWithRootViewController:tmpVRSettingViewController];
	[self presentViewController:tmpNavController animated:YES completion:nil];
}
*/

#pragma mark ---------------------------- 识别UI -----------------------------
- (IBAction)sdkUIRecognitionAction
{
    [self clean]; // 清楚log和result相关view
    BDTheme *theme = [BDTheme lightGreenTheme];
    // 创建识别控件
    BDRecognizerViewController *tmpRecognizerViewController = [[BDRecognizerViewController alloc] initWithOrigin:CGPointMake(9, 64) withTheme:theme];
    
    tmpRecognizerViewController.enableFullScreenMode = YES;
    
    // 全屏UI
//    if ([[BDVRSConfig sharedInstance].theme.name isEqualToString:@"全屏亮蓝"]) {
//        tmpRecognizerViewController.enableFullScreenMode = YES;
//    }
    
    tmpRecognizerViewController.delegate = self;
    self.recognizerViewController = tmpRecognizerViewController;
    
    // 设置识别参数
    BDRecognizerViewParamsObject *paramsObject = [[BDRecognizerViewParamsObject alloc] init];
    
    // 开发者信息，必须修改API_KEY和SECRET_KEY为在百度开发者平台申请得到的值，否则示例不能工作
    paramsObject.apiKey = API_KEY;
    paramsObject.secretKey = SECRET_KEY;
    
    // 设置是否需要语义理解，只在搜索模式有效
    paramsObject.isNeedNLU = [BDVRSConfig sharedInstance].isNeedNLU;
    
    // 设置识别语言
    paramsObject.language = [BDVRSConfig sharedInstance].recognitionLanguage;
    
    // 设置识别模式，分为搜索和输入
    paramsObject.recogPropList = @[[BDVRSConfig sharedInstance].recognitionProperty];
    
    // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
    paramsObject.cityID = 1;
    
    // 开启联系人识别
    paramsObject.enableContacts = YES;
    
    // 设置显示效果，是否开启连续上屏
    if ([BDVRSConfig sharedInstance].resultContinuousShow)
    {
        paramsObject.resultShowMode = BDRecognizerResultShowModeWholeShow;
    }
    else
    {
        paramsObject.resultShowMode = BDRecognizerResultShowModeWholeShow;
    }
    
    // 设置提示音开关，是否打开，默认打开
    if ([BDVRSConfig sharedInstance].uiHintMusicSwitch)
    {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordPlay;
    }
    else
    {
        paramsObject.recordPlayTones = EBDRecognizerPlayTonesRecordForbidden;
    }
    
    paramsObject.isShowTipAfter3sSilence = YES;
    paramsObject.isShowHelpButtonWhenSilence = YES;
    paramsObject.tipsTitle = @"可以使用如下指令";
    paramsObject.tipsList = [NSArray arrayWithObjects:@"例如:   ", @"郑州悉知", @"世界工厂网", @"......", nil];
    
    paramsObject.appCode = APPID;
    
    // 授权文件
//    paramsObject.licenseFilePath= [[NSBundle mainBundle] pathForResource:@"bdasr_temp_license" ofType:@"dat"];
    
    paramsObject.datFilePath = [[NSBundle mainBundle] pathForResource:@"s_1" ofType:@""];
    if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyMap) {
        paramsObject.LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_Navi" ofType:@""];
    } else if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyInput) {
        paramsObject.LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_InputMethod" ofType:@""];
    }
    
    paramsObject.recogGrammSlot = @{@"$name_CORE" : @"张三\n李四\n",
                                    @"$song_CORE" : @"小苹果\n朋友\n",
                                    @"$app_CORE" : @"QQ\n百度\n微信\n百度地图\n",
                                    @"$artist_CORE" : @"刘德华\n周华健\n"};
    
    [_recognizerViewController startWithParams:paramsObject];
    
}

- (IBAction)audioDataRecognitionAciton
{
    // 设置开发者信息，必须修改API_KEY和SECRET_KEY为在百度开发者平台申请得到的值，否则示例不能工作
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];
    // 设置是否需要语义理解，只在搜索模式有效
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:[BDVRSConfig sharedInstance].isNeedNLU];

    /* 文件识别
    NSBundle *bundle = [NSBundle mainBundle];
    NSString* recordFile = [bundle pathForResource:@"example_localRecord" ofType:@"pcm" inDirectory:nil];
    self.fileRecognizer = [[BDVRFileRecognizer alloc] initFileRecognizerWithFilePath:recordFile sampleRate:16000 mode:[BDVRSConfig sharedInstance].voiceRecognitionMode delegate:self];
    
    int status = [self.fileRecognizer startFileRecognition];
    if (status != EVoiceRecognitionStartWorking) {
        [self logOutToManualResut:[NSString stringWithFormat:@"错误码：%d\r\n", status]];
        return;
    }*/
    
    // 数据识别
    self.rawDataRecognizer = [[BDVRRawDataRecognizer alloc] initRecognizerWithSampleRate:16000 property:[[BDVRSConfig sharedInstance].recognitionProperty intValue] delegate:self];
   
    // 设置离线引擎参数
    self.rawDataRecognizer.appCode = APPID;
    self.rawDataRecognizer.licenseFilePath= [[NSBundle mainBundle] pathForResource:@"bdasr_temp_license" ofType:@"dat"];
    self.rawDataRecognizer.datFilePath = [[NSBundle mainBundle] pathForResource:@"s_1" ofType:@""];
    if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyMap) {
        self.rawDataRecognizer.LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_Navi" ofType:@""];
    } else if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyInput) {
        self.rawDataRecognizer.LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_InputMethod" ofType:@""];
    }
    self.rawDataRecognizer.recogGrammSlot = @{@"$name_CORE" : @"李四\n张三\n",
                                              @"$song_CORE" : @"小苹果\n我的滑板鞋\n",
                                              @"$app_CORE" : @"百度\n百度地图\n",
                                              @"$artist_CORE" : @"刘德华\n周华健\n"};
    
    int status = [self.rawDataRecognizer startDataRecognition];
    
    if (status != EVoiceRecognitionStartWorking) {
        [self logOutToManualResut:[NSString stringWithFormat:@"错误码：%d\r\n", status]];
        return;
    }
    NSThread* fileReadThread = [[NSThread alloc] initWithTarget:self
                                                       selector:@selector(fileReadThreadFunc)
                                                         object:nil];
    [fileReadThread start];
    // 数据识别
    
    
    [self clean];
    [self logOutToLogView:@"音频数据识别开始\r\n开始上传数据"];
}

- (void)fileReadThreadFunc
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString* recordFile = [bundle pathForResource:@"example_localRecord" ofType:@"pcm" inDirectory:nil];

    int hasReadFileSize = 0;
    
    // 每次向识别器发送的数据大小，建议不要超过4k，这里通过计算获得：采样率 * 时长 * 采样大小 / 压缩比
    // 其中采样率支持16000和8000，采样大小为16bit，压缩比为8，时长建议不要超过1s
    int sizeToRead = 16000 * 0.080 * 16 / 8;
    while (YES) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:recordFile];
        [fileHandle seekToFileOffset:hasReadFileSize];
        NSData* data = [fileHandle readDataOfLength:sizeToRead];
        [fileHandle closeFile];
        hasReadFileSize += [data length];
        if ([data length]>0)
        {
            [self.rawDataRecognizer sendDataToRecognizer:data];
        }
        else
        {
            [self.rawDataRecognizer allDataHasSent];
            break;
        }
    }
}

- (IBAction)uploadContactsAction:(UIButton *)sender {
    BDVRDataUploader *contactsUploader = [[BDVRDataUploader alloc] initDataUploader:self];
    self.contactsUploader = contactsUploader;
    [self.contactsUploader setApiKey:API_KEY withSecretKey:SECRET_KEY];
    NSString *jsonString = @"[{\"name\": \"test\",\"frequency\": 1},{\"name\": \"release\",\"frequency\": 2}]";
    [self.contactsUploader uploadContactsData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [self logOutToLogView:@"开始上传联系人..."];
}

#pragma mark - BDVRDataUploader delegate method
-(void)onComplete:(BDVRDataUploader *)dataUploader error:(NSError *)error
{
    if (error.code == 0) {
        [self logOutToLogView:@"联系人上传成功"];
    } else {
        [self logOutToLogView:[NSString stringWithFormat:@"联系人上传失败。错误码：%ld", (long)error.code]];
    }
}

- (void)VoiceRecognitionClientWorkStatus:(int) aStatus obj:(id)aObj
{
    switch (aStatus)
    {
        case EVoiceRecognitionClientWorkStatusFinish:
        {
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
            {
                NSMutableArray *audioResultData = (NSMutableArray *)aObj;
                NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
                
                for (int i=0; i<[audioResultData count]; i++)
                {
                    [tmpString appendFormat:@"%@\r\n",[audioResultData objectAtIndex:i]];
                }
                self.resultView.text = nil;
                [self logOutToManualResut:tmpString];
            }
            else
            {
                self.resultView.text = nil;
                NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aObj];
                [self logOutToManualResut:tmpString];
            }
            [self logOutToLogView:@"识别完成"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData:
        {
            NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
            
            [tmpString appendFormat:@"%@",[aObj objectAtIndex:0]];
            self.resultView.text = nil;
            [self logOutToManualResut:tmpString];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData:
        {
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] == EVoiceRecognitionPropertyInput)
            {
                self.resultView.text = nil;
                NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aObj];
                [self logOutToManualResut:tmpString];
            }
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd:
        {
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)VoiceRecognitionClientErrorStatus:(int) aStatus subStatus:(int)aSubStatus
{
    
}

- (void)VoiceRecognitionClientNetWorkStatus:(int) aStatus
{
    
}

#pragma mark ------- 语音识别 ---------
- (IBAction)voiceRecognitionAction
{
    [self clean];
    
    // 设置开发者信息
    [[BDVoiceRecognitionClient sharedInstance] setApiKey:API_KEY withSecretKey:SECRET_KEY];

    // 设置语音识别模式，默认是输入模式
    [[BDVoiceRecognitionClient sharedInstance] setPropertyList:@[[BDVRSConfig sharedInstance].recognitionProperty]];
    
    // 设置城市ID，当识别属性包含EVoiceRecognitionPropertyMap时有效
    [[BDVoiceRecognitionClient sharedInstance] setCityID: 1];
    
    // 设置是否需要语义理解，只在搜索模式有效
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"nlu" withFlag:[BDVRSConfig sharedInstance].isNeedNLU];
    
    // 开启联系人识别
    [[BDVoiceRecognitionClient sharedInstance] setConfig:@"enable_contacts" withFlag:YES];
    
    // 设置识别语言
    [[BDVoiceRecognitionClient sharedInstance] setLanguage:[BDVRSConfig sharedInstance].recognitionLanguage];
    
    // 是否打开语音音量监听功能，可选
    if ([BDVRSConfig sharedInstance].voiceLevelMeter)
    {
        BOOL res = [[BDVoiceRecognitionClient sharedInstance] listenCurrentDBLevelMeter];
        
        if (res == NO)  // 如果监听失败，则恢复开关值
        {
            [BDVRSConfig sharedInstance].voiceLevelMeter = NO;
        }
    }
    else
    {
        [[BDVoiceRecognitionClient sharedInstance] cancelListenCurrentDBLevelMeter];
    }
    
    // 设置播放开始说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecStart isPlay:[BDVRSConfig sharedInstance].playStartMusicSwitch];
    // 设置播放结束说话提示音开关，可选
    [[BDVoiceRecognitionClient sharedInstance] setPlayTone:EVoiceRecognitionPlayTonesRecEnd isPlay:[BDVRSConfig sharedInstance].playEndMusicSwitch];
    
    // 加载离线识别引擎
    NSString* appCode = APPID;
//    NSString* licenseFilePath= [[NSBundle mainBundle] pathForResource:@"bdasr_temp_license" ofType:@"dat"];
    NSString* datFilePath = [[NSBundle mainBundle] pathForResource:@"s_1" ofType:@""];
    NSString* LMDatFilePath = nil;
    if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyMap) {
        LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_Navi" ofType:@""];
    } else if ([[BDVRSConfig sharedInstance].recognitionProperty intValue] == EVoiceRecognitionPropertyInput) {
        LMDatFilePath = [[NSBundle mainBundle] pathForResource:@"s_2_InputMethod" ofType:@""];
    }
    
    NSDictionary* recogGrammSlot = @{@"$name_CORE" : @"张三\n李四\n",
                                    @"$song_CORE" : @"小苹果\n朋友\n",
                                    @"$app_CORE" : @"QQ\n百度\n微信\n百度地图\n",
                                    @"$artist_CORE" : @"刘德华\n周华健\n"};
    
    int ret = [[BDVoiceRecognitionClient sharedInstance] loadOfflineEngine:appCode
                                                                   license:nil
                                                                   datFile:datFilePath
                                                                 LMDatFile:LMDatFilePath
                                                                 grammSlot:recogGrammSlot];
    if (0 != ret) {
        NSLog(@"load offline engine failed: %d", ret);
        return;
    }
    
    // 创建语音识别界面，在其viewdidload方法中启动语音识别
    BDVRCustomRecognitonViewController *tmpAudioViewController = [[BDVRCustomRecognitonViewController alloc] initWithNibName:nil bundle:nil];
    tmpAudioViewController.clientSampleViewController = self;
    self.audioViewController = tmpAudioViewController;
    
    [[UIApplication sharedApplication].keyWindow addSubview:_audioViewController.view];
    

}

#pragma mark - BDRecognizerViewDelegate

- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerView withResults:(NSArray *)aResults
{
    _resultView.text = nil;
    
    if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
    {
        // 搜索模式下的结果为数组，示例为
        // ["公园", "公元"]
        NSMutableArray *audioResultData = (NSMutableArray *)aResults;
        NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
        
        for (int i=0; i < [audioResultData count]; i++)
        {
            [tmpString appendFormat:@"%@\r\n",[audioResultData objectAtIndex:i]];
        }
        
        _resultView.text = [_resultView.text stringByAppendingString:tmpString];
        _resultView.text = [_resultView.text stringByAppendingString:@"\n"];
        
    }
    else
    {
        // 输入模式下的结果为带置信度的结果，示例如下：
        //  [
        //      [
        //         {
        //             "百度" = "0.6055192947387695";
        //         },
        //         {
        //             "摆渡" = "0.3625582158565521";
        //         },
        //      ]
        //      [
        //         {
        //             "一下" = "0.7665404081344604";
        //         }
        //      ],
        //   ]
        NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aResults];
        
        _resultView.text = [_resultView.text stringByAppendingString:tmpString];
        _resultView.text = [_resultView.text stringByAppendingString:@"\n"];
    }
    
    if (_resultView.text.length > 0) {
        
        // 创建视图控制器
        MyViewController *myVC = [[MyViewController alloc]init];
        myVC.string = _resultView.text;
        [self presentViewController:myVC animated:YES completion:nil];
        
    }
}

#pragma mark - clean

- (void)clean
{
    _logCatView.text = nil; //  清除logview，避免打印过慢，影响UI
    _resultView.text = nil; //  清除result和_resultView，避免结果与log不对应
}

- (void)cleanResultViewAfter:(int)length
{
    _resultView.text = [_resultView.text substringToIndex:length];
}

#pragma mark - log & result

- (void)logOutToContinusManualResut:(NSString *)aResult
{
    _resultView.text = aResult;
    if (_resultView.text.length >0) {
        MyViewController *myVC = [[MyViewController alloc]init];
        myVC.string = _resultView.text;
        [self presentViewController:myVC animated:YES completion:nil];
    }
}

- (void)logOutToManualResut:(NSString *)aResult
{
    NSString *tmpString = _resultView.text;
    
    if (tmpString == nil || [tmpString isEqualToString:@""])
    {
        _resultView.text = aResult;
    }
    else
    {
        _resultView.text = [_resultView.text stringByAppendingString:aResult];
    }
    
    if (_resultView.text.length >0) {
        MyViewController *myVC = [[MyViewController alloc]init];
        myVC.string = tmpString;
        [self presentViewController:myVC animated:YES completion:nil];
    }
  
}

- (void)logOutToLogView:(NSString *)aLog
{
    NSString *tmpString = _logCatView.text;
    
    if (tmpString == nil || [tmpString isEqualToString:@""])
    {
        _logCatView.text = aLog;
    }
    else
    {
        _logCatView.text = [_logCatView.text stringByAppendingFormat:@"\r\n%@", aLog];
    }
}
@end
