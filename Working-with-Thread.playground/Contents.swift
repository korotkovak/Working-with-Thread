import Foundation

//Это нужно просто для подсчета и для принтов
var numberOfChipsAdded = 0
var numberOfChipsRemoved = 0
var numberOfSolderedChips = 0

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
        numberOfSolderedChips += 1
        print("Количество припаянных чипов - \(numberOfSolderedChips)")
    }
}

class Storage {
    private let condition = NSCondition()
    private var storageForChip: [Chip] = []
    var isAvailables = false

    var isEmpty: Bool {
        storageForChip.isEmpty
    }

    func push(item: Chip) {
        condition.lock()
        storageForChip.append(item)

        numberOfChipsAdded += 1
        print("\nКол-во созданных чипов - \(numberOfChipsAdded)")

        isAvailables = true
        condition.signal()
        condition.unlock()
    }

    func pop() -> Chip {
        condition.lock()

        while (!isAvailables) {
            condition.wait()
        }

        let chip = storageForChip.removeLast()

        if isEmpty {
            isAvailables = false
        }

        condition.unlock()
        return chip
    }
}

class GeneratingThread: Thread {
    private let storage: Storage
    private var timer = Timer()

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        timer = Timer.scheduledTimer(timeInterval: 2,
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
            let chip = storage.pop()
            numberOfChipsRemoved += 1
            print("Кол-во удаленных чипов из массива - \(numberOfChipsRemoved)")
            chip.sodering()

        } while storage.isEmpty || storage.isAvailables
    }
}

let storage = Storage()
let generatingThread = GeneratingThread(storage: storage)
let workThread = WorkThread(storage: storage)

generatingThread.start()
workThread.start()

sleep(20)
generatingThread.cancel()
