#import "ENDGameOverScene.h"
#import "ENDMyScene.h"

@implementation ENDGameOverScene

-(id)initWithSize:(CGSize)size score:(int)score
{
    if (self = [super initWithSize:size]) {
        
        int scoreToDisplay = score;
        
        self.backgroundColor = [SKColor whiteColor];
        
        SKLabelNode *gameOverLabel = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Light"];
        gameOverLabel.text = @"GAME OVER";
        gameOverLabel.fontSize = 40;
        gameOverLabel.fontColor = [SKColor blackColor];
        gameOverLabel.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:gameOverLabel];
        
        SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Light"];
        scoreLabel.text = [NSString stringWithFormat:@"Your score: %d", scoreToDisplay];
        scoreLabel.fontSize = 20;
        scoreLabel.fontColor = [SKColor redColor];
        scoreLabel.position = CGPointMake(self.size.width/2, self.size.height/2 + 50);
        [self addChild:scoreLabel];
        
        SKLabelNode *retryLabel = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Light"];
        retryLabel.text = [NSString stringWithFormat:@"Touch screen to play again"];
        retryLabel.fontSize = 20;
        retryLabel.fontColor = [SKColor blueColor];
        retryLabel.position = CGPointMake(self.size.width/2, self.size.height/2 - 30);
        [self addChild:retryLabel];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    SKAction *newGameAction = [SKAction runBlock:^{
        SKTransition *reveal = [SKTransition flipVerticalWithDuration:0.5];
        SKScene *newGameScene = [[ENDMyScene alloc] initWithSize:self.size];
        [self.view presentScene:newGameScene transition: reveal];
    }];
    [self runAction:[SKAction sequence:@[newGameAction]]];
}


@end
