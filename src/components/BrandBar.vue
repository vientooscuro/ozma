<i18n>
  {
    "en": {
      "toggle_theme": "Switch theme"
    },
    "ru": {
      "toggle_theme": "Переключить тему"
    },
    "es": {
      "toggle_theme": "Cambiar el tema"
    }
  }
</i18n>

<template>
  <header class="glass2-brand-bar">
    <OzmaLink
      class="glass2-brand"
      :link="homeLink"
      @goto="$emit('goto', $event)"
    >
      <span class="glass2-brand-tile">{{ brandInitial }}</span>
      <span v-if="!$isMobile" class="glass2-brand-name">{{ brandTitle }}</span>
    </OzmaLink>

    <nav v-if="!$isMobile" class="glass2-brand-tabs">
      <template v-for="(tab, tabI) in tabs">
        <!-- The boxless wrapper catches hover: OzmaLink replaces DOM
             listeners on href links, so mouseenter can't go on it. -->
        <span
          v-if="tab.directLink"
          :key="'direct' + tabI"
          style="display: contents"
          @mouseenter="hoverDirectTab"
        >
          <OzmaLink
            class="glass2-brand-tab"
            :link="tab.directLink"
            @goto="$emit('goto', $event)"
          >
            {{ $ustOrEmpty(tab.name) }}
          </OzmaLink>
        </span>
        <popper
          v-else
          :key="'tab' + tabI"
          trigger="clickToOpen"
          transition="ozma-popover"
          enter-active-class="ozma-popover-enter-active"
          leave-active-class="ozma-popover-leave-active"
          :visible-arrow="false"
          :options="{
            placement: 'bottom-start',
            positionFixed: true,
            modifiers: {
              offset: { offset: '0, 8' },
              preventOverflow: { enabled: true, boundariesElement: 'viewport' },
              hide: { enabled: true },
            },
          }"
          :disabled="openTabIndex !== tabI"
          :force-show="openTabIndex === tabI"
          @document-click="closeTab(tabI)"
        >
          <div class="popper glass2-brand-dropdown">
            <ButtonList :buttons="tabButtons(tab)" @goto="onEntryGoto" />
          </div>
          <!-- eslint-disable vue/no-deprecated-slot-attribute -->
          <button
            slot="reference"
            type="button"
            :class="['glass2-brand-tab', { active: tabI === activeTabIndex }]"
            @click.capture="toggleTab(tabI)"
            @mouseenter="hoverTab(tabI)"
          >
            {{ $ustOrEmpty(tab.name) }}
            <AppIcon class="glass2-brand-tab-chevron" name="expand_more" />
          </button>
          <!-- eslint-enable vue/no-deprecated-slot-attribute -->
        </popper>
      </template>
    </nav>

    <div class="glass2-brand-right">
      <button
        v-if="siblingThemeRef"
        type="button"
        class="glass2-theme-toggle"
        :aria-label="$t('toggle_theme').toString()"
        @click="switchTheme"
      >
        <AppIcon :name="themeToggleIcon" />
      </button>
      <ProfileButton @goto="$emit('goto', $event)" />
    </div>
  </header>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'
import { namespace } from 'vuex-class'
import type { IUserViewRef } from '@ozma-io/ozmadb-js/client'
import Popper from '@/components/common/OzmaPopper.vue'

import { homeLink } from '@/utils'
import { defaultVariantAttribute } from '@/utils_colors'
import type { IThemeRef } from '@/utils_colors'
import type { Button } from '@/components/buttons/buttons'
import type { IBrandBarTab } from '@/state/main_menu'
import { CurrentSettings } from '@/state/settings'
import type { ICurrentQueryHistory } from '@/state/query'
import ButtonList from '@/components/buttons/ButtonList.vue'
import ProfileButton from '@/components/ProfileButton.vue'

const settings = namespace('settings')
const query = namespace('query')
const mainMenu = namespace('mainMenu')

// Brand bar (Phase 2 §5): rendered by TopLevelUserView in glass2 themes
// only. Brand + main-menu category tabs + theme quick-toggle + avatar.
@Component({ components: { ButtonList, ProfileButton, Popper } })
export default class BrandBar extends Vue {
  @settings.State('current') currentSettings!: CurrentSettings
  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null
  @settings.Action('setCurrentTheme') setCurrentTheme!: (
    theme: IThemeRef,
  ) => Promise<void>
  @query.State('current') query!: ICurrentQueryHistory | null
  @mainMenu.State('tabs') storeTabs!: IBrandBarTab[] | null
  @mainMenu.Action('getMainMenu') getMainMenu!: () => Promise<IBrandBarTab[]>

  private openTabIndex: number | null = null
  private homeLink = homeLink

  mounted() {
    // Fire-and-forget: an unavailable menu just means no tabs.
    void this.getMainMenu().catch(() => {})
  }

  get tabs(): IBrandBarTab[] {
    return this.storeTabs ?? []
  }

  get brandTitle(): string {
    return this.currentSettings.getEntry('brand_title', String, 'Ozma')
  }

  get brandInitial(): string {
    return this.brandTitle.charAt(0).toUpperCase()
  }

  private get currentViewRef(): IUserViewRef | null {
    const source = this.query?.root.args.source
    if (source && source.type === 'named') {
      return source.ref
    }
    return null
  }

  // Active tab: the category containing a link to the current named view.
  // Heuristic per §8 — unmatched views simply have no active tab.
  get activeTabIndex(): number | null {
    const current = this.currentViewRef
    if (current === null) return null
    const index = this.tabs.findIndex((tab) =>
      tab.entries.some(
        (entry) =>
          entry.link.type === 'query' &&
          entry.link.query.args.source.type === 'named' &&
          entry.link.query.args.source.ref.schema === current.schema &&
          entry.link.query.args.source.ref.name === current.name,
      ),
    )
    return index === -1 ? null : index
  }

  // Sibling glass2 theme for the quick-toggle: same schema preferred, any
  // schema as fallback, hidden when the sibling isn't installed. The schema
  // MUST come from the themes map (instances differ) — never hardcoded.
  get siblingThemeRef(): IThemeRef | null {
    const current = this.currentThemeRef
    if (current === null) return null
    const targetName =
      current.name === 'dark-glass' ? 'light-glass-cool' : 'dark-glass'
    const themes = this.currentSettings.themes
    if (themes[current.schema]?.[targetName] !== undefined) {
      return { schema: current.schema, name: targetName }
    }
    const fallback = Object.entries(themes).find(
      ([, schemaThemes]) => targetName in schemaThemes,
    )
    return fallback ? { schema: fallback[0], name: targetName } : null
  }

  get themeToggleIcon(): string {
    return this.currentThemeRef?.name === 'dark-glass'
      ? 'light_mode'
      : 'dark_mode'
  }

  private switchTheme() {
    if (this.siblingThemeRef) {
      void this.setCurrentTheme(this.siblingThemeRef)
    }
  }

  private tabButtons(tab: IBrandBarTab): Button[] {
    return tab.entries.map(
      (entry): Button => ({
        type: 'link',
        caption: entry.name,
        variant: defaultVariantAttribute,
        link: entry.link,
        icon: entry.icon ?? undefined,
      }),
    )
  }

  private toggleTab(tabI: number) {
    this.openTabIndex = this.openTabIndex === tabI ? null : tabI
  }

  // Standard menubar hover behavior: while some dropdown is open, hovering
  // another tab moves the open dropdown there; hovering a direct-link tab
  // closes it. No hover-open when everything is closed — click opens first.
  private hoverTab(tabI: number) {
    if (this.openTabIndex !== null && this.openTabIndex !== tabI) {
      this.openTabIndex = tabI
    }
  }

  private hoverDirectTab() {
    if (this.openTabIndex !== null) {
      this.openTabIndex = null
    }
  }

  private closeTab(tabI: number) {
    if (this.openTabIndex === tabI) {
      this.openTabIndex = null
    }
  }

  private onEntryGoto(event: unknown) {
    this.openTabIndex = null
    this.$emit('goto', event)
  }
}
</script>
