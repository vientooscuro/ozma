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

const sqlKeywords = [
  'select',
  'from',
  'where',
  'join',
  'left',
  'right',
  'inner',
  'outer',
  'full',
  'cross',
  'on',
  'as',
  'and',
  'or',
  'not',
  'in',
  'is',
  'null',
  'case',
  'when',
  'then',
  'else',
  'end',
  'group',
  'order',
  'by',
  'asc',
  'desc',
  'limit',
  'offset',
  'union',
  'intersect',
  'except',
  'all',
  'distinct',
  'for',
  'insert',
  'into',
  'update',
  'delete',
  'values',
  'with',
  'recursive',
  'materialized',
  'partition',
  'over',
  'filter',
  'having',
  'between',
  'exists',
  'like',
  'ilike',
  'similar',
  'only',
  'lateral',
  'domain',
  'interval',
  'superuser',
  'role',
  'inherited',
  'oftype',
  'mapping',
  'reference',
  'enum',
  'internal',
  'default',
  'returns',
  'returning',
  'create',
  'alter',
  'drop',
  'replace',
  'table',
  'view',
  'function',
  'begin',
  'declare',
  'language',
  'set',
  'show',
  'grant',
  'revoke',
  'using',
  'array',
  'any',
  'some',
  'nulls',
  'first',
  'last',
  'true',
  'false',
] as const

const sqlTypeKeywords = [
  'int',
  'integer',
  'bigint',
  'smallint',
  'numeric',
  'decimal',
  'float',
  'real',
  'double',
  'text',
  'varchar',
  'char',
  'boolean',
  'bool',
  'date',
  'datetime',
  'time',
  'timestamp',
  'interval',
  'json',
  'jsonb',
  'uuid',
  'bytea',
  'array',
] as const

const ozmaFunqlMonarch: monaco.languages.IMonarchLanguage = {
  defaultToken: 'identifier',
  tokenPostfix: '.sql',
  ignoreCase: true,
  keywords: sqlKeywords,
  typeKeywords: sqlTypeKeywords,
  operators: [
    '=',
    '>',
    '<',
    '!',
    '~',
    '?',
    ':',
    '::',
    '->',
    '->>',
    '=>',
    '<=',
    '>=',
    '!=',
    '<>',
    '||',
    ':=',
    '@@',
    '@>',
    '<@',
  ],
  tokenizer: {
    root: [
      [/--.*$/, 'comment'],
      [/\/\*/, 'comment', '@comment'],
      [/'([^'\\]|\\.)*'/, 'string'],
      [/"([^"\\]|\\.)*"/, 'string'],
      [/\.\s*@@?[a-zA-Z_]\w*/, 'attribute'],
      [/@@?[a-zA-Z_]\w*/, 'attribute'],
      [/\$\$?[a-zA-Z_]\w*/, 'variable'],
      [/[{}()[\]]/, '@brackets'],
      [/[;,.]/, 'delimiter'],
      [/\d+(\.\d+)?/, 'number'],
      [
        /[a-zA-Z_]\w*/,
        {
          cases: {
            '@typeKeywords': 'type',
            '@keywords': 'keyword',
            '@default': 'identifier',
          },
        },
      ],
      [
        /[-+*/%<>=!|&:@?~]+/,
        {
          cases: {
            '@operators': 'operator',
            '@default': 'operator',
          },
        },
      ],
      [/\s+/, 'white'],
    ],
    comment: [
      [/[^/*]+/, 'comment'],
      [/\*\//, 'comment', '@pop'],
      [/./, 'comment'],
    ],
  },
}

const ozmaFunqlLanguageId = 'ozma-funql'
const ozmaSqlAliases = ['sql', 'oc', 'funql', 'pgsql']
const ozmaSqlAliasesSet = new Set(ozmaSqlAliases)

const setupOzmaFunqlLanguage = (): void => {
  const isRegistered = monaco.languages
    .getLanguages()
    .some((lang) => lang.id === ozmaFunqlLanguageId)
  if (!isRegistered) {
    monaco.languages.register({ id: ozmaFunqlLanguageId })
  }
  monaco.languages.setMonarchTokensProvider(
    ozmaFunqlLanguageId,
    ozmaFunqlMonarch,
  )
}

setupOzmaFunqlLanguage()

monaco.editor.defineTheme('ozma-light', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '7c3aed', // keyword
    '0f766e', // string
    'c2410c', // number
    '9ca3af', // comment
    '1d4ed8', // type
    '0369a1', // operator
    '2563eb', // @attr / .@attr
    'be185d', // $arg / $$arg
    '2e2e2e', // identifiers
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
    '0f766e', // keyword
    'b45309', // string
    '2563eb', // number
    '7c6f60', // comment
    '0b5e5a', // type
    '6f6a62', // operator
    '2563eb', // @attr / .@attr
    '1d4ed8', // $arg / $$arg
    '3f3b35', // identifiers
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
    'property.declaration': '#7ADBD6',
  },
  rules: [
    { token: 'keyword', foreground: 'CBA6F7', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: 'CBA6F7', fontStyle: 'bold' },
    { token: 'string', foreground: 'A6E3A1' },
    { token: 'string.sql', foreground: 'A6E3A1' },
    { token: 'number', foreground: 'FAB387' },
    { token: 'number.sql', foreground: 'FAB387' },
    { token: 'comment', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'type', foreground: '89B4FA' },
    { token: 'predefined', foreground: '89B4FA' },
    { token: 'operator', foreground: '89DCEB' },
    { token: 'operator.sql', foreground: '89DCEB' },
    { token: 'identifier', foreground: 'CDD3DE' },
    { token: 'identifier.quote', foreground: 'CDD3DE' },
    { token: 'identifier.quote.sql', foreground: 'CDD3DE' },
    { token: 'attribute', foreground: '8ECEFF' },
    { token: 'attribute.sql', foreground: '8ECEFF' },
    { token: 'variable', foreground: 'F38BA8' },
    { token: 'constant', foreground: 'B8AEFF' },
    { token: 'string.escape', foreground: 'B8AEFF' },
    { token: 'string.escape.sql', foreground: 'B8AEFF' },
    { token: 'number.float', foreground: 'FAB387' },
    { token: 'number.hex', foreground: 'FAB387' },
    { token: 'comment.block', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'CDD3DE80' },
    { token: 'delimiter.sql', foreground: 'CDD3DE80' },
    { token: 'delimiter.parenthesis', foreground: 'CDD3DECC' },
    { token: 'delimiter.parenthesis.sql', foreground: 'CDD3DECC' },
    { token: 'key.json', foreground: '89DCEB' },
    { token: 'string.value.json', foreground: 'A6E3A1' },
    { token: 'number.json', foreground: 'FAB387' },
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
    { token: 'keyword', foreground: 'C9A0FF', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: 'C9A0FF', fontStyle: 'bold' },
    { token: 'string', foreground: '44AA99' },
    { token: 'string.sql', foreground: '44AA99' },
    { token: 'number', foreground: 'DD9900' },
    { token: 'number.sql', foreground: 'DD9900' },
    { token: 'comment', foreground: '666A73', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '666A73', fontStyle: 'italic' },
    { token: 'type', foreground: '59D6CF' },
    { token: 'predefined', foreground: '59D6CF' },
    { token: 'operator', foreground: '49AAEE' },
    { token: 'operator.sql', foreground: '49AAEE' },
    { token: 'identifier', foreground: 'D4DEE6' },
    { token: 'identifier.quote', foreground: 'D4DEE6' },
    { token: 'identifier.quote.sql', foreground: 'D4DEE6' },
    { token: 'attribute', foreground: '6D77FF' },
    { token: 'attribute.sql', foreground: '6D77FF' },
    { token: 'variable', foreground: 'FF4FA2' },
    { token: 'constant', foreground: '9DE7E1' },
    { token: 'string.escape', foreground: '9DE7E1' },
    { token: 'string.escape.sql', foreground: '9DE7E1' },
    { token: 'number.float', foreground: '8AD8FF' },
    { token: 'number.hex', foreground: '8AD8FF' },
    { token: 'comment.block', foreground: '666A73', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: '666A73', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'D4DEE680' },
    { token: 'delimiter.sql', foreground: 'D4DEE680' },
    { token: 'delimiter.parenthesis', foreground: 'D4DEE6CC' },
    { token: 'delimiter.parenthesis.sql', foreground: 'D4DEE6CC' },
    { token: 'key.json', foreground: '59D6CF' },
    { token: 'string.value.json', foreground: '44AA99' },
    { token: 'number.json', foreground: 'DD9900' },
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
    const language = String(this.language || '').trim().toLowerCase()
    return ozmaSqlAliasesSet.has(language) ? ozmaFunqlLanguageId : this.language
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
    editor.onDidChangeModelContent(() => {
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
    if (model.getLanguageId() === this.monacoLanguage) return
    monaco.editor.setModelLanguage(model, this.monacoLanguage)
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
