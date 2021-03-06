//
//  BDVRCustomRecognitonViewController.m
//  BDVRClientSample
//
//  Created by Baidu on 13-9-25
//  Copyright 2013 Baidu Inc. All rights reserved.
//

// 头文件
#import "BDVRCustomRecognitonViewController.h"
#import "BDVRClientUIManager.h"
#import "WBVoiceRecordHUD.h"
#import "BDVRViewController.h"
#import "MyViewController.h"
#import "BDVRSConfig.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define VOICE_LEVEL_INTERVAL 0.1 // 音量监听频率为1秒中10次
#define WEAKSELF typeof(self) __weak weakSelf = self;
#define STRONGSELF typeof(weakSelf) __strong strongSelf = weakSelf;
#define CURRENT_SYS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
// image STRETCH
#define XH_STRETCH_IMAGE(image, edgeInsets) (CURRENT_SYS_VERSION < 6.0 ? [image stretchableImageWithLeftCapWidth:edgeInsets.left topCapHeight:edgeInsets.top] : [image resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch])

// 私有方法分类
@interface BDVRCustomRecognitonViewController ()
{
    UIView *tmpView; // 背景大view
    UILabel *tmpLabel;
    UIImageView *voiceImageStr; //按住提示
    // 动画相关实例
    CALayer *_layer;
    CAAnimationGroup *_animaTionGroup;
    CADisplayLink *_disPlayLink;
    
}
// 录音按钮相关
@property (nonatomic, weak, readonly) UIButton *holdDownButton;// 说话按钮
/**
 *  是否取消錄音
 */
@property (nonatomic, assign, readwrite) BOOL isCancelled;

/**
 *  是否正在錄音
 */
@property (nonatomic, assign, readwrite) BOOL isRecording;
/**
 *  当录音按钮被按下所触发的事件，这时候是开始录音
 */
- (void)holdDownButtonTouchDown;

/**
 *  当手指在录音按钮范围之外离开屏幕所触发的事件，这时候是取消录音
 */
- (void)holdDownButtonTouchUpOutside;

/**
 *  当手指在录音按钮范围之内离开屏幕所触发的事件，这时候是完成录音
 */
- (void)holdDownButtonTouchUpInside;

/**
 *  当手指滑动到录音按钮的范围之外所触发的事件
 */
- (void)holdDownDragOutside;

/**
 *  当手指滑动到录音按钮的范围之内所触发的时间
 */


#pragma mark - layout subViews UI

/**
 *  根据正常显示和高亮状态创建一个按钮对象
 *
 *  @param image   正常显示图
 *  @param hlImage 高亮显示图
 *
 *  @return 返回按钮对象
 */
- (UIButton *)createButtonWithImage:(UIImage *)image HLImage:(UIImage *)hlImage ;
- (void)holdDownDragInside;
- (void)createInitView; // 创建初始化界面，播放提示音时会用到
- (void)createRecordView;  // 创建录音界面
- (void)createRecognitionView; // 创建识别界面
- (void)createErrorViewWithErrorType:(int)aStatus; // 在识别view中显示详细错误信息
- (void)createRunLogWithStatus:(int)aStatus; // 在状态view中显示详细状态信息

- (void)finishRecord:(id)sender; // 用户点击完成动作
- (void)cancel:(id)sender; // 用户点击取消动作

- (void)startVoiceLevelMeterTimer;
- (void)freeVoiceLevelMeterTimerTimer;

@end// VoiceRecognitonViewController

// 类实现
@implementation BDVRCustomRecognitonViewController
@synthesize dialog = _dialog;
@synthesize clientSampleViewController;
@synthesize voiceLevelMeterTimer = _voiceLevelMeterTimer;

#pragma mark - init & dealloc

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
        // 
    }
    
    return self;
}

- (void)dealloc 
{
    [self freeVoiceLevelMeterTimerTimer];
}

#pragma mark - views lifestyle

- (void)loadView 
{
    [self customBackgroundView];
}

// 自定义背景
- (void)customBackgroundView
{
    tmpView = [[UIView alloc] initWithFrame:[[BDVRClientUIManager sharedInstance] VRBackgroundFrame]];
    tmpView.backgroundColor = [UIColor whiteColor];
    self.view = tmpView;
    
    // 语音搜索Label
    UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 10, 100, 25)];
    nameLabel.text = @"语音搜索";
    nameLabel.font = [UIFont systemFontOfSize:22];
    nameLabel.alpha = 0.6f;
    [tmpView addSubview:nameLabel];
    
    // 取消按钮
    UIButton *cancleButton = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 40, 12, 25, 25)];
    [cancleButton setImage:[UIImage imageNamed:@"cancleButton"] forState:UIControlStateNormal];
    [cancleButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [tmpView addSubview:cancleButton];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    [self installReconginzing];
}


// 初始化识别相关
- (void)installReconginzing
{
    /*
    // 开始语音识别功能，之前必须实现MVoiceRecognitionClientDelegate协议中的VoiceRecognitionClientWorkStatus:obj方法
    int startStatus = -1;
    startStatus = [[BDVoiceRecognitionClient sharedInstance] startVoiceRecognition:self];
    if (startStatus != EVoiceRecognitionStartWorking) // 创建失败则报告错误
    {
        NSString *statusString = [NSString stringWithFormat:@"%d",startStatus];
        [self performSelector:@selector(firstStartError:) withObject:statusString afterDelay:0.3];  // 延迟0.3秒，以便能在出错时正常删除view
        return;
    }*/

    
    // 是否需要播放开始说话提示音，如果是，则提示用户不要说话，在播放完成后再开始说话, 也就是收到EVoiceRecognitionClientWorkStatusStartWorkIng通知后再开始说话。
    if ([BDVRSConfig sharedInstance].playStartMusicSwitch)
    {
        [self createInitView];
    }
    else
    {
        [self createRecordView];
    }
    
    self.view.alpha = 0.0f;
    
    [UIView beginAnimations:@"show" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    self.view.alpha = 1.0f;
    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning 
{
	[self cancel:nil];
	self.clientSampleViewController.logCatView.text = [self.clientSampleViewController.logCatView.text stringByAppendingFormat:@"\n内存警告，停止本次识别"]; // 发生内存警告时，停止语音识别，避免出现崩溃
    [super didReceiveMemoryWarning];
}

#pragma mark - button action methods

- (void)finishRecord:(id)sender 
{
    [[BDVoiceRecognitionClient sharedInstance] speakFinish];
}

- (void)cancel:(id)sender 
{
	[[BDVoiceRecognitionClient sharedInstance] stopVoiceRecognition];
    
    if (self.view.superview)
    {
        [self.view removeFromSuperview];
    }
}

#pragma mark - MVoiceRecognitionClientDelegate

- (void)VoiceRecognitionClientErrorStatus:(int) aStatus subStatus:(int)aSubStatus
{
    // 为了更加具体的显示错误信息，此处没有使用aStatus参数
    [self createErrorViewWithErrorType:aSubStatus];
}

- (void)VoiceRecognitionClientWorkStatus:(int)aStatus obj:(id)aObj
{
    switch (aStatus)
    {
        case EVoiceRecognitionClientWorkStatusFlushData: // 连续上屏中间结果
        {
            NSString *text = [aObj objectAtIndex:0];
            
            if ([text length] > 0)
            {
//                [clientSampleViewController logOutToContinusManualResut:text];
                
                UILabel *clientWorkStatusFlushLabel = [[UILabel alloc]initWithFrame:CGRectMake(kScreenWidth/2 - 100,64,200,60)];
                clientWorkStatusFlushLabel.text = text;
                clientWorkStatusFlushLabel.textAlignment = NSTextAlignmentCenter;
                clientWorkStatusFlushLabel.font = [UIFont systemFontOfSize:18.0f];
                clientWorkStatusFlushLabel.numberOfLines = 0;
                clientWorkStatusFlushLabel.backgroundColor = [UIColor whiteColor];
                [self.view addSubview:clientWorkStatusFlushLabel];
                
            }

            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: // 识别正常完成并获得结果
        {
			[self createRunLogWithStatus:aStatus];
            
            if ([[BDVoiceRecognitionClient sharedInstance] getRecognitionProperty] != EVoiceRecognitionPropertyInput)
            {
                //  搜索模式下的结果为数组，示例为
                // ["公园", "公元"]
                NSMutableArray *audioResultData = (NSMutableArray *)aObj;
                NSMutableString *tmpString = [[NSMutableString alloc] initWithString:@""];
                
                for (int i=0; i < [audioResultData count]; i++)
                {
                    [tmpString appendFormat:@"%@\r\n",[audioResultData objectAtIndex:i]];
                }
                
                clientSampleViewController.resultView.text = nil;
                [clientSampleViewController logOutToManualResut:tmpString];
                
            }
            else
            {
                NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aObj];
                [clientSampleViewController logOutToContinusManualResut:tmpString];
                
            }
           
            if (self.view.superview)
            {
                [self.view removeFromSuperview];
            }
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusReceiveData:
        {
            // 此状态只有在输入模式下使用
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
//暂时关掉 -- 否则影响跳转结果
//            NSString *tmpString = [[BDVRSConfig sharedInstance] composeInputModeResult:aObj];
//            [clientSampleViewController logOutToContinusManualResut:tmpString];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: // 用户说话完成，等待服务器返回识别结果
        {
			[self createRunLogWithStatus:aStatus];
            if ([BDVRSConfig sharedInstance].voiceLevelMeter)
            {
                [self freeVoiceLevelMeterTimerTimer];
            }
			
            [self createRecognitionView];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel:
        {            
            if ([BDVRSConfig sharedInstance].voiceLevelMeter) 
            {
                [self freeVoiceLevelMeterTimerTimer];
            }
            
			[self createRunLogWithStatus:aStatus];  
            
            if (self.view.superview) 
            {
                [self.view removeFromSuperview];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusStartWorkIng: // 识别库开始识别工作，用户可以说话
        {
            if ([BDVRSConfig sharedInstance].playStartMusicSwitch) // 如果播放了提示音，此时再给用户提示可以说话
            {
                [self createRecordView];
            }
            
            if ([BDVRSConfig sharedInstance].voiceLevelMeter)  // 开启语音音量监听
            {
                [self startVoiceLevelMeterTimer];
            }
            
			[self createRunLogWithStatus:aStatus]; 

            break;
        }
		case EVoiceRecognitionClientWorkStatusNone:
		case EVoiceRecognitionClientWorkPlayStartTone:
		case EVoiceRecognitionClientWorkPlayStartToneFinish:
		case EVoiceRecognitionClientWorkStatusStart:
		case EVoiceRecognitionClientWorkPlayEndToneFinish:
		case EVoiceRecognitionClientWorkPlayEndTone:
		{
			[self createRunLogWithStatus:aStatus];
			break;
		}
        case EVoiceRecognitionClientWorkStatusNewRecordData:
        {
            break;
        }
        default:
        {
			[self createRunLogWithStatus:aStatus];
            if ([BDVRSConfig sharedInstance].voiceLevelMeter) 
            {
                [self freeVoiceLevelMeterTimerTimer];
            }
            if (self.view.superview) 
            {
                [self.view removeFromSuperview];
            }
 
            break;
        }
    }
}

- (void)VoiceRecognitionClientNetWorkStatus:(int) aStatus
{
    switch (aStatus) 
    {
        case EVoiceRecognitionClientNetWorkStatusStart:
        {	
			[self createRunLogWithStatus:aStatus];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;   
        }
        case EVoiceRecognitionClientNetWorkStatusEnd:
        {
			[self createRunLogWithStatus:aStatus];
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;   
        }          
    }
}

#pragma mark - voice search error result

- (void)firstStartError:(NSString *)statusString
{
    if (self.view.superview) 
    {
        [self.view removeFromSuperview];
    }
    
	[self createErrorViewWithErrorType:[statusString intValue]];
}

- (void)createErrorViewWithErrorType:(int)aStatus
{
    NSString *errorMsg = @"";
    
    switch (aStatus)
    {
        case EVoiceRecognitionClientErrorStatusIntrerruption:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonInterruptRecord", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusChangeNotAvailable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonChangeNotAvailable", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusUnKnow:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonStatusError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusNoSpeech:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoSpeech", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusShort:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoShort", nil);
            break;
        }
        case EVoiceRecognitionClientErrorStatusException:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonException", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkError", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusUnusable:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil);
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusTimeOut:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonNetWorkTimeOut", nil); 
            break;
        }
        case EVoiceRecognitionClientErrorNetWorkStatusParseError:
        {
            errorMsg = NSLocalizedString(@"StringVoiceRecognitonParseError", nil);
            break;
        }
		case EVoiceRecognitionStartWorkNoAPIKEY:
		{
			errorMsg = NSLocalizedString(@"StringAudioSearchNoAPIKEY", nil);
            break;
		}
        case EVoiceRecognitionStartWorkGetAccessTokenFailed:
        {
            errorMsg = NSLocalizedString(@"StringAudioSearchGetTokenFailed", nil);
            break;
        }
		case EVoiceRecognitionStartWorkDelegateInvaild:
		{
			errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoDelegateMethods", nil);  
            break;
		}
		case EVoiceRecognitionStartWorkNetUnusable:
		{
			errorMsg = NSLocalizedString(@"StringVoiceRecognitonNoNetWork", nil); 
            break;
		}
		case EVoiceRecognitionStartWorkRecorderUnusable:
		{
			errorMsg = NSLocalizedString(@"StringVoiceRecognitonCantRecord", nil); 
            break;
		}
        case EVoiceRecognitionStartWorkNOMicrophonePermission:
		{
            errorMsg = NSLocalizedString(@"StringAudioSearchNOMicrophonePermission", nil); 
            break;
		}
        //服务器返回错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerNoFindResult:     //没有找到匹配结果
        case EVoiceRecognitionClientErrorNetWorkStatusServerSpeechQualityProblem:    //声音过小
            
        case EVoiceRecognitionClientErrorNetWorkStatusServerParamError:       //协议参数错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerRecognError:      //识别过程出错
        case EVoiceRecognitionClientErrorNetWorkStatusServerAppNameUnknownError: //appName验证错误
        case EVoiceRecognitionClientErrorNetWorkStatusServerUnknownError:      //未知错误
        {
			errorMsg = [NSString stringWithFormat:@"%@-%d",NSLocalizedString(@"StringVoiceRecognitonServerError", nil),aStatus] ;
            break;
        }
        default:
        {
            errorMsg =[NSString stringWithFormat:@"%@：%d", NSLocalizedString(@"StringVoiceRecognitonDefaultError", nil), aStatus];
            break;
        }
    }
    // 不让显示错误❌的结果
//    [clientSampleViewController logOutToManualResut:errorMsg];
}

#pragma mark - voice search views

- (void)createInitView
{
    if (_holdDownButton && _holdDownButton.superview)
        [_holdDownButton removeFromSuperview];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 -36, kScreenHeight - 120, 72, 72)];
    [button setBackgroundImage:[UIImage imageNamed:@"client"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"Oval"] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(holdDownButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(holdDownButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(holdDownButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(holdDownDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(holdDownDragInside) forControlEvents:UIControlEventTouchDragEnter];
    _holdDownButton = button;
    [self.view addSubview:_holdDownButton];
    
    // 按住说话提示
    [voiceImageStr removeFromSuperview];
    voiceImageStr = [[UIImageView alloc]initWithFrame:CGRectMake(kScreenWidth/2 - 40, kScreenHeight - 153, 80, 33)];
    voiceImageStr.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"speck"]];
    [self.view addSubview:voiceImageStr];
    
   [tmpLabel removeFromSuperview];
    tmpLabel = [[UILabel alloc] initWithFrame:[[BDVRClientUIManager sharedInstance] VRRecordTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor blackColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonInit", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = self.view.center;
    [self.view addSubview:tmpLabel];

}

- (void)createRecordView
{
   
    if (_holdDownButton && _holdDownButton.superview)
        [_holdDownButton removeFromSuperview];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 -36, kScreenHeight - 120, 72, 72)];
    [button setBackgroundImage:[UIImage imageNamed:@"client"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"Oval"] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(holdDownButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(holdDownButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(holdDownButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(holdDownDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(holdDownDragInside) forControlEvents:UIControlEventTouchDragEnter];
    _holdDownButton = button;
    [self.view addSubview:_holdDownButton];
    
    // 按住说话提示
    [voiceImageStr removeFromSuperview];
    voiceImageStr = [[UIImageView alloc]initWithFrame:CGRectMake(kScreenWidth/2 - 40, kScreenHeight - 153, 80, 33)];
    voiceImageStr.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"speck"]];
    [self.view addSubview:voiceImageStr];
    
    [tmpLabel removeFromSuperview];
    tmpLabel = [[UILabel alloc] initWithFrame:[[BDVRClientUIManager sharedInstance] VRRecordTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor blackColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonPleaseSpeak", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = self.view.center;
    [self.view addSubview:tmpLabel];
    
}

- (void)createRecognitionView
{
    // 移除提示
    [voiceImageStr removeFromSuperview];
    if (_holdDownButton && _holdDownButton.superview)
        [_holdDownButton removeFromSuperview];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 -36, kScreenHeight - 120, 72, 72)];
    [button setBackgroundImage:[UIImage imageNamed:@"client"] forState:UIControlStateNormal];
    [button setBackgroundImage:[UIImage imageNamed:@"Oval"] forState:UIControlStateHighlighted];
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(holdDownButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(holdDownButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(holdDownButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(holdDownDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(holdDownDragInside) forControlEvents:UIControlEventTouchDragEnter];
    _holdDownButton = button;
    [self.view addSubview:_holdDownButton];
    
    [tmpLabel removeFromSuperview];
    tmpLabel = [[UILabel alloc] initWithFrame:[[BDVRClientUIManager sharedInstance] VRRecognizeTintWordFrame]];
    tmpLabel.backgroundColor = [UIColor clearColor];
    tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
    tmpLabel.textColor = [UIColor blackColor];
    tmpLabel.text = NSLocalizedString(@"StringVoiceRecognitonIdentify", nil);
    tmpLabel.textAlignment = NSTextAlignmentCenter;
    tmpLabel.center = self.view.center;
    [self.view addSubview:tmpLabel];
    
}

#pragma mark - voice search log

- (void)createRunLogWithStatus:(int)aStatus
{	
    NSString *statusMsg = nil;
	switch (aStatus)
	{
		case EVoiceRecognitionClientWorkStatusNone: //空闲
		{
			statusMsg = NSLocalizedString(@"StringLogStatusNone", nil);
			break;
		}
		case EVoiceRecognitionClientWorkPlayStartTone:  //播放开始提示音
		{
			statusMsg = NSLocalizedString(@"StringLogStatusPlayStartTone", nil);
			break;
		}
		case EVoiceRecognitionClientWorkPlayStartToneFinish: //播放开始提示音完成
		{
			statusMsg = NSLocalizedString(@"StringLogStatusPlayStartToneFinish", nil);
           
			break;
		}
		case EVoiceRecognitionClientWorkStatusStartWorkIng: //识别工作开始，开始采集及处理数据
		{
			statusMsg = NSLocalizedString(@"StringLogStatusStartWorkIng", nil);
			break;
		}
		case EVoiceRecognitionClientWorkStatusStart: //检测到用户开始说话
		{
			statusMsg = NSLocalizedString(@"StringLogStatusStart", nil);
            [tmpLabel removeFromSuperview];
            tmpLabel = [[UILabel alloc] initWithFrame:[[BDVRClientUIManager sharedInstance] VRRecordTintWordFrame]];
            tmpLabel.backgroundColor = [UIColor clearColor];
            tmpLabel.font = [UIFont boldSystemFontOfSize:28.0f];
            tmpLabel.textColor = [UIColor blackColor];
            tmpLabel.text = NSLocalizedString(@"StringVoiceStartSpeack", nil);
            tmpLabel.textAlignment = NSTextAlignmentCenter;
            tmpLabel.center = self.view.center;
            [self.view addSubview:tmpLabel];
			break;
		}
		case EVoiceRecognitionClientWorkPlayEndTone: //播放结束提示音 
		{
			statusMsg = NSLocalizedString(@"StringLogStatusPlayEndTone", nil);
			break;
		}
		case EVoiceRecognitionClientWorkPlayEndToneFinish: //播放结束提示音完成
		{
			statusMsg = NSLocalizedString(@"StringLogStatusPlayEndToneFinish", nil);
			break;
		}
        case EVoiceRecognitionClientWorkStatusReceiveData: //语音识别功能完成，服务器返回正确结果
        {
			statusMsg = NSLocalizedString(@"StringLogStatusSentenceFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: //语音识别功能完成，服务器返回正确结果
        {
			statusMsg = NSLocalizedString(@"StringLogStatusFinish", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: //本地声音采集结束结束，等待识别结果返回并结束录音
        {
			statusMsg = NSLocalizedString(@"StringLogStatusEnd", nil);
			break;
		}
		case EVoiceRecognitionClientNetWorkStatusStart: //网络开始工作
        {
			statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusStart", nil);
            break;   
        }
        case EVoiceRecognitionClientNetWorkStatusEnd:  //网络工作完成
        {
			statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusEnd", nil);
            break;   
        } 
        case EVoiceRecognitionClientWorkStatusCancel:  // 用户取消
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusCancel", nil);
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: // 出现错误
        {
            statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusErorr", nil);
            break;
        } 
		default:
		{
			statusMsg = NSLocalizedString(@"StringLogStatusNetWorkStatusDefaultErorr", nil);
			break;
		}
	}
	
//	if (statusMsg)
//	{
//		NSString *logString = self.clientSampleViewController.logCatView.text;
//		if (logString && [logString isEqualToString:@""] == NO)
//		{
//			self.clientSampleViewController.logCatView.text = [logString stringByAppendingFormat:@"\r\n%@", statusMsg];
//		}
//		else 
//		{
//			self.clientSampleViewController.logCatView.text = statusMsg;
//		}
//	}
}

#pragma mark - VoiceLevelMeterTimer methods

- (void)startVoiceLevelMeterTimer
{
    [self freeVoiceLevelMeterTimerTimer];

    NSDate *tmpDate = [[NSDate alloc] initWithTimeIntervalSinceNow:VOICE_LEVEL_INTERVAL];
    NSTimer *tmpTimer = [[NSTimer alloc] initWithFireDate:tmpDate interval:VOICE_LEVEL_INTERVAL target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    self.voiceLevelMeterTimer = tmpTimer;
    [[NSRunLoop currentRunLoop] addTimer:_voiceLevelMeterTimer forMode:NSDefaultRunLoopMode];
}

- (void)freeVoiceLevelMeterTimerTimer
{
	if(_voiceLevelMeterTimer)
	{
		if([_voiceLevelMeterTimer isValid])
			[_voiceLevelMeterTimer invalidate];
		self.voiceLevelMeterTimer = nil;
	}
}

- (void)timerFired:(id)sender
{
    // 获取语音音量级别
    int voiceLevel = [[BDVoiceRecognitionClient sharedInstance] getCurrentDBLevelMeter];
    
    NSString *statusMsg = [NSLocalizedString(@"StringLogVoiceLevel", nil) stringByAppendingFormat:@": %d", voiceLevel];
    [clientSampleViewController logOutToLogView:statusMsg];
}

#pragma mark - animation finish

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context 
{
    //
    
}

#pragma mark ------ 关于按钮操作的一些事情-------
- (void)holdDownButtonTouchDown {
    // 开始动画
    _disPlayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(delayAnimation)];
    _disPlayLink.frameInterval = 40;
    [_disPlayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    self.isCancelled = NO;
    self.isRecording = NO;
    
 // 开始语音识别功能，之前必须实现MVoiceRecognitionClientDelegate协议中的VoiceRecognitionClientWorkStatus:obj方法
    int startStatus = -1;
    startStatus = [[BDVoiceRecognitionClient sharedInstance] startVoiceRecognition:self];
    if (startStatus != EVoiceRecognitionStartWorking) // 创建失败则报告错误
    {
        NSString *statusString = [NSString stringWithFormat:@"%d",startStatus];
        [self performSelector:@selector(firstStartError:) withObject:statusString afterDelay:0.3];  // 延迟0.3秒，以便能在出错时正常删除view
        return;
    }
    // "按住说话－松开搜索"提示
    [voiceImageStr removeFromSuperview];
    voiceImageStr = [[UIImageView alloc]initWithFrame:CGRectMake(kScreenWidth/2 - 40, kScreenHeight - 153, 80, 33)];
    voiceImageStr.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"searchVoice"]];
    [self.view addSubview:voiceImageStr];
   
}

- (void)holdDownButtonTouchUpOutside {
    // 结束动画
    [self.view.layer removeAllAnimations];
    [_disPlayLink invalidate];
    _disPlayLink = nil;
    
    // 取消录音
    [[BDVoiceRecognitionClient sharedInstance] stopVoiceRecognition];
    
    if (self.view.superview)
    {
        [self.view removeFromSuperview];
    }
}

- (void)holdDownButtonTouchUpInside {
    // 结束动画
    [self.view.layer removeAllAnimations];
    [_disPlayLink invalidate];
    _disPlayLink = nil;
    
    [[BDVoiceRecognitionClient sharedInstance] speakFinish];
}

- (void)holdDownDragOutside {
    
    //如果已經開始錄音了, 才需要做拖曳出去的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
//        if ([self.delegate respondsToSelector:@selector(didDragOutsideAction)]) {
//            [self.delegate didDragOutsideAction];
//        }
    } else {
        self.isCancelled = YES;
    }
}

- (void)holdDownDragInside {
    
    //如果已經開始錄音了, 才需要做拖曳回來的動作, 否則只要切換 isCancelled, 不讓錄音開始.
    if (self.isRecording) {
//        if ([self.delegate respondsToSelector:@selector(didDragInsideAction)]) {
//            [self.delegate didDragInsideAction];
//        }
    } else {
        self.isCancelled = YES;
    }
}

#pragma mark - layout subViews UI

- (UIButton *)createButtonWithImage:(UIImage *)image HLImage:(UIImage *)hlImage {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2 -36, kScreenHeight - 120, 72, 72)];
    
    if (image)
        [button setBackgroundImage:image forState:UIControlStateNormal];
    if (hlImage)
        [button setBackgroundImage:hlImage forState:UIControlStateHighlighted];
    
    return button;
}

#pragma mark ----------- 动画部分 -----------
- (void)startAnimation
{
    CALayer *layer = [[CALayer alloc] init];
    layer.cornerRadius = [UIScreen mainScreen].bounds.size.width/2;
    layer.frame = CGRectMake(0, 0, layer.cornerRadius * 2, layer.cornerRadius * 2);
    layer.position = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height - 84);
    //    self.view.layer.position;
    UIColor *color = [UIColor colorWithRed:arc4random()%10*0.1 green:arc4random()%10*0.1 blue:arc4random()%10*0.1 alpha:1];
    layer.backgroundColor = color.CGColor;
    [self.view.layer addSublayer:layer];
    
    CAMediaTimingFunction *defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    
    _animaTionGroup = [CAAnimationGroup animation];
    _animaTionGroup.delegate = self;
    _animaTionGroup.duration = 2;
    _animaTionGroup.removedOnCompletion = YES;
    _animaTionGroup.timingFunction = defaultCurve;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @0.0;
    scaleAnimation.toValue = @1.0;
    scaleAnimation.duration = 2;
    
    CAKeyframeAnimation *opencityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opencityAnimation.duration = 2;
    opencityAnimation.values = @[@0.8,@0.4,@0];
    opencityAnimation.keyTimes = @[@0,@0.5,@1];
    opencityAnimation.removedOnCompletion = YES;
    
    NSArray *animations = @[scaleAnimation,opencityAnimation];
    _animaTionGroup.animations = animations;
    [layer addAnimation:_animaTionGroup forKey:nil];
    
    [self performSelector:@selector(removeLayer:) withObject:layer afterDelay:1.5];
}

- (void)removeLayer:(CALayer *)layer
{
    [layer removeFromSuperlayer];
}


- (void)delayAnimation
{
    [self startAnimation];
}
@end // BDVRCustomRecognitonViewController
