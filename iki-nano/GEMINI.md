<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

## Definition of Done (DoD)

All tasks and stories must satisfy the following criteria before being marked as complete:

1. **Compilation Guarantee**: Any code change MUST be compiled locally using `xcodebuild`. No compilation errors are allowed.
2. **Comprehensive Validation**: 
   - All automated tests must run successfully.
   - The user MUST manually test the changes on a physical device or simulator and provide confirmation.
   - A story cannot be moved to "Done" in Jira or local task lists without this manual verification.
