#!/usr/bin/env node
// Overwrites each corpus case's expectations with what a run of it produces.
//
//     node tests/record-corpus.js                  every case
//     node tests/record-corpus.js --grep "several files"
//
// --grep matches a substring of a case's claim or its group's title, the same
// handle Mocha takes. Read the diff before keeping it.

'use strict';

const fs = require('fs');
const { LEGS, loadCorpus, runCase } = require('./corpus-case');

const options = parseArguments(process.argv.slice(2));
let recorded = 0;

const matches = (text) => !options.grep
    || text.toLowerCase().includes(options.grep.toLowerCase());

for (const { file, group } of loadCorpus()) {
    const selected = matches(group.group) ? group.cases
        : group.cases.filter((c) => matches(c.name));
    if (!selected.length) continue;

    console.log(`\n${group.group}`);
    for (const testCase of selected) {
        const results = runCase(testCase);
        testCase.expect = expectationFrom(results);
        recorded += 1;
        console.log(`  ${testCase.name}`);
        for (const leg of LEGS) {
            console.log(`    ${leg}: exit ${results[leg].exit}`);
            for (const line of results[leg].stdout) console.log(`      out ${line}`);
            for (const line of results[leg].stderr.trim().split('\n').filter(Boolean)) {
                console.log(`      err ${line}`);
            }
        }
    }

    fs.writeFileSync(file, `${JSON.stringify(group, null, 2)}\n`);
}

console.log(`\n${recorded} case${recorded === 1 ? '' : 's'} recorded — read the diff`);

// Builds one case's expectation: a shared value per field where the two
// validators agree, an object keyed by validator name where they differ.
function expectationFrom(results) {
    const [left, right] = LEGS.map((leg) => results[leg]);
    const perLeg = (pick) => Object.fromEntries(LEGS.map((leg) => [leg, pick(results[leg])]));
    const expect = {};

    expect.exit = left.exit === right.exit ? left.exit : perLeg((r) => r.exit);
    expect.stdout = sameLines(left.stdout, right.stdout) ? left.stdout
        : perLeg((r) => r.stdout);

    if (LEGS.some((leg) => results[leg].stderr.trim())) {
        expect.stderrContains = perLeg((r) => firstLine(r.stderr));
    }
    return expect;
}

const sameLines = (a, b) => a.length === b.length && a.every((line, i) => line === b[i]);
const firstLine = (text) => (text.trim() ? text.trim().split('\n')[0] : '');

function parseArguments(argv) {
    const options = {};
    for (let i = 0; i < argv.length; i += 1) {
        if (argv[i] === '--grep') {
            options.grep = argv[i + 1];
            i += 1;
        } else {
            console.error(`record-corpus: unknown argument ${argv[i]}`);
            process.exit(2);
        }
    }
    return options;
}
