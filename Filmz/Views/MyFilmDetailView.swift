import SwiftUI
import Logging

struct MyFilmDetailView: View {
    @StateObject var viewModel: MyFilmDetailViewModel
    let logger = Logger(label: "MyFilmDetailView")

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Render film details and allow inline editing
                Section {
                    ImdbFilmDetailView(imdbId: viewModel.myFilm.imdbId ?? "")
                }
                Section(
                    header: Text("Watch Status")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                ) {
                    Toggle("Watched", isOn: $viewModel.myFilm.watched)
                    if viewModel.myFilm.watched {
                        DatePicker(
                            "Watch Date",
                            selection: Binding(
                                get: { viewModel.myFilm.watchDate ?? Date() },
                                set: { viewModel.myFilm.watchDate = $0 }
                            ), displayedComponents: .date
                        )
                        Button("Clear Date") {
                            viewModel.myFilm.watchDate = nil
                        }
                    }
                }
                Section(
                    header: Text("Additional Info")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                ) {
                    HStack {
                        Text("Streaming Service")
                        TextField(
                            "Streaming Service",
                            text: Binding(
                                get: {
                                    viewModel.myFilm.streamingService ?? ""
                                },
                                set: {
                                    viewModel.myFilm.streamingService =
                                        $0.isEmpty ? nil : $0
                                }
                            )
                        )
                    }
                    HStack {
                        Text("Recommended by")
                        TextField(
                            "Recommended by",
                            text: Binding(
                                get: { viewModel.myFilm.recommendedBy ?? "" },
                                set: { _ in }
                            )
                        )
                    }
                    HStack {
                        Text("Intended Audience")
                        Spacer()
                        Picker(
                            "", selection: $viewModel.myFilm.intendedAudience
                        ) {
                            Text("Me alone").tag(MyFilm.AudienceType.alone)
                            Text("Me and partner").tag(
                                MyFilm.AudienceType.partner)
                            Text("Family").tag(MyFilm.AudienceType.family)
                        }
                    }
                }
                // Controls to commit changes
                Button("Save") {
                    Task {
                        await viewModel.commitChanges()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
            }
            .padding()

        }
        .onAppear {
            logger.info("Entering MyFilmDetailView.body")
        }
    }
}

#Preview {
    let batmanId = "tt0372784"
    let lassoId = "tt10986410"
    let myFilm =  MyFilm.init(
        imdbId: batmanId, intendedAudience: MyFilm.AudienceType.family)
    
    let myFilmRepository = MyFilmRepositoryMock()
    let filmStore = MyFilmStore(myFilmRepository: myFilmRepository)

    let viewModel = MyFilmDetailViewModel(myFilmId: myFilmRepository.films[0].id, filmStore: filmStore)
    NavigationView {
        MyFilmDetailView(viewModel: viewModel)
    }
}