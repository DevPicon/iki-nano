require 'xcodeproj'

project_path = '/Users/devpicon/Dev/ondevice-ai-labs/iki-nano/ikinano.xcodeproj'
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'ikinano' }

models_group = project.main_group.find_subpath(File.join('ikinano', 'Models'), true)
models_file = models_group.new_file('LLMModel.swift')
main_target.source_build_phase.add_file_reference(models_file) unless main_target.source_build_phase.files_references.include?(models_file)

repos_group = project.main_group.find_subpath(File.join('ikinano', 'Repositories'), true)
repos_file = repos_group.new_file('LLMModelRepository.swift')
main_target.source_build_phase.add_file_reference(repos_file) unless main_target.source_build_phase.files_references.include?(repos_file)

project.save
puts "Added files successfully."