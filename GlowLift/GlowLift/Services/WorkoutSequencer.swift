import Foundation
import SwiftData

// MARK: - Workout Sequencer
// Determines the next suggested workout based on the last completed session.
// No weekday dependency — purely sequence-based.

final class WorkoutSequencer {

    // Returns the suggested next workout type given the last completed session.
    static func suggestedNext(after lastSession: WorkoutSession?) -> WorkoutType {
        guard let last = lastSession else {
            return .pushA   // First time: start with Push A
        }
        return last.type.next
    }

    // Fetches the most recent completed session
    static func lastCompletedSession(context: ModelContext) -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // Fetches all completed sessions, most recent first
    static func allSessions(context: ModelContext) -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // Fetches last completed session of a specific type
    static func lastSession(
        for type: WorkoutType,
        context: ModelContext
    ) -> WorkoutSession? {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.workoutType == typeRaw && $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    // Fetches last ExerciseSession for a given exercise name
    static func lastExerciseSession(
        named name: String,
        context: ModelContext
    ) -> ExerciseSession? {
        // Fetch all exercise sessions with that name, from completed workouts
        let descriptor = FetchDescriptor<ExerciseSession>(
            predicate: #Predicate { $0.exerciseName == name },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []
        // Filter to only those from completed workout sessions
        return sessions.first { $0.workoutSession?.isCompleted == true }
    }

    // Returns the template for a given workout type
    static func template(
        for type: WorkoutType,
        context: ModelContext
    ) -> WorkoutTemplate? {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            predicate: #Predicate { $0.workoutType == typeRaw }
        )
        return (try? context.fetch(descriptor))?.first
    }

    // Creates a new WorkoutSession from a template
    static func createSession(
        from template: WorkoutTemplate,
        context: ModelContext
    ) -> WorkoutSession {
        let session = WorkoutSession(
            workoutType: template.type,
            workoutName: template.name
        )
        session.exercises = template.sortedExercises.enumerated().map { idx, ex in
            let es = ExerciseSession(
                exerciseName: ex.exerciseName,
                exerciseCategory: ex.category,
                orderIndex: idx
            )
            es.workoutSession = session
            return es
        }
        context.insert(session)
        return session
    }
}
