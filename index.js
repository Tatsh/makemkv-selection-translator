const Parser = require("jison").Parser;
const fs = require("fs");
const bnf = fs.readFileSync("./sel.jison", "utf8");
// @ts-ignore
const parser = new Parser(bnf);

console.log(
  parser.parse(`-sel:all,
                +sel:((multi|stereo|mono)&favlang),
                -sel:mvcvideo,
                +sel:subtitle,
                =100:all,
                -10:favlang`)
);
console.log("");
console.log(
  parser.parse(
    "-sel:all,+sel:(favlang|nolang),-sel:mvcvideo,=100:all,-10:favlang"
  )
);

module.exports = parser;
