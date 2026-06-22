import SwiftUI

struct NotizenView: View {
    let mode: AppMode
    @EnvironmentObject var store: DataStore
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editing: Note? = nil
    @State private var reading: Note? = nil

    private var list: [Note] {
        let all = mode == .persoenlich ? store.personalNotes : store.familyNotes
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.body.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode == .persoenlich ? "Notizen" : "Gemeinsame Notizen")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("\(list.count) Einträge")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    AddButton { showingAdd = true }
                }
                .padding(.top, 8)

                SearchBarView(text: $searchText)

                if list.isEmpty {
                    EmptyStateView(icon: "note.text", text: searchText.isEmpty ? "Noch keine Notizen" : "Keine Ergebnisse")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(list) { note in
                            NoteCard(note: note)
                                .onTapGesture { reading = note }
                                .itemContextMenu(onEdit: { editing = note },
                                                 onDelete: { store.deleteNote(id: note.id) })
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingAdd) {
            NoteSheet(mode: mode, existing: nil, isPresented: $showingAdd)
                .environmentObject(store)
        }
        .sheet(item: $editing) { note in
            NoteSheet(mode: mode, existing: note, isPresented: Binding(
                get: { editing != nil },
                set: { if !$0 { editing = nil } }
            ))
            .environmentObject(store)
        }
        .sheet(item: $reading) { note in
            NoteDetailSheet(note: note,
                            onEdit: { reading = nil; editing = note },
                            onDelete: { store.deleteNote(id: note.id); reading = nil },
                            isPresented: Binding(get: { reading != nil }, set: { if !$0 { reading = nil } }))
        }
    }
}

// MARK: - Note Detail (read view)

struct NoteDetailSheet: View {
    let note: Note
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark").font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                            .frame(width: 34, height: 34).background(AppTheme.controlBackground).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "pencil").font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.onAccent)
                            .frame(width: 34, height: 34).background(AppTheme.accent).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.accentAmber)
                            .frame(width: 34, height: 34).background(AppTheme.controlBackground).clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(note.title)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(note.date.formatted(date: .long, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                        Divider().background(AppTheme.separator)
                        Text(note.body.isEmpty ? "Keine weiteren Inhalte." : note.body)
                            .font(.system(size: 16))
                            .foregroundColor(note.body.isEmpty ? AppTheme.textTertiary : AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 18)
                }
            }
            .padding(.horizontal, AppTheme.phoneScreenPadding)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Note Card

struct NoteCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
            Text(note.body)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(3)
            Spacer()
            Text(note.date.deDayMonth)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(AppTheme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusLarge).stroke(AppTheme.glassBorder, lineWidth: 0.5))
        .contentShape(Rectangle())
    }
}

// MARK: - Note Sheet (Add + Edit)

struct NoteSheet: View {
    let mode: AppMode
    let existing: Note?
    @Binding var isPresented: Bool
    @EnvironmentObject var store: DataStore

    @State private var title: String
    @State private var bodyText: String

    init(mode: AppMode, existing: Note?, isPresented: Binding<Bool>) {
        self.mode = mode
        self.existing = existing
        self._isPresented = isPresented
        _title = State(initialValue: existing?.title ?? "")
        _bodyText = State(initialValue: existing?.body ?? "")
    }

    var body: some View {
        DarkSheet(title: existing == nil ? "Neue Notiz" : "Notiz bearbeiten",
                  isPresented: $isPresented,
                  detents: [.medium, .large]) {
            VStack(spacing: 12) {
                DarkTextField(placeholder: "Titel", text: $title)
                DarkTextEditor(placeholder: "Notiz schreiben...", text: $bodyText)
            }
        } onSave: {
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            var n = existing ?? Note(title: "", body: "", isFamily: mode == .familie)
            n.title = title
            n.body = bodyText
            n.date = Date()
            if existing == nil { store.addNote(n) } else { store.updateNote(n) }
            isPresented = false
        }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textTertiary)
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Notizen durchsuchen").foregroundColor(AppTheme.textTertiary)
                }
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textPrimary)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}

extension View {
    func placeholder<C: View>(when show: Bool, @ViewBuilder placeholder: () -> C) -> some View {
        ZStack(alignment: .leading) { if show { placeholder() }; self }
    }
}
