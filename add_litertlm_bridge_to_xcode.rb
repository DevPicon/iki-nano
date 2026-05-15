require 'xcodeproj'

project_path = 'iki-nano-gemma-e2b/ikinano.xcodeproj'
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'ikinano' }

main_target.build_configurations.each do |config|
  config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = 'ikinano/ikinano-Bridging-Header.h'
  config.build_settings['SWIFT_OBJC_INTEROP_MODE'] = 'objcxx'
  
  # Framework search paths
  framework_search_paths = config.build_settings['FRAMEWORK_SEARCH_PATHS'] || ['$(inherited)']
  framework_search_paths = [framework_search_paths] if framework_search_paths.is_a?(String)
  framework_search_paths << '"$(SRCROOT)/Frameworks"'
  config.build_settings['FRAMEWORK_SEARCH_PATHS'] = framework_search_paths

  other_ldflags = config.build_settings['OTHER_LDFLAGS'] || ['$(inherited)']
  other_ldflags = [other_ldflags] if other_ldflags.is_a?(String)
  
  # Clean up bad flags
  other_ldflags.reject! { |flag| flag == '-framework' || flag == 'AVFoundation' || flag == 'AudioToolbox' || flag == 'CoreAudio' || flag == '-lLiteRTLM' || flag == '-all_load' }
  
  config.build_settings['OTHER_LDFLAGS'] = other_ldflags
  
  # RESTORE HEADER SEARCH PATHS
  header_search_paths = config.build_settings['HEADER_SEARCH_PATHS'] || ['$(inherited)']
  header_search_paths = [header_search_paths] if header_search_paths.is_a?(String)
  header_search_paths << '"$(SRCROOT)/Frameworks/LiteRTLM.xcframework/ios-arm64/LiteRTLM.framework/Headers"'
  header_search_paths << '"$(SRCROOT)/Frameworks/LiteRTLM.xcframework/ios-arm64_x86_64-simulator/LiteRTLM.framework/Headers"'
  header_search_paths << '"$(SRCROOT)/Frameworks/LiteRTLM.xcframework/ios-arm64-simulator/LiteRTLM.framework/Headers"'
  config.build_settings['HEADER_SEARCH_PATHS'] = header_search_paths
  
  # Clean up library search paths
  library_search_paths = config.build_settings['LIBRARY_SEARCH_PATHS']
  if library_search_paths
    library_search_paths = [library_search_paths] if library_search_paths.is_a?(String)
    library_search_paths.reject! { |path| path.include?('LiteRTLM.xcframework') }
    config.build_settings['LIBRARY_SEARCH_PATHS'] = library_search_paths
  end
  
  # Set Runpath Search Paths to ensure dyld can find the dynamic framework at runtime
  rpath = config.build_settings['LD_RUNPATH_SEARCH_PATHS'] || ['$(inherited)']
  rpath = [rpath] if rpath.is_a?(String)
  rpath << '@executable_path/Frameworks' unless rpath.include?('@executable_path/Frameworks')
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = rpath
end

# Link System Frameworks
frameworks_group = project.frameworks_group
link_phase = main_target.frameworks_build_phase

['AVFoundation.framework', 'AudioToolbox.framework', 'CoreAudio.framework'].each do |framework|
  ref = frameworks_group.find_file_by_path("System/Library/Frameworks/#{framework}") ||
        frameworks_group.new_reference("System/Library/Frameworks/#{framework}")
  ref.source_tree = 'SDKROOT'
  link_phase.add_file_reference(ref) unless link_phase.files_references.include?(ref)
end

# Link AND Embed the Dynamic LiteRTLM XCFramework
framework_path = 'Frameworks/LiteRTLM.xcframework'
framework_ref = frameworks_group.find_file_by_path(framework_path) || frameworks_group.new_file(framework_path)

# 1. Add to Link phase
link_phase.add_file_reference(framework_ref) unless link_phase.files_references.include?(framework_ref)

# 2. Add to Embed phase (MUST be Signed on copy for launch)
embed_phase = main_target.copy_files_build_phases.find { |p| p.name == 'Embed Frameworks' } || 
              main_target.new_copy_files_build_phase('Embed Frameworks')
embed_phase.dst_subfolder_spec = '10' # 10 is the spec for Frameworks

# Find or add build file for this reference in this phase
build_file = embed_phase.add_file_reference(framework_ref)
build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }

project.save
puts "Successfully configured build settings and ensured framework is properly Embedded and Signed."
