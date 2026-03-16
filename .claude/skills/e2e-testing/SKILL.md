---
name: e2e-testing
description: Write and review Playwright E2E tests for the HITL Eval Portal. Covers test generation from acceptance criteria, page object patterns, assertion strategies, and anti-patterns that cause flaky tests.
---

# Playwright E2E Testing

Write, review, and debug Playwright E2E tests for the HITL Eval Portal.

## MANDATORY: Local Test Run Required for Completion

Changes that include E2E tests CANNOT be considered completed until the tests have been run locally and confirmed to pass. Do not mark work as done, move tasks to completed, or present changes as finished until you have executed the tests and verified they all pass. A green CI pipeline is not a substitute -- tests must pass on the local dev stack first.

## When to Use

- Creating new E2E test specs
- Reviewing existing E2E tests for flakiness
- Adding page objects or fixtures
- Debugging CI test failures

## Golden Rule: Acceptance Criteria Are the Source of Truth

- Tests MUST be generated from acceptance criteria documents
- Each test assertion must trace back to a specific AC (referenced via `// AC-X.Y.Z` comments)
- Do NOT extrapolate beyond what the AC describes -- if the AC doesn't mention it, don't test it
- Do NOT invent requirements, edge cases, or behaviors not specified in the AC
- The AC defines what needs to happen AND what should not happen -- test both

## Test Structure Conventions

- **File naming:** `<feature-name>.spec.ts` in `tests/functional/specs/`
- **Import fixtures** from `../fixtures/base.ts` (not raw `@playwright/test`)
- **MANDATORY** `test.beforeAll` that resets data via reset helpers
- Group related tests in `test.describe()` blocks
- One user journey per test -- don't chain unrelated flows
- Use `screenshotStep()` at each visible state change

```typescript
import { test, expect } from "../fixtures/base";
import { getDb, resetEvaluations } from "../helpers/reset-data";

test.beforeAll(async () => {
  await resetEvaluations(getDb());
});

test.describe("Feature Name", () => {
  test("does the expected thing", async ({ evaluationsListPage, screenshotStep }) => {
    await evaluationsListPage.navigate();

    await screenshotStep("Initial state loaded", async () => {
      await expect(evaluationsListPage.heading).toBeVisible(); // AC-1.1
    });
  });
});
```

## Auto-Retrying Assertions (MANDATORY)

ALWAYS use web-first assertions for DOM state. These auto-retry until the condition is met or the timeout expires:

```typescript
// CORRECT -- auto-retrying
await expect(locator).toBeVisible();
await expect(locator).toContainText("Expected");
await expect(locator).toHaveURL(/pattern/);
await expect(page).toHaveTitle("Expected");
await expect(locator).toHaveCount(3);
await expect(locator).toHaveAttribute("aria-selected", "true");
```

NEVER do one-shot reads followed by a static assertion:

```typescript
// WRONG -- one-shot read, no retry
const text = await locator.textContent();
expect(text).toContain("Expected");

// WRONG -- no retry on visibility
expect(await locator.isVisible()).toBe(true);

// WRONG -- no retry on count
const count = await locator.count();
expect(count).toBe(3);
```

Non-retrying assertions (`toBe`, `toEqual`, `toContain`) are ONLY for already-resolved values: JS variables, computed results, API response bodies.

For async non-DOM checks (polling APIs, checking Firestore), use `expect.poll()` or `expect.toPass()`:

```typescript
// Polling an API until it returns the expected value
await expect.poll(async () => {
  const response = await page.request.get("/api/status");
  return response.json();
}, { timeout: 10_000 }).toMatchObject({ status: "completed" });

// Retrying a complex assertion block
await expect(async () => {
  const rows = await page.getByRole("row").count();
  expect(rows).toBeGreaterThan(0);
}).toPass({ timeout: 10_000 });
```

## No Hard Waits

NEVER use `waitForTimeout()` or `page.waitForTimeout(N)`.

Use semantic waits:

```typescript
// CORRECT
await page.waitForURL(/\/evaluations/);
await page.waitForLoadState("domcontentloaded");
await expect(locator).toBeVisible(); // auto-retrying wait

// WRONG
await page.waitForTimeout(2000);
```

`waitForLoadState("networkidle")` does NOT guarantee DOM re-render -- always follow with an `expect()` assertion on the expected DOM state.

## Locator Priority

Use locators in this priority order:

1. `getByRole()` -- buttons, headings, links, rows, cells
2. `getByLabel()` -- form inputs
3. `getByPlaceholder()` -- inputs without labels
4. `getByText()` -- visible text content
5. `data-slot` / `data-testid` -- custom test attributes
6. CSS selector -- last resort only

Never use CSS class names, XPath, or DOM structure selectors.

Scope locators to context:

```typescript
// CORRECT -- scoped to the row
const row = page.getByRole("row", { name: /9001/ });
await expect(row.getByRole("cell", { name: "pending" })).toBeVisible();

// WRONG -- unscoped, fragile
await expect(page.locator("td:nth-child(3)")).toContainText("pending");
```

## Page Object Model

Every UI interaction goes through a page object in `tests/functional/pages/`.

### Ownership rules

- **Page objects** own locators and actions -- specs own assertions and test logic
- **Exception:** page objects MAY contain `expect*()` helper methods that encapsulate retrying assertion patterns (e.g., `expectStatusForTicket()`)

### Naming conventions

| Type | Pattern | Example |
|------|---------|---------|
| Stable locator | Readonly property | `heading`, `table`, `dialog` |
| Dynamic locator | `get*()` method | `getRowByTicketId(id)` |
| User action | `click*()`/`fill*()` | `clickApprove()`, `fillFeedback()` |
| Assertion helper | `expect*()` | `expectStatusForTicket(id, status)` |

### Example page object

```typescript
import { type Page, type Locator, expect } from "@playwright/test";

export class EvaluationsListPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly table: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole("heading", { name: /evaluations/i });
    this.table = page.getByRole("table");
  }

  async navigate() {
    await this.page.goto("/evaluations");
  }

  getRowByTicketId(ticketId: number): Locator {
    return this.table.getByRole("row", { name: new RegExp(String(ticketId)) });
  }

  async expectStatusForTicket(ticketId: number, status: string) {
    const row = this.getRowByTicketId(ticketId);
    await expect(row).toContainText(status);
  }
}
```

Do NOT use raw Playwright selectors in spec files. If a new interaction is needed, add a method to the relevant page object first.

## Test Isolation & Data Reset

Every spec file MUST have a `test.beforeAll` that resets its data:

```typescript
import { getDb, resetEvaluations } from "../helpers/reset-data";

test.beforeAll(async () => {
  await resetEvaluations(getDb());
});
```

Available helpers from `../helpers/reset-data.ts`:

| Helper | What it resets |
|--------|---------------|
| `resetEvaluations(db)` | Deletes and re-creates all evaluations as `status: "pending"` |
| `resetUsers(db)` | Resets all test users to default state |
| `resetDatasets(db)` | Clears `datasets`, `dataset_names`, `dataset_versions`, `evaluation_snapshots`, `audit_events` |
| `resetPitNotes(db)` | Clears `pit_notes` and `pit_note_groups` |
| `resetRuns(db)` | Clears `evaluation_runs` |

No test may depend on state from a previous spec file.

If tests need non-default state (e.g., approved evaluations), set it up programmatically in `beforeAll` after calling the reset helper:

```typescript
test.beforeAll(async () => {
  const db = getDb();
  await resetEvaluations(db);

  // Set ticket #9001 to approved
  const snapshot = await db
    .collection("evaluations")
    .where("ticketId", "==", 9001)
    .limit(1)
    .get();

  await snapshot.docs[0].ref.update({
    status: "approved",
    reviewerId: "reviewer-a-id",
    reviewerName: "Alice Reviewer",
    reviewedAt: FieldValue.serverTimestamp(),
  });
});
```

## Deterministic Test Data

- No `Math.random()`, `Date.now()`, `crypto.randomUUID()` in test data
- Use fixed seed data from reset helpers
- Fixed test users: `reviewer-a@test.local`, `reviewer-b@test.local`, `admin@test.local`, `developer@test.local`
- Fixed test tickets: #9001, #9002, #210474711

## Auth Context

Default auth: `reviewer-a@test.local` (via playwright config `storageState`).

Switch with:

```typescript
import path from "path";

test.use({
  storageState: path.resolve(__dirname, "../../../playwright/.auth/admin.json"),
});
```

Available sessions: `reviewer-a.json`, `reviewer-b.json`, `admin.json`, `developer.json`

## Anti-Pattern Quick Reference

| Anti-pattern | Why it's wrong | Correct approach |
|---|---|---|
| `const text = await el.textContent(); expect(text)...` | One-shot read, no retry | `await expect(el).toContainText(...)` |
| `expect(await el.isVisible()).toBe(true)` | No retry on visibility | `await expect(el).toBeVisible()` |
| `await page.waitForTimeout(2000)` | Arbitrary sleep | `await expect(el).toBeVisible()` or `waitForURL()` |
| Raw `page.locator('.my-class')` in spec | Brittle, belongs in page object | Add method to page object |
| Testing behavior not in AC | Scope creep, untraceable | Only test what AC specifies |
| No `beforeAll` data reset | Depends on previous test state | Add `resetEvaluations(getDb())` etc. |
| Random test data | Non-reproducible failures | Use fixed seed data |
| `waitForLoadState("networkidle")` alone | Doesn't guarantee DOM render | Follow with `await expect(el).toBeVisible()` |
| `const count = await el.count(); expect(count)...` | One-shot read of count | `await expect(el).toHaveCount(N)` |

## Sources

- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Playwright Assertions](https://playwright.dev/docs/test-assertions)
- [Playwright Page Object Model](https://playwright.dev/docs/pom)
