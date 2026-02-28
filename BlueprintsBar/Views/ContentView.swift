import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if appState.selectedScope == nil {
                ScopePickerView()
            } else if let route = appState.navigationPath.last {
                switch route {
                case .stackDetail(let stack):
                    StackDetailView(stack: stack)
                case .resourceDetail(let stackID, let resource):
                    ResourceDetailView(stackID: stackID, resource: resource)
                case .operationDetail(let stackID, let operation):
                    OperationDetailView(stackID: stackID, operation: operation)
                }
            } else {
                StackListView()
            }
        }
        .frame(minWidth: 480, idealWidth: 480, minHeight: 560, idealHeight: 560)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            if appState.navigationPath.isEmpty && appState.selectedScope != nil {
                backButton { appState.clearScope() }
            } else if !appState.navigationPath.isEmpty {
                backButton { appState.navigationPath.removeLast() }
            }

            breadcrumb
            Spacer()
            environmentPicker
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func backButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    private func detachToWindow() {
        openWindow(id: "detached")
        NSApplication.shared.activate()
    }

    @ViewBuilder
    private var breadcrumb: some View {
        HStack(spacing: 4) {
            Text("Blueprints")
                .fontWeight(.semibold)

            if let scope = appState.selectedScope {
                chevron
                Text(scope.label)
                    .foregroundStyle(.secondary)
            }

            if let stackName = currentStackName {
                chevron
                Text(stackName)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.callout)
        .lineLimit(1)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .foregroundStyle(.quaternary)
            .font(.caption2)
    }

    private var currentStackName: String? {
        for route in appState.navigationPath {
            if case .stackDetail(let stack) = route {
                return stack.name
            }
        }
        return nil
    }

    private var environmentPicker: some View {
        Menu {
            ForEach(APIEnvironment.available, id: \.self) { env in
                Button {
                    appState.switchEnvironment(env)
                } label: {
                    HStack {
                        Text(env.label)
                        if env == appState.environment {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button("Open in Window") {
                detachToWindow()
            }
            Divider()
            Button("Quit BlueprintsBar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(appState.environment == .production ? .green : .orange)
                    .frame(width: 6, height: 6)
                Text(appState.environment.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
