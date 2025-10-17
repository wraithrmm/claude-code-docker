# Playwright Visual Testing Guidelines

This document provides comprehensive guidance for using Playwright to verify visual changes in web applications.

## CRITICAL: Mandatory Visual Verification

**REQUIREMENT**: ALL template and CSS changes MUST be verified using Playwright before being considered complete. This is non-negotiable.

## SSL Certificate Handling

Development environments will always show SSL certificate warnings. This is expected behavior.

### How to Handle SSL Warnings:
1. When navigating to `https://aurora.localhost/` or similar dev URLs
2. Browser will show security warning page
3. Click **"Advanced"** button
4. Click **"Accept the Risk and Continue"** (Firefox) or equivalent
5. Page will load normally after accepting

### Example Workflow:
```javascript
// Navigate to page
mcp__playwright__browser_navigate("https://aurora.localhost/")
// If SSL warning appears, click through it
mcp__playwright__browser_click("Advanced")
mcp__playwright__browser_click("Accept the Risk and Continue")
```

## Screenshot Management

### Storage Location
- **Output location**: `/Users/claude-code/screenshots/`

### File Naming Convention
- Use descriptive names with context
- Include iteration numbers when doing iterative fixes
- Examples:
   - `page-name-desktop-before.png`
   - `page-name-desktop-iteration-1.png`
   - `page-name-desktop-iteration-2.png`
   - `page-name-mobile-before.png`
   - `page-name-mobile-iteration-1.png`
   - `page-name-desktop-final.png`

## Iterative Testing Workflow

### MANDATORY Process:
1. **Initial Capture**
   - Navigate to the page
   - Handle SSL if needed
   - Take initial screenshot
   - Store in user directory

2. **Analysis Phase**
   - Examine screenshot for visual defects
   - Document all issues found
   - Prioritize fixes by severity

3. **Fix Implementation**
   - Make necessary CSS/template changes
   - Be specific about what you're fixing

4. **Verification Cycle**
   - Take new screenshot
   - Compare with previous
   - Identify remaining issues
   - If issues remain, return to step 3
   - Continue until perfect

5. **Final Validation**
   - Confirm all issues resolved
   - Take final screenshots for record
   - Test on multiple viewports

### MANDATORY: Common issues to check
   - Text overflow or excessive wrapping
   - Buttons or elements overlapping their containers
   - Alignment problems between elements
   - Container overflow (elements extending beyond boundaries)
   - Loading indicators stuck visible
   - Responsive layout breaks
   - Z-index/layering issues
   - Inconsistent spacing or padding
   - Images not scaling properly
   - Form elements not fitting properly
   - Content overflowing the viewport horizontally (going off the side of the screen)

## Responsive Testing Requirements

### Required Viewport Sizes:
```javascript
// Desktop
mcp__playwright__browser_resize(1440, 900)

// Tablet (optional but recommended)
mcp__playwright__browser_resize(768, 1024)

// Mobile
mcp__playwright__browser_resize(375, 812)
```

### Mobile Testing Specifics:
- Check for horizontal scrolling (should not exist)
- Verify touch target sizes (minimum 44x44px)
- Test collapsible navigation
- Verify text remains readable
- Check form input usability
- Validate button positioning

## Page Navigation Patterns

### Scrolling for Full Page Capture:
```javascript
// Scroll to capture below fold content
mcp__playwright__browser_evaluate("() => window.scrollBy(0, 400)")

// Scroll to specific element
mcp__playwright__browser_evaluate("() => document.querySelector('.checkout_right').scrollIntoView()")

// Scroll to bottom
mcp__playwright__browser_evaluate("() => window.scrollTo(0, document.body.scrollHeight)")
```

### Taking Screenshots:
```javascript
// Basic viewport screenshot
mcp__playwright__browser_take_screenshot("filename.png")

// Full page screenshot
mcp__playwright__browser_take_screenshot("fullpage.png", true) // fullPage parameter

// Element-specific screenshot (when available)
mcp__playwright__browser_take_screenshot("element.png", false, "element_ref")
```

## Workflow Example: CSS Changes

```markdown
1. Initial State Documentation
   - Navigate to page
   - Take "before" screenshot
   - Document current issues

2. Make CSS Changes
   - Edit CSS files
   - Apply modern styling

3. Iterative Verification
   - Take screenshot: "iteration-1.png"
   - Issues found: "buttons overflow, text wrapping"
   - Fix overflow issue
   - Take screenshot: "iteration-2.png"
   - Issues found: "text still wrapping"
   - Fix text wrapping
   - Take screenshot: "iteration-3.png"
   - No issues found

4. Responsive Verification
   - Resize to mobile (375x812)
   - Take screenshot: "mobile-1.png"
   - Fix any mobile-specific issues
   - Take screenshot: "mobile-final.png"

5. Final Validation
   - Desktop: Perfect ✓
   - Mobile: Perfect ✓
   - Ready to present solution
```

## Using the Playwright Visual Tester Agent

### When to Use the Sub-agent vs Direct MCP

**MANDATORY**: Always use the Playwright Visual Tester Agent unless instructed to do otherwise by the user.

The `playwright-visual-tester` agent is available for streamlined visual testing that reduces context pollution in conversations.

### Use the Sub-agent When:
- Performing routine visual verification after changes
- Capturing final screenshots without showing intermediate steps
- Running standard multi-step verification workflows
- You want a clean conversation without automation details

### Use Direct MCP Commands When:
- Debugging specific interaction issues
- Learning or demonstrating Playwright capabilities
- Needing fine-grained control over each step
- Troubleshooting failed automation sequences

### Sub-agent Usage Example:
```markdown
Instead of multiple MCP commands cluttering the conversation:
❌ mcp__playwright__browser_navigate("https://aurora.localhost/")
❌ mcp__playwright__browser_click("Advanced")
❌ mcp__playwright__browser_click("Accept the Risk")
❌ mcp__playwright__browser_take_screenshot("result.png")

Use the agent for a clean result:
✅ Task(subagent_type="playwright-visual-tester", 
     prompt="Navigate to https://aurora.localhost/ and capture screenshot as aurora-homepage.png")
```

The sub-agent will handle SSL warnings, wait for page loads, and return only the final screenshot without polluting the conversation with implementation details.

## Integration with Aurora Workflow

### When to Use Playwright:
- ANY changes to files in `/templates/` directory
- ANY changes to CSS files
- Layout modifications
- Responsive design updates
- UI component changes
- Theme modifications
- Email template updates (render and capture)

### Violation Examples:
❌ Making CSS changes without screenshots
❌ Claiming fixes work without visual proof
❌ Single screenshot without iteration
❌ Desktop-only testing for responsive sites
❌ Not copying screenshots to user directory

### Correct Approach:
✅ Screenshot before changes
✅ Multiple iterations with screenshots
✅ Test all viewport sizes
✅ Store all screenshots properly
✅ Continue until zero visual defects

## Advanced Techniques

### Snapshot Analysis:
```javascript
// Get page structure for debugging
mcp__playwright__browser_snapshot()
// Returns accessibility tree useful for understanding page structure
```

### Console Message Monitoring:
```javascript
// Check for JavaScript errors
mcp__playwright__browser_console_messages()
// Review for errors that might affect rendering
```

### Network Request Monitoring:
```javascript
// Check if resources loaded
mcp__playwright__browser_network_requests()
// Useful for debugging missing images/styles
```

## Best Practices

1. **Always iterate** - Never accept the first result if issues exist
2. **Document issues** - Clearly state what problems you see
3. **Be specific** - "Button overflows by 10px on right side" not "button looks wrong"
4. **Test interactions** - Hover states, focus states, active states
5. **Consider animations** - Some issues only appear during transitions
6. **Check loading states** - Ensure loading indicators hide properly
7. **Verify empty states** - Test with no data as well as with data
8. **Cross-browser notes** - Document any browser-specific issues

## Troubleshooting

### Common Issues and Solutions:

**Screenshot not saving:**
- Check `/Users/claude-code/screenshots/` directory exists
- Verify filename is valid
- Ensure no special characters in filename

**SSL Certificate Loop:**
- Clear browser data with new session
- Verify URL is correct
- Check for redirect loops

**Elements not visible:**
- Wait for page load
- Check for lazy loading
- Verify JavaScript executed
- Use wait commands when needed

**Responsive testing issues:**
- Clear viewport size before setting new
- Allow time for reflow
- Check media query breakpoints
- Verify viewport meta tag

## Summary

Visual verification through Playwright is MANDATORY for all template and CSS work. This ensures:
- High quality user experience
- Consistent visual presentation
- Responsive design integrity
- Early detection of visual regressions
- Professional delivery standards

Remember: **Iterate until perfect** - This is not optional.