<template>
  <!-- eslint-disable vue/no-deprecated-dollar-listeners-api -->
  <span
    v-if="lucideMarkup"
    class="material-icons app-icon-lucide"
    aria-hidden="true"
    v-on="$listeners"
    v-html="lucideMarkup"
  />
  <span v-else class="material-icons" v-on="$listeners">{{ name }}</span>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator'
import { namespace } from 'vuex-class'

import type { IThemeRef } from '@/utils_colors'
import { isGlass2Theme } from '@/utils/glass2'
import { lucideMarkupForMaterialName } from '@/utils/lucideIcons'

const settings = namespace('settings')

// Icon wrapper: takes a Material Icons ligature name. In the Glass 2.0
// themes mapped names render as inline Lucide SVGs; unmapped names and all
// other themes fall back to the Material ligature span, so DB-provided
// names degrade gracefully (§5).
@Component
export default class AppIcon extends Vue {
  @Prop({ type: String, required: true }) name!: string

  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null

  private get isGlass2Theme(): boolean {
    return isGlass2Theme(this.currentThemeRef)
  }

  get lucideMarkup(): string | null {
    if (!this.isGlass2Theme) return null
    return lucideMarkupForMaterialName(this.name)
  }
}
</script>

<style lang="scss" scoped>
.app-icon-lucide {
  display: inline-flex;
  align-items: center;
  justify-content: center;

  ::v-deep svg {
    display: block;
    width: 1em;
    height: 1em;
  }
}
</style>
