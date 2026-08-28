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

                if (testCase.defect) {
                    it(`known defect: ${testCase.defect.summary}`, function () {
                        assert.ok(testCase.defect.should,
                            'a defect must say what the behavior should become');
                    });
                }
            });
        }
    });
}

function describeCase(testCase) {
    return testCase.description ? `  ${testCase.description}` : '';
}
