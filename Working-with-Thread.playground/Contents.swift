import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

class Storage {
    private let condition = NSCondition()
    var storageForChip: [Chip] = []
    var availables = false

    func push(item: Chip) {
        condition.lock()
        print("\nPush начал работу")

        storageForChip.append(item)
        print("Чип добавлен в массив. Кол-во - \(storageForChip.count)")

        availables = true
        condition.signal()
        condition.unlock()
        print("Push закончил работу")
    }

    func pop() -> Chip {
        while (!availables) {
            condition.wait()
            print("ПОТОК ВОЗОБНОСИЛСЯ")

        }

        availables = false

        return storageForChip.removeLast()
    }
}

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
    }
}

class GeneratingThread: Thread {
    private let storage: Storage
    private var timer = Timer()

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(getChip),
                                     userInfo: nil, repeats: true)

        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 20))
    }

    @objc private func getChip() {
        storage.push(item: Chip.make())
    }
}

class WorkThread: Thread {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        repeat {
            storage.pop().sodering()
            print("Чип удален из массива. Кол-во - \(storage.storageForChip.count)")

        } while storage.storageForChip.isEmpty || storage.availables
    }
}

let storage = Storage()
let generatingThread = GeneratingThread(storage: storage)
let workThread = WorkThread(storage: storage)

generatingThread.start()
workThread.start()
