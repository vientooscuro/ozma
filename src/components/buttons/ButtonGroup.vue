<template>
  <!-- eslint-disable vue/v-on-event-hyphenation -->
  <popper
    ref="popup"
    trigger="clickToOpen"
    transition="ozma-popover"
    enter-active-class="ozma-popover-enter-active"
    leave-active-class="ozma-popover-leave-active"
    :visible-arrow="false"
    :options="{
      placement: listItem ? 'right-start' : 'bottom-end',
      positionFixed: true,
      modifiers: {
        offset: { offset: listItem ? '0, 5' : '0, 10' },
        // Nested poppers cannot appear outside the parent element if overflow is enabled.
        preventOverflow: { enabled: !listItem, boundariesElement: 'viewport' },
        hide: { enabled: !listItem },
      },
    }"
    :disabled="!show"
    :force-show="show"
    @document-click="onDocumentClick"
  >
    <div ref="content" class="popper shadow">
      <ButtonList
        :buttons="button.buttons"
        @button-click="onInnerButtonClick"
        @goto="$emit('goto', $event)"
      />
    </div>
    <!-- eslint-disable vue/no-deprecated-slot-attribute -->
    <ButtonView
      ref="reference"
      slot="reference"
      :list-item="listItem"
      :button="button"
      @click.capture="onReferenceClick"
    />
  </popper>
</template>

<script lang="ts">
import { Component, Vue, Prop } from 'vue-property-decorator'
import { namespace } from 'vuex-class'
import Popper from '@/components/common/OzmaPopper.vue'

import type { IButton, IButtonGroup } from '@/components/buttons/buttons'
import type { IThemeRef } from '@/utils_colors'
import { isGlass2Theme } from '@/utils/glass2'
import ButtonView from '@/components/buttons/ButtonView.vue'
import ButtonList from '@/components/buttons/ButtonList.vue'

const settings = namespace('settings')

@Component({
  components: {
    ButtonView,
    ButtonList,
    Popper,
  },
})
export default class ButtonsPanel extends Vue {
  @Prop({ type: Object, required: true }) button!: IButtonGroup
  @Prop({ type: Boolean, default: false }) listItem!: boolean

  @settings.State('currentThemeRef') currentThemeRef!: IThemeRef | null

  private show = false
  private closeTimer: number | null = null

  /* Nested menu entries (Тема, Язык…) open their submenu on hover in the
     new glass themes; top-level toolbar groups stay click-only. */
  private get hoverEnabled(): boolean {
    return this.listItem && isGlass2Theme(this.currentThemeRef)
  }

  mounted() {
    const ref = (this.$refs.reference as Vue | undefined)?.$el
    const content = this.$refs.content as HTMLElement | undefined
    ref?.addEventListener('mouseenter', this.onHoverEnter)
    ref?.addEventListener('mouseleave', this.onHoverLeave)
    content?.addEventListener('mouseenter', this.onContentEnter)
    content?.addEventListener('mouseleave', this.onHoverLeave)
  }

  beforeDestroy() {
    this.cancelScheduledClose()
    const ref = (this.$refs.reference as Vue | undefined)?.$el
    const content = this.$refs.content as HTMLElement | undefined
    ref?.removeEventListener('mouseenter', this.onHoverEnter)
    ref?.removeEventListener('mouseleave', this.onHoverLeave)
    content?.removeEventListener('mouseenter', this.onContentEnter)
    content?.removeEventListener('mouseleave', this.onHoverLeave)
  }

  private onHoverEnter = () => {
    if (!this.hoverEnabled) return
    this.cancelScheduledClose()
    this.show = true
  }

  private onContentEnter = () => {
    if (!this.hoverEnabled) return
    this.cancelScheduledClose()
  }

  private onHoverLeave = () => {
    if (!this.hoverEnabled) return
    this.cancelScheduledClose()
    this.closeTimer = window.setTimeout(() => {
      this.show = false
      this.closeTimer = null
    }, 250)
  }

  private cancelScheduledClose() {
    if (this.closeTimer !== null) {
      window.clearTimeout(this.closeTimer)
      this.closeTimer = null
    }
  }

  onReferenceClick() {
    this.show = !this.show
  }

  onDocumentClick() {
    this.show = false
  }

  onInnerButtonClick(button: IButton) {
    this.$emit('button-click', button)

    if (!button.keepButtonGroupOpened) {
      this.show = false
    }
  }
}
</script>

<style lang="scss" scoped>
.popper {
  border: none;
  border-radius: 0.5rem;
}

.list-group {
  max-height: 60vh;
  overflow-y: auto;
}
</style>
