//
//  GameOverScene.h
//  Breakout
//
//  Created by Tony Andrys on 3/13/14.
//  Copyright (c) 2014 Tony Andrys. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameOverScene : SKScene

// playerWon boolean lets this scene be used for when the player has won (cleared all blocks) or lost (ball misses paddle until all "lives" are gone)
-(id)initWithSize:(CGSize)size playerWon:(BOOL)isWon;

@end
