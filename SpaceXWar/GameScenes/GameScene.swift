//
//  GameScene.swift
//  SpaceXWar
//
//  Created by User on 12.04.2024.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let width = UIScreen.main.bounds.width
    let height = UIScreen.main.bounds.height
    let spaceShipCategory: Int32 = 0x1 << 0
    let asteroidCategory: Int32 = 0x1 << 1
    
    var spaceShip: SKSpriteNode!
    var score = 0
    var scoreLabel: SKLabelNode!
    var spaceBackground: SKSpriteNode!
    var asteroidLayer: SKNode!
    var starsLayer: SKNode!
    var gameIsPaused: Bool = false
    var spaceShipLayer: SKNode!
    var musicPlayer: AVAudioPlayer!
    
    var musicOn = true
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.8)
        
        scene?.size = UIScreen.main.bounds.size
        
        //size
        spaceBackground = SKSpriteNode(imageNamed: "spaceBackground")
        spaceBackground.size = CGSize(width: width + 50, height: height + 50)
        addChild(spaceBackground)
        
        //stars
        let starPath = Bundle.main.path(forResource: "Stars", ofType: "sks")
        let starsEmitter = NSKeyedUnarchiver.unarchiveObject(withFile: starPath!) as? SKEmitterNode
        
        starsEmitter?.zPosition = 1
        starsEmitter?.position = CGPoint(x: frame.midX, y: frame.height / 2)
        starsEmitter?.particlePositionRange.dx = frame.width
        starsEmitter?.advanceSimulationTime(10)
        
        starsLayer = SKNode()
        starsEmitter?.zPosition = 1
        addChild(starsLayer)
        
        starsLayer.addChild(starsEmitter!)
        
        //init node
        spaceShip = SKSpriteNode(imageNamed: "spaceShip")
        spaceShip.xScale = 0.08
        spaceShip.yScale = 0.08
        spaceShip.physicsBody = SKPhysicsBody(texture: spaceShip.texture!, size: spaceShip.size)
        spaceShip.physicsBody?.isDynamic = false
        
        spaceShip.physicsBody?.categoryBitMask = UInt32(spaceShipCategory)
        spaceShip.physicsBody?.collisionBitMask = UInt32(asteroidCategory)
        spaceShip.physicsBody?.contactTestBitMask = UInt32(asteroidCategory)
        
        let colorAction1 = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 1)
        let colorAction2 = SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 1)
        
        let colorSequenceAnimation = SKAction.sequence([colorAction1, colorAction2])
        let colorActionRepeat = SKAction.repeatForever(colorSequenceAnimation)
        
        spaceShip.run(colorActionRepeat)
        
        //addChild(spaceShip)
        
        //create layer for spaceship and fire
        spaceShipLayer = SKNode()
        spaceShipLayer.addChild(spaceShip)
        spaceShipLayer.zPosition = 3
        spaceShip.zPosition = 1
        spaceShipLayer.position = CGPoint(x: frame.midX, y: frame.height / 4)
        addChild(spaceShipLayer)
        
        //create fire
        let firePath =  Bundle.main.path(forResource: "Fire", ofType: "sks")
        let fireEmitter = NSKeyedUnarchiver.unarchiveObject(withFile: firePath!) as? SKEmitterNode
        fireEmitter?.zPosition = 0
        fireEmitter?.position.y = -40
        fireEmitter?.targetNode = self
        spaceShipLayer.addChild(fireEmitter!)
        
        //generation asteroid
        asteroidLayer = SKNode()
        asteroidLayer.zPosition = 2
        addChild(asteroidLayer)
        
        let asteroidCreate = SKAction.run {
            let asteroid = self.createAsteroid()
            self.addChild(asteroid)
            asteroid.zPosition = 2
        }
        let asteroidPerSecond: Double = 3
        let asteroidCreationDelay = SKAction.wait(forDuration: 1.0 / asteroidPerSecond, withRange: 0.5)
        let asteroidSequenceAction = SKAction.sequence([asteroidCreate, asteroidCreationDelay])
        let asteroidRunAction = SKAction.repeatForever(asteroidSequenceAction)
        
        self.asteroidLayer.run(asteroidRunAction)
        
        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.position = CGPoint(
            x: frame.size.width / scoreLabel.frame.size.width,
            y: 300
        )
        addChild(scoreLabel)
        
        spaceBackground.zPosition = 0
        scoreLabel.zPosition = 3
        
        playMusic()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameIsPaused {
            if let touch = touches.first {
                let touchLocation = touch.location(in: self)
                
                let distance = distanceCalc(a: spaceShip.position, b: touchLocation)
                let speed: CGFloat = 500
                let time = timeToTravelDistance(distance: distance, speed: speed)
                let moveAction = SKAction.move(to: touchLocation, duration: 1)
                moveAction.timingMode = SKActionTimingMode.easeInEaseOut
                
                spaceShipLayer.run(moveAction)
                
                let bgMoveAction = SKAction.move(to: CGPoint(x: -touchLocation.x / 100, y: -touchLocation.y / 100), duration: time)
                spaceBackground.run(bgMoveAction)
            }
        }
    }
    
    override func didSimulatePhysics() {
        enumerateChildNodes(withName: "asteroid") { (asteroid, stop) in
            let heightScreen = UIScreen.main.bounds.height
            if asteroid.position.y < -heightScreen {
                asteroid.removeFromParent()
                
                self.score = self.score + 1
                self.scoreLabel.text = "Score: \(self.score)"
            }
        }
    }
    
    func pauseTheGame() {
        gameIsPaused = true
        self.asteroidLayer.isPaused = true
        physicsWorld.speed = 0
        starsLayer.isPaused = true
        
        musicOnOrOff()
    }
    
    func unpauseTheGame() {
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
        starsLayer.isPaused = false
        
        musicOnOrOff()
    }
    
    func resetTheGame() {
        score = 0
        scoreLabel.text = "Score: \(score)"
        
        gameIsPaused = false
        self.asteroidLayer.isPaused = false
        physicsWorld.speed = 1
    }
    
    func distanceCalc(a: CGPoint, b: CGPoint) -> CGFloat {
        return sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
    }
    
    func timeToTravelDistance(distance: CGFloat, speed: CGFloat) -> TimeInterval {
        let time = distance / speed
        return TimeInterval(time)
    }
    
    func createAsteroid() -> SKSpriteNode {
        
        let asteroid = SKSpriteNode(imageNamed: "asteroid")
        let randomScale = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: 6)) / 10
        let asteroidSpeedX: CGFloat = 100.0
        
        asteroid.xScale = randomScale * 2
        asteroid.yScale = randomScale * 2
        
        asteroid.position.x = CGFloat(GKRandomSource.sharedRandom().nextInt(upperBound: Int(frame.size.height)))
        asteroid.position.y = frame.size.height + asteroid.size.height
        
        asteroid.physicsBody = SKPhysicsBody(texture: asteroid.texture!, size: asteroid.size)
        asteroid.name = "asteroid"
        
        asteroid.physicsBody?.categoryBitMask = UInt32(asteroidCategory)
        asteroid.physicsBody?.collisionBitMask = UInt32(spaceShipCategory)
        asteroid.physicsBody?.contactTestBitMask = UInt32(spaceShipCategory)
        
        asteroid.physicsBody?.angularVelocity = CGFloat(drand48() * 2 - 1) * 3
        asteroid.physicsBody?.velocity.dx = CGFloat(drand48() * 2 - 1) * asteroidSpeedX
        
        return asteroid
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("Contact!")
        
        if contact.bodyA.categoryBitMask == spaceShipCategory && contact.bodyB.categoryBitMask == asteroidCategory || contact.bodyB.categoryBitMask == spaceShipCategory && contact.bodyA.categoryBitMask == asteroidCategory {
            self.score = 0
            self.scoreLabel.text = "Score: \(self.score)"
        }
        
        let hitSoundAction = SKAction.playSoundFileNamed("HitSound", waitForCompletion: true)
        run(hitSoundAction)
    }
    
    func playMusic() {
        if let musicPath = Bundle.main.url(forResource: "PumpUpTheJam", withExtension: "mp3") {
            musicPlayer = try? AVAudioPlayer(contentsOf: musicPath, fileTypeHint: nil)
            musicOnOrOff()
        }
        
        musicPlayer.numberOfLoops = -1
        musicPlayer.volume = 0.5
    }
    
    func musicOnOrOff() {
        if musicOn {
            musicPlayer.play()
        } else {
            musicPlayer.stop()
        }
    }
}

