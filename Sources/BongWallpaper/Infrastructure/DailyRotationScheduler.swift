import Foundation

@MainActor
final class DailyRotationScheduler {
    private var timer: Timer?

    func start(interval: TimeInterval = 1800, action: @escaping @Sendable () -> Void) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
