//
//  GameOverScene.m
//  Breakout
//
//  Created by Tony Andrys on 3/13/14.
//  Copyright (c) 2014 Tony Andrys. All rights reserved.
//

// Scene the player will see when either all lives or lost, or all bricks have been destroyed
#import "GameOverScene.h"
#import "MyScene.h"

@implementation GameOverScene

-(id)initWithSize:(CGSize)size playerWon:(BOOL)isWon {
    self = [super initWithSize:size];
    if (self) {
        
        // Load and position the background for this scene
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"bg.png"];
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addChild:background];
        
        // Load and define position of the two text labels
        // Label 1
        SKLabelNode *textLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        textLabel.fontSize = 36;
        textLabel.fontColor = [NSColor whiteColor];
        textLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        
        // Write the appropriate message to the label depending on the context and add it to the  scene
        if (isWon) {
            textLabel.text = @"You Win!";
        } else {
            textLabel.text = @"You Lose!";
        }
        [self addChild:textLabel];
        
        // Label 2
        SKLabelNode *textLabelTwo = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        textLabelTwo.fontColor = [NSColor whiteColor];
        textLabelTwo.fontSize = 22;
        textLabelTwo.position = CGPointMake(CGRectGetMidX(self.frame), textLabel.position.y - textLabel.fontSize - 20.0f);
        textLabelTwo.text = @"Click to play again.";
        [self addChild:textLabelTwo];
    }
    return self;
}

// Fired when the mouse is pressed down
-(void)mouseDown:(NSEvent *)theEvent {
    // When the user touches the screen, the jumps back into the breakout game
    MyScene *breakoutScene = [[MyScene alloc] initWithSize:self.size];
    [self.view presentScene:breakoutScene];
}

@end
