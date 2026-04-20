local utils = import 'utils.libjsonnet';

{
  uses_user_defaults: true,
  project_type: 'other',
  project_name: 'makemkv-selection-translator',
  version: '0.0.1',
  description: 'Translate a MakeMKV track selection string to plain English.',
  keywords: ['elm', 'makemkv', 'utility', 'web-app'],
  want_main: false,
  package_json+: {
    devDependencies+: {
      elm: utils.latestNpmPackageVersionCaret('elm'),
    },
    files+: ['dist/**/*.js'],
    main: 'index.js',
    scripts+: {
      'build:ci': 'elm make src/Main.elm --output=main.js --optimize',
    },
    types: './dist/',
  },
}
