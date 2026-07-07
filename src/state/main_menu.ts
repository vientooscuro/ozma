import { Module } from 'vuex'
import FunDBAPI, { IViewExprResult } from '@ozma-io/ozmadb-js/client'

import { IRef, mapMaybe, tryDicts, waitTimeout } from '@/utils'
import { CancelledError } from '@/modules'
import { Link, attrToLink, IAttrToLinkOpts } from '@/links'
import { rawToUserString, UserString } from '@/state/translations'
import { valueToPunnedText } from '@/user_views/combined'

// Brand-bar tabs (Phase 2 §5): one tab per main-menu category. Loaded once
// from the same user view the menu screen renders (user.main) and cached
// for the session.

export interface IBrandBarEntry {
  name: UserString
  link: Link
}

export interface IBrandBarTab {
  name: UserString
  // Category entries shown in the tab dropdown. Empty for loose top-level
  // links, which navigate directly via `directLink`.
  entries: IBrandBarEntry[]
  directLink: Link | null
}

// Same options Menu.vue uses for the user.main view (homeSchema comes from
// the named ref's schema).
const linkOpts: IAttrToLinkOpts = {
  homeSchema: 'user',
  defaultTarget: 'root',
}

// Flatten a category's content into link entries (sub-categories are
// flattened — the bar has a single dropdown level).
const collectEntries = (content: unknown[]): IBrandBarEntry[] => {
  return content.flatMap((rawEntry) => {
    if (typeof rawEntry !== 'object' || rawEntry === null) return []
    const entry = rawEntry as Record<string, unknown>
    const name = rawToUserString(entry.name)
    if (name === null) return []
    if ('content' in entry) {
      return entry.content instanceof Array ? collectEntries(entry.content) : []
    }
    const link = attrToLink(entry, linkOpts)
    if (link === null) return []
    return [{ name, link }]
  })
}

// A wrapper level is a single entry with a blank name whose `content`
// holds the real categories (the local user.main is shaped this way).
const isBlankName = (name: UserString | null): boolean =>
  name === null || (typeof name === 'string' && name.trim() === '')

// New-format menu: single json column, one menu object/array per row
// (mirrors Menu.vue's buildNewMenu/convertNewMenuEntry).
const parseNewMenu = (res: IViewExprResult): IBrandBarTab[] => {
  let rawEntries: unknown[] = res.result.rows.flatMap((row): unknown[] => {
    const rawMenu = row.values[0].value
    return rawMenu instanceof Array
      ? rawMenu
      : typeof rawMenu === 'object' && rawMenu !== null
        ? [rawMenu]
        : []
  })

  // Unwrap blank wrapper levels before extracting tabs, so the wrapper
  // itself never becomes an empty-captioned tab. Bounded to avoid looping
  // on pathological data.
  for (let unwrap = 0; unwrap < 3 && rawEntries.length === 1; unwrap++) {
    const rawOnly = rawEntries[0]
    if (typeof rawOnly !== 'object' || rawOnly === null) break
    const only = rawOnly as Record<string, unknown>
    if (!(only.content instanceof Array)) break
    if (!isBlankName(rawToUserString(only.name))) break
    rawEntries = only.content
  }

  return mapMaybe((rawEntry: unknown): IBrandBarTab | undefined => {
    if (typeof rawEntry !== 'object' || rawEntry === null) return undefined
    const entry = rawEntry as Record<string, unknown>
    const name = rawToUserString(entry.name)
    if (name === null) return undefined
    if ('content' in entry) {
      if (!(entry.content instanceof Array)) return undefined
      return { name, entries: collectEntries(entry.content), directLink: null }
    }
    const link = attrToLink(entry, linkOpts)
    if (link === null) return undefined
    return { name, entries: [], directLink: link }
  }, rawEntries)
}

// Old-format menu: two columns (category, button), grouped by category text
// (mirrors Menu.vue's buildOldMenu, including the link-attr precedence).
const parseOldMenu = (res: IViewExprResult): IBrandBarTab[] => {
  const categoryType = res.info.columns[0].valueType
  const buttonType = res.info.columns[1].valueType
  const viewAttrs = res.result.attributes
  const buttonsColumnAttrs = res.result.columnAttributes[1]

  const categories = new Map<string, IBrandBarEntry[]>()
  res.result.rows.forEach((row) => {
    const categoryName = valueToPunnedText(categoryType, row.values[0])
    let entries = categories.get(categoryName)
    if (entries === undefined) {
      entries = []
      categories.set(categoryName, entries)
    }

    const buttonCell = row.values[1]
    const buttonName = valueToPunnedText(buttonType, buttonCell)
    const linkAttr = tryDicts<string, unknown>(
      'link',
      buttonCell.attributes,
      buttonsColumnAttrs,
      row.attributes,
      viewAttrs,
    )
    const link = attrToLink(linkAttr, linkOpts)
    if (link === null) return
    entries.push({ name: buttonName, link })
  })

  return Array.from(categories.entries()).map(([name, entries]) => ({
    name,
    entries,
    directLink: null,
  }))
}

export interface IMainMenuState {
  tabs: IBrandBarTab[] | null
  pending: Promise<IBrandBarTab[]> | null
}

const mainMenuModule: Module<IMainMenuState, {}> = {
  namespaced: true,
  state: {
    tabs: null,
    pending: null,
  },
  mutations: {
    setTabs: (state, tabs: IBrandBarTab[]) => {
      state.tabs = tabs
      state.pending = null
    },
    setPending: (state, pending: Promise<IBrandBarTab[]> | null) => {
      state.pending = pending
    },
    clearTabs: (state) => {
      state.tabs = null
      state.pending = null
    },
  },
  actions: {
    getMainMenu: ({ state, commit, dispatch }): Promise<IBrandBarTab[]> => {
      if (state.tabs !== null) {
        return Promise.resolve(state.tabs)
      }
      if (state.pending !== null) {
        return state.pending
      }
      const pending: IRef<Promise<IBrandBarTab[]>> = {}
      pending.ref = (async () => {
        await waitTimeout() // Delay so the promise gets saved to `pending` first.
        try {
          const res = (await dispatch(
            'callApi',
            {
              func: (api: FunDBAPI) =>
                api.getNamedUserView({ schema: 'user', name: 'main' }),
            },
            { root: true },
          )) as IViewExprResult
          if (state.pending !== pending.ref) {
            throw new CancelledError()
          }
          const tabs =
            res.info.columns.length === 1
              ? parseNewMenu(res)
              : res.info.columns.length === 2
                ? parseOldMenu(res)
                : []
          commit('setTabs', tabs)
          return tabs
        } catch (e) {
          if (state.pending === pending.ref) {
            commit('clearTabs')
          }
          throw e
        }
      })()
      commit('setPending', pending.ref)
      return pending.ref
    },
  },
}

export default mainMenuModule
