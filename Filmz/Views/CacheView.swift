import SwiftUI
import CloudKit

struct DiskCacheEntry: Identifiable {
    var id: String { originalUrl }
    let originalUrl: String
    let fileUrl: URL
}

struct CacheView: View {
    @State private var loadCount = 0
    @State private var memoryImages: [String] = []
    @State private var diskImages: [DiskCacheEntry] = []
    @State private var cloudImages: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                List {
                    Section(header: Text("Memory Cache")) {
                        ForEach(memoryImages, id: \ .self) { url in
                            HStack {
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                Text(url)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }

                    Section(header: Text("Disk Cache")) {
                        ForEach(diskImages) { entry in
                            HStack {
                                AsyncImage(url: entry.fileUrl) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                Text(entry.originalUrl)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }

                    Section(header: Text("CloudKit Cache")) {
                        ForEach(cloudImages, id: \ .self) { url in
                            HStack {
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 50, height: 50)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                Text(url)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Cache Test")
            .onAppear {
                Task {
                    await loadCacheContent()
                }
            }
        }
    }

    private func loadCacheContent() async {
        // Load memory cache content using the public computed property
        memoryImages = ImageCache.shared.memoryCacheKeys

        // Load disk cache content using the public computed property
        let fileManager = FileManager.default
        let cacheDirectory = ImageCache.shared.diskCacheDirectory
        if let diskContents = try? fileManager.contentsOfDirectory(atPath: cacheDirectory.path) {
            var entries = [DiskCacheEntry]()
            for file in diskContents {
                // Skip companion .url files
                if file.hasSuffix(".url") { continue }
                let fileUrl = cacheDirectory.appendingPathComponent(file)
                let urlFile = cacheDirectory.appendingPathComponent(file + ".url")
                let originalUrl: String
                if let urlString = try? String(contentsOf: urlFile) {
                    originalUrl = urlString
                } else {
                    originalUrl = file // fallback if companion file is missing
                }
                entries.append(DiskCacheEntry(originalUrl: originalUrl, fileUrl: fileUrl))
            }
            diskImages = entries
        }

        // Load CloudKit cache content
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        let query = CKQuery(recordType: "CachedImage", predicate: NSPredicate(value: true))
        do {
            let records = try await database.perform(query, inZoneWith: nil)
            cloudImages = records.compactMap { $0["url"] as? String }
        } catch {
            print("Error loading CloudKit cache: \(error.localizedDescription)")
        }
    }
}
