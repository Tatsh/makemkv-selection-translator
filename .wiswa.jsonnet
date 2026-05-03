{
  uses_user_defaults: true,
  project_type: 'other',
  project_name: 'makemkv-selection-translator',
  version: '0.0.7',
  description: 'Translate a MakeMKV track selection string to plain English.',
  keywords: ['elm', 'makemkv', 'utility', 'web-app'],
  prettierignore+: ['*.elm', '*.jison'],
  want_main: false,
  package_json+: {
    dependenciesMeta+: {
      elm: { built: true },
    },
    devDependencies+: {
      elm: '^0.19.1-6',
      'elm-test': '0.19.1-revision17',
    },
    files+: ['dist/**/*.js'],
    main: 'index.js',
    scripts+: {
      'build:ci': 'elm make src/Main.elm --output=main.js --optimize',
      test: 'elm-test',
    },
    types: './dist/',
  },
  shared_ignore+: ['/elm-stuff/'],
}
