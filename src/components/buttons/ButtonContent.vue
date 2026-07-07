<template>
  <fragment>
    <span v-if="button.icon && iconType === 'emoji'" class="icon emoji-icon">{{
      button.icon
    }}</span>
    <AppIcon v-else-if="button.icon" class="icon" :name="button.icon" />
    <AppIcon
      v-else-if="listItem && phantomIcon"
      v-visible="false"
      name="arrow_right"
    />

    <span
      v-if="button.caption || listItem"
      :class="[listItem ? 'mx-2' : 'button-caption']"
      >{{ button.caption ? $ustOrEmpty(button.caption) : undefined }}</span
    >

    <AppIcon
      v-if="button.caption && button.type == 'button-group'"
      class="ml-auto dropdown-icon"
      name="arrow_right"
    />

    <span v-if="!button.caption">&#8203;</span>
  </fragment>
</template>

<script lang="ts">
import { Component, Vue, Prop } from 'vue-property-decorator'
import type { Button } from '@/components/buttons/buttons'
import { getIconType } from '@/utils'

@Component
export default class ButtonContent extends Vue {
  @Prop({ type: Object, required: true }) button!: Button
  @Prop({ type: Boolean, default: false }) listItem!: boolean
  @Prop({ type: Boolean, default: false }) phantomIcon!: boolean

  private get iconType() {
    return getIconType(this.button.icon)
  }
}
</script>

<style lang="scss" scoped>
.dropdown-icon {
  margin: -0.1rem 0;
  line-height: 0;
}
</style>
