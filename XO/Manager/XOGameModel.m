//
//  XOGameModel.m
//  XO
//
//  Created by Misha on 05.05.14.
//  Copyright (c) 2014 mobilez365. All rights reserved.
//

#import "XOGameModel.h"

@interface XOGameModel ()
@end
@implementation XOGameModel
@synthesize gameColumns = _gameColumns;
#pragma mark - Static
static XOGameModel *_instance=Nil;
#pragma mark - Lifecicle
- (id)init
{
    self = [super init];
    if (self) {
        _gameColumns = [self gameColumns];
        _xTurn = YES;
        _dimension = 3;
    }
    return self;
}
- (void) clear
{
    _gameColumns = [self gameColumns];
     _gameFieldMatrix = [XOMatrix matrixWithDimension:_gameColumns];
    _xTurn = YES;
}

#pragma mark - Custom Accsesors
- (int) gameColumns
{
    if (!_gameColumns) {
        [self setGameColumns:3];
    }
    return _gameColumns;
}
- (void)setGameColumns:(int)gColumns
{
    _gameColumns = gColumns;
    _gameFieldMatrix = [XOMatrix matrixWithDimension:gColumns];
}
- (void)setGameMode:(XOGameMode)gameMode
{
    _gameMode = gameMode;
    _player = XOPlayerFirst;
}
#pragma mark - Class Methods
+ (XOGameModel*)sharedInstance{
    @synchronized(self) {
        if (_instance==nil) {
            _instance=[[self alloc] init];
        }
        return _instance;
    }
}
#pragma mark - GameFieldViewController Delegate
- (void)willChangeValueForIndexPath:(NSIndexPath *)indexPath
{
    if (_gameMode == XOGameModeMultiplayer)
    {
            int value = _player?-1:1;
            if ([_gameFieldMatrix setValue:value forIndexPath:indexPath]) {
                if ([_delegate respondsToSelector:@selector(didChangeValue:forIndexPath:)]) {
                    [_delegate didChangeValue:value forIndexPath:indexPath];
                }
                _player= _player ? XOPlayerFirst : XOPlayerSecond;
            }
        NSLog(@"%@", _gameFieldMatrix);
    }
    else if (_gameMode == XOGameModeOnline)
    {
        if (!_player) {
            if ([_gameFieldMatrix setValue:1 forIndexPath:indexPath]) {
                if ([_delegate respondsToSelector:@selector(didChangeValue:forIndexPath:)]) {
                    [_delegate didChangeValue:1 forIndexPath:indexPath];
                }
                _player=XOPlayerSecond;
            }
        }
    }
    else if (_gameMode == XOGameModeSingle)
    {
        if (!_player) {
            if ([_gameFieldMatrix setValue:1 forIndexPath:indexPath]) {
                if ([_delegate respondsToSelector:@selector(didChangeValue:forIndexPath:)]) {
                    [_delegate didChangeValue:1 forIndexPath:indexPath];
                }
                _player=XOPlayerSecond;
            }
        }
    }
}
- (void)setMoveForIndexPath:(NSIndexPath *)indexPath
{
    if ([_gameFieldMatrix setValue:-1 forIndexPath:indexPath]) {
        if ([_delegate respondsToSelector:@selector(didChangeValue:forIndexPath:)]) {
            [_delegate didChangeValue:-1 forIndexPath:indexPath];
        }
        _player=XOPlayerFirst;
    }
}
- (void)willChangeValueforIndexPath:(NSIndexPath *)indexPath
{
    
}
#pragma mark - Protocol Methods

@end
