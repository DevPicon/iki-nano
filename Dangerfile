warn("This PR touches `ikinano.xcodeproj/project.pbxproj`. Double-check that project setting changes are intentional.") if git.modified_files.include?("ikinano.xcodeproj/project.pbxproj")

warn("Large PR: #{git.lines_of_code} changed lines. Consider splitting if review becomes hard.") if git.lines_of_code > 800

swift_files = (git.modified_files + git.added_files).select { |file| file.end_with?(".swift") }
service_changes = swift_files.any? { |file| file.include?("/Services/") || file.include?("/ViewModels/") }

warn("Service/ViewModel changes without tests. Consider adding coverage or a manual validation note in the PR.") if service_changes

markdown("""
## Automated PR Review

- CI will run SwiftLint and an iOS build on every PR.
- Review carefully when changing inference engine code, project settings, or generated Xcode metadata.
""")
