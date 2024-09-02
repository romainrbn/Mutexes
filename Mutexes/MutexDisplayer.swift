//
//  MutexDisplayer.swift
//  Mutexes
//
//  Created by Romain Rabouan on 02/09/2024.
//

import Foundation
import Synchronization

final class MutexDisplayer: ObservableObject {
    @Published var results: [String] = []
    @Published var isLoading: Bool = false

    private var task: Task<Void, Never>?

    let numberOfTasks: Int              = 10
    let numberOfItems: Int              = 1_000_000

    enum AlgorithmMethod: String {
        case actor = "Actor"
        case mutex = "Mutex"
        case nsLock = "NSLock"
    }

    let methods: [AlgorithmMethod] = [.actor, .nsLock, .mutex]

    func buttonAction() {
        if task?.isCancelled == false {
            task?.cancel()
        }

        task = Task { [weak self] in
            guard Task.isCancelled == false else { return }
            await self?.runAlgorithms()
        }
    }

    // MARK: - Main

    private func runAlgorithms() async {
        await MainActor.run {
            isLoading = true
            results.removeAll()
        }
        let lockAlgorithm = FifoWithNSLock()
        let actorAlgorithm = FifoWithActor()
        let mutexAlgorithm = FifoWithMutex()

        for method in methods {
            let timeBegin = CFAbsoluteTimeGetCurrent()

            await withTaskGroup(of: Int.self) { group in
                for _ in 0..<numberOfTasks {
                    group.addTask { [weak self] in
                        guard let self else { return 0 }
                        for i in 0..<numberOfItems {
                            switch method {
                            case .nsLock:
                                lockAlgorithm.enqueue(item: i)
                            case .actor:
                                await actorAlgorithm.enqueue(item: i)
                            case .mutex:
                                mutexAlgorithm.enqueue(item: i)
                            }
                        }
                        return 0
                    }
                }
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - timeBegin
            await MainActor.run {
                results.append("\(method.rawValue): elapsed time = \(elapsed) seconds")
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - NSLock

final class FifoWithNSLock: @unchecked Sendable {
    private var storage: Int = 0
    private let lock = NSLock()

    init() { }

    func enqueue(item: Int) {
        lock.withLock {
            storage += 1
        }
    }
}

// MARK: - Actor

actor FifoWithActor {
    private var storage: Int = 0

    func enqueue(item: Int) {
        storage += 1
    }
}

// MARK: - Mutex

final class FifoWithMutex: @unchecked Sendable {
    private let _storage = Mutex<Int>(0)

    init() { }

    func enqueue(item: Int) {
        _storage.withLock { storage in
            storage += 1
        }
    }
}
