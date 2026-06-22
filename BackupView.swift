import SwiftUI
import UIKit

struct BackupSheet: View {
    @EnvironmentObject var store: DataStore
    @Binding var isPresented: Bool

    @State private var exportURL: URL? = nil
    @State private var importText = ""
    @State private var message: String? = nil
    @State private var messageColor: Color = AppTheme.accentGreen
    @State private var showImportConfirm = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    HStack {
                        Text("Backup")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Spacer()
                        Button { isPresented = false } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.06)).clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 18)

                    if let message {
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(messageColor)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(messageColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }

                    // Export
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Exportieren")
                        Text("Sichere alle Daten (Termine, Erinnerungen, Notizen, Einkauf, Tracker) als Datei. Ohne Backup gehen Daten beim Löschen der App verloren.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        if let url = exportURL {
                            ShareLink(item: url) {
                                actionLabel(icon: "square.and.arrow.up", text: "Backup teilen / sichern", filled: true)
                            }
                        }
                        Button {
                            UIPasteboard.general.string = store.exportJSON()
                            flash("In Zwischenablage kopiert ✓", AppTheme.accentGreen)
                        } label: {
                            actionLabel(icon: "doc.on.doc", text: "In Zwischenablage kopieren", filled: false)
                        }
                        .buttonStyle(.plain)
                    }
                    .glassCard()

                    // Import
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Importieren")
                        Text("Backup-Text hier einfügen und importieren. Achtung: ersetzt alle aktuellen Daten.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        DarkTextEditor(placeholder: "Backup-JSON hier einfügen...", text: $importText)

                        Button {
                            if let s = UIPasteboard.general.string { importText = s }
                        } label: {
                            actionLabel(icon: "doc.on.clipboard", text: "Aus Zwischenablage einfügen", filled: false)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showImportConfirm = true
                        } label: {
                            actionLabel(icon: "tray.and.arrow.down", text: "Importieren", filled: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }
                    .glassCard()

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { exportURL = store.exportFileURL() }
        .alert("Daten ersetzen?", isPresented: $showImportConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Importieren", role: .destructive) { performImport() }
        } message: {
            Text("Alle aktuellen Daten werden durch das Backup ersetzt. Das kann nicht rückgängig gemacht werden.")
        }
    }

    private func performImport() {
        if store.importJSON(importText) {
            importText = ""
            flash("Import erfolgreich ✓", AppTheme.accentGreen)
            exportURL = store.exportFileURL()
        } else {
            flash("Import fehlgeschlagen – ungültiges Backup.", AppTheme.accentAmber)
        }
    }

    private func flash(_ text: String, _ color: Color) {
        message = text
        messageColor = color
    }

    private func actionLabel(icon: String, text: String, filled: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
            Text(text).font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .foregroundColor(filled ? .white : AppTheme.textPrimary)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(filled ? AppTheme.accentBlue.opacity(0.8) : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusMedium).stroke(AppTheme.glassBorder, lineWidth: 0.5))
    }
}
