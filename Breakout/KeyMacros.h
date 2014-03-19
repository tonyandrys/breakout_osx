//
//  KeyMacros.h
//  Breakout
//
//  Created by Tony Andrys on 3/18/14.
//  Copyright (c) 2014 Tony Andrys. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

// Keycodes
#define BR_PADDLE_RIGHT     124 // Right arrow
#define BR_PADDLE_LEFT      123 // Left arrow

// Brick parameters
#define BR_BRICK_COUNT      72
#define BR_BRICK_ROWS       12

// Speeds & Parameters
#define BR_BALL_SPEED       10.5f
#define BR_PADDLE_SPEED     20.0f

// Bitmasks
static const uint32_t BALL_CATEGORY = 0x1 << 0; // 00000000000000000000000000000001
static const uint32_t BOTTOM_CATEGORY = 0x1 << 1; // 00000000000000000000000000000010
static const uint32_t BLOCK_CATEGORY = 0x1 << 2; // 00000000000000000000000000000100
static const uint32_t PADDLE_CATEGORY = 0x1 << 3; // 00000000000000000000000000001000