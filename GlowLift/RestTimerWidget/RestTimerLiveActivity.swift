import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            lockScreenBanner(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                compactLeadingView
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                minimalView
            }
            .keylineTint(.green)
        }
    }

    private var expandedLeading: some View {
        HStack(spacing: 6) {
            Image(systemName: "dumbbell.fill")
                .font(.title3)
                .foregroundStyle(.green)
            Text("Rest")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }

    private func expandedTrailing(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        Group {
            if context.state.isPaused {
                Text(context.state.pausedTimeDisplay)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.green)
            } else {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .font(.title3.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        if !context.state.isPaused {
            ProgressView(timerInterval: Date()...context.state.endDate, countsDown: false)
                .tint(.green)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
    }

    private var compactLeadingView: some View {
        Image(systemName: "timer")
            .foregroundStyle(.green)
            .font(.caption.bold())
    }

    private func compactTrailingView(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        Group {
            if context.state.isPaused {
                Text(context.state.pausedTimeDisplay)
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(.green)
            } else {
                Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                    .frame(minWidth: 36)
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(.green)
            }
        }
    }

    private var minimalView: some View {
        Image(systemName: "timer")
            .foregroundStyle(.green)
    }

    private func lockScreenBanner(context: ActivityViewContext<RestTimerAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.title2.bold())
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if context.state.isPaused {
                    Text(context.state.pausedTimeDisplay + " · paused")
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.green)
                } else {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            if !context.state.isPaused {
                ProgressView(timerInterval: Date()...context.state.endDate, countsDown: false)
                    .progressViewStyle(.circular)
                    .tint(.green)
                    .frame(width: 40, height: 40)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(red: 0.05, green: 0.1, blue: 0.06))
        .activitySystemActionForegroundColor(.green)
    }
}
