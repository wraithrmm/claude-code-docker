---
name: confluence-documentation
description: Create, test, and publish Confluence documentation using the automated publisher. Use this skill when creating markdown files with Confluence YAML front-matter, validating Confluence output, or understanding the publication pipeline. Covers YAML front-matter, supported markdown, local testing, and CI/CD auto-publish.
---

# Confluence Documentation

Create and publish markdown documentation to Atlassian Confluence using the repository's automated publisher.

## When to Use

- When creating or updating a markdown file that publishes to Confluence
- When asked to publish or document something in Confluence
- When adding the Confluence publish action to a repository's CI
- When troubleshooting Confluence publishing issues

## Prerequisites (MANDATORY)

Before creating a Confluence document, these **must** be in place:

### 1. The Confluence Page Must Already Exist

The publisher **updates** existing pages — it cannot create new ones. The user must:

1. Create a page in Confluence (or identify an existing one to target)
2. Get the page ID:
   - Navigate to the page in Confluence
   - Click the "..." menu > "Page Information"
   - Find `pageId=XXXXXXXXX` in the URL
3. Provide the numeric page ID to you

**You cannot proceed without a page ID.** If the user hasn't provided one, ask them to create the page and give you the ID.

### 2. The CI/CD Workflow Must Include the Confluence Publish Step

Check the repo's CI workflow for `Years-com/confluence-publish-action`. If missing, add this job:

```yaml
  confluence-publish:
    name: Publish Confluence Docs
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - uses: Years-com/confluence-publish-action@v1
        with:
          confluence_base_url: ${{ secrets.CONFLUENCE_BASE_URL }}
          confluence_user_email: ${{ secrets.CONFLUENCE_USER_EMAIL }}
          confluence_api_token: ${{ secrets.CONFLUENCE_API_TOKEN }}
          files: 'README.md'
```

Set `files` to the markdown file(s) to publish (comma-separated), or omit it to auto-discover all `README.confluence.md` files. Add `needs: <gate-job>` if the repo has quality-gate jobs.

The three secrets (`CONFLUENCE_BASE_URL`, `CONFLUENCE_USER_EMAIL`, `CONFLUENCE_API_TOKEN`) must be configured in **Settings > Secrets and variables > Actions**. If they are not, inform the user.

### 3. Environment Variables for Local Testing

Three environment variables are required to publish locally:

| Variable | Description | Example |
|----------|-------------|---------|
| `CONFLUENCE_BASE_URL` | Atlassian instance URL | `https://yourorg.atlassian.net` |
| `CONFLUENCE_USER_EMAIL` | User or service account email | `user@yourorg.com` |
| `CONFLUENCE_API_TOKEN` | Classic (scopeless) API token | `ATATT3x...` |

These should be set in the `.env` file or exported in the shell. Granular/scoped tokens are **not** supported.

## Step-by-Step: Creating a Confluence Document

### Step 1: Choose the File

Any `.md` file can be published — add YAML front-matter and either list it in the `files` action input, or name it `README.confluence.md` for auto-discovery.

### Step 2: Add YAML Front-Matter

Every file must start with a YAML header between `---` markers:

```yaml
---
confluence:
  page_id: 305299457
  space: "YD"
  title: "My Page Title"
  labels: ["automation", "documentation"]
  update_mode: "replace"
---
```

### Step 3: Write the Content

Write standard markdown below the YAML header. See "Supported Markdown Elements" and "Documentation Standards" below.

### Step 4: Test Locally

See "Testing and Validation" below.

### Step 5: Commit

On merge to `main`, the CI/CD pipeline automatically publishes changed files.

## YAML Front-Matter Reference

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `page_id` | number | Numeric Confluence page ID. The page **must already exist**. |
| `title` | string | Page title as it will appear in Confluence. |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `space` | string | `AC` | Confluence space key |
| `labels` | list | `[]` | Labels applied to the page after publishing |
| `update_mode` | string | `replace` | Only `replace` is supported |

### Example Header

```yaml
---
confluence:
  page_id: 2078933017
  space: "YD"
  title: "Workflow Observability Guide"
  labels: ["observability", "elk", "documentation"]
  update_mode: "replace"
---
```

## Supported Markdown Elements

The publisher converts Markdown to Confluence Storage Format (XHTML). These elements are fully supported:

| Element | Markdown Syntax | Confluence Rendering |
|---------|----------------|---------------------|
| Headings | `# H1` through `###### H6` | Native heading styles |
| Bold | `**text**` | Bold text |
| Italic | `*text*` | Italic text |
| Bold italic | `***text***` | Bold italic text |
| Inline code | `` `code` `` | Monospace inline |
| Fenced code blocks | ` ```language ` | Confluence Code macro with syntax highlighting |
| Tables | Pipe tables `\| A \| B \|` | Native Confluence tables with styled headers |
| Unordered lists | `- item` | Bullet lists |
| Ordered lists | `1. item` | Numbered lists |
| Links | `[text](url)` | Clickable hyperlinks |
| Horizontal rules | `---` | Divider line |
| HTML passthrough | `<a name="">`, `<br/>` | Passed through to Confluence |
| Paragraphs | Blank line between text | Separate paragraphs |

### Supported Code Block Languages

The publisher maps language identifiers to Confluence-supported languages:

| Markdown | Confluence | Markdown | Confluence |
|----------|-----------|----------|-----------|
| `bash`, `sh`, `shell` | bash | `python`, `py` | python |
| `yaml`, `yml` | yml | `javascript`, `js` | javascript |
| `typescript`, `ts` | typescript | `json` | javascript |
| `xml` | xml | `html` | html |
| `css` | css | `sql` | sql |
| `java` | java | `go` | go |
| `ruby`, `rb` | ruby | `php` | php |
| `groovy` | groovy | `powershell` | powershell |
| `c` | c | `cpp` | cpp |
| `csharp` | csharp | `diff` | diff |
| *(no language)* | none | `dockerfile` | bash |

## Known Limitations

These markdown patterns do **not** render correctly and should be avoided:

### Nested Lists

Nested bullet points under numbered lists do not render reliably:

```markdown
1. First item
   - nested bullet    <-- AVOID: causes numbering reset
   - nested bullet
2. Second item
```

**Workaround:** Keep lists flat, or use separate sections.

### Code Blocks Under Numbered Lists

Fenced code blocks inside numbered lists reset the numbering:

```markdown
1. First step
2. Second step
```bash
some code           <-- AVOID: breaks numbering
```
3. Third step       <-- will restart at 1
```

**Workaround:** Place code blocks between list sections, not inside them.

### Internal Confluence Links

Standard markdown anchor links (`[text](#section)`) have limited support. They work for external URLs but same-page anchors may not resolve correctly in Confluence.

### Images

Standard markdown images (`![alt](url)`) produce `<img>` tags which have limited support in Confluence. For critical images, use Confluence's native attachment system.

## Testing and Validation

### Dependencies

The publisher scripts live in the `Years-com/confluence-publish-action` repository. Clone it and install dependencies:

```bash
git clone git@github.com:Years-com/confluence-publish-action.git
cd confluence-publish-action
pip install -r requirements.txt
```

### Option 1: Dump HTML (No Credentials Needed)

Inspect the generated Confluence Storage Format without publishing:

```bash
python test_local.py --dump-html path/to/README.confluence.md
```

This outputs the full HTML that would be sent to Confluence. Use this to:
- Verify tables render as `<table>` with proper headers
- Check code blocks use Confluence code macros
- Confirm lists, links, and formatting are correct

### Option 2: Dry Run (Credentials Required)

Validate the file and check the page exists in Confluence, without publishing:

```bash
python test_local.py --dry-run path/to/README.confluence.md
```

This confirms:
- YAML header is valid
- Page ID exists in Confluence
- Authentication works

### Option 3: Live Publish (Credentials Required)

Publish the document to Confluence:

```bash
python test_local.py path/to/README.confluence.md
```

After publishing, verify the page in your browser at:
`https://yourorg.atlassian.net/wiki/spaces/SPACE/pages/PAGE_ID`

### Using publish.py Directly

The full publisher CLI supports additional options:

```bash
# Publish all README.confluence.md files
python publish.py --find-all

# Dry-run all files
python publish.py --find-all --dry-run

# Publish specific files
python publish.py path/to/file.md

# Continue on errors
python publish.py --find-all --no-fail-on-missing
```

## Documentation Standards

### Structure

1. **Start with a clear H1 title** that matches the YAML `title` field
2. **Lead with a summary paragraph** explaining what this page documents
3. **Use H2 for major sections**, H3 for subsections
4. **End with troubleshooting** or reference sections if applicable

### Content Guidelines

- Write in present tense, active voice
- Use numbered lists for sequential steps, bullet lists for unordered items
- Include code examples for any CLI commands, configuration, or API calls
- Use tables for structured reference data (options, fields, parameters)
- Keep paragraphs short — Confluence pages are scanned, not read linearly

### Formatting Rules

- Use inline code (backticks) for: file paths, command names, variable names, field names, values
- Use fenced code blocks for: multi-line commands, configuration examples, JSON/YAML
- Always specify a language for fenced code blocks when applicable
- Use bold for emphasis on key terms on first use, not for entire sentences
- Avoid HTML unless necessary for Confluence-specific rendering

### File Naming

- **Explicit files** (recommended): any `.md` filename, listed in the `files` action input
- **Auto-discovered files**: `README.confluence.md` (one per directory, found when `files` is omitted)

### Labels

Choose labels that help users find the page. Common patterns:
- Technology: `n8n`, `elk`, `docker`, `terraform`
- Purpose: `documentation`, `runbook`, `architecture`, `how-to`
- Process: `ci-cd`, `automation`, `deployment`

## Auto-Generated Page Features

The publisher automatically adds to every published page:

1. **Info banner at the top** — Warns that the page is auto-managed, links to the source repository, names the source file, and warns that direct edits will be overwritten

2. **Source reference at the bottom** — Shows which file generated the page content

These are added by the publisher and should **not** be included in your markdown content.

## CI/CD Behaviour

The `confluence-publish` job runs on push to `main`, only publishes changed files (via `git diff`), and fails the build if Confluence secrets are not configured. Once merged, publishing is automatic.

## Troubleshooting

### "Missing required fields: page_id"

The YAML header is missing `page_id`. Ensure the header has:
```yaml
confluence:
  page_id: 123456789
```

### "No YAML header found"

The file must start with `---` on the first line, followed by YAML, followed by `---`. No content before the first `---`.

### 401 Unauthorized

- Verify `CONFLUENCE_USER_EMAIL` matches your Atlassian account login
- Regenerate the API token — they can silently expire
- Ensure you're using a classic (scopeless) token, not a granular/scoped one

### Page not found (404)

- Double-check the `page_id` value
- Verify the API token has access to the target space
- Confirm the page exists: `https://yourorg.atlassian.net/wiki/spaces/SPACE/pages/PAGE_ID`

### Tables appear as raw text

- Ensure there is a blank line before the table
- Ensure the header separator row uses `|---|` pattern
- Check there are no leading spaces before pipe characters

## Quick Reference Template

Copy this as a starting point for any new Confluence document:

```yaml
---
confluence:
  page_id: REPLACE_WITH_PAGE_ID
  space: "YD"
  title: "REPLACE WITH PAGE TITLE"
  labels: ["documentation"]
  update_mode: "replace"
---

# Page Title

Summary of what this page documents.

## Section One

Content here.

## Section Two

| Column A | Column B | Column C |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |

## Troubleshooting

### Common Issue

Steps to resolve.
```

## Reference Files

- **Publisher action repo:** `Years-com/confluence-publish-action` (contains `publish.py`, `test_local.py`, `test_renderer.py`)
- **Publisher documentation:** `scripts/confluence_publish/README.confluence.md`
- **CI workflow:** `.github/workflows/n8n-ci.yml` (job: `confluence-publish`, uses the action)
