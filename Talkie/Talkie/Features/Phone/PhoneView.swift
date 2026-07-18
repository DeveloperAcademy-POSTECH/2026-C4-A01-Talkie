//
//  FakeCallView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct PhoneView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Scenario.title,order: .reverse)
    private var scenarios: [Scenario]

    @State private var viewModel = PhoneViewModel()

    var body: some View {
        NavigationStack {
            Form {
                scenarioSection

                delaySection

                reservationButtonSection
            }
            .navigationTitle("전화")
            .onAppear {
                viewModel.selectDefaultScenarioIfNeeded(
                    from: scenarios
                )
            }
            .onChange(of: scenarios.count) {
                viewModel.selectDefaultScenarioIfNeeded(
                    from: scenarios
                )
            }
            .alert(
                "예약 오류",
                isPresented: errorAlertBinding
            ) {
                Button("확인", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

private extension PhoneView {

    var scenarioSection: some View {
        Section("통화 시나리오") {
            if scenarios.isEmpty {
                ContentUnavailableView(
                    "시나리오가 없습니다",
                    systemImage: "phone.badge.plus",
                    description: Text(
                        "먼저 시나리오 탭에서 시나리오를 만들어 주세요."
                    )
                )
            } else {
                Picker(
                    "시나리오",
                    selection: $viewModel.selectedScenario
                ) {
                    ForEach(scenarios) { scenario in
                        Text(scenario.title)
                            .tag(scenario as Scenario?)
                    }
                }
            }
        }
    }

    var delaySection: some View {
        Section("전화 시간") {
            Stepper(
                value: $viewModel.delaySeconds,
                in: 1...300,
                step: 1
            ) {
                HStack {
                    Text("전화 수신")

                    Spacer()

                    Text("\(viewModel.delaySeconds)초 뒤")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    var reservationButtonSection: some View {
        Section {
            Button {
                viewModel.createReservation(
                    modelContext: modelContext
                )
            } label: {
                Text("전화걸기")
                    .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.selectedScenario == nil)
        }
    }

    var errorAlertBinding: Binding<Bool> {
        Binding(
            get: {
                viewModel.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

#Preview {
    PhoneView()
}
