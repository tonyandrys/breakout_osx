//
//  MyScene.m
//  Breakout
//
//  Created by Tony Andrys on 3/12/14.
//  Copyright (c) 2014 Tony Andrys. All rights reserved.
//

#import "MyScene.h"
#import "KeyMacros.h"
#import "GameOverScene.h"

// Constants to help identify game objects
static NSString *ballCategoryName = @"ball";
static NSString *paddleCategoryName = @"paddle";
static NSString *blockCategoryName = @"block";
static NSString *blockNodeCategoryName = @"blockNode";
static NSString *scoreLabelName = @"scoreLabel";

@interface MyScene()

@property (nonatomic, assign) BOOL gamePaused;
@property (nonatomic, assign) BOOL gameStarted;
@property (nonatomic, assign) BOOL moveLeft;
@property (nonatomic, assign) BOOL moveRight;

@property (nonatomic, assign) CGFloat paddleWidth;

// Storage for preloaded sounds
@property (strong, nonatomic) SKAction *ballBounceSound;
@property (strong, nonatomic) SKAction *brickBreakSound;

// Need this property to implement dragging of the paddle
@property (nonatomic) BOOL isFingerOnPaddle;
@property (nonatomic) NSInteger bricksRemaining;
@property (nonatomic) NSInteger playerScore;
@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // Set this class to be the contact delegate for all collisions that happen physicsWorld
        self.physicsWorld.contactDelegate = self;
        
        // Initialize the background sprite
        //SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
        
        // Position it in the center of the main frame
        //background.position = CGPointMake(self.frame.size.width/2, self.frame.size.width/2);
        
        // Add it to the scene
        //[self addChild:background];
        
        // * Change the gravity of the game world
        // Default SK gravity is (x=0.0, y=-9.8) to simulate gravity of the Earth
        // Breakout doesn't require gravity (nothing falls, ball has to fly up), so set x and y axis gravity to 0.
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        
        // * Want to restrict the ball to keep it inside the screen at all times, so we need a body that borders the screen.
        // Create a physics body, SKPhysicsBody, an object used to add physics simulation to a node.
        // We want an edge-based body that does not have mass or volume, and unaffected by forces or impulses.
        SKPhysicsBody *borderBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        
        // Set physicsBody of scene to the new body we just created
        self.physicsBody = borderBody;
        
        // Set the friction of the view's physicsBody to 0 (since the ball can't lose momentum when it hits bricks/borders)
        self.physicsBody.friction = 0.0f;
        
        // * Need to add the ball to the game
        SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
        
        ball.name = ballCategoryName; // Name it for future reference
        
        // The starting position of the ball should be near the bottom of the screen
        ball.position = CGPointMake(self.frame.size.width/3, self.frame.size.height/3);
        
        // Add the ball to the scene
        [self addChild:ball];
        
        // * Define and configure the physics body of the ball to configure the way it will interact with the World
        // We create a volume-based body, since the ball should be affected by forces, impulses, and collisions with other objects
        ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.frame.size.width/2]; // radius = 1/2*width
        
        ball.physicsBody.friction = 0.0f; // Remove all friction from the ball
        ball.physicsBody.restitution = 1.0f; // Restitution = "bounciness", we want elastic (no energy lost) collisions
        ball.physicsBody.linearDamping = 0.0f; // Simulates air/fluid friction, we don't want this
        ball.physicsBody.allowsRotation = NO; // We don't want the ball to rotate
        ball.physicsBody.categoryBitMask = BALL_CATEGORY; // Assign ball category bitmask
        ball.physicsBody.contactTestBitMask = BOTTOM_CATEGORY | BLOCK_CATEGORY; // Only notify if the ball makes contact with the bottom of the screen OR a block
        
        // Finally, apply an impulse (force vector) to the ball to kick off the motion of the ball.
        // if dx=10.0 and dy=-10.0, then we're pushing the ball to the bottom right of the screen (slope m = -1)
        [ball.physicsBody applyImpulse:CGVectorMake(BR_BALL_SPEED, BR_BALL_SPEED)];
        
        // * Construct the paddle and its physics body
        SKSpriteNode *paddle = [[SKSpriteNode alloc] initWithImageNamed:@"paddle"];
        paddle.name = paddleCategoryName;
        
        // Paddle's initial position: x=middle of frame
        paddle.position = CGPointMake(CGRectGetMidX(self.frame), paddle.frame.size.height*2);
        [self addChild:paddle];
        
        // Define the physics body of the paddle
        paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:paddle.frame.size];
        paddle.physicsBody.restitution = 0.1f;
        paddle.physicsBody.friction = 0.4f;
        paddle.physicsBody.categoryBitMask = PADDLE_CATEGORY; // assign "paddle" category bitmask
        
        // Make the paddle's physics body static, meaning it will not react to forces and impulses.
        paddle.physicsBody.dynamic = NO;
        
        // Store the width of the paddle
        self.paddleWidth = paddle.size.width;
        
        // Define a physics body to stretch along the bottom of the screen to detect when the paddle misses the ball
        CGRect bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 1);
        SKNode* bottom = [SKNode node];
        bottom.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:bottomRect];
        bottom.physicsBody.categoryBitMask = BOTTOM_CATEGORY; // Assign "bottom" category bitmask to detect collisions
        [self addChild:bottom];
        
        // Add the bricks to the scene
        self.bricksRemaining = BR_BRICK_COUNT;
        [self addBricksToScene];
        
        // Start pre-loading sounds
        self.brickBreakSound = [SKAction playSoundFileNamed:@"brick-break.wav" waitForCompletion:NO];
        self.ballBounceSound = [SKAction playSoundFileNamed:@"ball-bounce.wav" waitForCompletion:NO];

        /*// Lazy creation of score label and score count field if a score of zero is set (game is starting up)
         NSLog(@"Initializing score label and counter...");
         SKLabelNode *scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
         scoreLabelNode.fontColor = [UIColor whiteColor];
         scoreLabelNode.fontSize = 16;
         scoreLabelNode.position = CGPointMake(self.frame.origin.x, (self.frame.origin.y + 16.0f));
         scoreLabelNode.text = @"Score:";
         [self addChild:scoreLabelNode];
         
         SKLabelNode *scoreCountNode = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
         scoreCountNode.fontColor = [UIColor whiteColor];
         scoreCountNode.fontSize = 16;
         scoreCountNode.position = CGPointMake(self.frame.origin.x + scoreLabelNode.frame.size.width + 3.0f, (self.frame.origin.y + 16.0f));
         scoreCountNode.text = @"0"; // initial score is zero
         scoreCountNode.name = scoreLabelName;
         [self addChild:scoreCountNode];
         
         // Initialize the score counter and set the player's score to 0
         self.playerScore = 0;
         [self updatePlayerScore];*/
    }
    return self;
}

// Adds BRICK_COUNT bricks to the scene and configures them appropriately
-(void)addBricksToScene {
    
    NSLog(@"** Adding bricks to the scene...");
    
    // Get the length and width of the screen and the width of each brick
    float screenHeight = self.frame.size.height;
    float screenWidth = self.frame.size.width;
    NSLog(@"screen height=%f", screenHeight);
    NSLog(@"screen width=%f", screenWidth);
    
    float brickWidth = [SKSpriteNode spriteNodeWithImageNamed:@"red-brick"].size.width; // all bricks are the same width
    float brickHeight = [SKSpriteNode spriteNodeWithImageNamed:@"red-brick"].size.height; // all bricks are the same height
    NSLog(@"brick height=%f | brick width=%f", brickHeight, brickWidth);
    
    // define the amount of padding from the top of the screen to the first brick
    float topPadding = 30.0f;
    
    // initialize an array of NSStrings corresponding to the brick images to place
    NSArray *brickImageStrings = @[@"red-brick", @"orange-brick", @"gold-brick", @"yellow-brick", @"green-brick", @"blue-brick"];
    
    /*NSArray *brickNodeArray = @[
     [SKSpriteNode spriteNodeWithImageNamed:@"red-brick.png"],
     [SKSpriteNode spriteNodeWithImageNamed:@"orange-brick.png"],
     [SKSpriteNode spriteNodeWithImageNamed:@"gold-brick.png"],
     [SKSpriteNode spriteNodeWithImageNamed:@"yellow-brick.png"],
     [SKSpriteNode spriteNodeWithImageNamed:@"green-brick.png"],
     [SKSpriteNode spriteNodeWithImageNamed:@"blue-brick.png"],
     
     ];*/
    
    /* To achieve 40px of padding from the top of the screen and on the left and right of the stack of blocks, the first brick should be
     placed at (topPadding, screenHeight-topPadding)*/
    CGPoint brickPos = CGPointMake(topPadding, screenHeight-topPadding);
    
    // Actually add the bricks to the scene
    for (int i=0; i<BR_BRICK_COUNT; i++) {
        
        // Get the appropriate image for this row and create the node for this brick
        NSString *imageString = [brickImageStrings objectAtIndex:floor((i/BR_BRICK_ROWS))];
        SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:imageString];
        
        // Calculate new position for this block
        //NSLog(@"[i=%d] Next brick location: [", i);
        //NSLog(@" X => [%d MOD 7] * brickWidth = %d * %f", i+1, (i+1)%7, ((i+1)%7)*brickWidth);
        //NSLog(@" Y => %f - floor(i/7)=%f * brickHeight(%f) = %f", (screenHeight-topPadding), floor(i/7), brickHeight, floor(i/7) * brickHeight);
        brickPos.x = 60.0f + ((i+1)%BR_BRICK_ROWS)*brickWidth;
        brickPos.y = (screenHeight-topPadding) - (floor(i/BR_BRICK_ROWS) * brickHeight);
        
        // Position the brick
        brick.position = brickPos;
        
        // Define the physics body of this brick
        brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.frame.size];
        brick.physicsBody.allowsRotation = NO;
        brick.physicsBody.friction = 0.0f;
        brick.physicsBody.dynamic = NO;
        
        // Set name and category of this brick for collision detection with ball and add to the scene
        brick.name = blockCategoryName;
        brick.physicsBody.categoryBitMask = BLOCK_CATEGORY;
        [self addChild:brick];
        
        NSLog(@"[i=%d] Added brick %d at (%f,%f) [img string=#%f]", i, i, brickPos.x, brickPos.y, floor(i/7));
    }
    
}

// Checks the player's progress in the game and updates the isGameWom property if all blocks have been destroyed.
-(BOOL)checkGameStatus {
    if (self.bricksRemaining == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - Collision Handling

-(void)didBeginContact:(SKPhysicsContact *)contact {
    
    // Set the body with the lowest category bitmask to firstBody
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        // Do the opposite
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    // If the ball makes contact with a brick, destroy it and decrement the number of remaining bricks
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == BLOCK_CATEGORY) {
        [secondBody.node removeFromParent];
        self.bricksRemaining -= 1;
        [self runAction:self.brickBreakSound]; // Play the brick break sound
        NSLog(@"Brick destroyed (remaining: %ld)", (long)self.bricksRemaining);
        
        // Check if any bricks are remaining -- if none remain, the player has won the game.
        if ([self checkGameStatus]) {
            GameOverScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.frame.size playerWon:YES];
            [self.view presentScene:gameOverScene];
        }
        
    }
    
    // If the ball has made contact with the bottom body, the player will lose a life.
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == BOTTOM_CATEGORY) {
        // FIXME: Change this to lose a life, but go to the gameover scene automatically for now
        GameOverScene* gameOverScene = [[GameOverScene alloc] initWithSize:self.frame.size playerWon:NO];
        [self.view presentScene:gameOverScene];
    }
    
}


#pragma mark - OSX Event Handling

// Start movement
-(void) keyDown:(NSEvent *)theEvent {
    //NSLog(@"Key pressed: %hu", theEvent.keyCode);
    [self handleKeyEvent:theEvent keyDown:YES];
}

// Handle movement based on key pressed
-(void) handleKeyEvent:(NSEvent *)keyEvent keyDown:(BOOL)isKeyDown {
    
    if ([keyEvent keyCode] == BR_PADDLE_LEFT) {
        self.moveLeft = isKeyDown;
        //NSLog(@"Left key bool: %d", isKeyDown);
    } else if ([keyEvent keyCode] == BR_PADDLE_RIGHT) {
        self.moveRight = isKeyDown;
        //NSLog(@"Right key bool: %d", isKeyDown);
    }
    
}

// End movement
-(void) keyUp:(NSEvent *)theEvent {
    [self handleKeyEvent:theEvent keyDown:NO];
    //NSLog(@"Key released: %hu", theEvent.keyCode);
}

// Checks if the paddle has reached the left boundary
- (BOOL)reachedLeftBound:(SKSpriteNode*)paddle {
    return CGRectGetMinX(self.frame) > (paddle.position.x - self.paddleWidth/2 + 0);
}

// Checks if the paddle has reached the right boundary
- (BOOL)reachedRightBound:(SKSpriteNode*)paddle {
    return CGRectGetMaxX(self.frame) <= (paddle.position.x + self.paddleWidth/2 + 0);
}

#pragma mark - Update Frame

// Called before each frame is rendered
-(void)update:(NSTimeInterval)currentTime {
    
    // Move Paddle if movement key (left or right) is pressed
    // FIXME: Look at left and right bounds check, some paddle escapes the sides of the screen
    SKSpriteNode *paddle = (SKSpriteNode *)[self childNodeWithName:paddleCategoryName]; // Get a reference to the paddle by name
    CGPoint currentPosition = CGPointMake(paddle.position.x, paddle.position.y);
    //NSLog(@"Position: (%f,%f)", currentPosition.x, currentPosition.y);
    
    if (self.moveRight && ![self reachedRightBound:paddle]) {
        // Calculate the new position and move the paddle to the new position
        CGPoint newPosition = CGPointMake(paddle.position.x + BR_PADDLE_SPEED, paddle.position.y);
        paddle.position = newPosition;
    } else if (self.moveLeft && ![self reachedLeftBound:paddle]) {
        // Calculate the new position and move the paddle to the new position
        CGPoint newPosition = CGPointMake(paddle.position.x - BR_PADDLE_SPEED, paddle.position.y);
        paddle.position = newPosition;
    }
}

@end
