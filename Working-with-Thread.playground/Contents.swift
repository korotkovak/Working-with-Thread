import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let condition = NSCondition()
var availables = false
var storageForChip: [Chip] = []

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
    override func main() {
        for _ in 1...10 {
            condition.lock()

            storageForChip.append(Chip.make())
            availables = true

            condition.signal()
            condition.unlock()

            Thread.sleep(forTimeInterval: 2)
        }
    }
}

class WorkThread: Thread {
    override func main() {
        for _ in 1...10 {

            while(!availables) {
                condition.wait()
            }

            if let chip = storageForChip.first {
                chip.sodering()
                storageForChip.removeFirst()
            }

            if storageForChip.count < 1 {
                availables = false
            }
        }
    }
}

let generatingThread = GeneratingThread()
generatingThread.start()

let workThread = WorkThread()
workThread.start()
