import HealthKit

struct PickerSettings {
    let min: Double
    let max: Double
    let step: Double
}

enum PickerGenerator {
    static func generatePickerValues(setting: PickerSettings, units: HKUnit, roundedFormat: String = "%.1f") -> [Double] {
        var values: [Double] = []
        var currentValue = setting.min

        while currentValue <= setting.max {
            values.append(currentValue)
            currentValue += setting.step
        }

        // Glucose values are stored as mg/dl values, so Integers.
        // Filter out duplicate values when rounded to 1 decimal place.
        if units == .millimolesPerLiter {
            // Use a Set to track unique values rounded to 1 decimal
            var uniqueRoundedValues = Set<String>()
            values = values.filter { value in
                let mmollValue = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: value)
                let roundedValue = String(format: roundedFormat, mmollValue.doubleValue(for: .millimolesPerLiter))
                return uniqueRoundedValues.insert(roundedValue).inserted
            }
        }

        return values
    }
}
