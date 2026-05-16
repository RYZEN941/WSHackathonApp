//
//  CreateRegistryView.swift
//  WSHackathonApp
//

import SwiftUI

struct CreateRegistryView: View {

    @StateObject private var viewModel = CreateRegistryViewModel()
    @EnvironmentObject var tabBarVM: WSTabBarViewModel
    @EnvironmentObject var registryRepo: RegistryRepository

    @State private var navigateToSuccess = false

    var body: some View {
        Form {
            Section {
                TextField(AppStrings.Registry.firstName, text: $viewModel.firstName)
                    .textContentType(.givenName)
                TextField(AppStrings.Registry.lastName, text: $viewModel.lastName)
                    .textContentType(.familyName)
            } header: {
                sectionLabel("Personal Details")
            }

            Section {
                Picker(AppStrings.Registry.event, selection: $viewModel.selectedEvent) {
                    ForEach(RegistryEvent.allCases) { event in
                        Text(event.title).tag(event)
                    }
                }

                DatePicker(
                    AppStrings.Registry.eventDate,
                    selection: $viewModel.date,
                    in: Date()...,
                    displayedComponents: .date
                )
            } header: {
                sectionLabel("Event Details")
            }

            Section {
                Button(action: createRegistry) {
                    Text(AppStrings.Registry.createYourRegistry)
                        .font(WSFont.subheading(16))
                        .foregroundStyle(viewModel.isValid ? Color.white : Color.wsMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            if viewModel.isValid {
                                WSGradient.button
                            } else {
                                Color.wsSurface
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!viewModel.isValid)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .wsAppBackground()
        .navigationTitle(AppStrings.Registry.createYourRegistry)
        .navigationBarTitleDisplayMode(.inline)
        .tint(.wsCharcoal)
        .navigationDestination(isPresented: $navigateToSuccess) {
            RegistrySuccessView()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(WSFont.caption(12))
            .foregroundStyle(Color.wsTextSecondary)
            .textCase(nil)
    }

    private func createRegistry() {
        registryRepo.createRegistry(
            firstName: viewModel.firstName,
            lastName: viewModel.lastName,
            event: viewModel.selectedEvent,
            date: viewModel.date
        )
        navigateToSuccess = true
    }
}
