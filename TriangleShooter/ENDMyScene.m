@import CoreMotion;
#import "ENDMyScene.h"
#import "ENDGameOverScene.h"

@interface ENDMyScene () <SKPhysicsContactDelegate>
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) int enemiesDestroyed;
@end

const float MaxPlayerAccel = 500.0f;
const float MaxPlayerSpeed = 300.0f;
const float BorderCollisionDamping = 0.1f;

static const uint32_t projectileCategory    = 0x1 << 0;
static const uint32_t enemyCategory         = 0x1 << 1;
static const uint32_t playerCategory        = 0x1 << 3;

@implementation ENDMyScene
{
    
    CGSize _winSize;
    SKSpriteNode *_playerSprite;
    SKSpriteNode *_enemySprite;
    
    CMMotionManager *_motionManager;
    UIAccelerationValue _accelerometerX;
    
    float _playerAccelX;
    float _playerSpeedX;
    
    SKLabelNode *_label;
}

static inline float vectorLength(CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor whiteColor];
        
        _winSize = CGSizeMake(size.width, size.height);
        
        SKTexture *texture = [SKTexture textureWithImageNamed:@"player"];
        texture.filteringMode = SKTextureFilteringNearest;
        _playerSprite = [SKSpriteNode spriteNodeWithTexture:texture];
        _playerSprite.position = CGPointMake(_winSize.width/2.0f, _playerSprite.size.height);
        _playerSprite.color = [SKColor blackColor];
        _playerSprite.colorBlendFactor = 1.0;
        
        _motionManager = [[CMMotionManager alloc] init];
        
        _playerSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_playerSprite.size];
        _playerSprite.physicsBody.dynamic = YES;
        _playerSprite.physicsBody.categoryBitMask = playerCategory;
        _playerSprite.physicsBody.contactTestBitMask = enemyCategory;
        _playerSprite.physicsBody.collisionBitMask = 0;
        
        _label = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Light"];
        _label.text = [NSString stringWithFormat:@"Score: %d", self.enemiesDestroyed];
        _label.fontSize = 20;
        _label.fontColor = [SKColor blackColor];
        _label.position = CGPointMake(50, 15);
        [self addChild:_label];
        
        // Make sure there is no gravity being applied,
        // because we are hand coding the falling down of enemies later :)
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        [self startMonitoringAcceleration];
        [self addChild:_playerSprite];
        
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitoringAcceleration];
    _motionManager = nil;
}

-(void)startMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable) {
        [_motionManager startAccelerometerUpdates];
        NSLog(@"Accelerometer ON!");
    }
}

-(void)stopMonitoringAcceleration
{
    if (_motionManager.accelerometerAvailable && _motionManager.accelerometerActive) {
        [_motionManager stopAccelerometerUpdates];
        NSLog(@"Accelerometer OFF!");
    }
}

-(void)updatePlayerAccelerationFromMotionManager
{
    const double FilteringFactor = 0.75;
    CMAcceleration acceleration = _motionManager.accelerometerData.acceleration;
    _accelerometerX = acceleration.x * FilteringFactor + _accelerometerX * (1.0 - FilteringFactor);
    
    if (_accelerometerX < -0.05)
    {
        _playerAccelX = -MaxPlayerAccel;
    }
    else if (_accelerometerX > 0.05)
    {
        _playerAccelX = MaxPlayerAccel;
    }
}

-(void)updatePlayer:(NSTimeInterval)dt
{
    _playerSpeedX += _playerAccelX*dt;
    
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlayerSpeed), -MaxPlayerSpeed);
    
    float newX = _playerSprite.position.x + _playerSpeedX*dt;

    BOOL collidedWithVerticalBorder = NO;
    
    if (newX < _playerSprite.size.width/2)
    {
        newX = _playerSprite.size.width/2;
        collidedWithVerticalBorder = YES;
    }
    else if (newX > _winSize.width - _playerSprite.size.width/2)
    {
        newX = _winSize.width - _playerSprite.size.width/2;
        collidedWithVerticalBorder = YES;
    }
    
    if (collidedWithVerticalBorder)
    {
        _playerAccelX = -_playerAccelX * BorderCollisionDamping;
        _playerSpeedX = -_playerSpeedX * BorderCollisionDamping;
    }
    
    _playerSprite.position = CGPointMake(newX, 50);

}

-(void)addEnemy
{
    // Make sprite
    SKSpriteNode *enemy = [SKSpriteNode spriteNodeWithImageNamed:@"enemy"];
    
    float randomR = (arc4random_uniform(101) / 100.0f);
    float randomG = (arc4random_uniform(101) / 100.0f);
    float randomB = (arc4random_uniform(101) / 100.0f);
    
    enemy.color = [SKColor colorWithRed:randomR green:randomG blue:randomB alpha:1.0];
    enemy.colorBlendFactor = 1.0;
    
    enemy.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:enemy.size];
    enemy.physicsBody.dynamic = YES;
    enemy.physicsBody.categoryBitMask = enemyCategory;
    enemy.physicsBody.contactTestBitMask = projectileCategory;
    enemy.physicsBody.collisionBitMask = 0;
    
    // Determine where to spawn the enemy along the X axis
    int minX = enemy.size.width;
    int maxX = self.frame.size.width - enemy.size.width;
    int rangeX = maxX - minX;
    int actualX = (arc4random() % rangeX) + minX;
    
    // Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above.
    enemy.position = CGPointMake(actualX, self.frame.size.height + enemy.size.height/2);
    
    // Determine the speed of the monster
    int minDuration = 1.0;
    int maxDuration = 5.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    [self addChild:enemy];
    
    // float enemySpeed = 100.0f/1.0f;
    // float enemyMoveDuration = self.size.height / enemySpeed;
    CGPoint destination = CGPointMake(actualX, -enemy.size.width/2);
    
    // Create the actions
    SKAction *actionMove = [SKAction moveTo:destination duration:actualDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
    
}

-(void)playerShoot
{
    SKSpriteNode *projectile = [SKSpriteNode spriteNodeWithImageNamed:@"projectile"];
    projectile.position = CGPointMake(_playerSprite.position.x, _playerSprite.position.y + _playerSprite.size.height);
    
    projectile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:projectile.size];
    projectile.physicsBody.dynamic = YES;
    projectile.physicsBody.categoryBitMask = projectileCategory;
    projectile.physicsBody.contactTestBitMask = enemyCategory;
    projectile.physicsBody.collisionBitMask = 0;
    projectile.physicsBody.usesPreciseCollisionDetection = YES;
    
    float velocity = 480.0f/1.0f;
    float realMoveDuration = self.size.height / velocity;
    
    [self addChild:projectile];
    
    CGPoint realDest = CGPointMake(_playerSprite.position.x, _playerSprite.position.y + 1000);
    
    SKAction *actionMove = [SKAction moveTo:realDest duration:realMoveDuration];
    SKAction *actionMoveDone = [SKAction removeFromParent];
    [projectile runAction:[SKAction sequence:@[actionMove, actionMoveDone]]];
}

-(void)firstEntity:(SKSpriteNode *)firstEntity didCollideWithSecondEntity:(SKSpriteNode *)secondEntity
{
    NSLog(@"Hit");
    [self runAction:[SKAction playSoundFileNamed:@"explosion.wav" waitForCompletion:NO]];
    [firstEntity removeFromParent];
    [secondEntity removeFromParent];
    
    NSString *burstPath =
    [[NSBundle mainBundle]
     pathForResource:@"BurstParticle" ofType:@"sks"];
    
    SKEmitterNode *burstNode =
    [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
    
    burstNode.position = CGPointMake(firstEntity.position.x, firstEntity.position.y);
    [self addChild:burstNode];
    
    SKAction *wait =       [SKAction waitForDuration: 0.5];
    SKAction *fadeAway =   [SKAction fadeOutWithDuration:0.25];
    SKAction *removeNode = [SKAction removeFromParent];
    
    SKAction *sequence = [SKAction sequence:@[wait, fadeAway, removeNode]];
    [burstNode runAction: sequence];
    
    self.enemiesDestroyed++;
    _label.text = [NSString stringWithFormat:@"Score: %d", self.enemiesDestroyed];
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if ((firstBody.categoryBitMask &projectileCategory) != 0 && (secondBody.categoryBitMask &enemyCategory) != 0)
    {
        [self firstEntity:(SKSpriteNode *)firstBody.node didCollideWithSecondEntity:(SKSpriteNode *)secondBody.node];
    }
    else if ((firstBody.categoryBitMask &enemyCategory) != 0 && (secondBody.categoryBitMask &playerCategory) != 0)
    {
        SKAction *loseAction = [SKAction runBlock:^{
            SKTransition *reveal = [SKTransition flipVerticalWithDuration:0.5];
            SKScene *gameOverScene = [[ENDGameOverScene alloc] initWithSize:self.size score:_enemiesDestroyed];
            [self.view presentScene:gameOverScene transition: reveal];
        }];
        [self runAction:[SKAction playSoundFileNamed:@"gameOver.wav" waitForCompletion:NO]];
        [self runAction:[SKAction sequence:@[loseAction]]];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    [self runAction:[SKAction playSoundFileNamed:@"shoot.wav" waitForCompletion:NO]];
    [self playerShoot];
}

-(void)update:(CFTimeInterval)currentTime {
    // Handle time delta.
    // If we drop below 60fps, we still want everything to move the same distance.
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // More than a second since last update
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    [self updatePlayerAccelerationFromMotionManager];
    [self updatePlayer:timeSinceLast];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > 1) {
        self.lastSpawnTimeInterval = 0;
        [self addEnemy];
    }
}
@end
