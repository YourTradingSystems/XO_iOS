//
//  TTGameViewController.m
//  Tic tac toe
//
//  Created by Stas Volskyi on 30.04.14.
//  Copyright (c) 2014 mobilesoft365. All rights reserved.
//

#import "XOGameViewController.h"
#import "XOSettingsViewController.h"
#import "GameManager.h"
#import "MPManager.h"
#import "XOGameModel.h"
#import "SoundManager.h"
#import "MGCicleProgress.h"

@interface XOGameViewController () <XOStepTimerDelegate, weHaveVictory, playersTurn, UIAlertViewDelegate, GADInterstitialDelegate>{
    NSTimer *stepTimer;
    NSTimer *restartGameTimer;
    int time;
    float restart;
}

@property (weak, nonatomic) IBOutlet UIView *gameFieldContainerView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *myName;
@property (weak, nonatomic) IBOutlet UILabel *opponentName;
@property (weak, nonatomic) IBOutlet UIImageView *myPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *opponentPhoto;
@property (weak, nonatomic) IBOutlet UIView *myPhotoFrame;
@property (weak, nonatomic) IBOutlet UIView *opponentPhotoFrame;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstPlayerScore;
@property (weak, nonatomic) IBOutlet UILabel *secondPlayerScore;
@property (weak, nonatomic) IBOutlet MGCicleProgress *progress;
@property (weak, nonatomic) IBOutlet UIImageView *timer;
@property (weak, nonatomic) IBOutlet MGCicleProgress *timerCircle;

- (IBAction)back:(id)sender;
- (IBAction)settings:(id)sender;

@end

@implementation XOGameViewController

#pragma mark - Lifecicle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configGameField];
    [XOGameModel sharedInstance].timerDelegate = self;
    [XOGameModel sharedInstance].victoryDelegate = self;
    [XOGameModel sharedInstance].playersTurnDelegate = self;
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg"]]];
    if ([GameManager sharedInstance].mode == XOGameModeOnline){
        [[GameManager sharedInstance].progress loadData];        
    }
    _progress.maxValue = 30;
    time=30;
    stepTimer=[NSTimer scheduledTimerWithTimeInterval:1.0
                                               target:self
                                             selector:@selector(onTick:)
                                             userInfo:nil
                                              repeats:YES];
    [MPManager sharedInstance].firstMessage = YES;
    [self setPlayersInfo];
}

- (void) viewWillAppear:(BOOL)animated{
    [[GameManager sharedInstance] loadFullScreenADV];
}

- (void) viewWillDisappear:(BOOL)animated{
    if ([GameManager sharedInstance].mode == XOGameModeOnline){
        [[MPManager sharedInstance].roomToTrack leave];
    }
    if ([stepTimer isValid]) {
        [stepTimer invalidate];
    }
}

- (void) dealloc{
    [[XOGameModel sharedInstance] clear];
    [self clearProgress];
}

#pragma mark - Other methods

- (void)configGameField
{
    _gameFieldViewController = [[UIStoryboard storyboardWithName:@"GameField" bundle:nil] instantiateViewControllerWithIdentifier:@"gameField"];
    [_gameFieldContainerView addSubview:_gameFieldViewController.view];
    _gameFieldViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [_gameFieldContainerView addConstraint:[NSLayoutConstraint constraintWithItem:_gameFieldContainerView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_gameFieldViewController.view
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0]];
    
    [_gameFieldContainerView addConstraint:[NSLayoutConstraint constraintWithItem:_gameFieldContainerView
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_gameFieldViewController.view
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:1.0
                                                                         constant:0]];
    [_gameFieldContainerView addConstraint:[NSLayoutConstraint constraintWithItem:_gameFieldContainerView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_gameFieldViewController.view
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0
                                                                         constant:0]];
    [_gameFieldContainerView addConstraint:[NSLayoutConstraint constraintWithItem:_gameFieldContainerView
                                                                        attribute:NSLayoutAttributeLeft
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_gameFieldViewController.view
                                                                        attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0
                                                                         constant:0]];
    [self addChildViewController:_gameFieldViewController];
}

- (void) setPlayersInfo{
    if ([GameManager sharedInstance].mode == XOGameModeOnline){
        [self.timerLabel setHidden:NO];
        [self.timer setHidden:NO];
        [self.timerCircle setHidden:NO];
        [self.settingsButton setHidden:YES];
        self.myName.text=[GameManager sharedInstance].googleUserName;
        self.opponentName.text=[GameManager sharedInstance].opponentName;
        self.myPhoto.image=[UIImage imageWithData:[NSData  dataWithContentsOfURL:[NSURL URLWithString:[GameManager sharedInstance].googleUserImage]]];
        self.opponentPhoto.image=[UIImage imageWithData:[NSData  dataWithContentsOfURL:[GameManager sharedInstance].opponentImage]];
    }
    else if ([GameManager sharedInstance].mode == XOGameModeMultiplayer){
        self.myName.text=[NSString stringWithFormat:NSLocalizedString(@"Player %i", nil), 1];
        self.opponentName.text=[NSString stringWithFormat:NSLocalizedString(@"Player %i", nil), 2];
        self.myPhoto.image=[UIImage imageNamed:@"xPlayer"];
        self.opponentPhoto.image=[UIImage imageNamed:@"oPlayer"];
        [self nowTurn:XOPlayerFirst];
        [self.timerLabel setHidden:YES];
        [self.timer setHidden:YES];
        [self.timerCircle setHidden:YES];
        [self.settingsButton setHidden:NO];
    }
    else if ([GameManager sharedInstance].mode == XOGameModeSingle){
        self.myName.text=NSLocalizedString(@"Me", nil);
        self.opponentName.text=@"iPhone";
        if ([[GPGManager sharedInstance] isSignedIn]) {
            self.myPhoto.image=[UIImage imageWithData:[NSData  dataWithContentsOfURL:[NSURL URLWithString:[GameManager sharedInstance].googleUserImage]]];
        }
        else{
            self.myPhoto.image=[UIImage imageNamed:@"user"];
        }
        self.opponentPhoto.image=[UIImage imageNamed:@"apple"];
        [self nowTurn:XOPlayerFirst];
        [self.timerLabel setHidden:YES];
        [self.timer setHidden:YES];
        [self.timerCircle setHidden:YES];
        [self.settingsButton setHidden:NO];
    }
    self.myName.layer.cornerRadius=4;
    self.opponentName.layer.cornerRadius=4;
    self.myPhoto.layer.cornerRadius=27.5;
    self.opponentPhoto.layer.cornerRadius=27.5;
    self.myPhotoFrame.layer.cornerRadius=32.5;
    self.opponentPhotoFrame.layer.cornerRadius=32.5;
    self.myPhoto.clipsToBounds=YES;
    self.opponentPhoto.clipsToBounds=YES;
    switch ([GameManager sharedInstance].mode) {
        case XOGameModeSingle:{
            if ([XOGameModel sharedInstance].aiGameMode == 0) {
                self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.easyVictory];
                self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.easyLooses];
            }
            if ([XOGameModel sharedInstance].aiGameMode == 1) {
                
            }
            if ([XOGameModel sharedInstance].aiGameMode == 2) {
                self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.hardVictory];
                self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.hardLooses];
            }
        }
            break;
        case XOGameModeMultiplayer:{
            self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].firstPlayerVictory];
            self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].secondPlayerVictory];
        }
            break;
        default:{
            self.firstPlayerScore.text=[self textScore:0];
            self.secondPlayerScore.text=[self textScore:0];
        }
            break;
    }
}

- (void) changePhotos{
    if (self.myPhoto.image==[UIImage imageNamed:@"oPlayer"]){
        self.myPhoto.image=[UIImage imageNamed:@"xPlayer"];
        self.opponentPhoto.image=[UIImage imageNamed:@"oPlayer"];
    }
    else{
        self.opponentPhoto.image=[UIImage imageNamed:@"xPlayer"];
        self.myPhoto.image=[UIImage imageNamed:@"oPlayer"];
    }
}

#pragma mark - UIActions

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [[SoundManager sharedInstance] playClickSound];
    [self resetBtnStatus];
}

- (IBAction)settings:(id)sender {
    XOSettingsViewController *settingsVew=[[UIStoryboard storyboardWithName:@"iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"settings"];
    [self.navigationController pushViewController:settingsVew animated:YES];
    [[SoundManager sharedInstance] playClickSound];
    [self resetBtnStatus];
}

#pragma mark - Disable MultiTouch

- (IBAction) pressed: (id) sender
{
    if (sender == self.backButton)
    {
    	self.settingsButton.enabled = false;
    }
    else if (sender == self.settingsButton)
    {
    	self.backButton.enabled = false;
    }
}

- (IBAction)touchUpOutside:(id)sender{
    [self resetBtnStatus];
}

- (void) resetBtnStatus{
    self.settingsButton.enabled = true;
    self.backButton.enabled = true;
}

#pragma mark - Score methods

- (void) showScore{
    switch ([GameManager sharedInstance].mode) {
        case XOGameModeMultiplayer:{
            self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].firstPlayerVictory];
            self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].secondPlayerVictory];
        }
        break;
        case XOGameModeSingle:{
            if ([XOGameModel sharedInstance].aiGameMode == 0) {
                self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.easyVictory];
                self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.easyLooses];
            }
            if ([XOGameModel sharedInstance].aiGameMode == 1) {
               
            }
            if ([XOGameModel sharedInstance].aiGameMode == 2) {
                self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.hardVictory];
                self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.hardLooses];
            }           
        }
        break;
        case XOGameModeOnline:{
            self.firstPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.myVictory];
            self.secondPlayerScore.text=[self textScore:[GameManager sharedInstance].progress.opponentVictory];
        }
        break;
    }
}

- (void) clearProgress{
    [GameManager sharedInstance].firstPlayerVictory=0;
    [GameManager sharedInstance].secondPlayerVictory=0;
    [GameManager sharedInstance].progress.myVictory=0;
    [GameManager sharedInstance].progress.opponentVictory=0;
}

- (NSString*)textScore:(int)score{
    NSString *strScore=[NSString new];
    strScore=[NSString stringWithFormat:@"%i",score];
    return strScore;
}

#pragma mark - Timer Methods

- (void) onTick:(NSTimer *)timer{
    time--;
    self.timerLabel.text=[NSString stringWithFormat:@"%i",time];
    _progress.doubleValue = (double)time;
    if (time<=1) {
        [stepTimer invalidate];
        if ([XOGameModel sharedInstance].gameMode==XOGameModeOnline) {
            if ([XOGameModel sharedInstance].player == [XOGameModel sharedInstance].me) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"timeOut", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
                [[MPManager sharedInstance] leaveRoom];
            }
            else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"timeOponent", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [[GameManager sharedInstance].progress updateProgress:XOGameModeOnline forMe:YES];
                [alert show];
                [[MPManager sharedInstance] leaveRoom];
            }
        }
        time=30;
    }
}

- (void) restartTick:(NSTimer *)timer{
    restart-=0.2f;
    if (restart<=0){
        [restartGameTimer invalidate];
        if ([GameManager sharedInstance].mode==XOGameModeMultiplayer) {
            [self changePhotos];
        }
    }

}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex==0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - XOStepTimerDelegate

- (void) resetTimer{
    time=30;
    self.timerLabel.text=[NSString stringWithFormat:@"%i",time];
}
- (void) stopTimer
{
    if ([stepTimer isValid]==YES) {
       [stepTimer invalidate];
    }
    stepTimer = nil;
}

- (void)startTimer{
    switch ([GameManager sharedInstance].mode) {
        case XOGameModeMultiplayer:
            [[GameManager sharedInstance] trackScreenWithName:MULTIPLAYER_SCREEN];
            break;
        case XOGameModeOnline:
            [[GameManager sharedInstance] trackScreenWithName:ONLINE_SCREEN];
            break;
        case XOGameModeSingle:
            [[GameManager sharedInstance] trackScreenWithName:SINGLE_SCREEN];
            break;
    }
    time=30;
    if (!stepTimer.isValid) {
    stepTimer =[NSTimer scheduledTimerWithTimeInterval:1.0
                                               target:self
                                             selector:@selector(onTick:)
                                             userInfo:nil
                                              repeats:YES];
    }
}

#pragma mark - playersTurnDelegate

- (void) nowTurn:(XOPlayer)player{
    if (player == XOPlayerFirst) {
        self.myPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(190.0/255.0) blue:(70.0/255.0) alpha:0.65f];
        self.opponentPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(25.0/255.0) blue:(0.0/255.0) alpha:1];
    } else if (player == XOPlayerSecond) {
        self.opponentPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(190.0/255.0) blue:(70.0/255.0) alpha:0.65f];
        self.myPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(25.0/255.0) blue:(0.0/255.0) alpha:1];
    }
}

- (void)nowMyTurn:(BOOL)myTurn
{
    if (myTurn) {
        self.myPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(190.0/255.0) blue:(70.0/255.0) alpha:0.65f];
        self.opponentPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(25.0/255.0) blue:(0.0/255.0) alpha:1];
    } else {
        self.opponentPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(190.0/255.0) blue:(70.0/255.0) alpha:0.65f];
        self.myPhotoFrame.backgroundColor=[UIColor colorWithRed:(50.0/255.0) green:(25.0/255.0) blue:(0.0/255.0) alpha:1];
    }
}

#pragma mark - victoryDelegate
- (void) drawVector:(XOVectorType)vectorType atLine:(int)line{
    UIImage *lineIMG = [[UIImage alloc] init];
    CGRect frame;
    
       switch (vectorType) {
        case XOVectorTypeDiagonalLeft:{
            lineIMG=[UIImage imageNamed:@"left"];
            frame=CGRectMake(0,0,self.gameFieldContainerView.frame.size.width,self.gameFieldContainerView.frame.size.height);
        }
        break;
        case XOVectorTypeDiagonalRight:{
            lineIMG=[UIImage imageNamed:@"right"];
            frame=CGRectMake(0,0,self.gameFieldContainerView.frame.size.width,self.gameFieldContainerView.frame.size.height);
        }
        break;
        case XOVectorTypeHorisontal:{
            lineIMG=[UIImage imageNamed:@"horizontal"];
            line*=self.gameFieldContainerView.frame.size.height/3;
            frame=CGRectMake(0, ((self.gameFieldContainerView.frame.size.height/3)/4)+line, self.gameFieldContainerView.frame.size.width, self.gameFieldContainerView.frame.size.height/10);
        }
        break;
        case XOVectorTypeVertical:{
            lineIMG=[UIImage imageNamed:@"vertical"];
            line*=self.gameFieldContainerView.frame.size.width/3;
            frame=CGRectMake(((self.gameFieldContainerView.frame.size.width/3)/3)+line, 0, self.gameFieldContainerView.frame.size.width/10, self.gameFieldContainerView.frame.size.height);
        }
        break;
        default:
        [self removeVector];
        return;
    }
    UIImageView *lineView=[[UIImageView alloc] initWithImage:lineIMG];
    lineView.frame=frame;
    lineView.tag = 79;
    [self.gameFieldContainerView addSubview:lineView];
    [self showScore];
}

- (void)restartGame{
    restartGameTimer=[NSTimer scheduledTimerWithTimeInterval:0.1
                                                               target:self
                                                             selector:@selector(restartTick:)
                                                             userInfo:nil
                                                              repeats:YES];
    restart=2.0f;
}

- (void) removeVector
{
    UIImageView *lineView = (UIImageView *)[_gameFieldContainerView viewWithTag:79];
    [lineView removeFromSuperview];
}

@end
