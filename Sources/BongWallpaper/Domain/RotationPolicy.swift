import Foundation

struct RotationPolicy {
    func shouldAutoRotate(rotateDaily: Bool, hasAutoRotatedToday: Bool) -> Bool {
        rotateDaily && !hasAutoRotatedToday
    }
}
