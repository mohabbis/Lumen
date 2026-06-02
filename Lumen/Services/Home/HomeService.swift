import Foundation
import SwiftData
import Observation

// MARK: - Home Service
// Owns all home/room CRUD. The only place modelContext is touched for spatial entities.

@MainActor
@Observable
final class HomeService {

    private let modelContext: ModelContext
    private(set) var primaryHome: Home?
    private(set) var isLoaded = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Bootstrap

    func load() throws {
        let descriptor = FetchDescriptor<Home>(
            predicate: #Predicate { $0.isPrimary == true },
            sortBy: [SortDescriptor(\Home.createdAt)]
        )
        let primaries = try modelContext.fetch(descriptor)
        primaryHome = primaries.first

        // Fallback: if no primary is flagged, promote the first home found.
        if primaryHome == nil {
            let all = try fetchAllHomes()
            if let first = all.first {
                first.isPrimary = true
                try modelContext.save()
                primaryHome = first
            }
        }
        isLoaded = true
    }

    // MARK: - Home CRUD

    @discardableResult
    func createHome(name: String, street: String? = nil, city: String? = nil) throws -> Home {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidConfiguration(reason: "Home name cannot be empty.")
        }
        let home = Home(
            name: cleaned,
            street: street,
            city: city,
            isPrimary: primaryHome == nil
        )
        modelContext.insert(home)
        try modelContext.save()
        if primaryHome == nil { primaryHome = home }
        return home
    }

    func setPrimary(home: Home) throws {
        let all = try fetchAllHomes()
        for h in all { h.isPrimary = false }
        home.isPrimary = true
        primaryHome = home
        try modelContext.save()
    }

    func updateHome(_ home: Home, name: String) throws {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidConfiguration(reason: "Home name cannot be empty.")
        }
        home.name = cleaned
        home.updatedAt = Date()
        try modelContext.save()
    }

    func deleteHome(_ home: Home) throws {
        let wasPrimary = home.isPrimary
        modelContext.delete(home)
        try modelContext.save()

        if wasPrimary {
            let remaining = try fetchAllHomes()
            if let next = remaining.first {
                next.isPrimary = true
                try modelContext.save()
                primaryHome = next
            } else {
                primaryHome = nil
            }
        }
    }

    // MARK: - Room CRUD

    @discardableResult
    func addRoom(
        to home: Home,
        name: String,
        type: RoomType,
        level: Int? = nil,
        isAccessible: Bool = true
    ) throws -> Room {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidConfiguration(reason: "Room name cannot be empty.")
        }
        let room = Room(name: cleaned, type: type, level: level, isAccessible: isAccessible)
        room.home = home
        home.rooms.append(room)
        home.updatedAt = Date()
        try modelContext.save()
        return room
    }

    func updateRoom(_ room: Room, name: String? = nil, type: RoomType? = nil, level: Int? = nil) throws {
        if let name {
            let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                throw AppError.invalidConfiguration(reason: "Room name cannot be empty.")
            }
            room.name = cleaned
        }
        if let type { room.type = type }
        if let level { room.level = level }
        room.updatedAt = Date()
        try modelContext.save()
    }

    func deleteRoom(_ room: Room) throws {
        modelContext.delete(room)
        try modelContext.save()
    }

    // MARK: - Private

    private func fetchAllHomes() throws -> [Home] {
        let descriptor = FetchDescriptor<Home>(
            sortBy: [SortDescriptor(\Home.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }
}
