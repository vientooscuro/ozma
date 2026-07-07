import type { IThemeRef } from '@/utils_colors'

// Single source of truth for "is the active theme one of the Glass 2.0
// themes". Everything structurally gated in Phase 2 (brand bar, page
// header, numbered pagination) must use this helper, never inline
// theme-name literals.
export const isGlass2Theme = (themeRef: IThemeRef | null): boolean => {
  const name = themeRef?.name
  return (
    name === 'dark-glass' ||
    name === 'light-glass-cool' ||
    name === 'light-glass-warm'
  )
}
