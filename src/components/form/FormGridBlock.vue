<template>
  <b-col
    cols="12"
    :lg="blockContent.size"
    :class="[
      'form_grid_block__column',
      { 'element-block': blockContent.type === 'element' },
    ]"
  >
    <div
      :class="[
        {
          first_level_grid_block: firstLevel,
          'has-sub-blocks': firstLevel && blockContent.type === 'section_with_sub_blocks',
          'has-no-content': hasNoContent,
          'only-nested-userview': singleUserViewSection,
        },
      ]"
    >
      <slot
        v-if="blockContent.type === 'element'"
        :element="blockContent.element"
      />
      <b-row v-else-if="blockContent.type === 'section'">
        <FormGridBlock
          v-for="(subBlock, subBlockI) in blockContent.content"
          :key="subBlockI"
          v-slot="slotProps"
          :block-content="subBlock"
        >
          <slot :element="slotProps.element" />
        </FormGridBlock>
      </b-row>
      <template v-else-if="blockContent.type === 'section_with_sub_blocks'">
        <template v-for="(subBlock, subBlockI) in blockContent.subBlocks">
          <!-- Sub-block with card: rendered as a glass card -->
          <div
            v-if="subBlock.hasCard"
            :key="subBlockI"
            class="form_sub_block"
            :style="subBlock.color ? { '--sub-block-color': subBlock.color } : {}"
          >
            <div v-if="subBlock.title" class="form_sub_block__title">
              {{ subBlock.title }}
            </div>
            <b-row>
              <FormGridBlock
                v-for="(item, itemI) in subBlock.content"
                :key="itemI"
                v-slot="slotProps"
                :block-content="item"
              >
                <slot :element="slotProps.element" />
              </FormGridBlock>
            </b-row>
          </div>
          <!-- Elements without sub-block: rendered with standard background -->
          <div v-else :key="'inline-' + subBlockI" class="form_inline_block">
            <b-row>
              <FormGridBlock
                v-for="(item, itemI) in subBlock.content"
                :key="itemI"
                v-slot="slotProps"
                :block-content="item"
              >
                <slot :element="slotProps.element" />
              </FormGridBlock>
            </b-row>
          </div>
        </template>
      </template>
    </div>
  </b-col>
</template>

<script lang="ts">
import { Vue, Component, Prop } from 'vue-property-decorator'

import type { GridElement } from '@/components/form/FormGrid.vue'

@Component({
  name: 'FormGridBlock',
})
export default class FormGridBlock extends Vue {
  @Prop({ type: Object }) blockContent!: GridElement<any>
  @Prop({ type: Boolean, default: false }) firstLevel!: boolean
  @Prop({ type: Boolean, default: false }) hasNoContent!: boolean
  @Prop({ type: Boolean, default: false }) singleUserViewSection!: boolean
}
</script>

<style lang="scss" scoped>
.form_grid_block__column {
  padding-right: 0;
  padding-bottom: 0;
  padding-left: 0;

  &:not(:last-child) {
    margin-bottom: 0.625rem;
  }

  &.element-block.col-lg-12 ::v-deep .col-12 {
    padding: 0;

    .border-label {
      left: 0.5rem;
    }
  }
}

.first_level_grid_block {
  border-radius: 0.75rem;
  background: var(--backgroundColor);
  padding: 1.25rem;
  height: 100%;

  @include mobile {
    padding: 1.25rem 0.75rem 0.75rem 0.75rem;
  }

  // Remove box shadow from nested .first_level_grid_block
  .first_level_grid_block {
    box-shadow: none;
  }

  &:not(.only-nested-userview) {
    ::v-deep .nested-userview {
      margin-top: 0.5rem;
      margin-bottom: 0.25rem;
      border: 1px solid var(--default-borderColor);
      border-radius: 0.625rem;
      overflow: hidden;
    }
  }

  &.has-sub-blocks {
    background: transparent;
    border: none;
    border-radius: 0;
    box-shadow: none;
    padding: 0;
  }
}

.form_inline_block {
  border-radius: 0.75rem;
  background: var(--backgroundColor);
  padding: 1.25rem;
  margin-bottom: 0.75rem;

  @include mobile {
    padding: 1.25rem 0.75rem 0.75rem 0.75rem;
  }

  &:last-child {
    margin-bottom: 0;
  }
}

.form_sub_block {
  border: 1px solid var(--sub-block-color, var(--default-borderColor));
  border-radius: 1.5rem;
  background: var(--backgroundColor);
  padding: 1.5rem;
  margin-bottom: 0.75rem;

  @include mobile {
    padding: 1rem 0.75rem 0.75rem 0.75rem;
  }

  &:last-child {
    margin-bottom: 0;
  }
}

.form_sub_block__title {
  margin-bottom: 1.25rem;
  padding-bottom: 0;
  color: var(--default-foregroundDarkerColor);
  font-size: 0.75rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.has-no-content {
  display: none;
}

.only-nested-userview {
  padding: 0;
}

.row {
  margin: 0;
}
</style>
