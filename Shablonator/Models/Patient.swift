//
//  Patient.swift
//  Shablonator
//
//  Created by Никита Долгов on 13.10.25.
//

import Foundation
import GRDB

struct Patient: Codable, Identifiable, Hashable {
    let id: Int64
    var firstName: String
    var lastName: String
    var phone: String?
    var email: String?
    var dateOfBirth: Date?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: Int64 = 0,
        firstName: String,
        lastName: String,
        phone: String? = nil,
        email: String? = nil,
        dateOfBirth: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.email = email
        self.dateOfBirth = dateOfBirth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Computed properties
    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    var displayPhone: String {
        guard let phone = phone, !phone.isEmpty else { return "Не указан" }

        // Форматирование российского номера +7 (999) 999-99-99
        let digits = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if digits.count == 11, digits.hasPrefix("7") {
            let index1 = digits.index(digits.startIndex, offsetBy: 1)
            let index2 = digits.index(digits.startIndex, offsetBy: 4)
            let index3 = digits.index(digits.startIndex, offsetBy: 7)
            let index4 = digits.index(digits.startIndex, offsetBy: 9)

            let code = String(digits[index1..<index2])
            let part1 = String(digits[index2..<index3])
            let part2 = String(digits[index3..<index4])
            let part3 = String(digits[index4...])

            return "+7 (\(code)) \(part1)-\(part2)-\(part3)"
        }

        return phone
    }

    var displayEmail: String {
        return email ?? "Не указан"
    }

    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }

    var displayAge: String {
        guard let age = age else { return "Не указан" }
        return "\(age) лет"
    }

    var initials: String {
        let firstInitial = String(firstName.prefix(1)).uppercased()
        let lastInitial = String(lastName.prefix(1)).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }

    var hasContactInfo: Bool {
        return (phone != nil && !phone!.isEmpty) || (email != nil && !email!.isEmpty)
    }
}

// MARK: - GRDB Record Conformance
extension Patient: FetchableRecord, MutablePersistableRecord {

    static let databaseTableName = "patient"

    init(row: Row) {
        id = row["id"]
        firstName = row["first_name"]
        lastName = row["last_name"]
        phone = row["phone"]
        email = row["email"]
        dateOfBirth = row["date_of_birth"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["first_name"] = firstName
        container["last_name"] = lastName
        container["phone"] = phone
        container["email"] = email
        container["date_of_birth"] = dateOfBirth
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }

    private mutating func willSave(_ db: Database) throws {
        updatedAt = Date()
    }
}

// MARK: - Database Queries
extension Patient {

    /// Получить всех пациентов, отсортированных по фамилии
    static func allSorted() -> QueryInterfaceRequest<Patient> {
        return Patient.all().order(Column("last_name"), Column("first_name"))
    }

    /// Поиск пациентов по имени, фамилии или телефону
    static func search(query: String) -> QueryInterfaceRequest<Patient> {
        let searchPattern = "%\(query)%"
        return Patient.filter(
            Column("first_name").like(searchPattern) ||
            Column("last_name").like(searchPattern) ||
            Column("phone").like(searchPattern)
        ).order(Column("last_name"), Column("first_name"))
    }

    /// Получить пациентов с контактной информацией
    static func withContactInfo() -> QueryInterfaceRequest<Patient> {
        return Patient.filter(
            (Column("phone") != nil && Column("phone") != "") ||
            (Column("email") != nil && Column("email") != "")
        ).order(Column("last_name"))
    }

    /// Получить пациентов по возрастной группе
    static func ageGroup(from minAge: Int, to maxAge: Int) -> QueryInterfaceRequest<Patient> {
        let calendar = Calendar.current
        let now = Date()
        let minDate = calendar.date(byAdding: .year, value: -maxAge, to: now)!
        let maxDate = calendar.date(byAdding: .year, value: -minAge, to: now)!

        return Patient.filter(Column("date_of_birth") >= minDate && Column("date_of_birth") <= maxDate)
            .order(Column("date_of_birth").desc)
    }

    /// Поиск по телефону
    static func findByPhone(_ phone: String) -> QueryInterfaceRequest<Patient> {
        let cleanPhone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Patient.filter(Column("phone").like("%\(cleanPhone)%"))
    }

    /// Получить недавно добавленных пациентов
    static func recent(limit: Int = 10) -> QueryInterfaceRequest<Patient> {
        return Patient.all()
            .order(Column("created_at").desc)
            .limit(limit)
    }
}

// MARK: - Mock Data для тестирования
extension Patient {
    static var mockData: [Patient] {
        let calendar = Calendar.current
        return [
            Patient(
                id: 1,
                firstName: "Анна",
                lastName: "Иванова",
                phone: "+7 (916) 123-45-67",
                email: "anna.ivanova@email.com",
                dateOfBirth: calendar.date(byAdding: .year, value: -28, to: Date())
            ),
            Patient(
                id: 2,
                firstName: "Петр",
                lastName: "Петров",
                phone: "+7 (916) 765-43-21",
                email: "petr.petrov@email.com",
                dateOfBirth: calendar.date(byAdding: .year, value: -35, to: Date())
            ),
            Patient(
                id: 3,
                firstName: "Мария",
                lastName: "Сидорова",
                phone: "+7 (916) 987-65-43",
                email: "maria.sidorova@email.com",
                dateOfBirth: calendar.date(byAdding: .year, value: -42, to: Date())
            ),
            Patient(
                id: 4,
                firstName: "Алексей",
                lastName: "Кузнецов",
                phone: "+7 (916) 345-67-89",
                email: nil,
                dateOfBirth: calendar.date(byAdding: .year, value: -25, to: Date())
            ),
            Patient(
                id: 5,
                firstName: "Елена",
                lastName: "Васильева",
                phone: nil,
                email: "elena.vasilieva@email.com",
                dateOfBirth: calendar.date(byAdding: .year, value: -39, to: Date())
            )
        ]
    }
}
