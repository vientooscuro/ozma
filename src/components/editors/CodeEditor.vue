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
  attribute: string,
  variable: string,
  identifier: string,
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
  { token: 'attribute', foreground: attribute },
  { token: 'attribute.sql', foreground: attribute },
  { token: 'variable', foreground: variable },
  { token: 'variable.sql', foreground: variable },
  { token: 'identifier', foreground: identifier },
  { token: 'identifier.sql', foreground: identifier },
  { token: 'delimiter', foreground: operator },
  { token: 'delimiter.sql', foreground: operator },
]

monaco.editor.defineTheme('ozma-light', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '2f7a6f', // keyword: muted green
    'b5365a', // string: muted rose-red
    '6f8f2e', // number: olive green
    '7c8c7a', // comment: muted sage, italic
    '286f7a', // type: dark teal
    '5a5a5a', // operator: dark grey
    '3d6fd6', // attribute: medium blue
    '3d6fd6', // variable: medium blue
    '2e2e2e', // identifier: editor foreground
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

monaco.editor.defineTheme('ozma-light-glass', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '0f766e', // keyword: glass accent teal
    'b45309', // string: warm amber-brown
    '4f46e5', // number: indigo
    '7c6f60', // comment: warm neutral
    '0b5e5a', // type: deep teal
    '6f6a62', // operator: muted glass text
    '2563eb', // attribute: clean blue
    '1d4ed8', // variable: saturated blue
    '3f3b35', // identifier: glass text-soft
  ),
  colors: {
    'editor.background': '#fffdf8',
    'editor.foreground': '#1f1f1f',
    'editorLineNumber.foreground': '#9f9689',
    'editorLineNumber.activeForeground': '#5f5850',
    'editor.selectionBackground': '#59d6cf33',
    'editor.inactiveSelectionBackground': '#59d6cf20',
    'editor.lineHighlightBackground': '#f4efe4cc',
    'editorCursor.foreground': '#0f766e',
    'editor.findMatchBackground': '#f6b94166',
    'editor.findMatchHighlightBackground': '#f6b94133',
    'editorIndentGuide.background1': '#c4b6a34d',
    'editorIndentGuide.activeBackground1': '#c4b6a380',
  },
})

const funqlSqlKeywords = [
  'select', 'from', 'where', 'join', 'left', 'right', 'inner', 'outer',
  'full', 'cross', 'on', 'as', 'and', 'or', 'not', 'in', 'is', 'null',
  'case', 'when', 'then', 'else', 'end', 'group', 'order', 'by', 'asc',
  'desc', 'limit', 'offset', 'union', 'intersect', 'except', 'all',
  'distinct', 'for', 'insert', 'into', 'update', 'delete', 'values', 'with',
  'recursive', 'materialized', 'partition', 'over', 'filter', 'having',
  'between', 'exists', 'like', 'ilike', 'similar', 'only', 'lateral',
  'domain', 'interval', 'superuser', 'role', 'inherited', 'oftype', 'mapping',
  'reference', 'enum', 'internal', 'default', 'returns', 'returning',
  'create', 'alter', 'drop', 'replace', 'table', 'view', 'function', 'begin',
  'declare', 'language', 'set', 'show', 'grant', 'revoke', 'using', 'array',
  'any', 'some', 'nulls', 'first', 'last', 'true', 'false',
]

const customSqlMonarch = {
  defaultToken: '',
  ignoreCase: true,
  keywords: funqlSqlKeywords,
  typeKeywords: [
    'int', 'integer', 'bigint', 'smallint', 'numeric', 'decimal', 'float',
    'real', 'double', 'text', 'varchar', 'char', 'boolean', 'bool', 'date',
    'datetime', 'time', 'timestamp', 'interval', 'json', 'jsonb', 'uuid',
    'bytea', 'array',
  ],
  operators: [
    '=', '>', '<', '!', '~', '?', ':', '::', '->', '->>', '=>', '<=', '>=',
    '!=', '<>', '||', ':=', '@@', '@>', '<@',
  ],
  tokenizer: {
    root: [
      [/--.*$/, 'comment'],
      [/\/\*/, 'comment', '@comment'],
      [/'([^'\\]|\\.)*'/, 'string'],
      [/"([^"\\]|\\.)*"/, 'string'],
      [/[{}()[\]]/, '@brackets'],
      [/[;,.]/, 'delimiter'],
      [/@@?[a-zA-Z_]\w*/, 'attribute'],
      [/\$\$?[a-zA-Z_]\w*/, 'variable'],
      [/\b\d+(\.\d+)?\b/, 'number'],
      [/[a-zA-Z_]\w*/, {
        cases: {
          '@keywords': 'keyword',
          '@typeKeywords': 'type',
          '@default': 'identifier',
        },
      }],
      [/[-+*/%<>=!|&:@?~]+/, {
        cases: {
          '@operators': 'operator',
          '@default': 'operator',
        },
      }],
      [/\s+/, 'white'],
    ],
    comment: [
      [/[^/*]+/, 'comment'],
      [/\*\//, 'comment', '@pop'],
      [/./, 'comment'],
    ],
  },
}

const OZMA_FUNQL_LANGUAGE_ID = 'ozma-funql'
const SQL_FUNQL_ALIASES = ['sql', 'oc', 'funql', 'pgsql'] as const
const SQL_FUNQL_ALIASES_SET = new Set<string>(SQL_FUNQL_ALIASES)

const installCustomSqlTokenizer = () => {
  const languages = monaco.languages.getLanguages()
  if (!languages.some((lang) => lang.id === OZMA_FUNQL_LANGUAGE_ID)) {
    monaco.languages.register({ id: OZMA_FUNQL_LANGUAGE_ID })
  }
  monaco.languages.setMonarchTokensProvider(
    OZMA_FUNQL_LANGUAGE_ID,
    customSqlMonarch as monaco.languages.IMonarchLanguage,
  )
}

installCustomSqlTokenizer()

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
    { token: 'attribute', foreground: '8ECEFF' },
    { token: 'attribute.sql', foreground: '8ECEFF' },
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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
;(monaco.editor.defineTheme as any)('ozma-dark-glass', {
  base: 'vs-dark',
  inherit: true,
  semanticHighlighting: true,
  semanticTokenColors: {
    'variable': '#8ad8ff',
    'variable.readonly': '#9de7e1',
    'variable.defaultLibrary': '#8ad8ff',
    'parameter': '#d4dee6',
    'function': '#f6b941',
    'function.defaultLibrary': '#8ad8ff',
    'method': '#f6b941',
    'method.defaultLibrary': '#8ad8ff',
    'class': '#f6b941',
    'class.defaultLibrary': '#f6b941',
    'interface': '#f6b941',
    'type': '#f6b941',
    'typeParameter': '#f6b941',
    'namespace': '#d4dee6',
    'property': '#9de7e1',
    'enumMember': '#9de7e1',
    'event': '#9de7e1',
    'macro': '#59d6cf',
    'label': '#d4dee6',
    'property.declaration': '#59d6cf',
  },
  rules: [
    { token: 'keyword', foreground: '59D6CF', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: '59D6CF', fontStyle: 'bold' },
    { token: 'string', foreground: 'F6B941' },
    { token: 'string.sql', foreground: 'F6B941' },
    { token: 'number', foreground: '8AD8FF' },
    { token: 'number.sql', foreground: '8AD8FF' },
    { token: 'comment', foreground: '7E94A6', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '7E94A6', fontStyle: 'italic' },
    { token: 'type', foreground: 'F6B941' },
    { token: 'predefined', foreground: '8AD8FF' },
    { token: 'operator', foreground: 'D4DEE6' },
    { token: 'operator.sql', foreground: '59D6CF' },
    { token: 'identifier', foreground: 'D4DEE6' },
    { token: 'identifier.quote', foreground: 'D4DEE6' },
    { token: 'identifier.quote.sql', foreground: 'D4DEE6' },
    { token: 'attribute', foreground: '8AD8FF' },
    { token: 'attribute.sql', foreground: '8AD8FF' },
    { token: 'variable', foreground: '8AD8FF' },
    { token: 'constant', foreground: '9DE7E1' },
    { token: 'string.escape', foreground: '9DE7E1' },
    { token: 'string.escape.sql', foreground: '9DE7E1' },
    { token: 'number.float', foreground: '8AD8FF' },
    { token: 'number.hex', foreground: '8AD8FF' },
    { token: 'comment.block', foreground: '7E94A6', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: '7E94A6', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'D4DEE680' },
    { token: 'delimiter.sql', foreground: 'D4DEE680' },
    { token: 'delimiter.parenthesis', foreground: 'D4DEE6CC' },
    { token: 'delimiter.parenthesis.sql', foreground: 'D4DEE6CC' },
    { token: 'key.json', foreground: '59D6CF' },
    { token: 'string.value.json', foreground: 'F6B941' },
    { token: 'number.json', foreground: '8AD8FF' },
    { token: 'keyword.json', foreground: '9DE7E1' },
  ],
  colors: {
    'editor.background': '#0b1623',
    'editor.foreground': '#e7ecef',
    'editorLineNumber.foreground': '#95a7b666',
    'editorLineNumber.activeForeground': '#d4dee6b3',
    'editor.selectionBackground': '#59d6cf3d',
    'editor.inactiveSelectionBackground': '#59d6cf26',
    'editor.lineHighlightBackground': '#122235cc',
    'editorCursor.foreground': '#59d6cf',
    'editor.findMatchBackground': '#f6b94170',
    'editor.findMatchHighlightBackground': '#f6b94142',
    'editorIndentGuide.background1': '#8cb0c81a',
    'editorIndentGuide.activeBackground1': '#8cb0c838',
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

  private get monacoLanguage(): string {
    const normalizedLanguage = String(this.language || '').trim().toLowerCase()
    if (SQL_FUNQL_ALIASES_SET.has(normalizedLanguage)) {
      return OZMA_FUNQL_LANGUAGE_ID
    }
    return this.language
  }

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
    const themeStyleName = this.currentThemeStyleName
    if (themeStyleName === 'light-glass') return 'ozma-light-glass'
    if (themeStyleName === 'dark-glass') return 'ozma-dark-glass'
    if (themeStyleName.endsWith('-glass')) {
      return this.isDarkTheme ? 'ozma-dark-glass' : 'ozma-light-glass'
    }
    return this.isDarkTheme ? 'ozma-dark' : 'ozma-light'
  }

  private get currentThemeStyleName(): string {
    const themeRef = this.currentThemeRef as { name?: string } | null
    return themeRef?.name ?? document.documentElement.dataset.themeStyle ?? ''
  }

  get options(): monaco.editor.IStandaloneEditorConstructionOptions {
    const fontSize = 12

    const options: monaco.editor.IStandaloneEditorConstructionOptions = {
      language: this.monacoLanguage,
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

  @Watch('language')
  private onLanguageChange() {
    this.syncModelLanguage()
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
    monaco.editor.setTheme(this.monacoTheme)
    const editor = monaco.editor.create(this.$el as HTMLElement, {
      ...this.options,
      value: this.content,
    })
    this.syncModelLanguage(editor)
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

  private syncModelLanguage(
    editor: monaco.editor.IStandaloneCodeEditor | null = this.editor,
  ) {
    if (editor === null) return
    const model = editor.getModel()
    if (model === null) return
    if (model.getLanguageId() !== this.monacoLanguage) {
      monaco.editor.setModelLanguage(model, this.monacoLanguage)
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
