import SwiftUI
import UIKit // for UIImage-backed sample thumbnails

/// Phase 0 Scan screen.
///
/// The live capture → identify → cut/trim flow is built in Phases 2–3. For now
/// this screen introduces the flow and proves the datasets and bundled sample
/// images loaded: it shows the real sample photos and live counts from the
/// knowledge base and toxicity data.
struct ScanView: View {
    private let species = KnowledgeBaseService.shared.species
    private let toxicityCount = ToxicityService.shared.byScientificName.count
    private let samples = SampleImageLibrary.shared.images

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    flowCard
                    if !samples.isEmpty { sampleStrip }
                    dataStatus
                    ComingSoonNote(text: "Camera capture and the on-device cut & trim guide arrive in the next phases.")
                }
                .padding()
            }
            .background(Theme.groupedBackground)
            .navigationTitle("Scan")
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 52))
                .foregroundStyle(Theme.leaf)
            Text("Scan a plant to grow it")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("Photograph a plant to identify it, check whether it's safe for your pets, and see exactly where to cut.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var flowCard: some View {
        SectionCard(title: "How it will work", systemImage: "list.number") {
            VStack(alignment: .leading, spacing: 14) {
                FlowStep(number: 1, title: "Capture or pick a photo",
                         detail: "Take a picture, or choose one from your library.",
                         systemImage: "camera.fill")
                FlowStep(number: 2, title: "Identify + pet safety",
                         detail: "See the species, its difficulty, and a bold pet-toxicity flag.",
                         systemImage: "checkmark.seal.fill")
                FlowStep(number: 3, title: "Where to cut",
                         detail: "An on-device model marks nodes and yellowing leaves on your photo; the app draws a ✂️ cut-here marker.",
                         systemImage: "scissors")
            }
        }
    }

    private var sampleStrip: some View {
        SectionCard(title: "Bundled sample photos", systemImage: "photo.on.rectangle") {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(samples) { sample in
                            VStack(spacing: 6) {
                                sampleThumbnail(sample)
                                Text(KnowledgeBaseService.shared.species(id: sample.speciesID)?.commonName ?? sample.caption)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(width: 110)
                            }
                        }
                    }
                }
                Text("Placeholders so Scan works in the Simulator — replace with real photos before the demo.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func sampleThumbnail(_ sample: SampleImage) -> some View {
        if let image = sample.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.sprout.opacity(0.2))
                .frame(width: 110, height: 110)
                .overlay(Image(systemName: "leaf").foregroundStyle(Theme.leaf))
        }
    }

    private var dataStatus: some View {
        HStack(spacing: 16) {
            statusItem(count: species.count, label: "species", systemImage: "books.vertical.fill")
            statusItem(count: toxicityCount, label: "toxicity records", systemImage: "pawprint.fill")
            statusItem(count: samples.count, label: "sample photos", systemImage: "photo.fill")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
    }

    private func statusItem(count: Int, label: String, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).foregroundStyle(Theme.leaf)
            Text("\(count)").font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScanView()
}
