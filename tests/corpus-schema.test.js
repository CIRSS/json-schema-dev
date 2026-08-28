// Validates the corpus files against corpus-schema.json, and checks that the
// schema rejects malformed ones.

'use strict';

const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { LEGS, CORPUS_DIR, runLeg } = require('./corpus-case');

const SCHEMA = path.join(__dirname, 'corpus-schema.json');

// Builds a corpus file holding one valid case, with caseFields overriding it.
function corpusFile(caseFields) {
    return {
        group: 'a group',
        description: 'a description',
        cases: [{
            name: 'a claim',
            schema: {},
            instance: {},
            expect: { exit: 0, stdout: ['VALID'] },
            ...caseFields,
        }],
    };
}

const MALFORMED = [
    {
        name: 'a mistyped field name is rejected rather than ignored',
        document: corpusFile({ instance: undefined, instanceTxt: '{}' }),
    },
    {
        name: 'a case carrying both instance forms is rejected',
        document: corpusFile({ instanceText: '{}' }),
    },
    {
        name: 'a case with no instance at all is rejected',
        document: corpusFile({ instance: undefined }),
    },
    {
        name: 'a case with no schema at all is rejected',
        document: corpusFile({ schema: undefined }),
    },
    {
        name: 'a defect that says what is wrong but not what it should be is rejected',
        document: corpusFile({ defect: { summary: 'something is wrong' } }),
    },
    {
        name: 'an exit status the contract does not define is rejected',
        document: corpusFile({ expect: { exit: 3, stdout: [] } }),
    },
    {
        name: 'a per-leg expectation naming a wrapper that does not exist is rejected',
        document: corpusFile({
            expect: { exit: { 'jsonschema-validate': 0, ajv: 0 }, stdout: [] },
        }),
    },
    {
        name: 'a group with no cases is rejected',
        document: { group: 'a group', description: 'a description', cases: [] },
    },
    {
        name: 'an expectation with no recorded stdout is rejected',
        document: corpusFile({ expect: { exit: 0 } }),
    },
];

describe('the corpus conforms to its own schema', function () {
    const files = fs.readdirSync(CORPUS_DIR).filter((name) => name.endsWith('.json')).sort();

    it('finds corpus files to check', function () {
        assert.ok(files.length > 0, 'no corpus files found');
    });

    for (const file of files) {
        describe(file, function () {
            const paths = {
                schema: SCHEMA,
                instance: path.join(CORPUS_DIR, file),
                refs: [],
                directory: CORPUS_DIR,
            };

            for (const leg of LEGS) {
                it(`is valid under ${leg}`, function () {
                    const result = runLeg(leg, {}, paths);
                    assert.deepStrictEqual(
                        result.stdout, ['VALID'],
                        `${file} does not conform to corpus-schema.json:\n  `
                        + result.stdout.join('\n  ')
                        + (result.stderr.trim() ? `\n  ${result.stderr.trim()}` : ''),
                    );
                    assert.strictEqual(result.exit, 0, 'expected exit 0');
                });
            }
        });
    }
});

describe('the corpus schema rejects what it exists to catch', function () {
    let directory;

    before(function () {
        directory = fs.mkdtempSync(path.join(os.tmpdir(), 'corpus-schema-'));
    });

    after(function () {
        fs.rmSync(directory, { recursive: true, force: true });
    });

    for (const malformed of MALFORMED) {
        it(malformed.name, function () {
            const instance = path.join(directory, 'instance.json');
            // Setting a field to undefined removes it: JSON.stringify omits those.
            fs.writeFileSync(instance, `${JSON.stringify(malformed.document, null, 2)}\n`);
            const paths = { schema: SCHEMA, instance, refs: [], directory };

            for (const leg of LEGS) {
                const result = runLeg(leg, {}, paths);
                assert.strictEqual(result.exit, 1,
                    `${leg} should have reported INVALID (exit 1), got exit ${result.exit}`
                    + `\n  stdout: ${JSON.stringify(result.stdout)}`
                    + `\n  stderr: ${JSON.stringify(result.stderr.trim())}`);
            }
        });
    }
});
