import SwiftUI

struct SettingsPanel: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(EditorViewModel.self) private var editorVM
    @Environment(MenuBarManager.self) private var menuBarManager
    @State private var showProSheet = false

    private let languages = [
        "auto",
        "swift", "python", "javascript", "typescript", "java",
        "c", "cpp", "csharp", "go", "rust",
        "ruby", "php", "kotlin", "scala", "sql",
        "html", "css", "shell", "json", "yaml"
    ]

    private let presetColors = ["#ffffff", "#000000", "#1e1e2e", "#0d1117", "#282a36", "clear"]

    var body: some View {
        @Bindable var settings = settings
        @Bindable var editorVM = editorVM

        Form {
            themeSection
            codeSection(settings: $settings, editorVM: $editorVM)
            canvasSection(settings: $settings)
            windowFrameSection(settings: $settings)
            exportSection(settings: $settings)
            menuBarSection(settings: $settings)
        }
        .formStyle(.grouped)
        .onChange(of: self.settings.menuBarModeEnabled) { _, enabled in
            if enabled && purchaseManager.isPro {
                menuBarManager.enable(
                    editorVM: editorVM,
                    settings: self.settings,
                    themeManager: themeManager,
                    purchaseManager: purchaseManager
                )
            } else {
                menuBarManager.disable()
                self.settings.menuBarModeEnabled = false
            }
        }
        .onChange(of: self.settings.hideDockIcon) { _, hide in
            NSApp.setActivationPolicy(hide ? .accessory : .regular)
        }
        .sheet(isPresented: $showProSheet) {
            ProUpgradeSheet()
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section("Theme") {
            ThemePicker()
        }
    }

    // MARK: - Code

    private func codeSection(
        settings: Bindable<AppSettings>,
        editorVM: Bindable<EditorViewModel>
    ) -> some View {
        Section("Code") {
            Picker("Language", selection: editorVM.language) {
                Text("Auto-detect").tag("auto")
                ForEach(languages.dropFirst(), id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .onChange(of: self.editorVM.language) { _, newLang in
                self.editorVM.setLanguage(newLang)
            }

            Picker("Font", selection: settings.fontFamily) {
                ForEach(monospaceFonts, id: \.self) { family in
                    Text(family).tag(family)
                }
            }

            LabeledContent("Size  \(Int(self.settings.fontSize)) pt") {
                Slider(value: settings.fontSize, in: 10...24, step: 1)
            }
            .onChange(of: self.settings.fontSize) { _, newSize in
                self.editorVM.setFontSize(newSize)
            }
        }
    }

    // MARK: - Canvas

    private func canvasSection(settings: Bindable<AppSettings>) -> some View {
        Section("Canvas") {
            ColorPicker("Background", selection: backgroundColorBinding)

            HStack(spacing: 6) {
                ForEach(presetColors, id: \.self) { hex in
                    Circle()
                        .fill(hex == "clear" ? Color.clear : Color(hex: hex))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        }
                        .overlay {
                            if self.settings.backgroundColorHex == hex {
                                Circle().stroke(Color.accentColor, lineWidth: 2)
                            }
                        }
                        .onTapGesture {
                            self.settings.backgroundColorHex = hex
                        }
                }
            }

            LabeledContent("Padding  \(Int(self.settings.padding)) pt") {
                Slider(value: settings.padding, in: 8...80, step: 4)
            }

            LabeledContent("Corner radius  \(Int(self.settings.cornerRadius)) pt") {
                Slider(value: settings.cornerRadius, in: 0...24, step: 2)
            }
        }
    }

    // MARK: - Window Frame

    private func windowFrameSection(settings: Bindable<AppSettings>) -> some View {
        Section("Window Frame") {
            Toggle("Show window frame", isOn: settings.showWindowFrame)

            ProLockedRow(
                label: "Frame style",
                isPro: purchaseManager.isPro,
                onTap: { showProSheet = true }
            ) {
                Picker("Frame style", selection: settings.windowFrameStyle) {
                    Text("macOS").tag("macos")
                    Text("Chrome").tag("chrome")
                    Text("Arc").tag("arc")
                    Text("None").tag("none")
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Export

    private func exportSection(settings: Bindable<AppSettings>) -> some View {
        Section("Export") {
            Picker("Resolution", selection: settings.exportScale) {
                Text("1\u{00D7}").tag(1.0)
                Text("2\u{00D7}").tag(2.0)
            }
            .pickerStyle(.segmented)

            ProLockedRow(
                label: "Hi-res",
                isPro: purchaseManager.isPro,
                onTap: { showProSheet = true }
            ) {
                Picker("Hi-res export", selection: settings.exportScale) {
                    Text("3\u{00D7}").tag(3.0)
                    Text("4\u{00D7}").tag(4.0)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Menu Bar

    private func menuBarSection(settings: Bindable<AppSettings>) -> some View {
        Section("Menu Bar") {
            ProLockedRow(
                label: "Menu bar mode",
                isPro: purchaseManager.isPro,
                onTap: { showProSheet = true }
            ) {
                Toggle("Menu bar mode", isOn: settings.menuBarModeEnabled)
            }

            if self.settings.menuBarModeEnabled {
                Toggle("Hide dock icon", isOn: settings.hideDockIcon)
            }
        }
    }

    // MARK: - Helpers

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: {
                if settings.backgroundColorHex == "clear" { return .white.opacity(0) }
                return Color(hex: settings.backgroundColorHex)
            },
            set: { settings.backgroundColorHex = $0.toHex() }
        )
    }

    private var monospaceFonts: [String] {
        let fm = NSFontManager.shared
        return fm.availableFontFamilies.filter { family in
            guard let members = fm.availableMembers(ofFontFamily: family),
                  let firstName = members.first?[0] as? String,
                  let font = NSFont(name: firstName, size: 12)
            else { return false }
            return font.isFixedPitch
        }
    }
}

#Preview {
    SettingsPanel()
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(PurchaseManager())
        .environment(EditorViewModel())
        .environment(MenuBarManager())
        .frame(width: 280, height: 700)
}
