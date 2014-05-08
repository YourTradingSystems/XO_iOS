//
//  TTGameFieldViewController.m
//  Tic tac toe
//
//  Created by Misha on 30.04.14.
//  Copyright (c) 2014 mobilesoft365. All rights reserved.
//

#import "XOGameFieldViewController.h"
#import "XOCollectionViewCell.h"
#import "XOGameModel.h"
#import "MPManager.h"
#import "GameManager.h"
#import "XOGameModel.h"

@interface XOGameFieldViewController () <XOGameModelDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) BOOL color;
@end

@implementation XOGameFieldViewController

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
    [XOGameModel sharedInstance].delegate = self;
    _delegate = [XOGameModel sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(win:) name:@"Win" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Win" object:nil];
}

- (void) playSound{
    if ([GameManager sharedInstance].sound==YES) {
    }
}

#pragma mark - CollectionView Data Sourse
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [XOGameModel sharedInstance].gameColumns;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [XOGameModel sharedInstance].gameColumns;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];    return cell;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - CollectionView Delegate
- (BOOL) collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegate respondsToSelector:@selector(willChangeValueForIndexPath:)]) {
        [_delegate willChangeValueForIndexPath:indexPath];
    }
    return NO;
}
- (BOOL) collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}
#pragma mark - Private
- (void)clearGameField
{
    [_collectionView reloadData];
}
#pragma mark - GameModel Delegate
- (void)playerWin:(XOPlayer)player
{
    
}
-  (void)didChangeValue:(int)value forIndexPath:(NSIndexPath *)indexPath
{
    XOCollectionViewCell *cell = (XOCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.mode = value;
    cell.selected = YES;

}
- (void)win:(NSNotification *)notification
{
    NSDictionary *info = [notification object];
    XOVectorType vT = [[info valueForKey:@"type"] intValue];
    
    switch (vT) {
        case XOVectorTypeHorisontal:
            [_collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:[[info valueForKey:@"s"] intValue]]];
            _color = YES;
            break;
        case XOVectorTypeVertical:
            [_collectionView reloadSections:[[NSIndexSet alloc] initWithIndex:[[info valueForKey:@"r"] intValue]]];
            _color = YES;
            break;
        case XOVectorTypeDiagonalLeft:
            break;
        case XOVectorTypeDiagonalRight:
            break;
        default:
            break;
    }
    
}
@end
