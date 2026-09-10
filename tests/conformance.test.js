// Runs every corpus case through both validators, checking each against its
// recorded behavior and the two against each other.

'use strict';

const assert = require('node:assert');
const {
    LEGS, loadCorpus, runCase, expectedFor, locations,
} = require('./corpus-case');

for (const { group } of loadCorpus()) {
    describe(group.group, function () {
        for (const testCase of group.cases) {
            describe(testCase.name, function () {
                let results;

                before(function () {
                    results = runCase(testCase);
                });

                for (const leg of LEGS) {
                    it(`${leg} behaves as recorded`, function () {
                        const expected = expectedFor(testCase, leg);
                        const observed = results[leg];

                        if ('exit' in expected) {
                            assert.strictEqual(observed.exit, expected.exit,
                                `exit status\n${describeCase(testCase)}`);
                        }
                        if ('stdout' in expected) {
                            assert.deepStrictEqual(observed.stdout, expected.stdout,
                                `stdout\n${describeCase(testCase)}`);
                        }
                        if ('report' in expected) {
                            assert.deepStrictEqual(observed.report, expected.report,
                                `JSON report\n${describeCase(testCase)}`);
                        }
                        if (expected.stderrContains) {
                            assert.ok(observed.stderr.includes(expected.stderrContains),
                                `stderr should contain ${JSON.stringify(expected.stderrContains)}`
                                + `\n  observed: ${JSON.stringify(observed.stderr.trim())}`);
                        }
                    });
                }

                it('reports the same verdict from both implementations', function () {
                    // Only a defect that splits the two suspends this check;
                    // one they share leaves them agreeing.
                    if (testCase.defect && testCase.defect.divergent) this.skip();
                    const [left, right] = LEGS.map((leg) => results[leg]);

                    assert.strictEqual(left.exit, right.exit,
                        'the two implementations disagree on exit status');
                    assert.strictEqual(left.stdout.length, right.stdout.length,
                        'the two implementations disagree on the number of verdict lines'
                        + `\n  ${LEGS[0]}: ${JSON.stringify(left.stdout)}`
                        + `\n  ${LEGS[1]}: ${JSON.stringify(right.stdout)}`);
                    assert.deepStrictEqual(locations(left.stdout), locations(right.stdout),
                        'the two implementations disagree on where the failures are');

                    if (testCase.identicalMessages) {
                        assert.deepStrictEqual(left.stdout, right.stdout,
                            'this case asserts identical messages, but the two differ');
                    }
                });

                it('produces the same report from both implementations', function () {
                    // Not suspended by a divergent defect. Those record the
                    // text form showing what each library said, which is what
                    // the text form is for; the report is where the two are
                    // contracted to agree, and no case has yet needed that
                    // suspended -- the one that looked like it did turned out
                    // to be repairable.
                    const [left, right] = LEGS.map((leg) => results[leg].report);
                    assert.deepStrictEqual(left, right,
                        'the two implementations disagree about what was found'
                        + `\n  ${LEGS[0]}: ${JSON.stringify(left)}`
                        + `\n  ${LEGS[1]}: ${JSON.stringify(right)}`);

                    // The wrappers lay the report out themselves, so nothing
                    // above would notice the two drifting apart: the
                    // comparison parses the JSON and never sees whitespace.
                    const [leftText, rightText] = LEGS.map((leg) => results[leg].layout);
                    assert.strictEqual(leftText, rightText,
                        'the two implementations lay the report out differently');
                });

                // `found` is the value at `site`, and this is what makes it
                // worth trusting: the wrappers resolve it against the
                // finished path rather than reporting what their library
                // handed over, so a relocated site cannot carry the parent's
                // value. Walked here independently of the walkers under test,
                // since a check that borrows the code it checks asserts
                // nothing.
                if ('instance' in testCase) {
                    it('reports as found the value at each site', function () {
                        for (const leg of LEGS) {
                            for (const entry of foundEntries(results[leg].report)) {
                                assert.deepStrictEqual(
                                    entry.found, valueAt(entry.site, testCase.instance),
                                    `${leg}: found is not the value at /${entry.site.join('/')}`
                                    + `\n${describeCase(testCase)}`);
                            }
                        }
                    });
                }

                // A defect's summary becomes a test name, so the inventory of
                // known-wrong behavior is part of the report and cannot drift
                // from the cases that demonstrate it. The test asserts nothing
                // beyond its own title, which is the whole of its job.
                if (testCase.defect) {
                    it(`known defect: ${testCase.defect.summary}`, function () {});
                }
            });
        }
    });
}

// Every entry carrying a `found`, including those nested inside a rejection.
function* foundEntries(report) {
    for (const entry of (report && report.errors) || []) yield* walkEntry(entry);
}

function* walkEntry(entry) {
    if ('found' in entry) yield { site: entry.site || [], found: entry.found };
    for (const rejection of entry.rejections || []) {
        for (const nested of rejection.errors || []) yield* walkEntry(nested);
    }
}

function valueAt(site, instance) {
    return site.reduce((node, segment) => node[segment], instance);
}

function describeCase(testCase) {
    return testCase.description ? `  ${testCase.description}` : '';
}
