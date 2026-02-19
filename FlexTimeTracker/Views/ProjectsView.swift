import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var showingAdd = false
    @State private var showingArchived = false
    
    private var activeProjects: [Project] {
        projects.filter { !$0.isArchived }
    }
    
    private var archivedProjects: [Project] {
        projects.filter { $0.isArchived }
    }
    
    var body: some View {
        List {
            Section {
                if activeProjects.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No projects yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add a project to group your time entries\n(e.g., a shoot, client, or event)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(activeProjects) { project in
                        ProjectRow(project: project)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            activeProjects[i].isArchived = true
                        }
                    }
                }
            } header: {
                Text("Active Projects")
            } footer: {
                Text("Projects are optional — entries without a project are tracked as \"General\" time.")
            }
            
            if !archivedProjects.isEmpty {
                Section("Archived") {
                    ForEach(archivedProjects) { project in
                        ProjectRow(project: project)
                            .opacity(0.6)
                            .swipeActions(edge: .leading) {
                                Button("Restore") {
                                    project.isArchived = false
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(project)
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddProjectView()
        }
    }
}

struct ProjectRow: View {
    let project: Project
    @State private var showingEdit = false
    
    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(project.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .fontWeight(.medium)
                    Text("\(project.entries?.count ?? 0) entries · \(project.totalSeconds.hoursMinutes)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showingEdit) {
            EditProjectView(project: project)
        }
    }
}

// MARK: - Add Project

struct AddProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedColorHex = Project.availableColors[0].hex
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g., Super Bowl Shoot", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Project.availableColors, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColorHex == color.hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColorHex = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let project = Project(name: name, colorHex: selectedColorHex)
                        modelContext.insert(project)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Project

struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    @State private var name: String
    @State private var selectedColorHex: String
    
    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _selectedColorHex = State(initialValue: project.colorHex)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Project name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Project.availableColors, id: \.hex) { color in
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if selectedColorHex == color.hex {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColorHex = color.hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Stats") {
                    HStack {
                        Text("Total Entries")
                        Spacer()
                        Text("\(project.entries?.count ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Time")
                        Spacer()
                        Text(project.totalSeconds.hoursMinutes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        project.name = name
                        project.colorHex = selectedColorHex
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
