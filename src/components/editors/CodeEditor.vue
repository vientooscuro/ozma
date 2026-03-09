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
    '3d6fd6', // keyword: medium blue (softer than pure blue)
    'b5365a', // string: muted rose-red
    '6f8f2e', // number: olive green
    '7c8c7a', // comment: muted sage, italic
    '286f7a', // type: dark teal
    '5a5a5a', // operator: dark grey
  ),
  colors: {
    'editor.background': '#ffffff',
    'editor.foreground': '#2e2e2e',
    'editorLineNumber.foreground': '#aaaaaa',
    'editorLineNumber.activeForeground': '#555555',
    'editor.lineHighlightBackground': '#f0f0f0',
    'editor.selectionBackground': '#cce5ff',
    'editor.inactiveSelectionBackground': '#e5e5e5',
    'editorIndentGuide.background1': '#e0e0e0',
    'editorIndentGuide.activeBackground1': '#bbbbbb',
  },
})

// eslint-disable-next-line @typescript-eslint/no-explicit-any
;(monaco.editor.defineTheme as any)('ozma-dark', {
  base: 'vs-dark',
  inherit: true,
  semanticHighlighting: true,
  semanticTokenColors: {
    'variable': '#8ECEFF',
    'variable.readonly': '#B8AEFF',
    'variable.defaultLibrary': '#8ECEFF',
    'parameter': '#CDD3DE',
    'function': '#F2B896',
    'function.defaultLibrary': '#8ECEFF',
    'method': '#F2B896',
    'method.defaultLibrary': '#8ECEFF',
    'class': '#F2B896',
    'class.defaultLibrary': '#8ECEFF',
    'interface': '#F2B896',
    'type': '#F2B896',
    'typeParameter': '#F2B896',
    'namespace': '#CDD3DE',
    'property': '#B8AEFF',
    'enumMember': '#B8AEFF',
    'event': '#B8AEFF',
    'macro': '#7ADBD6',
    'label': '#CDD3DE',
    // JSON
    'property.declaration': '#7ADBD6',
  },
  rules: [
    { token: 'keyword', foreground: '7ADBD6', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: '7ADBD6', fontStyle: 'bold' },
    { token: 'string', foreground: 'E8A0E0' },
    { token: 'string.sql', foreground: 'E8A0E0' },
    { token: 'number', foreground: 'F0CE96' },
    { token: 'number.sql', foreground: 'F0CE96' },
    { token: 'comment', foreground: '555E6E', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '555E6E', fontStyle: 'italic' },
    { token: 'type', foreground: 'F2B896' },
    { token: 'predefined', foreground: '8ECEFF' },
    { token: 'operator', foreground: 'CDD3DE' },
    { token: 'operator.sql', foreground: '7ADBD6' },
    { token: 'identifier', foreground: 'CDD3DE' },
    { token: 'identifier.quote', foreground: 'CDD3DE' },
    { token: 'identifier.quote.sql', foreground: 'CDD3DE' },
    { token: 'variable', foreground: '8ECEFF' },
    { token: 'constant', foreground: 'B8AEFF' },
    { token: 'string.escape', foreground: 'B8AEFF' },
    { token: 'string.escape.sql', foreground: 'B8AEFF' },
    { token: 'number.float', foreground: 'F0CE96' },
    { token: 'number.hex', foreground: 'F0CE96' },
    { token: 'comment.block', foreground: '555E6E', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: '555E6E', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'CDD3DE80' },
    { token: 'delimiter.sql', foreground: 'CDD3DE80' },
    { token: 'delimiter.parenthesis', foreground: 'CDD3DECC' },
    { token: 'delimiter.parenthesis.sql', foreground: 'CDD3DECC' },
    // JSON
    { token: 'key.json', foreground: '7ADBD6' },
    { token: 'string.value.json', foreground: 'E8A0E0' },
    { token: 'number.json', foreground: 'F0CE96' },
    { token: 'keyword.json', foreground: 'B8AEFF' },
  ],
  colors: {
    'editor.background': '#121418',
    'editor.foreground': '#CDD3DEEB',
    'editorLineNumber.foreground': '#CDD3DE40',
    'editorLineNumber.activeForeground': '#CDD3DEAA',
    'editor.selectionBackground': '#2A3A5299',
    'editor.inactiveSelectionBackground': '#2A3A5266',
    'editor.lineHighlightBackground': '#1a1e24',
    'editorCursor.foreground': '#CDD3DEEB',
    'editor.findMatchBackground': '#7ADBD655',
    'editor.findMatchHighlightBackground': '#7ADBD633',
    'editorIndentGuide.background1': '#CDD3DE10',
    'editorIndentGuide.activeBackground1': '#CDD3DE28',
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
      fontFamily:
        '"JetBrains Mono", Menlo, Monaco, Consolas, "Courier New", monospace',
      lineNumbersMinChars: 3,
      scrollbar: {
        useShadows: false,
      },
      unicodeHighlight: {
        ambiguousCharacters: false,
        nonBasicASCII: false,
      },
      fontLigatures: true,
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
