import PhotosUI
import SwiftUI
import UIKit

struct AppRootView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            HanSceneBackdrop()

            if viewModel.currentUser == nil {
                AuthFlowView()
                    .environmentObject(viewModel)
            } else {
                RootTabView()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct AuthFlowView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var mode: AuthMode = .login
    @State private var name = ""
    @State private var studentID = ""
    @State private var email = "member@hanfu.com"
    @State private var password = "Member1234!"
    @State private var message: String?
    @State private var isError = false
    @State private var forgotEmail = ""

    enum AuthMode: String, CaseIterable, Identifiable {
        case login = "登入"
        case register = "註冊"
        case forgot = "忘記密碼"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "scroll.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color.hanCrimson)
                        .padding(16)
                        .background(Color.hanGold.opacity(0.18), in: Circle())
                    Text("iClude")
                        .font(.largeTitle.bold())
                        .fontDesign(.serif)
                    Text("中原大學漢服研究社")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                Picker("模式", selection: $mode) {
                    ForEach(AuthMode.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    if mode == .register {
                        StyledInputField(title: "姓名", text: $name)
                        StyledInputField(title: "學號", text: $studentID)
                    }

                    if mode == .forgot {
                        StyledInputField(title: "Email", text: $forgotEmail, keyboardType: .emailAddress)
                    } else {
                        StyledInputField(title: "Email", text: $email, keyboardType: .emailAddress)
                        StyledSecureField(title: "密碼", text: $password)
                    }

                    Button {
                        Task {
                            await performAction()
                        }
                    } label: {
                        Text(buttonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
                .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.hanGold.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.hanInk.opacity(0.08), radius: 18, x: 0, y: 8)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(isError ? .red : .green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 6)
                }

                LoginHintCard()
            }
            .padding()
        }
    }

    private var buttonTitle: String {
        switch mode {
        case .login: return "Email 登入"
        case .register: return "建立會員"
        case .forgot: return "送出重設信"
        }
    }

    private func performAction() async {
        do {
            switch mode {
            case .login:
                _ = try await viewModel.login(email: email, password: password)
                message = "登入成功"
                isError = false
            case .register:
                _ = try await viewModel.register(name: name, studentID: studentID, email: email, password: password)
                message = "註冊成功"
                isError = false
            case .forgot:
                let result = try await viewModel.sendPasswordReset(email: forgotEmail)
                message = result
                isError = false
            }
        } catch {
            message = error.localizedDescription
            isError = true
        }
    }
}

struct LoginHintCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("測試帳號")
                .font(.headline)
            AccountCredentialsRow(
                title: "管理員",
                email: "admin@hanfu.com",
                password: "Admin1234!"
            )
            AccountCredentialsRow(
                title: "會員",
                email: "member@hanfu.com",
                password: "Member1234!"
            )
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.hanPaper.opacity(0.82), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct AccountCredentialsRow: View {
    let title: String
    let email: String
    let password: String
    @State private var copiedField: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            CopySnippet(label: "", value: email, copied: copiedField == "email") {
                copy(value: email, field: "email")
            }

            CopySnippet(label: "", value: password, copied: copiedField == "password") {
                copy(value: password, field: "password")
            }
        }
    }

    private func copy(value: String, field: String) {
        UIPasteboard.general.string = value
        copiedField = field

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if copiedField == field {
                copiedField = nil
            }
        }
    }
}

struct CopySnippet: View {
    let label: String
    let value: String
    let copied: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(displayText)
                    .lineLimit(1)
                Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(copied ? Color.gray : Color.primary)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)，點擊複製")
    }

    private var displayText: String {
        label.isEmpty ? value : "\(label)：\(value)"
    }
}

struct RootTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首頁", systemImage: "house.fill") }
            EventListView()
                .tabItem { Label("活動", systemImage: "calendar.badge.plus") }
            HanfuCatalogView()
                .tabItem { Label("漢服", systemImage: "figure.dress.line.vertical.figure") }
            CostumeRentalView()
                .tabItem { Label("租借", systemImage: "hanger") }
            SocialFeedView()
                .tabItem { Label("社群", systemImage: "message.and.waveform") }
            MemberCenterView()
                .tabItem { Label("會員中心", systemImage: "person.crop.circle.fill") }
            if viewModel.isAdmin {
                AdminCenterView()
                    .tabItem { Label("管理員", systemImage: "gearshape.2.fill") }
            }
        }
        .tint(Color.hanInk)
    }
}

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HomeHeroCard(userName: viewModel.currentUser?.name ?? "會員")

                    StatsRow(
                        items: [
                            .init(title: "可借用漢服", value: "\(availableCostumes.count)"),
                            .init(title: "活動", value: "\(viewModel.snapshot.events.count)"),
                            .init(title: "貼文", value: "\(viewModel.snapshot.posts.count)")
                        ]
                    )

                    SectionCard(title: "最新公告") {
                        ForEach(viewModel.snapshot.announcements.prefix(3)) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title).font(.headline)
                                Text(item.content).font(.subheadline).foregroundStyle(.secondary)
                                Text(item.createdAt.appShortString).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("首頁")
            .hanfuNavigationHeader()
        }
    }

    private var availableCostumes: [Costume] {
        viewModel.snapshot.costumes.filter { $0.available }
    }
}

struct HomeHeroCard: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("你好，\(userName)")
                .font(.title.bold())
                .fontDesign(.serif)
            Text("快速查看可借用漢服、活動與貼文，直接進入你要的內容。")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.hanPaper.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }
}

struct StatsRow: View {
    struct StatItem: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    let items: [StatItem]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                VStack(spacing: 6) {
                    Text(item.value)
                        .font(.title2.bold())
                    Text(item.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.hanPaper.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.hanGold.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontDesign(.serif)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.hanPaper.opacity(0.9), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }
}

struct EventListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedEvent: Event?

    var body: some View {
        NavigationStack {
            List {
                Section("所有活動") {
                    ForEach(viewModel.snapshot.events) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            EventRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("已報名活動") {
                    if registeredEvents.isEmpty {
                        Text("尚未報名任何活動")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(registeredEvents) { event in
                            Button {
                                selectedEvent = event
                            } label: {
                                registeredEventRow(event)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("活動管理")
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
                    .environmentObject(viewModel)
            }
            .hanfuNavigationHeader()
        }
    }

    private var registeredEvents: [Event] {
        viewModel.registeredEvents
    }

    private func registeredEventRow(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
            Text(event.date.appShortString)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("剩餘名額：\(event.remainingSlots)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(event.remainingSlots > 0 ? .green : Color.hanCrimson)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: event.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack { Color.hanCrimson.opacity(0.12); Image(systemName: "calendar") }
                }
            }
            .frame(width: 84, height: 84)
            .clipped()
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title).font(.headline)
                Text(event.location).font(.subheadline).foregroundStyle(.secondary)
                Text(event.date.appShortString).font(.caption).foregroundStyle(.secondary)
                Text("剩餘名額：\(event.remainingSlots)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(event.remainingSlots > 0 ? .green : Color.hanCrimson)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let event: Event
    @State private var message: String?

    private var currentEvent: Event {
        viewModel.snapshot.events.first(where: { $0.eventID == event.eventID }) ?? event
    }

    private var isRegistered: Bool {
        guard let userID = viewModel.currentUser?.uid else { return false }
        return currentEvent.registeredUserIDs.contains(userID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: currentEvent.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            RoundedRectangle(cornerRadius: 24).fill(Color.hanCrimson.opacity(0.14)).overlay(Image(systemName: "photo").font(.largeTitle))
                        }
                    }
                    .frame(height: 240)
                    .clipped()
                    .cornerRadius(24)

                    Text(currentEvent.title).font(.title.bold())
                    Text(currentEvent.description)
                    DetailLine(title: "活動日期", value: currentEvent.date.appShortString)
                    DetailLine(title: "地點", value: currentEvent.location)
                    DetailLine(title: "名額", value: "\(currentEvent.registeredUserIDs.count)/\(currentEvent.quota)")

                    Button {
                        guard !isRegistered else { return }
                        Task { await register() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isRegistered ? "checkmark.circle.fill" : "calendar.badge.plus")
                            Text(isRegistered ? "已報名" : "活動報名")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(isRegistered ? Color.gray.opacity(0.72) : Color.hanCrimson, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isRegistered ? Color.gray.opacity(0.35) : Color.hanGold.opacity(0.2), lineWidth: 1)
                    )
                    .disabled(isRegistered)
                    .animation(.easeInOut(duration: 0.2), value: isRegistered)

                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("活動詳情")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("關閉") { dismiss() } } }
            .hanfuNavigationHeader()
        }
    }

    private func register() async {
        do {
            _ = try await viewModel.registerForEvent(eventID: event.eventID)
            message = "活動已報名"
        } catch {
            message = error.localizedDescription
        }
    }
}

struct HanfuCatalogView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedDynasty: HanfuDynasty? = nil
    @State private var selectedHanfu: Hanfu?

    var filteredItems: [Hanfu] {
        viewModel.snapshot.hanfus.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText) || item.detail.localizedCaseInsensitiveContains(searchText)
            let matchesDynasty = selectedDynasty == nil || item.dynasty == selectedDynasty
            return matchesSearch && matchesDynasty
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("搜尋名稱或介紹", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.hanGold.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(title: "全部", isSelected: selectedDynasty == nil) { selectedDynasty = nil }
                        ForEach(HanfuDynasty.allCases) { dynasty in
                            FilterChip(title: dynasty.rawValue, isSelected: selectedDynasty == dynasty) { selectedDynasty = dynasty }
                        }
                    }
                    .padding(.horizontal)
                }

                List(filteredItems) { hanfu in
                    Button {
                        selectedHanfu = hanfu
                    } label: {
                        HanfuRow(hanfu: hanfu)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("漢服圖鑑")
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .sheet(item: $selectedHanfu) { item in
                HanfuDetailView(hanfu: item)
                    .environmentObject(viewModel)
            }
            .hanfuNavigationHeader()
        }
    }
}

struct HanfuRow: View {
    let hanfu: Hanfu

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: hanfu.imageURL)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: RoundedRectangle(cornerRadius: 16).fill(Color.hanCrimson.opacity(0.14)).overlay(Image(systemName: "photo"))
                }
            }
            .frame(width: 84, height: 84)
            .clipped()
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 6) {
                Text(hanfu.name).font(.headline)
                Text(hanfu.dynasty.rawValue).font(.subheadline).foregroundStyle(.secondary)
                Text(hanfu.detail).lineLimit(2).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HanfuDetailView: View {
    let hanfu: Hanfu

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: hanfu.imageURL)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: RoundedRectangle(cornerRadius: 24).fill(Color.hanCrimson.opacity(0.14)).overlay(Image(systemName: "photo"))
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                    .cornerRadius(24)

                    Text(hanfu.name).font(.title.bold())
                    DetailLine(title: "朝代", value: hanfu.dynasty.rawValue)
                    Text(hanfu.detail)
                }
                .padding()
            }
            .navigationTitle("詳情")
            .hanfuNavigationHeader()
        }
    }
}

struct CostumeRentalView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var selectedCostume: Costume?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section("漢服列表") {
                    ForEach(viewModel.snapshot.costumes) { costume in
                        Button {
                            selectedCostume = costume
                        } label: {
                            CostumeRow(costume: costume)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("借閱紀錄") {
                    ForEach(viewModel.myRentals) { rental in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(costumeName(for: rental.costumeID)).font(.headline)
                            Text("借用日期：\(rental.rentDate.appShortString)")
                            Text(rental.returned ? "已歸還" : "借用中")
                                .foregroundStyle(rental.returned ? .green : .orange)

                            if !rental.returned {
                                Button("歸還") {
                                    Task { await returnRental(rentalID: rental.rentalID) }
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(Color.hanCrimson, in: Capsule())
                                .foregroundStyle(.white)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.hanCrimson.opacity(0.25), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("漢服租借")
            .sheet(item: $selectedCostume) { costume in
                CostumeDetailView(costume: costume, message: $message)
                    .environmentObject(viewModel)
            }
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                }
            }
            .hanfuNavigationHeader()
        }
    }

    private func costumeName(for costumeID: String) -> String {
        viewModel.snapshot.costumes.first(where: { $0.costumeID == costumeID })?.name ?? "未知漢服"
    }

    private func returnRental(rentalID: String) async {
        do {
            _ = try await viewModel.returnCostume(rentalID: rentalID)
            message = "已完成歸還"
        } catch {
            message = error.localizedDescription
        }
    }
}

struct CostumeRow: View {
    let costume: Costume

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: costume.imageURL)) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                default: RoundedRectangle(cornerRadius: 16).fill(Color.hanCrimson.opacity(0.14)).overlay(Image(systemName: "hanger"))
                }
            }
            .frame(width: 84, height: 84)
            .clipped()
            .cornerRadius(16)

            VStack(alignment: .leading, spacing: 6) {
                Text(costume.name).font(.headline)
                Text("尺寸：\(costume.size)  朝代：\(costume.dynasty.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(costume.available ? "可借用" : "已借出")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(costume.available ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CostumeDetailView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let costume: Costume
    @Binding var message: String?

    private var currentCostume: Costume {
        viewModel.snapshot.costumes.first(where: { $0.costumeID == costume.costumeID }) ?? costume
    }

    private var isBorrowed: Bool {
        !currentCostume.available
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AsyncImage(url: URL(string: currentCostume.imageURL)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: RoundedRectangle(cornerRadius: 24).fill(Color.hanCrimson.opacity(0.14)).overlay(Image(systemName: "hanger"))
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                    .cornerRadius(24)

                    Text(currentCostume.name).font(.title.bold())
                    DetailLine(title: "尺寸", value: currentCostume.size)
                    DetailLine(title: "朝代", value: currentCostume.dynasty.rawValue)
                    DetailLine(title: "狀態", value: isBorrowed ? "已被借用" : "可借用")

                    Button {
                        Task { await borrow() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isBorrowed ? "checkmark.circle.fill" : "arrow.up.circle.fill")
                    Text(isBorrowed ? "已被借用" : "借用申請")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(isBorrowed ? Color.gray.opacity(0.35) : Color.hanCrimson, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(isBorrowed ? Color.primary : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isBorrowed ? Color.gray.opacity(0.45) : Color.clear, lineWidth: 1)
                    )
                    .disabled(isBorrowed)

                    Text("歸還會在租借頁的借閱紀錄中處理。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("借用詳情")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("關閉") { dismiss() } } }
            .hanfuNavigationHeader()
        }
    }

    private func borrow() async {
        do {
            _ = try await viewModel.borrowCostume(costumeID: currentCostume.costumeID)
            message = "已被借用"
        } catch {
            message = error.localizedDescription
        }
    }
}

struct SocialFeedView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var content = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var imageURL: String?
    @State private var message: String?
    @State private var commentDrafts: [String: String] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    postComposer
                    ForEach(viewModel.snapshot.posts) { post in
                        postCard(post)
                    }
                }
                .padding()
            }
            .navigationTitle("社群分享")
            .hanfuNavigationHeader()
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    private var postComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("發文")
                .font(.headline)
            TextEditor(text: $content)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("上傳圖片", systemImage: "photo.on.rectangle.angled")
            }

            if let imageURL {
                Text("已選擇圖片並轉換為上傳 URL：\(imageURL)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("送出貼文") {
                Task { await publishPost() }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func postCard(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(Color.hanCrimson.opacity(0.22)).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(authorName(for: post.userID)).font(.headline)
                    Text(post.createdAt.appShortString).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(post.content)

            if let imageURL = post.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        RoundedRectangle(cornerRadius: 18).fill(Color.hanCrimson.opacity(0.14))
                    }
                }
                .frame(height: 220)
                .clipped()
                .cornerRadius(18)
            }

            HStack {
                let isLiked = viewModel.hasLiked(postID: post.postID)
                Button {
                    Task {
                        do {
                            _ = try await viewModel.likePost(postID: post.postID)
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                } label: {
                    Label("\(post.likes)", systemImage: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .frame(minWidth: 92)
                        .background(isLiked ? Color.hanCrimson : Color.hanPaper, in: Capsule())
                        .foregroundStyle(isLiked ? .white : .primary)
                        .overlay(
                            Capsule()
                                .stroke(Color.hanCrimson.opacity(isLiked ? 0 : 0.28), lineWidth: 1)
                        )
                }

                Spacer()
            }

            Text("留言")
                .font(.subheadline.bold())

            ForEach(viewModel.commentsByPostID[post.postID] ?? [], id: \.commentID) { comment in
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.authorName).font(.caption.bold())
                    Text(comment.text).font(.footnote)
                }
                .padding(.vertical, 4)
            }

            HStack {
                TextField("寫下留言", text: Binding(
                    get: { commentDrafts[post.postID, default: ""] },
                    set: { commentDrafts[post.postID] = $0 }
                ))
                .textFieldStyle(.plain)
                .padding()
                .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.hanGold.opacity(0.12), lineWidth: 1)
                )

                Button("送出") {
                    Task { await sendComment(for: post) }
                }
            }
        }
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    private func authorName(for userID: String) -> String {
        viewModel.snapshot.users.first(where: { $0.uid == userID })?.name ?? "匿名"
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                imageURL = try await viewModel.uploadImageData(data)
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func publishPost() async {
        do {
            _ = try await viewModel.createPost(content: content, imageURL: imageURL)
            content = ""
            selectedPhoto = nil
            selectedImageData = nil
            imageURL = nil
            message = "發文成功"
        } catch {
            message = error.localizedDescription
        }
    }

    private func sendComment(for post: Post) async {
        let text = commentDrafts[post.postID, default: ""].trimmed
        guard !text.isEmpty else { return }
        do {
            _ = try await viewModel.addComment(postID: post.postID, text: text)
            commentDrafts[post.postID] = ""
        } catch {
            message = error.localizedDescription
        }
    }
}

struct MemberCenterView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var editName = ""
    @State private var editStudentID = ""
    @State private var editEmail = ""
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileCard
                    editableProfileCard
                    groupedListSection(title: "已報名活動") {
                        ForEach(viewModel.registeredEvents) { event in
                            eventCompactRow(event: event)
                        }
                    }
                    groupedListSection(title: "漢服借閱紀錄") {
                        ForEach(viewModel.myRentals) { rental in
                            rentalRow(rental)
                        }
                    }
                    groupedListSection(title: "我的貼文") {
                        ForEach(viewModel.myPosts) { post in
                            postCompactRow(post)
                        }
                    }
                    Button("登出") {
                        Task { await viewModel.logout() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
            .navigationTitle("會員中心")
            .onAppear(perform: loadProfile)
            .hanfuNavigationHeader()
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.currentUser?.name ?? "")
                .font(.title.bold())
                .fontDesign(.serif)
            DetailLine(title: "Email", value: viewModel.currentUser?.email ?? "")
            DetailLine(title: "學號", value: viewModel.currentUser?.studentID ?? "")
            DetailLine(title: "身份", value: viewModel.currentUser?.role.displayName ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    private var editableProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("個人資料修改").font(.headline)
            StyledInputField(title: "姓名", text: $editName)
            StyledInputField(title: "學號", text: $editStudentID)
            StyledInputField(title: "Email", text: $editEmail, keyboardType: .emailAddress)
            Button("儲存修改") {
                Task { await saveProfile() }
            }
            .buttonStyle(PrimaryButtonStyle())
            if let message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    private func loadProfile() {
        editName = viewModel.currentUser?.name ?? ""
        editStudentID = viewModel.currentUser?.studentID ?? ""
        editEmail = viewModel.currentUser?.email ?? ""
    }

    private func saveProfile() async {
        do {
            _ = try await viewModel.updateProfile(name: editName, studentID: editStudentID, email: editEmail)
            message = "資料已更新"
        } catch {
            message = error.localizedDescription
        }
    }

    @ViewBuilder
    private func groupedListSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    private func eventCompactRow(event: Event) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title).font(.subheadline.bold())
            Text(event.date.appShortString).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rentalRow(_ rental: Rental) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(costumeName(for: rental.costumeID)).font(.subheadline.bold())
            Text(rental.returned ? "已歸還" : "借用中").font(.caption).foregroundStyle(rental.returned ? .green : .orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func postCompactRow(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.content).lineLimit(2)
            Text(post.createdAt.appShortString).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventTitle(for eventID: String) -> String {
        viewModel.snapshot.events.first(where: { $0.eventID == eventID })?.title ?? "未知活動"
    }

    private func costumeName(for costumeID: String) -> String {
        viewModel.snapshot.costumes.first(where: { $0.costumeID == costumeID })?.name ?? "未知漢服"
    }
}

struct AdminCenterView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var announcementTitle = ""
    @State private var announcementContent = ""
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventLocation = ""
    @State private var eventQuota = "20"
    @State private var eventImageURL = "https://picsum.photos/600/400?admin-event"
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    adminOverview

                    adminSection(title: "內容發布") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("新增公告")
                                .font(.headline)
                            StyledInputField(title: "公告標題", text: $announcementTitle)
                            TextEditor(text: $announcementContent)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Button("新增公告") { Task { await createAnnouncement() } }
                                .buttonStyle(PrimaryButtonStyle())
                        }

                        Divider().opacity(0.2)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("新增活動")
                                .font(.headline)
                            StyledInputField(title: "活動名稱", text: $eventTitle)
                            TextEditor(text: $eventDescription)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            StyledInputField(title: "地點", text: $eventLocation)
                            StyledInputField(title: "名額", text: $eventQuota, keyboardType: .numberPad)
                            StyledInputField(title: "圖片 URL", text: $eventImageURL)
                            Button("建立活動") { Task { await createEvent() } }
                                .buttonStyle(PrimaryButtonStyle())
                        }
                    }

                    adminSection(title: "管理公告") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.snapshot.announcements) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.title)
                                        .font(.headline)
                                    Text(item.content)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Spacer()
                                        Button("刪除") { Task { await deleteAnnouncement(id: item.announcementID) } }
                                            .font(.caption.weight(.semibold))
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 14)
                                            .background(Color.hanCrimson, in: Capsule())
                                            .foregroundStyle(.white)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.hanCrimson.opacity(0.25), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding()
                                .background(Color.hanPaper.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }

                    adminSection(title: "管理會員") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.snapshot.users) { user in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.subheadline.weight(.semibold))
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(user.role.displayName)
                                        .font(.caption.weight(.semibold))
                                }
                                .padding()
                                .background(Color.hanPaper.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("管理員功能")
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.hanPaper.opacity(0.88))
                        .foregroundStyle(.secondary)
                }
            }
            .hanfuNavigationHeader()
        }
    }

    private var adminOverview: some View {
        HStack(spacing: 12) {
            adminStat(title: "公告", value: "\(viewModel.snapshot.announcements.count)")
            adminStat(title: "活動", value: "\(viewModel.snapshot.events.count)")
            adminStat(title: "會員", value: "\(viewModel.snapshot.users.count)")
        }
    }

    private func adminStat(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.hanPaper.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func adminSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontDesign(.serif)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.hanPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.hanGold.opacity(0.14), lineWidth: 1)
        )
    }

    private func createAnnouncement() async {
        do {
            _ = try await viewModel.createAnnouncement(title: announcementTitle, content: announcementContent)
            announcementTitle = ""
            announcementContent = ""
            message = "公告已新增"
        } catch {
            message = error.localizedDescription
        }
    }

    private func createEvent() async {
        do {
            let quota = Int(eventQuota) ?? 20
            _ = try await viewModel.createEvent(title: eventTitle, description: eventDescription, date: Date().addingTimeInterval(60 * 60 * 24 * 10), location: eventLocation, quota: quota, imageURL: eventImageURL)
            eventTitle = ""
            eventDescription = ""
            eventLocation = ""
            message = "活動已新增"
        } catch {
            message = error.localizedDescription
        }
    }

    private func deleteAnnouncement(id: String) async {
        do {
            try await viewModel.deleteAnnouncement(announcementID: id)
            message = "公告已刪除"
        } catch {
            message = error.localizedDescription
        }
    }
}

struct DetailLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(isSelected ? Color.hanCrimson : Color.hanPaper.opacity(0.82), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .background(Color.hanCrimson.opacity(configuration.isPressed ? 0.82 : 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.hanGold.opacity(configuration.isPressed ? 0.08 : 0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct StyledInputField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding()
            .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hanGold.opacity(0.12), lineWidth: 1)
            )
    }
}

struct StyledSecureField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .padding()
            .background(Color.hanPaper.opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.hanGold.opacity(0.12), lineWidth: 1)
            )
    }
}

struct HanSceneBackdrop: View {
    var body: some View {
        Color.hanPaperDeep
        .ignoresSafeArea()
    }
}

private extension View {
    func hanfuNavigationHeader() -> some View {
        toolbarBackground(Color.hanPaper.opacity(0.96), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .tint(Color.black)
    }
}

extension Color {
    static let hanPaper = Color(red: 0.98, green: 0.95, blue: 0.90)
    static let hanPaperDeep = Color(red: 0.94, green: 0.88, blue: 0.78)
    static let hanCrimson = Color(red: 0.57, green: 0.12, blue: 0.12)
    static let hanInk = Color(red: 0.20, green: 0.16, blue: 0.13)
    static let hanGold = Color(red: 0.76, green: 0.58, blue: 0.24)
}

#Preview {
    AppRootView()
}
