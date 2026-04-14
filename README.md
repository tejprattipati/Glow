# GlowLift

Personal iPhone gym tracking app. Dark purple neon aesthetic. Built in SwiftUI + SwiftData.

## Features

- **Push/Pull/Legs A/B split sequencing** — no weekday dependency, pure sequence logic
- **Fast set logging** — weight + reps entry with quick-fill from last set / last session
- **Rest timer** — floating, persistent across all tabs; presets (60/90/120/180s), haptic + notification on completion
- **Exercise history** — last performance shown inline inside every active workout
- **Streak engine** — flow streak (consecutive sessions) + calendar streak + special circumstance days
- **Claude AI coach** — integrated chat with persistent conversation history; uses your workout data as context
- **Workout history** — all sessions browsable by month, tappable for full detail
- **Progress charts** — top set weight / volume / sets over time per exercise (Swift Charts)
- **Template editor** — add/remove/rename exercises in any of the six templates
- **Settings** — units, rest defaults, streak rules, special day logging

## Requirements

- Xcode 15.4+
- iOS 17.0+ target device or simulator
- Apple Developer account (free is fine for personal device via Xcode)

## Setup

```bash
git clone <repo>
open GlowLift/GlowLift.xcodeproj
```

1. In Xcode, select your iPhone as the run destination
2. Set your Apple ID under **Signing & Capabilities** → Team
3. Build & Run (`Cmd+R`)

The app seeds default templates on first launch. No backend required.

## API Key

The Claude API key is embedded in `Services/ClaudeService.swift` split across two string constants (`keyPartA` + `keyPartB`). To rotate the key, update those two strings and rebuild.

## Architecture

```
GlowLift/
├── GlowLiftApp.swift          # App entry, ModelContainer init, seed
├── ContentView.swift          # TabView + global floating timer overlay
├── Theme/
│   └── GlowTheme.swift        # Colors, fonts, spacing, glow modifiers
├── Models/                    # All @Model SwiftData types
│   ├── ExerciseDefinition.swift
│   ├── WorkoutTemplate.swift
│   ├── WorkoutSession.swift
│   ├── StreakModels.swift
│   ├── ChatModels.swift
│   └── UserPreferences.swift
├── Services/
│   ├── WorkoutSequencer.swift  # Next-workout logic, session creation
│   ├── StreakEngine.swift      # Flow + calendar streak calculation
│   ├── RestTimerManager.swift  # Observable singleton timer
│   ├── LLMService.swift        # Protocol + error types
│   └── ClaudeService.swift     # Anthropic API implementation
├── SeedData/
│   └── DefaultTemplates.swift  # All six PPL templates pre-seeded
├── Components/
│   ├── GlowCard.swift          # Card container, buttons, chips
│   ├── ExerciseIcon.swift      # Category → SF Symbol mapping
│   └── FloatingRestTimer.swift # Collapsible sticky timer bar
└── Views/
    ├── Home/HomeView.swift
    ├── Train/WorkoutSelectionView.swift
    ├── Train/ActiveWorkoutView.swift
    ├── Train/SetLoggingSheet.swift
    ├── History/HistoryView.swift
    ├── Progress/ProgressView.swift
    ├── Chat/ChatView.swift
    ├── Chat/ChatThreadView.swift
    ├── Templates/TemplateEditorView.swift
    └── Settings/SettingsView.swift
```

## Workout Sequence

Push A → Pull A → Legs A → Push B → Pull B → Legs B → repeat

The app always recommends the next in sequence from your **last completed** session. If you override, the sequence continues from what you actually did.
