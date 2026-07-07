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

const regexAlternation = (words: readonly string[]): string =>
  words
    .slice()
    .sort((a, b) => b.length - a.length)
    .map((word) => word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('|')

const sqlKeywordsRegex = new RegExp(
  `\\b(?:${regexAlternation(sqlKeywords)})\\b`,
  'i',
)
const sqlTypeKeywordsRegex = new RegExp(
  `\\b(?:${regexAlternation(sqlTypeKeywords)})\\b`,
  'i',
)

const ozmaFunqlMonarch: monaco.languages.IMonarchLanguage = {
  defaultToken: 'identifier',
  tokenPostfix: '.sql',
  ignoreCase: true,
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
      [sqlTypeKeywordsRegex, 'type'],
      [sqlKeywordsRegex, 'keyword'],
      [/[a-zA-Z_]\w*/, 'identifier'],
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
let ozmaFunqlProviderInitialized = false

const setupOzmaFunqlLanguage = (): void => {
  const isRegistered = monaco.languages
    .getLanguages()
    .some((lang) => lang.id === ozmaFunqlLanguageId)
  if (!isRegistered) {
    monaco.languages.register({ id: ozmaFunqlLanguageId })
  }
  if (!ozmaFunqlProviderInitialized) {
    monaco.languages.setMonarchTokensProvider(
      ozmaFunqlLanguageId,
      ozmaFunqlMonarch,
    )
    monaco.languages.setLanguageConfiguration(ozmaFunqlLanguageId, {
      comments: {
        lineComment: '--',
        blockComment: ['/*', '*/'],
      },
      brackets: [
        ['{', '}'],
        ['[', ']'],
        ['(', ')'],
      ],
      autoClosingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: "'", close: "'", notIn: ['string', 'comment'] },
        { open: '"', close: '"', notIn: ['string', 'comment'] },
      ],
      surroundingPairs: [
        { open: '{', close: '}' },
        { open: '[', close: ']' },
        { open: '(', close: ')' },
        { open: "'", close: "'" },
        { open: '"', close: '"' },
      ],
      indentationRules: {
        increaseIndentPattern: /.*[{[(]\s*$/,
        decreaseIndentPattern: /^\s*[})\]]/,
      },
    })
    ozmaFunqlProviderInitialized = true
  }
}

setupOzmaFunqlLanguage()

monaco.editor.defineTheme('ozma-light', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '0b6e6a', // keyword
    '0f766e', // string
    'b65300', // number
    '9ca3af', // comment
    '7a3fc2', // type
    '6b7280', // operator
    '3f6fd3', // @attr / .@attr
    '9a2a6c', // $arg / $$arg
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
    '0f766e', // keyword (teal)
    'b45309', // string
    'b45309', // number
    '7c6f60', // comment
    '7b4db1', // type
    '6f6a62', // operator
    '3f6fd3', // @attr / .@attr
    '8e2d62', // $arg / $$arg
    '3f3b35', // identifiers
  ),
  colors: {
    'editor.background': '#fffdf8',
    'editor.foreground': '#1f1f1f',
    'editorLineNumber.foreground': '#9f9689',
    'editorLineNumber.activeForeground': '#5f5850',
    'editor.selectionBackground': '#14b8a633',
    'editor.inactiveSelectionBackground': '#14b8a620',
    'editor.lineHighlightBackground': '#f4efe4cc',
    'editorCursor.foreground': '#0f766e',
    'editor.findMatchBackground': '#f6b94166',
    'editor.findMatchHighlightBackground': '#f6b94133',
    'editorIndentGuide.background1': '#c4b6a34d',
    'editorIndentGuide.activeBackground1': '#c4b6a380',
  },
})

monaco.editor.defineTheme('ozma-light-glass-cool', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '0b8577', // keyword (teal)
    '0fa968', // string (green)
    '0e7fa8', // number (cyan)
    '74898f', // comment
    '8b5cf6', // type (purple)
    '40585f', // operator
    '0e7fa8', // @attr / .@attr
    'c2410c', // $arg / $$arg
    '0b1b1e', // identifiers
  ),
  colors: {
    'editor.background': '#f6fbfa',
    'editor.foreground': '#0b1b1e',
    'editorLineNumber.foreground': '#74898f',
    'editorLineNumber.activeForeground': '#40585f',
    'editor.selectionBackground': '#14b8a633',
    'editor.inactiveSelectionBackground': '#14b8a61f',
    'editor.lineHighlightBackground': '#0a232808',
    'editorCursor.foreground': '#0b8577',
    'editor.findMatchBackground': '#14b8a64d',
    'editor.findMatchHighlightBackground': '#14b8a626',
    'editorIndentGuide.background1': '#0a232812',
    'editorIndentGuide.activeBackground1': '#0a232830',
  },
})

monaco.editor.defineTheme('ozma-light-glass-warm', {
  base: 'vs',
  inherit: true,
  rules: tokenRules(
    '1a5f7a', // keyword (sea-teal)
    '1e8e5a', // string (green)
    '16708f', // number (link)
    '8a8172', // comment
    '8b5cf6', // type (purple)
    '5b544a', // operator
    '16708f', // @attr / .@attr
    'c2410c', // $arg / $$arg
    '241f18', // identifiers
  ),
  colors: {
    'editor.background': '#faf7f0',
    'editor.foreground': '#241f18',
    'editorLineNumber.foreground': '#8a8172',
    'editorLineNumber.activeForeground': '#5b544a',
    'editor.selectionBackground': '#3db8c833',
    'editor.inactiveSelectionBackground': '#3db8c81f',
    'editor.lineHighlightBackground': '#3c301e08',
    'editorCursor.foreground': '#2185a0',
    'editor.findMatchBackground': '#3db8c84d',
    'editor.findMatchHighlightBackground': '#3db8c826',
    'editorIndentGuide.background1': '#3c301e12',
    'editorIndentGuide.activeBackground1': '#3c301e30',
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
    { token: 'number', foreground: 'F5A97F' },
    { token: 'number.sql', foreground: 'F5A97F' },
    { token: 'comment', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '6C7086', fontStyle: 'italic' },
    { token: 'type', foreground: 'C6A0F6' },
    { token: 'predefined', foreground: 'C6A0F6' },
    { token: 'operator', foreground: '9AA3B2' },
    { token: 'operator.sql', foreground: '9AA3B2' },
    { token: 'identifier', foreground: 'CDD3DE' },
    { token: 'identifier.quote', foreground: 'CDD3DE' },
    { token: 'identifier.quote.sql', foreground: 'CDD3DE' },
    { token: 'attribute', foreground: 'F2B896' },
    { token: 'attribute.sql', foreground: 'F2B896' },
    { token: 'variable', foreground: 'FF7AB2' },
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
    'variable': '#8cd8f0',
    'variable.readonly': '#8cf0e3',
    'variable.defaultLibrary': '#8cd8f0',
    'parameter': '#a3b8be',
    'function': '#45e3cf',
    'function.defaultLibrary': '#4fc9e8',
    'method': '#45e3cf',
    'method.defaultLibrary': '#4fc9e8',
    'class': '#4fc9e8',
    'class.defaultLibrary': '#4fc9e8',
    'interface': '#4fc9e8',
    'type': '#4fc9e8',
    'typeParameter': '#4fc9e8',
    'namespace': '#a3b8be',
    'property': '#8cf0e3',
    'enumMember': '#8cf0e3',
    'event': '#8cf0e3',
    'macro': '#2dd4bf',
    'label': '#a3b8be',
    'property.declaration': '#2dd4bf',
  },
  rules: [
    { token: 'keyword', foreground: '4FC9E8', fontStyle: 'bold' },
    { token: 'keyword.sql', foreground: '4FC9E8', fontStyle: 'bold' },
    { token: 'string', foreground: '6EF0D2' },
    { token: 'string.sql', foreground: '6EF0D2' },
    { token: 'number', foreground: 'FFBA53' },
    { token: 'number.sql', foreground: 'FFBA53' },
    { token: 'comment', foreground: '64808A', fontStyle: 'italic' },
    { token: 'comment.sql', foreground: '64808A', fontStyle: 'italic' },
    { token: 'type', foreground: '2DD4BF' },
    { token: 'predefined', foreground: '2DD4BF' },
    { token: 'operator', foreground: 'A3B8BE' },
    { token: 'operator.sql', foreground: 'A3B8BE' },
    { token: 'identifier', foreground: 'F1F7F7' },
    { token: 'identifier.quote', foreground: 'F1F7F7' },
    { token: 'identifier.quote.sql', foreground: 'F1F7F7' },
    { token: 'attribute', foreground: 'FFBA53' },
    { token: 'attribute.sql', foreground: 'FFBA53' },
    { token: 'variable', foreground: 'B18CFF' },
    { token: 'constant', foreground: '8CF0E3' },
    { token: 'string.escape', foreground: '8CF0E3' },
    { token: 'string.escape.sql', foreground: '8CF0E3' },
    { token: 'number.float', foreground: 'FFBA53' },
    { token: 'number.hex', foreground: 'FFBA53' },
    { token: 'comment.block', foreground: '64808A', fontStyle: 'italic' },
    { token: 'comment.block.sql', foreground: '64808A', fontStyle: 'italic' },
    { token: 'delimiter', foreground: 'A3B8BE80' },
    { token: 'delimiter.sql', foreground: 'A3B8BE80' },
    { token: 'delimiter.parenthesis', foreground: 'A3B8BECC' },
    { token: 'delimiter.parenthesis.sql', foreground: 'A3B8BECC' },
    { token: 'key.json', foreground: '2DD4BF' },
    { token: 'string.value.json', foreground: '6EF0D2' },
    { token: 'number.json', foreground: 'FFBA53' },
    { token: 'keyword.json', foreground: '8CF0E3' },
  ],
  colors: {
    'editor.background': '#081217',
    'editor.foreground': '#f1f7f7',
    'editorLineNumber.foreground': '#64808a99',
    'editorLineNumber.activeForeground': '#a3b8be',
    'editor.selectionBackground': '#2dd4bf3d',
    'editor.inactiveSelectionBackground': '#2dd4bf26',
    'editor.lineHighlightBackground': '#0e1920cc',
    'editorCursor.foreground': '#35d3c0',
    'editor.findMatchBackground': '#ffba5370',
    'editor.findMatchHighlightBackground': '#ffba5342',
    'editorIndentGuide.background1': '#a3b8be1a',
    'editorIndentGuide.activeBackground1': '#a3b8be38',
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
  private semanticDecorationIds: string[] = []

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
    if (themeStyleName === 'light-glass-cool') return 'ozma-light-glass-cool'
    if (themeStyleName === 'light-glass-warm') return 'ozma-light-glass-warm'
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
      tabSize: 4,
      insertSpaces: true,
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
    setupOzmaFunqlLanguage()
    this.syncModelLanguage()
  }

  @Watch('currentThemeRef')
  private onThemeChange() {
    this.applyTokenThemeClass()
    if (this.editor !== null) {
      monaco.editor.setTheme(this.monacoTheme)
      this.applySemanticDecorations()
    }
  }

  @Watch('content')
  private updateContent(content: string) {
    if (this.editor !== null && this.editor.getValue() !== content) {
      this.editor.setValue(content)
      this.applySemanticDecorations()
    }
  }

  private mounted() {
    setupOzmaFunqlLanguage()
    this.applyTokenThemeClass()
    monaco.editor.setTheme(this.monacoTheme)
    const model = monaco.editor.createModel(this.content, this.monacoLanguage)
    const editor = monaco.editor.create(this.$el as HTMLElement, {
      ...this.options,
      model,
    })
    this.syncModelLanguage(editor)
    this.$nextTick(() => {
      setupOzmaFunqlLanguage()
      this.syncModelLanguage(editor)
      this.applyTokenThemeClass()
      monaco.editor.setTheme(this.monacoTheme)
      this.applySemanticDecorations()
    })
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
      this.applySemanticDecorations()
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

  private applyTokenThemeClass() {
    const root = this.$el as HTMLElement
    if (!root) return
    for (const themeName of [
      'ozma-light',
      'ozma-light-glass',
      'ozma-light-glass-cool',
      'ozma-light-glass-warm',
      'ozma-dark',
      'ozma-dark-glass',
    ]) {
      root.classList.remove(`ozma-theme-${themeName}`)
    }
    root.classList.add(`ozma-theme-${this.monacoTheme}`)
  }

  private static collectMatches(
    source: string,
    pattern: RegExp,
    kind: string,
    protectedRanges: Array<{ start: number; end: number }>,
    occupiedRanges: Array<{ start: number; end: number }>,
  ): Array<{ start: number; end: number; kind: string }> {
    const matches: Array<{ start: number; end: number; kind: string }> = []
    pattern.lastIndex = 0
    // no-cond-assign: keep regex matching loop explicit for lint compatibility
    while (true) {
      const match = pattern.exec(source)
      if (match === null) break
      const start = match.index
      const end = start + match[0].length
      if (start === end) continue
      if (
        protectedRanges.some((range) => start < range.end && end > range.start)
      ) {
        continue
      }
      if (occupiedRanges.some((range) => start < range.end && end > range.start)) {
        continue
      }
      matches.push({ start, end, kind })
      occupiedRanges.push({ start, end })
    }
    return matches
  }

  private static collectCaptureMatches(
    source: string,
    pattern: RegExp,
    captureGroupIndex: number,
    kind: string,
    protectedRanges: Array<{ start: number; end: number }>,
    occupiedRanges: Array<{ start: number; end: number }>,
  ): Array<{ start: number; end: number; kind: string }> {
    const matches: Array<{ start: number; end: number; kind: string }> = []
    pattern.lastIndex = 0
    // no-cond-assign: keep regex matching loop explicit for lint compatibility
    while (true) {
      const match = pattern.exec(source)
      if (match === null) break
      const captured = match[captureGroupIndex]
      if (!captured) continue
      const fullStart = match.index
      const fullText = match[0]
      const capturedOffset = fullText.indexOf(captured)
      if (capturedOffset < 0) continue
      const start = fullStart + capturedOffset
      const end = start + captured.length
      if (
        protectedRanges.some((range) => start < range.end && end > range.start)
      ) {
        continue
      }
      if (occupiedRanges.some((range) => start < range.end && end > range.start)) {
        continue
      }
      matches.push({ start, end, kind })
      occupiedRanges.push({ start, end })
    }
    return matches
  }

  private applySemanticDecorations() {
    if (this.editor === null) return
    const model = this.editor.getModel()
    if (model === null) return
    if (model.getLanguageId() !== ozmaFunqlLanguageId) {
      this.semanticDecorationIds = this.editor.deltaDecorations(
        this.semanticDecorationIds,
        [],
      )
      return
    }

    const decorations: monaco.editor.IModelDeltaDecoration[] = []
    const lineCount = model.getLineCount()

    for (let lineNumber = 1; lineNumber <= lineCount; lineNumber += 1) {
      const line = model.getLineContent(lineNumber)
      const protectedRanges: Array<{ start: number; end: number }> = []
      const occupiedRanges: Array<{ start: number; end: number }> = []

      const lineCommentStart = line.indexOf('--')
      if (lineCommentStart >= 0) {
        protectedRanges.push({ start: lineCommentStart, end: line.length })
      }

      const stringRegex = /'([^'\\]|\\.)*'/g
      while (true) {
        const stringMatch = stringRegex.exec(line)
        if (stringMatch === null) break
        protectedRanges.push({
          start: stringMatch.index,
          end: stringMatch.index + stringMatch[0].length,
        })
      }

      const tokenRanges = [
        ...CodeEditor.collectMatches(
          line,
          /\b\d+(?:\.\d+)?\b/g,
          'number',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectMatches(
          line,
          /\b(?:int|integer|bigint|smallint|numeric|decimal|float|real|double|text|varchar|char|boolean|bool|date|datetime|time|timestamp|interval|json|jsonb|uuid|bytea|array)\b/gi,
          'type',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectMatches(
          line,
          /\b(?:select|from|where|join|left|right|inner|outer|full|cross|on|as|and|or|not|in|is|null|case|when|then|else|end|group|order|by|asc|desc|limit|offset|union|intersect|except|all|distinct|for|insert|into|update|delete|values|with|recursive|materialized|partition|over|filter|having|between|exists|like|ilike|similar|only|lateral|domain|interval|superuser|role|inherited|oftype|mapping|reference|enum|internal|default|returns|returning|create|alter|drop|replace|table|view|function|begin|declare|language|set|show|grant|revoke|using|array|any|some|nulls|first|last|true|false)\b/gi,
          'keyword',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectMatches(
          line,
          /(?:\b[a-zA-Z_]\w*\.)?@@?[a-zA-Z_]\w*|@@?[a-zA-Z_]\w*/g,
          'attribute',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectMatches(
          line,
          /\$\$?[a-zA-Z_]\w*/g,
          'variable',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectCaptureMatches(
          line,
          /(?:^|[\s,(])([a-zA-Z_]\w*)\s*=/g,
          1,
          'property',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectCaptureMatches(
          line,
          /(?:^|[^\w$@.])([a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*)\s*(?=\()/g,
          1,
          'function',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectCaptureMatches(
          line,
          /=>\s*([a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*)/g,
          1,
          'relation-target',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectCaptureMatches(
          line,
          /\b([a-zA-Z_]\w*)\.[a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*/g,
          1,
          'namespace',
          protectedRanges,
          occupiedRanges,
        ),
        ...CodeEditor.collectCaptureMatches(
          line,
          /\b[a-zA-Z_]\w*\.([a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*)/g,
          1,
          'dotted-tail',
          protectedRanges,
          occupiedRanges,
        ),
      ]

      const identifierMatches = CodeEditor.collectMatches(
        line,
        /\b[a-zA-Z_]\w*(?:\.[a-zA-Z_]\w*)*\b/g,
        'identifier',
        protectedRanges,
        occupiedRanges,
      )

      for (const range of [...identifierMatches, ...tokenRanges]) {
        decorations.push({
          range: new monaco.Range(
            lineNumber,
            range.start + 1,
            lineNumber,
            range.end + 1,
          ),
          options: {
            inlineClassName: `ozma-token-${range.kind}`,
          },
        })
      }
    }

    this.semanticDecorationIds = this.editor.deltaDecorations(
      this.semanticDecorationIds,
      decorations,
    )
  }

  @Watch('autofocus')
  private onAutofocus(autofocus: boolean) {
    if (autofocus && this.editor) {
      this.editor.focus()
    }
  }

  private beforeDestroy() {
    if (this.editor !== null) {
      this.semanticDecorationIds = this.editor.deltaDecorations(
        this.semanticDecorationIds,
        [],
      )
    }
    const model = this.editor?.getModel()
    this.editor?.dispose()
    model?.dispose()
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

.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-identifier {
  color: #343a40 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-keyword {
  color: #0b6e6a !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-type {
  color: #7a3fc2 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-attribute {
  color: #3f6fd3 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-variable {
  color: #9a2a6c !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-property {
  color: #2b6f66 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-function {
  color: #8a4f1f !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-number {
  color: #b65300 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-relation-target {
  color: #343a40 !important;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-namespace {
  color: #7a3fc2 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light ::v-deep .ozma-token-dotted-tail {
  color: #343a40 !important;
}

.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-identifier {
  color: #3a4046 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-keyword {
  color: #0f766e !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-type {
  color: #7b4db1 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-attribute {
  color: #3f6fd3 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-variable {
  color: #8e2d62 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-property {
  color: #2a6f66 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-function {
  color: #905522 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-number {
  color: #b45309 !important;
}
.code-editor.ozma-theme-ozma-light-glass
  ::v-deep
  .ozma-token-relation-target {
  color: #3a4046 !important;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-namespace {
  color: #7b4db1 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass ::v-deep .ozma-token-dotted-tail {
  color: #3a4046 !important;
}

.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-identifier {
  color: #d4cd8b !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-keyword {
  color: #7adbd6 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-type {
  color: #c6a0f6 !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-attribute {
  color: #f2b896 !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-variable {
  color: #ff7ab2 !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-property {
  color: #69c4bc !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-function {
  color: #93d29c !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-number {
  color: #f5a97f !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-relation-target {
  color: #d4cd8b !important;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-namespace {
  color: #c6a0f6 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark ::v-deep .ozma-token-dotted-tail {
  color: #d4cd8b !important;
}

.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-identifier {
  color: #f1f7f7 !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-keyword {
  color: #4fc9e8 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-type {
  color: #2dd4bf !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-attribute {
  color: #ffba53 !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-variable {
  color: #b18cff !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-property {
  color: #8cf0e3 !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-function {
  color: #45e3cf !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-number {
  color: #ffba53 !important;
}
.code-editor.ozma-theme-ozma-dark-glass
  ::v-deep
  .ozma-token-relation-target {
  color: #f1f7f7 !important;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-namespace {
  color: #4fc9e8 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-dark-glass ::v-deep .ozma-token-dotted-tail {
  color: #f1f7f7 !important;
}

.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-identifier {
  color: #0b1b1e !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-keyword {
  color: #0b8577 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-type {
  color: #8b5cf6 !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-attribute {
  color: #0e7fa8 !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-variable {
  color: #c2410c !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-property {
  color: #0e8f96 !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-function {
  color: #0b8577 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-number {
  color: #b45309 !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool
  ::v-deep
  .ozma-token-relation-target {
  color: #0b1b1e !important;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-namespace {
  color: #8b5cf6 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-cool ::v-deep .ozma-token-dotted-tail {
  color: #0b1b1e !important;
}

.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-identifier {
  color: #241f18 !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-keyword {
  color: #1a5f7a !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-type {
  color: #8b5cf6 !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-attribute {
  color: #16708f !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-variable {
  color: #c2410c !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-property {
  color: #178a91 !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-function {
  color: #1a5f7a !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-number {
  color: #b45309 !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm
  ::v-deep
  .ozma-token-relation-target {
  color: #241f18 !important;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-namespace {
  color: #8b5cf6 !important;
  font-weight: 600;
}
.code-editor.ozma-theme-ozma-light-glass-warm ::v-deep .ozma-token-dotted-tail {
  color: #241f18 !important;
}

</style>
