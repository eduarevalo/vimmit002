var jsdiff = require('diff'),
fs = require('fs');

var one = fs.readFileSync('testa.txt', 'utf8');
var other = fs.readFileSync('testb.txt', 'utf8');

var diff = jsdiff.diffChars(one, other);

diff.forEach(function(part){
  console.log(part);
});
