import SwiftUI
import Foundation
import MapKit
import CoreLocation

struct UserLocation: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var name: String
}

enum UserRole: String, Codable {
    case patient
    case doctor
}


enum ValidationError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let value):
            return value
        }
    }
}

enum AppValidator {
    static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizedPhone(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    static func validatePersonName(_ value: String, fieldName: String) throws -> String {
        let clean = trimmed(value)
        guard !clean.isEmpty else {
            throw ValidationError.message("Please enter your \(fieldName.lowercased()).")
        }

        let allowed = CharacterSet.letters.union(.whitespaces).union(CharacterSet(charactersIn: "-'") )
        guard clean.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw ValidationError.message("\(fieldName) must contain only letters.")
        }

        return clean
    }

    static func validateEmail(_ value: String) throws -> String {
        let clean = trimmed(value).lowercased()
        guard !clean.isEmpty else {
            throw ValidationError.message("Please enter your email address.")
        }
        guard clean.contains("@"), clean.contains(".") else {
            throw ValidationError.message("Please enter a valid email address.")
        }
        return clean
    }

    static func validateAge(_ value: String, min: Int, max: Int) throws -> Int {
        let clean = trimmed(value)
        guard let age = Int(clean), age >= min, age <= max else {
            throw ValidationError.message("Please enter a valid age between \(min) and \(max).")
        }
        return age
    }

    static func validatePhone(_ value: String) throws -> String {
        let digits = normalizedPhone(value)
        guard digits.count == 10 else {
            throw ValidationError.message("Phone number must contain exactly 10 digits.")
        }
        guard digits.hasPrefix("05") || digits.hasPrefix("06") || digits.hasPrefix("07") else {
            throw ValidationError.message("Phone number must start with 05, 06, or 07.")
        }
        return digits
    }

    static func validateLicense(_ value: String) throws -> String {
        let clean = trimmed(value)
        guard clean.count >= 6 else {
            throw ValidationError.message("License number is too short.")
        }
        return clean
    }

    static func validatePrice(_ value: String) throws -> Int {
        let clean = trimmed(value)
        guard let price = Int(clean), price >= 500, price <= 50000 else {
            throw ValidationError.message("Consultation price must be between 500 DA and 50000 DA.")
        }
        return price
    }

    static func validateRequiredText(_ value: String, fieldName: String) throws -> String {
        let clean = trimmed(value)
        guard !clean.isEmpty else {
            throw ValidationError.message("Please enter your \(fieldName.lowercased()).")
        }
        return clean
    }

    static func validateAvailableTimes(_ value: String) throws -> [String] {
        let rawValues = value
            .split(separator: ",")
            .map { trimmed(String($0)) }
            .filter { !$0.isEmpty }

        guard !rawValues.isEmpty else {
            throw ValidationError.message("Please enter at least one available time.")
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard rawValues.allSatisfy({ formatter.date(from: $0) != nil }) else {
            throw ValidationError.message("Times must use the HH:mm format, for example 09:00, 14:30.")
        }

        return Array(NSOrderedSet(array: rawValues)) as? [String] ?? rawValues
    }
}


struct UserProfile: Codable, Equatable {
    var firstName: String
    var lastName: String
    var phone: String
    var age: Int
    var email: String

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}

struct Doctor: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var ownerUID: String? = nil
    var firstName: String
    var lastName: String
    var specialty: String
    var rating: Double
    var reviews: Int
    var experience: Int
    var sex: String
    var image: String
    var price: Int
    var hospital: String
    var location: String
    var phone: String
    var license: String
    var bio: String
    var availableTimes: [String]
    var serviceType: String = "clinic"

    var name: String {
        "Dr. \(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var displayLocation: String {
        "\(hospital), \(location)"
    }
}

struct DoctorDraft {
    var firstName: String = ""
    var lastName: String = ""
    var phone: String = ""
    var age: String = ""
    var specialty: String = ""
    var license: String = ""
    var price: String = ""
    var hospital: String = ""
    var location: String = ""
    var bio: String = ""
    var availableTimesText: String = ""
    var sex: String = "Homme"
    var image: String = "stethoscope"
    var serviceType: String = "clinic"

    init() {}

    init(doctor: Doctor) {
        firstName = doctor.firstName
        lastName = doctor.lastName
        phone = doctor.phone
        age = String(doctor.experience + 25)
        specialty = doctor.specialty
        license = doctor.license
        price = String(doctor.price)
        hospital = doctor.hospital
        location = doctor.location
        bio = doctor.bio
        availableTimesText = doctor.availableTimes.joined(separator: ", ")
        sex = doctor.sex
        image = doctor.image
    }

    func toDoctor(existingID: UUID? = nil, rating: Double = 4.8, reviews: Int = 0) throws -> Doctor {
        let validatedAge = try AppValidator.validateAge(age, min: 25, max: 89)

        return Doctor(
            id: existingID ?? UUID(),
            ownerUID: nil,
            firstName: try AppValidator.validatePersonName(firstName, fieldName: "First name"),
            lastName: try AppValidator.validatePersonName(lastName, fieldName: "Last name"),
            specialty: try AppValidator.validateRequiredText(specialty, fieldName: "Specialty"),
            rating: rating,
            reviews: reviews,
            experience: max(validatedAge - 25, 1),
            sex: sex,
            image: image,
            price: try AppValidator.validatePrice(price),
            hospital: try AppValidator.validateRequiredText(hospital, fieldName: "Hospital"),
            location: try AppValidator.validateRequiredText(location, fieldName: "Location"),
            phone: try AppValidator.validatePhone(phone),
            license: try AppValidator.validateLicense(license),
            bio: try AppValidator.validateRequiredText(bio, fieldName: "Bio"),
            availableTimes: try AppValidator.validateAvailableTimes(availableTimesText)
        )
    }
}

struct UserProfileDraft {
    var firstName: String = ""
    var lastName: String = ""
    var phone: String = ""
    var age: String = ""
    var email: String = ""

    init() {}

    init(profile: UserProfile) {
        firstName = profile.firstName
        lastName = profile.lastName
        phone = profile.phone
        age = String(profile.age)
        email = profile.email
    }

    func toUserProfile() throws -> UserProfile {
        UserProfile(
            firstName: try AppValidator.validatePersonName(firstName, fieldName: "First name"),
            lastName: try AppValidator.validatePersonName(lastName, fieldName: "Last name"),
            phone: try AppValidator.validatePhone(phone),
            age: try AppValidator.validateAge(age, min: 1, max: 120),
            email: try AppValidator.validateEmail(email)
        )
    }
}


struct Appointment: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var doctor: Doctor
    var doctorUID: String
    var patientUID: String
    var patientName: String
    var patientEmail: String
    var date: Date
    var time: String
    var status: AppointmentStatus
    var userLocation: UserLocation?
    var createdAt: Date = Date()
    var statusChangedAt: Date?
    
    

    enum CodingKeys: String, CodingKey {
        case id, doctor, doctorUID, patientUID, patientName, patientEmail, date, time, status, createdAt, statusChangedAt
        case userLocation
    }
       
    init(
        id: UUID = UUID(),
        doctor: Doctor,
        doctorUID: String,
        patientUID: String,
        patientName: String,
        patientEmail: String,
        date: Date,
        time: String,
        status: AppointmentStatus,
        userLocation: UserLocation? = nil,
        createdAt: Date = Date(),
        statusChangedAt: Date? = nil
    ) {
        self.id = id
        self.doctor = doctor
        self.doctorUID = doctorUID
        self.patientUID = patientUID
        self.patientName = patientName
        self.patientEmail = patientEmail
        self.date = date
        self.time = time
        self.status = status
        self.createdAt = createdAt
        self.statusChangedAt = statusChangedAt
        self.userLocation = userLocation
    }
}

enum AppointmentStatus: String, Codable {
    case pending
    case approved
    case rejected
    

    var label: String {
        switch self {
        case .pending: return "En attente"
        case .approved: return "Accepté"
        case .rejected: return "Refusé"
        
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}


extension Color {
    static let medPrimary = Color(red: 0.05, green: 0.45, blue: 0.85)
    static let medSecondary = Color(red: 0.10, green: 0.72, blue: 0.65)
    static let medBackground = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let medCard = Color.white
    static let medText = Color(red: 0.10, green: 0.12, blue: 0.20)
    static let medSubtext = Color(red: 0.45, green: 0.50, blue: 0.60)
}
struct LocationModel: Codable, Equatable {
    var latitude: Double
    var longitude: Double
}
