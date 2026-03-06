<template>
  <div :class="['code-editor', { 'monaco-editor_modal': isModal }]" />
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from 'vue-property-decorator'
import { namespace } from 'vuex-class'

import * as monaco from 'monaco-editor'

import { CurrentSettings } from '@/state/settings'

const tokenRules = (
  keyword: string,
  string: string,
  number: string,
  comment: string,
  type: string,
  operator: string,
): monaco.editor.ITokenThemeRule[] => [
  { token: 'keyword', foreground: keyword, fontStyle: 'bold' },
  { token: 'keyword.sql', foreground: keyword, fontStyle: 'bold' },
  { token: 'string', foreground: string },
  { token: 'string.sql', foreground: string },
  { token: 'number', foreground: number },
  { token: 'number.sql', foreground: number },
  { token: 'comment', foreground: comment, fontStyle: 'italic' },
  { token: 'comment.sql', foreground: comment, fontStyle: 'italic' },
  { token: 'type', foreground: type },
  { token: 'predefined', foreground: type },
  { token: 'operator', foreground: operator },
  { token: 'operator.sql', foreground: operator },
]

monaco.editor.defineTheme('ozma-light', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '0000ff', // keyword: blue
    'a31515', // string: dark red
    '098658', // number: green
    '008000', // comment: green
    '267f99', // type: teal
    '000000', // operator: black
  ),
  colors: {},
})

// eslint-disable-next-line @typescript-eslint/no-explicit-any
;(monaco.editor.defineTheme as any)('ozma-dark', {
  base: 'vs-dark',
  inherit: true,
  semanticHighlighting: true,
  semanticTokenColors: {
    'variable': '#87C3FF',
    'variable.readonly': '#AAA0FA',
    'variable.defaultLibrary': '#87C3FF',
    'parameter': '#D6D6DD',
    'function': '#EFB080',
    'function.defaultLibrary': '#87C3FF',
    'method': '#EFB080',
    'method.defaultLibrary': '#87C3FF',
    'class': '#EFB080',
    'class.defaultLibrary': '#87C3FF',
    'interface': '#EFB080',
    'type': '#EFB080',
    'typeParameter': '#EFB080',
    'namespace': '#D6D6DD',
    'property': '#AAA0FA',
    'enumMember': '#AAA0FA',
    'event': '#AAA0FA',
    'macro': '#82D2CE',
    'label': '#D6D6DD',
    // JSON
    'property.declaration': '#82D2CE',
  },
  rules: [
    { token: 'keyword', foreground: '82D2CE', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: '82D2CE', fontStyle: 'bold' },
    { token: 'string', foreground: 'E394DC' },
    { token: 'string.sql', foreground: 'E394DC' },
    { token: 'number', foreground: 'EBC88D' },
    { token: 'number.sql', foreground: 'EBC88D' },
    { token: 'comment', foreground: 'E4E4E45E', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: 'E4E4E45E', fontStyle: 'italic' },
    { token: 'type', foreground: 'EFB080' },
    { token: 'predefined', foreground: '87C3FF' },
    { token: 'operator', foreground: 'D6D6DD' },
    { token: 'operator.sql', foreground: '82D2CE' },
    { token: 'identifier', foreground: 'D6D6DD' },
    { token: 'identifier.quote', foreground: 'D6D6DD' },
    { token: 'identifier.quote.sql', foreground: 'D6D6DD' },
    { token: 'variable', foreground: '87C3FF' },
    { token: 'constant', foreground: 'AAA0FA' },
    { token: 'string.escape', foreground: 'AAA0FA' },
    { token: 'string.escape.sql', foreground: 'AAA0FA' },
    { token: 'number.float', foreground: 'EBC88D' },
    { token: 'number.hex', foreground: 'EBC88D' },
    { token: 'comment.block', foreground: 'E4E4E45E', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: 'E4E4E45E', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'E4E4E48D' },
    { token: 'delimiter.sql', foreground: 'E4E4E48D' },
    { token: 'delimiter.parenthesis', foreground: 'E4E4E4EB' },
    { token: 'delimiter.parenthesis.sql', foreground: 'E4E4E4EB' },
    // JSON
    { token: 'key.json', foreground: '82D2CE' },
    { token: 'string.value.json', foreground: 'E394DC' },
    { token: 'number.json', foreground: 'EBC88D' },
    { token: 'keyword.json', foreground: 'AAA0FA' },
  ],
  colors: {
    'editor.background': '#181818',
    'editor.foreground': '#E4E4E4EB',
    'editorLineNumber.foreground': '#E4E4E45E',
    'editorLineNumber.activeForeground': '#E4E4E4EB',
    'editor.selectionBackground': '#40404099',
    'editor.inactiveSelectionBackground': '#40404066',
    'editor.lineHighlightBackground': '#262626',
    'editorCursor.foreground': '#E4E4E4EB',
    'editor.findMatchBackground': '#81A1C155',
    'editor.findMatchHighlightBackground': '#81A1C133',
    'editorIndentGuide.background1': '#E4E4E413',
    'editorIndentGuide.activeBackground1': '#E4E4E42E',
  },
})

const settings = namespace('settings')

@Component
export default class CodeEditor extends Vue {
  @settings.State('current') settings!: CurrentSettings
  @settings.State('currentThemeRef') currentThemeRef!: unknown

  @Prop({ default: '' }) content!: string
  @Prop({ default: 'sql', type: String }) language!: string
  @Prop({ default: '' }) theme!: string
  @Prop({ default: false }) readOnly!: boolean
  @Prop({ default: false }) autofocus!: boolean
  @Prop({ default: false }) isModal!: boolean

  editor: monaco.editor.IStandaloneCodeEditor | null = null

  private get isDarkTheme(): boolean {
    // Depend on currentThemeRef to make this reactive to theme changes
    void this.currentThemeRef
    const el =
      document.querySelector('.default-variant') ?? document.documentElement
    const bg = getComputedStyle(el)
      .getPropertyValue('--default-backgroundColor')
      .trim()
    if (!bg) return false
    // Parse rgb/rgba or hex and check luminance
    const canvas = document.createElement('canvas')
    canvas.width = 1
    canvas.height = 1
    const ctx = canvas.getContext('2d')!
    ctx.fillStyle = bg
    ctx.fillRect(0, 0, 1, 1)
    const [r, g, b] = ctx.getImageData(0, 0, 1, 1).data
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return luminance < 0.5
  }

  private get monacoTheme(): string {
    return this.isDarkTheme ? 'ozma-dark' : 'ozma-light'
  }

  get options(): monaco.editor.IStandaloneEditorConstructionOptions {
    const fontSize = 12

    const options: monaco.editor.IStandaloneEditorConstructionOptions = {
      language: this.language,
      readOnly: this.readOnly,
      automaticLayout: true,
      lineNumbersMinChars: 3,
      scrollbar: {
        useShadows: false,
      },
      unicodeHighlight: {
        ambiguousCharacters: false,
        nonBasicASCII: false,
      },
      fontSize,
      theme: this.monacoTheme,
    }

    const mobileOptions: monaco.editor.IStandaloneEditorConstructionOptions = {
      minimap: { enabled: false },
      lineNumbers: 'off',
      glyphMargin: false,
      folding: false,
      lineDecorationsWidth: 0,
      lineNumbersMinChars: 0,
    }

    return this.$isMobile ? { ...options, ...mobileOptions } : options
  }

  @Watch('options')
  private updateOptions(
    newOptions: monaco.editor.IStandaloneEditorConstructionOptions,
  ) {
    if (this.editor !== null) {
      this.editor.updateOptions(newOptions)
    }
  }

  @Watch('currentThemeRef')
  private onThemeChange() {
    if (this.editor !== null) {
      monaco.editor.setTheme(this.monacoTheme)
    }
  }

  @Watch('content')
  private updateContent(content: string) {
    if (this.editor !== null && this.editor.getValue() !== content) {
      this.editor.setValue(content)
    }
  }

  private mounted() {
    const editor = monaco.editor.create(this.$el as HTMLElement, {
      ...this.options,
      value: this.content,
    })
    editor.onDidFocusEditorWidget(() => {
      this.$root.$emit('form-input-focused')
      this.$emit('focus')
    })
    editor.onDidBlurEditorWidget(() => {
      this.$emit('blur')
    })
    editor.onDidChangeModelContent((event) => {
      const content = editor.getValue()
      if (content !== this.content) {
        this.$emit('update:content', content)
      }
    })
    this.editor = editor
    if (this.autofocus) {
      // FIXME: With the next line autofocus work for the first table cell open
      //        with codeeditor. But close the edit cell for a second time.
      // editor.focus();
    }
  }

  @Watch('autofocus')
  private onAutofocus(autofocus: boolean) {
    if (autofocus && this.editor) {
      this.editor.focus()
    }
  }

  private beforeDestroy() {
    this.editor!.dispose()
  }
}
</script>

<style lang="scss" scoped>
.code-editor {
  border: 1px solid var(--MainBorderColor);
  border-radius: 4px;
  overflow: hidden;

  ::v-deep textarea {
    white-space: pre; // `reset.css` broke spaces in Chrome/Safari.
  }
}

.monaco-editor_modal {
  height: 350px;
}
</style>
