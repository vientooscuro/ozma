const { test, expect } = require('@playwright/test')

// Checks the `save_confirm` column attribute: editing such a field must ask
// before the changes are submitted, and declining must not save anything.
//
// Requires a form user view whose field carries the attribute, e.g.
//   dev.save_confirm_test_form  (field `mark_code` with save_confirm = {...})
// Point E2E_SAVE_CONFIRM_URL at it:
//   E2E_SAVE_CONFIRM_URL='/views/dev/save_confirm_test_form?id=1' yarn e2e save-confirm

async function login(page) {
  const usernameField = page.locator('#username')
  const passwordField = page.locator('#password')
  const loginButton = page.locator('#kc-login')

  const loginFormVisible =
    (await usernameField.count()) > 0 &&
    (await passwordField.count()) > 0 &&
    (await loginButton.count()) > 0

  if (!loginFormVisible) return

  await usernameField.fill(process.env.E2E_LOGIN ?? 'admin@example.com')
  await passwordField.fill(process.env.E2E_PASSWORD ?? 'admin')
  await loginButton.click()
  await page.waitForLoadState('networkidle')
}

const viewUrl = process.env.E2E_SAVE_CONFIRM_URL

test.describe('save_confirm attribute', () => {
  test.skip(
    !viewUrl,
    'Set E2E_SAVE_CONFIRM_URL to a form user view with a save_confirm field.',
  )

  test.beforeEach(async ({ page }) => {
    await page.goto(viewUrl)
    await login(page)
    await page.goto(viewUrl)
    await page.waitForLoadState('networkidle')
  })

  const markField = (page) =>
    page.locator('input[type="text"], textarea').nth(1)
  const saveButton = (page) => page.locator('.save-button').first()
  const dialog = (page) => page.locator('.modal-content')

  test('asks before saving and keeps changes when declined', async ({
    page,
  }) => {
    const before = await markField(page).inputValue()
    const typed = `code-${Date.now()}`

    await markField(page).fill(typed)
    await markField(page).blur()
    await saveButton(page).click()

    // The dialog must appear and quote the attribute's message.
    await expect(dialog(page)).toBeVisible()
    await expect(dialog(page)).toContainText('фискальный чек')

    await page.getByRole('button', { name: 'Отмена' }).click()
    await expect(dialog(page)).toBeHidden()

    // Declining leaves the typed value in the form, unsaved.
    await expect(markField(page)).toHaveValue(typed)

    await page.reload()
    await page.waitForLoadState('networkidle')
    await expect(markField(page)).toHaveValue(before)
  })

  test('saves after confirmation', async ({ page }) => {
    const typed = `code-${Date.now()}`

    await markField(page).fill(typed)
    await markField(page).blur()
    await saveButton(page).click()

    await expect(dialog(page)).toBeVisible()
    await page.getByRole('button', { name: 'Пробить чек' }).click()
    await expect(dialog(page)).toBeHidden()

    await page.reload()
    await page.waitForLoadState('networkidle')
    await expect(markField(page)).toHaveValue(typed)
  })

  test('does not ask for a field without the attribute', async ({ page }) => {
    const plainField = page.locator('input[type="text"], textarea').first()

    await plainField.fill(`name-${Date.now()}`)
    await plainField.blur()
    await saveButton(page).click()

    await expect(dialog(page)).toHaveCount(0)
  })
})
