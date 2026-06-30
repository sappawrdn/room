//
//  EntityBrain.swift
//  room
//


import RealityKit
import simd

class EntityBrain {
    enum State {
        case static_
        case watcher
        case hunter
    }

    weak var monster: ModelEntity?
    var playerPos: SIMD3<Float> = .zero
    var roomSize: Float = 20

    var watcherSpawnPoints: [SIMD3<Float>] = []
    var watcherCloseRange: Float = 5
    var lastWatcherWasClose = false

    private(set) var state: State = .static_

    private var watcherTimer: Float = 0
    private let watcherInterval: Float = 4
    private let hunterSpeed: Float = 1.6

    // Stun (abis QTE proximity sukses): entity diem sebentar
    private var stunTimer: Float = 0
    var isStunned: Bool { stunTimer > 0 }
    func stun(seconds: Float) { stunTimer = seconds }

    func start() {
        if watcherSpawnPoints.isEmpty { generateDefaultSpawnPoints() }
        enter(.static_)
    }

    func update(monster: ModelEntity, playerPos: SIMD3<Float>, dt: Float) {
        self.monster = monster
        self.playerPos = playerPos
        
        if stunTimer > 0 {
                    stunTimer -= dt
                    return   
                }

        switch state {
        case .static_:
            break
        case .watcher:
            watcherTimer += dt
            if watcherTimer > watcherInterval {
                watcherTimer = 0
                watcherAppear()
            }
        case .hunter:
            hunterChase(dt: dt)
        }
    }

    // Pindah state + aksi pas masuk state (ganti didEnter)
    private func enter(_ newState: State) {
        state = newState
        switch newState {
        case .static_:
            break
        case .watcher:
            watcherTimer = 0
            watcherAppear()
        case .hunter:
            break
        }
    }

    // Dipicu pas ambil kunci (1 dipegang + 2 dicari = total 3)
    func onKeyCollected(totalKeys: Int) {
        if totalKeys >= 3 {
            enter(.hunter)
        } else if totalKeys >= 2 {
            enter(.watcher)
        }
    }

    // SEMENTARA buat testing: muter Static -> Watcher -> Hunter -> Static
    func debugCycle() {
        switch state {
        case .static_: enter(.watcher)
        case .watcher: enter(.hunter)
        case .hunter: enter(.static_)
        }
    }

    var currentStateName: String {
        switch state {
        case .static_: return "STATIC"
        case .watcher: return "WATCHER"
        case .hunter: return "HUNTER"
        }
    }

    private func watcherAppear() {
        guard let monster = monster,
              let point = watcherSpawnPoints.randomElement() else { return }
        monster.position = point

        let to = SIMD3<Float>(playerPos.x - point.x, 0, playerPos.z - point.z)
        let dist = length(to)
        if dist > 0.001 {
            let yaw = atan2(to.x, to.z)
            monster.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        }
        lastWatcherWasClose = dist < watcherCloseRange
    }

    // HUNTER: ngejar pemain
    private func hunterChase(dt: Float) {
        guard let monster = monster else { return }
        let to = SIMD3<Float>(playerPos.x - monster.position.x, 0,
                              playerPos.z - monster.position.z)
        let d = length(to)
        if d > 0.4 {
            let dir = to / d
            var mp = monster.position + dir * hunterSpeed * dt
            mp.y = 0
            monster.position = mp
        }
    }

    private func generateDefaultSpawnPoints() {
        let half = roomSize / 2
        let inset: Float = 0.8
        let perWall = 4
        let spread = roomSize - 4
        var pts: [SIMD3<Float>] = []
        for i in 0..<perWall {
            let t = Float(i) / Float(perWall - 1)
            let along = -spread / 2 + spread * t
            pts.append([along, 0, -half + inset])
            pts.append([along, 0, half - inset])
            pts.append([-half + inset, 0, along])
            pts.append([half - inset, 0, along])
        }
        watcherSpawnPoints = pts
    }
}
