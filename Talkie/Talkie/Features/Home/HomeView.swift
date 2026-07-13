//
//  HomeView.swift
//  Talkie
//
//  Created by DS on 7/11/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var callerProfiles: [CallerProfile]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("설정된 가짜 전화 상대")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    if let callerProfile = callerProfiles.first {
                        Text(callerProfile.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(callerProfile.relationship)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("설정된 프로필이 없습니다")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.1))
                .cornerRadius(16)
                
                Button {
                    
                } label: {
                    Text("가상 통화 시작")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                
                List {
                    ForEach(callerProfiles) { profile in
                        Section {
                            let sortedLines = profile.scriptLines.sorted {
                                $0.sortOrder < $1.sortOrder
                            }
                            
                            if sortedLines.isEmpty {
                                Text("등록된 대사X")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(sortedLines) { scriptLine in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(scriptLine.sortOrder + 1).")
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                        
                                        Text(scriptLine.text)
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.name)
                                        .font(.headline)
                                    
                                    Text(profile.relationship)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}
