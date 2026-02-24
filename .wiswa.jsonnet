local utils = import 'utils.libjsonnet';

{
  project_type: 'other',
  project_name: 'makemkv-selection-translator',
  version: '0.0.1',
  description: 'Translate a MakeMKV track selection string to plain English.',
  keywords: ['elm', 'makemkv', 'utility', 'web-app'],
  want_main: false,
  copilot+: {
    intro: 'makemkv-selection-translator translates a MakeMKV track selection string into plain English.',
  },
  package_json+: {
    devDependencies+: {
      'elm': utils.latestNpmPackageVersionCaret('elm'),
    },
    files+: ['dist/**/*.js'],
    main: 'index.js',
    types: './dist/',
  },
}
