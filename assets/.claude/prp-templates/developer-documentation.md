# PRP Template: Developer Documentation (README.confluence.md)

## Purpose
This template guides Claude Code in creating developer documentation that automatically publishes to Confluence. These files must be named `README.confluence.md` and placed anywhere in the codebase where developer documentation is needed.

## MANDATORY Required Information
Claude Code MUST obtain the following from the user before proceeding:

1. **page_id** (CRITICAL - CANNOT BE GENERATED):
   - Must be a numeric Confluence page ID
   - User MUST provide this - Claude cannot create or guess page IDs
   - Example: 535855431

2. **title**:
   - Clear, descriptive title for the Confluence page
   - Example: "Neural Search Implementation Guide"

3. **space** (optional):
   - Confluence space key (default: "Dev")
   - Use "Dev" for technical/developer documentation unless specified otherwise

4. **labels** (optional):
   - Array of labels for searchability
   - Always include: ["documentation", "dev-tooling"]
   - Add topic-specific labels as appropriate

5. **Documentation scope**:
   - What system/feature/component is being documented
   - Target audience (developers working on what?)

## Claude Code Workflow Steps

### Step 1: Gather Required Information
**MANDATORY**: If the user has not provided a page_id, Claude MUST ask:
```
To create developer documentation that publishes to Confluence, I need:
- Confluence page_id (numeric ID from existing page)
- Documentation title
- What component/feature to document

Please provide the Confluence page_id for this documentation.
```

### Step 2: Determine File Location
- Place README.confluence.md in the most relevant directory
- Examples:
  - TBC...

### Step 3: Create File with Exact Header Format
The file MUST start with this exact YAML header format:
```yaml
---
confluence:
  page_id: [NUMERIC_ID_FROM_USER]
  space: "Dev"
  title: "[Documentation Title]"
  labels: [ "documentation", "dev-tooling", "[topic-label]" ]
  update_mode: "replace"
---
```

### Step 4: Structure Content
After the header, add documentation content:
1. Main heading matching the title
2. Overview/Purpose section
3. Technical details organized by topic
4. Code examples where relevant
5. Configuration examples
6. Troubleshooting section (if applicable)
7. Reference links

### Step 5: Validation Checklist
Claude MUST verify:
- [ ] Header has all required fields (page_id, space, title, labels, update_mode)
- [ ] page_id is numeric (not a string or placeholder)
- [ ] File is named exactly `README.confluence.md`
- [ ] Header uses exact YAML format with proper indentation
- [ ] Content uses Confluence-compatible markdown

## Implementation Approach

### File Map
#### New Files 🆕
- `[relevant-directory]/README.confluence.md` - Developer documentation for [component]

### Technical Details

#### Header Format Requirements
- Must use YAML front matter with `---` delimiters
- `confluence:` key with proper indentation
- All sub-keys indented with exactly 2 spaces
- Labels as YAML array with square brackets
- Strings in quotes

#### Content Guidelines
1. Use Confluence markdown syntax
2. Code blocks with language specification
3. Avoid HTML (use markdown equivalents)
4. Use headers for navigation (#, ##, ###)
5. Include practical examples

#### Publishing Behavior
- Files named `README.confluence.md` are automatically published during build
- `update_mode: "replace"` overwrites existing content and is the only supported value
- Changes publish on next build/deployment automatically
- You need not do anything to publish this or change infrastructure

## Example Reference
See `TBC` for a working example of:
- Proper header format
- Content structure
- Code examples
- Configuration documentation

## Questions for User (if not provided)
1. What is the Confluence page_id for this documentation?
2. What is the title for this documentation page?
3. What component/system should be documented?
4. Are there specific aspects that need emphasis?
5. Should this go in a space other than "Dev"?

## Acceptance Criteria
- [ ] Confluence header with valid page_id present
- [ ] Documentation covers intended scope
- [ ] Examples and code snippets included where relevant
- [ ] File placed in appropriate directory
- [ ] Header format exactly matches required structure
- [ ] Content is developer-focused and technical

## Notes
- NEVER generate or guess page_ids - always get from user
- The build system will fail if header format is incorrect
- Use existing README.confluence.md files as reference
- Keep documentation close to the code it documents