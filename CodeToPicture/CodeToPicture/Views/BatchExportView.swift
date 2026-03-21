import SwiftUI

struct BatchExportView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(AppSettings.self) private var settings
    @Environment(ThemeManager.self) private var themeManager
    @State private var vm = BatchExportViewModel()
    @State private var showProSheet = false

    var body: some View {
        Group {
            if !purchaseManager.isPro {
                proGate
            } else {
                content
            }
        }
        .frame(width: 560, height: 480)
    }

    // MARK: - Pro gate

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Batch Export is a Pro feature")
                .font(.headline)
            Text("Upgrade to export multiple files at once.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Upgrade to Pro") { showProSheet = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showProSheet) {
            ProUpgradeSheet()
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 0) {
            if vm.items.isEmpty {
                dropZone
            } else {
                itemList
            }

            Divider()

            bottomBar
        }
    }

    // MARK: - Drop zone

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            .foregroundStyle(.tertiary)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Drop code files here")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .dropDestination(for: URL.self) { urls, _ in
                vm.addFiles(urls)
                return true
            }
    }

    // MARK: - Item list

    private var itemList: some View {
        List {
            ForEach(vm.items) { item in
                HStack {
                    statusIcon(for: item.status)
                    VStack(alignment: .leading) {
                        Text(item.filename)
                            .font(.body)
                        Text(item.detectedLanguage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if case .failed(let msg) = item.status {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    vm.removeItem(vm.items[index])
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            vm.addFiles(urls)
            return true
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(vm.progress), total: max(1, Double(vm.items.count)))

            Text("\(vm.progress) / \(vm.items.count) exported")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Choose Output Folder") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = false
                    panel.canCreateDirectories = true
                    if panel.runModal() == .OK {
                        vm.outputFolderURL = panel.url
                    }
                }

                if let folder = vm.outputFolderURL {
                    Text(folder.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if vm.progress == vm.items.count && vm.progress > 0 {
                    Button("Open Folder") {
                        if let url = vm.outputFolderURL {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }

                Button("Export All") {
                    Task {
                        await vm.startExport(
                            settings: settings,
                            themeManager: themeManager,
                            isPro: purchaseManager.isPro
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isExporting || vm.items.isEmpty || vm.outputFolderURL == nil)
            }
        }
        .padding()
    }

    // MARK: - Status icon

    @ViewBuilder
    private func statusIcon(for status: BatchExportItem.Status) -> some View {
        switch status {
        case .waiting:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .processing:
            ProgressView()
                .controlSize(.small)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    BatchExportView()
        .environment(AppSettings())
        .environment(ThemeManager())
        .environment(PurchaseManager())
}
