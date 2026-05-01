require 'xcodeproj'

project_path = '/Users/devpicon/Dev/ondevice-ai-labs/iki-nano/ikinano.xcodeproj'
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'ikinano' }

views_group = project.main_group.find_subpath(File.join('ikinano', 'Views'), true)
views_file = views_group.new_file('ModelManagementView.swift')
main_target.source_build_phase.add_file_reference(views_file) unless main_target.source_build_phase.files_references.include?(views_file)

project.save
puts "Added ModelManagementView.swift to Xcode"