import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatThread.updatedAt, order: .reverse) private var threads: [ChatThread]
    @Query(sort: \WorkoutSession.completedAt, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showNewThread = false
    @State private var selectedThread: ChatThread?

    var body: some View {
        NavigationStack {
            ZStack {
                GlowTheme.Colors.gradientBackground.ignoresSafeArea()

                if threads.isEmpty {
                    emptyState
                } else {
                    threadList
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewThread) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(GlowTheme.Colors.purple)
                    }
                }
            }
            .navigationDestination(item: $selectedThread) { thread in
                ChatThreadView(thread: thread, recentSessions: Array(sessions.prefix(5)))
            }
        }
        .onAppear { createDefaultThreadIfNeeded() }
    }

    private var threadList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GlowTheme.Spacing.sm) {
                ForEach(threads) { thread in
                    threadCard(thread)
                        .onTapGesture { selectedThread = thread }
                }
                Spacer(minLength: 80)
            }
            .padding(.horizontal, GlowTheme.Spacing.md)
            .padding(.top, GlowTheme.Spacing.md)
        }
    }

    private func threadCard(_ thread: ChatThread) -> some View {
        GlowCard(glowColor: GlowTheme.Colors.purple, glowIntensity: 0.3) {
            HStack(spacing: GlowTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(GlowTheme.Colors.purple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18))
                        .foregroundColor(GlowTheme.Colors.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(thread.title)
                            .font(GlowTheme.Fonts.subheadline())
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if thread.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundColor(GlowTheme.Colors.accent)
                        }
                    }
                    Text(thread.previewText)
                        .font(GlowTheme.Fonts.caption())
                        .foregroundColor(GlowTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(thread.updatedAt, style: .relative)
                        .font(GlowTheme.Fonts.caption(10))
                        .foregroundColor(GlowTheme.Colors.textTertiary)
                    Text("\(thread.messageCount)")
                        .font(GlowTheme.Fonts.caption(10))
                        .foregroundColor(GlowTheme.Colors.textMuted)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                context.delete(thread)
                try? context.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: GlowTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(GlowTheme.Colors.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 44))
                    .foregroundColor(GlowTheme.Colors.purple)
            }
            .glowEffect(radius: 20)

            Text("Your AI Coach")
                .font(GlowTheme.Fonts.headline(22))
                .foregroundColor(.white)

            Text("Ask anything about your training,\nprogressions, or next steps.")
                .font(GlowTheme.Fonts.body())
                .foregroundColor(GlowTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            GlowButton(title: "Start Chatting", icon: "arrow.right") {
                createNewThread()
            }
            .frame(width: 200)
        }
    }

    private func createNewThread() {
        let thread = ChatThread(title: "GlowLift Coach")
        context.insert(thread)
        try? context.save()
        selectedThread = thread
    }

    private func createDefaultThreadIfNeeded() {
        guard threads.isEmpty else { return }
        let thread = ChatThread(title: "GlowLift Coach")
        context.insert(thread)
        try? context.save()
    }
}
