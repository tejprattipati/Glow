import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: Tab = .home
    @ObservedObject private var timerManager = RestTimerManager.shared

    enum Tab: String, CaseIterable {
        case home      = "Home"
        case train     = "Train"
        case history   = "History"
        case progress  = "Progress"
        case chat      = "Chat"
        case templates = "Templates"

        var icon: String {
            switch self {
            case .home:      return "house.fill"
            case .train:     return "dumbbell.fill"
            case .history:   return "calendar"
            case .progress:  return "chart.line.uptrend.xyaxis"
            case .chat:      return "bubble.left.and.bubble.right.fill"
            case .templates: return "list.bullet.clipboard.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label(Tab.home.rawValue, systemImage: Tab.home.icon) }
                    .tag(Tab.home)

                TrainTabView()
                    .tabItem { Label(Tab.train.rawValue, systemImage: Tab.train.icon) }
                    .tag(Tab.train)

                HistoryView()
                    .tabItem { Label(Tab.history.rawValue, systemImage: Tab.history.icon) }
                    .tag(Tab.history)

                ProgressView()
                    .tabItem { Label(Tab.progress.rawValue, systemImage: Tab.progress.icon) }
                    .tag(Tab.progress)

                ChatView()
                    .tabItem { Label(Tab.chat.rawValue, systemImage: Tab.chat.icon) }
                    .tag(Tab.chat)

                TemplateEditorView()
                    .tabItem { Label(Tab.templates.rawValue, systemImage: Tab.templates.icon) }
                    .tag(Tab.templates)
            }
            .tint(GlowTheme.Colors.purple)
            .onAppear { configureTabBarAppearance() }

            // Global floating timer — shown on all tabs
            if timerManager.isVisible {
                VStack {
                    FloatingRestTimerBar(timer: timerManager)
                    Spacer()
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(GlowTheme.Colors.surface)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(GlowTheme.Colors.textMuted)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(GlowTheme.Colors.purple)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(GlowTheme.Colors.textMuted)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(GlowTheme.Colors.purple)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Train Tab (quick-start standalone)
struct TrainTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showPicker = false
    @State private var activeSession: WorkoutSession?

    private var suggested: WorkoutType {
        WorkoutSequencer.suggestedNext(after: sessions.first { $0.isCompleted })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                VStack(spacing: GlowTheme.Spacing.xl) {
                    Spacer()

                    // Big start button
                    VStack(spacing: GlowTheme.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(GlowTheme.Colors.purple.opacity(0.15))
                                .frame(width: 140, height: 140)
                                .blur(radius: 12)
                            Circle()
                                .fill(GlowTheme.Colors.gradientPurple)
                                .frame(width: 110, height: 110)
                            Image(systemName: "play.fill")
                                .font(.system(size: 44, weight: .black))
                                .foregroundColor(.white)
                        }
                        .glowEffect(radius: 24, intensity: 1.2)
                        .onTapGesture { startSuggested() }

                        VStack(spacing: 6) {
                            Text("Start \(suggested.rawValue)")
                                .font(GlowTheme.Fonts.headline(22))
                                .foregroundColor(.white)
                            Text(suggested.focus)
                                .font(GlowTheme.Fonts.body())
                                .foregroundColor(GlowTheme.Colors.textSecondary)
                        }
                    }

                    GlowButton(
                        title: "Choose Different Workout",
                        icon: "list.bullet",
                        action: { showPicker = true },
                        style: .ghost
                    )
                    .frame(width: 260)

                    Spacer()
                }
                .padding(.horizontal, GlowTheme.Spacing.xl)
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPicker) {
                WorkoutSelectionView(activeSession: $activeSession)
            }
            .navigationDestination(item: $activeSession) { session in
                ActiveWorkoutView(session: session)
            }
        }
    }

    private func startSuggested() {
        guard let template = WorkoutSequencer.template(for: suggested, context: context) else { return }
        activeSession = WorkoutSequencer.createSession(from: template, context: context)
    }
}
