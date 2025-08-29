---
description: Replace uniscribe with kb in refterm using systematic 6-step replacement cycles
argument-hint: [specific component or "continue"]
---

# Parse the argument (optional specific component to focus on)
COMPONENT=$ARGUMENTS

# Define the three critical paths
UNISCRIBE_SOURCE="~/refterm-uniscribe"
KB_LIBRARY="~/kb"
REFTERM_KB_DEST="~/refterm-kb"

# Check if we're already on a specialized branch, create one if not
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "develop" ]]; then
  git checkout -b "replace-uniscribe-with-kb-$(date +%Y%m%d)"
else
  echo "Already on specialized branch: $CURRENT_BRANCH"
fi

# Initial setup and analysis phase
# CRITICAL: Create and maintain a comprehensive todolist throughout!
Use researcher agent to analyze all three codebases and create initial todolist:

1. Research uniscribe usage patterns in $UNISCRIBE_SOURCE
2. Research kb capabilities and API in $KB_LIBRARY
3. Research current replacement progress in $REFTERM_KB_DEST
4. MANDATORY: Create detailed todolist with TodoWrite tool following the 6-step pattern
   - The todolist is your PRIMARY tracking mechanism
   - Keep it updated CONSTANTLY throughout the replacement process
   - Track which uniscribe features have been replaced and which remain

# Execute the replacement process with 6-step cycles
# Each cycle handles one specific uniscribekb replacement task

For each replacement task, follow this 6-step sequence:

Step 1 - Research Uniscribe Implementation:
  Use researcher to understand uniscribe usage in refterm-uniscribe
  - Mark current research task as in_progress in todolist
  - Analyze specific uniscribe API calls and features
  - Understand text shaping/rendering pipeline
  - Identify font handling and glyph processing
  - Document complex script support requirements
  - Note performance characteristics and optimizations
  - Update todolist with specific uniscribe features found

Step 2 - Research KB Equivalent Functionality:
  Use researcher to find kb's approach to the same problem
  - Continue tracking in todolist
  - Study kb's text rendering architecture in $KB_LIBRARY
  - Map uniscribe features to kb equivalents
  - Understand kb's API for similar operations
  - Identify any gaps or different approaches
  - Note kb's performance characteristics
  - Document how kb handles what uniscribe was doing
  - Update todolist with kb implementation approach

Step 3 - Research Current Replacement State:
  Use researcher to check progress in refterm-kb
  - Examine what's already been replaced in $REFTERM_KB_DEST
  - Identify partial implementations or TODOs
  - Check for any temporary shims or compatibility layers
  - Understand integration patterns already established
  - Find where this specific replacement should go
  - Note any existing helper functions or utilities
  - THIS IS CRITICAL: maintain consistency with existing replacements

Step 4 - Execute Replacement:
  Use executioner to implement the uniscribekb replacement
  - Mark execution task as in_progress in todolist
  - Remove uniscribe-specific code systematically
  - Implement kb equivalent following established patterns
  - Ensure proper memory management (kb may use different allocation)
  - Handle edge cases that differ between uniscribe and kb
  - Maintain performance parity or improvement
  - Mark completed replacement as done IMMEDIATELY

Step 5 - Research Replacement Quality:
  Use researcher to verify the replacement is complete and correct
  - Compare functionality between old uniscribe and new kb implementation
  - Verify all text rendering cases still work
  - Check performance characteristics
  - Ensure no uniscribe dependencies remain
  - Validate kb patterns are used correctly
  - Identify any regressions or missing features
  - Test complex scripts and edge cases if applicable

Step 6 - Adjust Todos & Commit:
  MANDATORY: Full todolist update and commit cycle
  - Commit current replacement with descriptive message (e.g., "Replace uniscribe ScriptShape with kb text shaping")
  - Mark ALL completed replacements as done in todolist
  - Add tasks for any issues discovered in Step 5
  - Add follow-up tasks for related uniscribe removals
  - Remove obsolete tasks that are no longer needed
  - Ensure todolist tracks remaining uniscribe dependencies
  - Maintain the 6-step pattern for remaining replacements
  - Continue cycle if more replacements needed
  - NEVER skip this todolist update - it's CRITICAL for tracking

# Example todolist structure for uniscribekb replacement:
1. Research: Analyze uniscribe's ScriptItemize usage in refterm-uniscribe
2. Research: Study kb's text segmentation approach
3. Research: Check ScriptItemize replacement status in refterm-kb
4. Execute: Replace ScriptItemize with kb segmentation
5. Research: Verify segmentation replacement quality
6. Adjust & Commit: Update todos and commit segmentation replacement
7. Research: Analyze uniscribe's ScriptShape glyph generation
8. Research: Study kb's glyph shaping system
9. Research: Check current glyph shaping in refterm-kb
10. Execute: Replace ScriptShape with kb glyph shaping
11. Research: Verify glyph shaping quality and correctness
12. Adjust & Commit: Update todos and commit glyph shaping
...continue 6-step pattern...

# Special considerations for uniscribekb replacement:
- Uniscribe is Windows-specific, kb is cross-platform
- Memory allocation patterns differ significantly
- Performance characteristics may vary
- Complex script support needs careful testing
- Font handling approaches are fundamentally different
- Some uniscribe features may not have direct kb equivalents

# Quality assurance and final commit
Final research step to validate the complete replacement:
- Verify ALL uniscribe dependencies are removed
- Check that all text rendering features work with kb
- Ensure no Windows-specific code remains (unless intentional)
- Validate performance meets or exceeds uniscribe version
- Test with various fonts and scripts
- Make final commit summarizing the complete uniscribekb replacement

Think carefully at each step! The goal is systematic replacement of uniscribe with kb while maintaining all functionality!

REMEMBER: The todolist is your primary tool for success - keep it updated CONSTANTLY throughout all 6 steps!
REMEMBER: This is a REPLACEMENT, not a port - uniscribe code must be removed, not adapted!
REMEMBER: Always research all three codebases before making changes!