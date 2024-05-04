import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate{
    let verticalPipeGap = 150.0
    
    var newGameButton: SKLabelNode!
    var soundIsPlaying: Bool = false
    
    var ball: SKSpriteNode!
    var playersTextureUp: SKTexture!
    var playersTextureDown: SKTexture!
    var movePlayersAndRemove: SKAction!
    var moving: SKNode!
    var players: SKNode!
    var canRestart = Bool()
    var scoreLabelNode: SKLabelNode!
    var score = NSInteger()
    var highScore = UserDefaults.standard.integer(forKey: "highScore")
    var gameEndImage: SKSpriteNode!
    
    let ballCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    override func didMove(to view: SKView) {
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        canRestart = true
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        moving = SKNode()
        self.addChild(moving)
        players = SKNode()
        moving.addChild(players)
        
        let groundTexture = SKTexture(imageNamed: "crowd")
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
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height)
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
        
        let lineHeight: CGFloat = 10

        // Bottom Line
        let bottomLine = SKSpriteNode(color: .white, size: CGSize(width: self.frame.size.width, height: lineHeight))
        bottomLine.position = CGPoint(x: self.frame.midX, y: groundTexture.size().height * 1.5)
        self.addChild(bottomLine)

        bottomLine.physicsBody = SKPhysicsBody(rectangleOf: bottomLine.size)
        bottomLine.physicsBody?.isDynamic = false
        bottomLine.physicsBody?.categoryBitMask = worldCategory

        // Top Line
        let safeAreaTopInset: CGFloat

        if #available(iOS 11.0, *) {
          if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            safeAreaTopInset = scene.windows.first!.safeAreaInsets.top
          } else {
            safeAreaTopInset = 0
          }
        } else {
            safeAreaTopInset = 0
        }

        let topLine = SKSpriteNode(color: .white, size: CGSize(width: self.frame.size.width, height: lineHeight))
        topLine.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - safeAreaTopInset)
        topLine.zPosition = 1
        self.addChild(topLine)

        topLine.physicsBody = SKPhysicsBody(rectangleOf: topLine.size)
        topLine.physicsBody?.isDynamic = false
        topLine.physicsBody?.categoryBitMask = worldCategory

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
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"VT323")
        scoreLabelNode.fontSize = 36
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: self.frame.height * 5/6)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String("\(score) - \(highScore)")
        self.addChild(scoreLabelNode)
        
        let gameEndTexture = SKTexture(imageNamed: "card_red")
        gameEndTexture.filteringMode = .nearest
        gameEndImage = SKSpriteNode(texture: gameEndTexture)
        gameEndImage.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 100)
        gameEndImage.size = CGSize(width: 100.0, height: 130.0)
        gameEndImage.isHidden = true
        self.addChild(gameEndImage)
                
        newGameButton = SKLabelNode(fontNamed: "VT323")
        newGameButton.text = "New Game"
        newGameButton.fontSize = 20
        newGameButton.fontColor = SKColor.white
        newGameButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 60)
        newGameButton.isHidden = true
        self.addChild(newGameButton)
    }
    
    func spawnPipes() {
        let randomInt1 = Int.random(in: 1..<13)
        let randomInt2 = Int.random(in: 1..<13)
        playersTextureUp = SKTexture(imageNamed: "team-\(randomInt1)")
        playersTextureUp.filteringMode = .nearest
        playersTextureDown = SKTexture(imageNamed: "team-\(randomInt2)")
        playersTextureDown.filteringMode = .nearest
        
        
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
        score = 0
        scoreLabelNode.text = String("\(score) - \(highScore)")
        
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
                    gameEndImage.isHidden = true
                    
                    if soundIsPlaying == false {
                        soundIsPlaying = true
                        backgroundMusic.removeFromParent()
                        addChild(backgroundMusic)
                    }
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
                
                scoreLabelNode.text = String("\(score) - \(highScore)")
                
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            }
            else {
                
                moving.speed = 0
                
                ball.physicsBody?.collisionBitMask = worldCategory
                ball.run(  SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(ball.position.y) * 0.01, duration:1), completion:{self.ball.speed = 0 })
                
                self.canRestart = true
                
                soundIsPlaying = false
                backgroundMusic.run(SKAction.stop())
            }
        }
        else {
            newGameButton.isHidden = false
            gameEndImage.isHidden = false
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            let shake = SKAction.shake(gameEndImage.position, duration: 0.5)
            gameEndImage.run(shake)
            
            if score > highScore {
                run(whistleGood)
            } else {
                run(whistleBad)
            }
        }
    }
    
    var soundDying = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    var whistleGood = SKAction.playSoundFileNamed("whistle-good.wav", waitForCompletion: false)
    var whistleBad = SKAction.playSoundFileNamed("whistle-bad.wav", waitForCompletion: false)
    var backgroundMusic: SKAudioNode = SKAudioNode(fileNamed: "gameplay.wav")
}


extension SKAction {
    class func shake(_ initialPosition: CGPoint, duration: Float, amplitudeX: Int = 20, amplitudeY: Int = 10) -> SKAction {
        let startingX = initialPosition.x
        let startingY = initialPosition.y
        let numberOfShakes = duration / 0.015
        var actionsArray:[SKAction] = []
        for _ in 1...Int(numberOfShakes) {
            let newXPos = startingX + CGFloat(arc4random_uniform(UInt32(amplitudeX))) - CGFloat(amplitudeX / 2)
            let newYPos = startingY + CGFloat(arc4random_uniform(UInt32(amplitudeY))) - CGFloat(amplitudeY / 2)
            actionsArray.append(SKAction.move(to: CGPointMake(newXPos, newYPos), duration: 0.015))
        }
        actionsArray.append(SKAction.move(to: initialPosition, duration: 0.015))
        return SKAction.sequence(actionsArray)
    }
}
