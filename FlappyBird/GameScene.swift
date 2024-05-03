import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    let verticalPipeGap = 150.0
    
    var newGameButton: SKLabelNode!
    
    var ball: SKSpriteNode!
    var skyColor: SKColor!
    var playersTextureUp: SKTexture!
    var playersTextureDown: SKTexture!
    var movePlayersAndRemove: SKAction!
    var moving: SKNode!
    var players: SKNode!
    var canRestart = Bool()
    var scoreLabelNode: SKLabelNode!
    var highScoreLabelNode: SKLabelNode!
    var score = NSInteger()
    var highScore = UserDefaults.standard.integer(forKey: "highScore")
    
    let ballCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMove(to view: SKView) {
        
        canRestart = true
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        players = SKNode()
        moving.addChild(players)
        
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        let skyTexture = SKTexture(imageNamed: "field")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.01 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        playersTextureUp = SKTexture(imageNamed: "team-1")
        playersTextureUp.filteringMode = .nearest
        playersTextureDown = SKTexture(imageNamed: "team-2")
        playersTextureDown.filteringMode = .nearest
        
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * playersTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePlayersAndRemove = SKAction.sequence([movePipes, removePipes])
        
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        let ballTexture = SKTexture(imageNamed: "ball-soccer")
        ballTexture.filteringMode = .nearest
        
        ball = SKSpriteNode(texture: ballTexture)
        ball.setScale(0.5)
        ball.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
        
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.height / 1.2)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.allowsRotation = true
        
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        ball.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(ball)
        
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"VT323")
        scoreLabelNode.fontSize = 36
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 100)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String("\(score) - 0")
        self.addChild(scoreLabelNode)
        
        highScoreLabelNode = SKLabelNode(fontNamed:"VT323")
        highScoreLabelNode.fontSize = 16
        highScoreLabelNode.position = CGPoint( x: self.frame.midX, y: 8 * self.frame.size.height / 9 )
        highScoreLabelNode.zPosition = 100
        highScoreLabelNode.text = String("HighScore: \(highScore)")
        self.addChild(highScoreLabelNode)
        
        newGameButton = SKLabelNode(fontNamed: "VT323")
        newGameButton.text = "New Game"
        newGameButton.fontSize = 20
        newGameButton.fontColor = SKColor.white
        newGameButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        newGameButton.isHidden = true
        self.addChild(newGameButton)
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + playersTextureUp.size().width * 2, y: 0 )
        pipePair.zPosition = -10
        
        let height = UInt32( self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: playersTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = ballCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: playersTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = ballCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + ball.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = ballCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePlayersAndRemove)
        players.addChild(pipePair)
        
    }
    
    func resetScene (){
        ball.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        ball.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        ball.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        ball.speed = 1.0
        ball.zRotation = 0.0
        
        players.removeAllChildren()
        
        canRestart = false
        highScore = max(score, highScore)
        UserDefaults.standard.setValue(highScore, forKey: "highScore")
        highScoreLabelNode.text = String("HighScore: \(highScore)")
        score = 0
        scoreLabelNode.text = String("\(score) - 0")

        moving.speed = 1
    }
    
    var touching = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = true
        
        if moving.speed > 0  {
            ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
        } else if canRestart {
            for touch in touches {
                let location = touch.location(in: self)
                if newGameButton.contains(location) {
                    resetScene()
                    newGameButton.isHidden = true
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touching = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        if touching {
            ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 1))
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                score += 1

                scoreLabelNode.text = String("\(score) - 0")
                highScoreLabelNode.text = String("HighScore: \(highScore)")
                
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            }
            else {
                
                moving.speed = 0
                
                ball.physicsBody?.collisionBitMask = worldCategory
                ball.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(ball.position.y) * 0.01, duration:1), completion:{self.ball.speed = 0 })
                
                
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                    self.backgroundColor = self.skyColor
                }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                    self.canRestart = true
                })]), withKey: "flash")
            }
        }
        else {
            newGameButton.isHidden = false
        }
    }
    
}
