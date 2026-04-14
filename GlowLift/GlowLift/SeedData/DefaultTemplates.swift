import Foundation
import SwiftData

// MARK: - Default Workout Templates

struct DefaultTemplates {

    static func seedAll(context: ModelContext) {
        // Check if already seeded
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for template in allTemplates() {
            context.insert(template)
        }

        // Seed streak state if needed
        let streakDesc = FetchDescriptor<StreakState>()
        let streaks = (try? context.fetch(streakDesc)) ?? []
        if streaks.isEmpty {
            context.insert(StreakState())
        }

        // Seed preferences if needed
        let prefDesc = FetchDescriptor<UserPreferences>()
        let prefs = (try? context.fetch(prefDesc)) ?? []
        if prefs.isEmpty {
            context.insert(UserPreferences())
        }

        try? context.save()
    }

    static func allTemplates() -> [WorkoutTemplate] {
        [pushA(), pullA(), legsA(), pushB(), pullB(), legsB()]
    }

    // MARK: Push A — Chest Emphasis
    static func pushA() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .pushA, name: "Push A — Chest Emphasis")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Flat Machine Press / Barbell Bench", .chestPress, 0),
            ("Incline Dumbbell Press",             .inclinePress, 1),
            ("Pec Deck / Cable Fly",               .fly, 2),
            ("Seated DB / Machine Shoulder Press", .shoulderPress, 3),
            ("Cable Lateral Raise",                .lateralRaise, 4),
            ("Triceps Pressdown",                  .triceps, 5)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }

    // MARK: Pull A — Lat + Upper Back
    static func pullA() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .pullA, name: "Pull A — Lat + Upper Back")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Pull-Ups / Lat Pulldown",             .pulldown, 0),
            ("Chest-Supported Row",                 .row, 1),
            ("One-Arm Cable Row / Machine High Row",.row, 2),
            ("Rear Delt Fly",                       .rearDelt, 3),
            ("Face Pull / Reverse Pec Deck",        .rearDelt, 4),
            ("Incline Dumbbell Curl",               .curl, 5),
            ("Hammer Curl",                         .curl, 6)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }

    // MARK: Legs A
    static func legsA() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .legsA, name: "Legs A")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Leg Press / Hack Squat",         .legPress, 0),
            ("Seated Leg Curl",                .legCurl, 1),
            ("Romanian Deadlift / DB RDL",     .rdl, 2),
            ("Leg Extension",                  .legPress, 3),
            ("Calf Raises",                    .calfRaise, 4),
            ("Hanging Leg Raises / Cable Crunch", .abs, 5)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }

    // MARK: Push B — Upper Chest / Shoulder Support
    static func pushB() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .pushB, name: "Push B — Upper Chest / Shoulder")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Incline Machine / Smith Incline Press",   .inclinePress, 0),
            ("Flat DB Press / Converging Machine Press",.chestPress, 1),
            ("Cable Fly (Low-to-High)",                 .fly, 2),
            ("Lateral Raise Variation",                 .lateralRaise, 3),
            ("Overhead Triceps Extension",              .triceps, 4),
            ("Machine Shoulder Press (Optional)",       .shoulderPress, 5)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }

    // MARK: Pull B — Back Thickness
    static func pullB() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .pullB, name: "Pull B — Back Thickness")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Chest-Supported T-Bar Row / Machine Row", .row, 0),
            ("Neutral-Grip Pulldown",                   .pulldown, 1),
            ("Seated Cable Row",                        .row, 2),
            ("Rear Delt Fly",                           .rearDelt, 3),
            ("Shrug / Upper Back Machine Row",          .shrug, 4),
            ("Preacher Curl / Cable Curl",              .curl, 5),
            ("Hammer Curl",                             .curl, 6)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }

    // MARK: Legs B
    static func legsB() -> WorkoutTemplate {
        let t = WorkoutTemplate(workoutType: .legsB, name: "Legs B")
        let exercises: [(String, ExerciseCategory, Int)] = [
            ("Hack Squat / Smith Squat Machine",    .squat, 0),
            ("Lying / Seated Leg Curl",             .legCurl, 1),
            ("Bulgarian Split Squat / Walking Lunge", .squat, 2),
            ("RDL / Hip Hinge Machine",             .rdl, 3),
            ("Calf Raises",                         .calfRaise, 4),
            ("Abs",                                 .abs, 5)
        ]
        t.exercises = exercises.map { name, cat, idx in
            WorkoutExerciseTemplate(exerciseName: name, exerciseCategory: cat, orderIndex: idx)
        }
        return t
    }
}
