import SwiftUI
import SwiftData

@main
struct GlowLiftApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                WorkoutTemplate.self,
                WorkoutExerciseTemplate.self,
                ExerciseDefinition.self,
                WorkoutSession.self,
                ExerciseSession.self,
                SetEntry.self,
                StreakState.self,
                SpecialCircumstanceDay.self,
                ChatThread.self,
                ChatMessage.self,
                UserPreferences.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("GlowLift: Failed to create ModelContainer — \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    RestTimerManager.requestNotificationPermission()
                    // Seed default templates on first launch
                    let ctx = container.mainContext
                    DefaultTemplates.seedAll(context: ctx)
                }
        }
        .modelContainer(container)
    }
}
