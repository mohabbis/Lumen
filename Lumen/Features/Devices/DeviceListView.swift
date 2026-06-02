import SwiftUI

// MARK: - Device List View (Intel tab)

struct DeviceListView: View {

    @State var viewModel: DeviceViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()
            scrollContent
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                discoveryBanner
                if viewModel.liveDevices.isEmpty {
                    emptyDevices
                } else {
                    ForEach(viewModel.liveDevicesByCategory, id: \.0) { category, devices in
                        categorySection(category: category, devices: devices)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LUMEN")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text("Intel")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                if viewModel.isRefreshing {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background(Color.white.opacity(0.1), in: Circle())
            .padding(.top, 4)
        }
    }

    // MARK: - Discovery Banner

    @ViewBuilder
    private var discoveryBanner: some View {
        switch viewModel.homekitStatus {
        case .idle:
            EmptyView()

        case .connecting:
            DiscoveryCard(
                icon: "antenna.radiowaves.left.and.right",
                iconColor: Color(hex: "#C49A6C"),
                title: "Looking for devices…",
                message: "Scanning your HomeKit home for smart devices.",
                actionLabel: nil,
                actionColor: .clear,
                action: nil,
                isAnimating: true
            )

        case .authorizationRequired:
            DiscoveryCard(
                icon: "house.fill",
                iconColor: Color(hex: "#C49A6C"),
                title: "Connect to HomeKit",
                message: "Allow Lumen to access your HomeKit home to discover devices automatically.",
                actionLabel: "Open Settings",
                actionColor: Color(hex: "#C49A6C"),
                action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                isAnimating: false
            )

        case .denied:
            DiscoveryCard(
                icon: "lock.fill",
                iconColor: .red.opacity(0.8),
                title: "HomeKit access denied",
                message: "Enable HomeKit access in Settings to discover your devices.",
                actionLabel: "Open Settings",
                actionColor: .red.opacity(0.8),
                action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                isAnimating: false
            )

        case .authorized:
            if viewModel.totalCount > 0 {
                HStack(spacing: 8) {
                    Circle().fill(Color(hex: "#6FDBA8")).frame(width: 6, height: 6)
                    Text("HomeKit · \(viewModel.totalCount) device\(viewModel.totalCount == 1 ? "" : "s") discovered")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.45))
                    Spacer()
                    Text("\(viewModel.reachableCount) online")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#6FDBA8"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Empty Devices

    private var emptyDevices: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkle")
                .font(.system(size: 36))
                .foregroundStyle(Color.white.opacity(0.2))
            Text("No devices yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.45))
            Text("Once HomeKit connects, your devices will appear here automatically.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // MARK: - Category Section

    private func categorySection(category: DeviceCategory, devices: [any SmartDevice]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            if sizeClass == .regular {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(devices, id: \.id) { device in
                        NavigationLink(destination: DeviceDetailView(device: device, viewModel: viewModel)) {
                            DeviceDarkRow(device: device)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(devices, id: \.id) { device in
                        NavigationLink(destination: DeviceDetailView(device: device, viewModel: viewModel)) {
                            DeviceDarkRow(device: device)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Discovery Card

private struct DiscoveryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String
    let actionLabel: String?
    let actionColor: Color
    let action: (() -> Void)?
    let isAnimating: Bool

    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .scaleEffect(isAnimating && pulse ? 1.15 : 1.0)
                        .animation(isAnimating ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default, value: pulse)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let label = actionLabel, let action {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(actionColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(actionColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.06), lineWidth: 1))
        .onAppear { if isAnimating { pulse = true } }
    }
}

// MARK: - Device Dark Row

private struct DeviceDarkRow: View {
    let device: any SmartDevice

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)
                Image(systemName: device.category.systemImage)
                    .font(.system(size: 19))
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(device.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                if let room = device.roomName {
                    Text(room)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }

            Spacer()

            Circle()
                .fill(device.reachability == .reachable ? Color(hex: "#6FDBA8") : Color.white.opacity(0.2))
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }
}
