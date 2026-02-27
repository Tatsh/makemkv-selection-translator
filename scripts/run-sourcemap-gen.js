'use strict';

const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const projectRoot = path.resolve(__dirname, '..');
const outputFile = process.argv[2] || 'main.js';
const sourceFile = process.argv[3] || 'src/Main.elm';
const mapPath = path.join(projectRoot, outputFile + '.map');
const jsPath = path.join(projectRoot, outputFile);

const dom = new JSDOM('<!DOCTYPE html><html><body><div id="app"></div></body></html>', {
  url: 'file://' + projectRoot + '/',
  runScripts: 'dangerously',
  resources: 'usable',
});

const window = dom.window;
const document = window.document;
global.window = window;
global.document = document;

const genPath = path.join(__dirname, 'sourcemap-gen', 'sourcemap-gen.js');
const genCode = fs.readFileSync(genPath, 'utf8');
const script = window.document.createElement('script');
script.textContent = genCode;
window.document.body.appendChild(script);

const app = window.Elm.Main.init({
  node: document.getElementById('app'),
  flags: { outputFile, sourceFile },
});

app.ports.emitMap.subscribe(function (mapJson) {
  fs.writeFileSync(mapPath, mapJson, 'utf8');
  const js = fs.readFileSync(jsPath, 'utf8');
  const trimmed = js.replace(/\n*\/\/# sourceMappingURL=.*$/m, '');
  fs.writeFileSync(
    jsPath,
    trimmed + '\n//# sourceMappingURL=' + path.basename(outputFile) + '.map\n',
    'utf8',
  );
  process.exit(0);
});
