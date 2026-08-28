// Reads the corpus, writes a case's files, and runs a case through a validator.
// Used by both the test suite and the recorder, so they build the same command.

'use strict';

const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const LEGS = ['jsonschema-validate', 'ajv-validate'];
const CORPUS_DIR = path.join(__dirname, 'corpus');

// Returns every corpus file as { file, group }, in filename order.
function loadCorpus() {
    return fs.readdirSync(CORPUS_DIR)
        .filter((name) => name.endsWith('.json'))
        .sort()
        .map((name) => ({
            file: path.join(CORPUS_DIR, name),
            group: JSON.parse(fs.readFileSync(path.join(CORPUS_DIR, name), 'utf8')),
        }));
}

// Writes a case's schema, instance, and ref files into a scratch directory.
//
// A document is inline JSON ("schema") or raw text ("schemaText"). Raw text is
// needed for anything a JSON value cannot carry: a duplicate member name, or a
// document that does not parse.
function materialize(testCase) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'json-schema-dev-'));
    const omit = new Set(testCase.omit || []);
    const directories = new Set(testCase.makeDirectory || []);
    const paths = { directory, refs: [] };

    for (const role of ['schema', 'instance']) {
        const file = path.join(directory, `${role}.json`);
        paths[role] = file;
        if (omit.has(role)) continue;
        if (directories.has(role)) {
            fs.mkdirSync(file);
        } else if (`${role}Text` in testCase) {
            fs.writeFileSync(file, testCase[`${role}Text`]);
        } else if (role in testCase) {
            fs.writeFileSync(file, `${JSON.stringify(testCase[role], null, 2)}\n`);
        }
    }

    (testCase.refs || []).forEach((ref, index) => {
        const file = path.join(directory, `ref-${index}.json`);
        fs.writeFileSync(file, typeof ref === 'string' ? ref
            : `${JSON.stringify(ref, null, 2)}\n`);
        paths.refs.push(file);
    });

    return paths;
}

// Builds one validator's argument list, from "argv" if the case supplies it,
// otherwise from --schema, --instance, a --ref per file, and "args".
function argumentsFor(testCase, paths) {
    if (testCase.argv) {
        return testCase.argv.map((argument) => argument
            .replace('{schema}', paths.schema)
            .replace('{instance}', paths.instance));
    }
    const args = ['--schema', paths.schema, '--instance', paths.instance];
    for (const ref of paths.refs) args.push('--ref', ref);
    return args.concat(testCase.args || []);
}

// Runs one validator and returns { exit, stdout, stderr }.
//
// The scratch directory is new every run, so its path is replaced with {dir}:
// without that, any expectation quoting a filename would never match twice.
function runLeg(leg, testCase, paths) {
    let stdout = '';
    let stderr = '';
    let exit = 0;
    try {
        stdout = execFileSync(leg, argumentsFor(testCase, paths),
            { encoding: 'utf8', stdio: 'pipe' });
    } catch (error) {
        exit = error.status;
        stdout = error.stdout || '';
        stderr = error.stderr || '';
    }
    const scrub = (text) => text.split(paths.directory).join('{dir}');
    return {
        exit,
        stdout: stdout.length ? scrub(stdout).replace(/\n$/, '').split('\n') : [],
        stderr: scrub(stderr),
    };
}

// Runs a case through both validators, removing the scratch directory after.
function runCase(testCase) {
    const paths = materialize(testCase);
    try {
        return Object.fromEntries(LEGS.map((leg) => [leg, runLeg(leg, testCase, paths)]));
    } finally {
        fs.rmSync(paths.directory, { recursive: true, force: true });
    }
}

// Returns one validator's expectation: a scalar binds both, an object keyed by
// validator name records that the two differ.
function expectedFor(testCase, leg) {
    const expect = testCase.expect || {};
    const resolved = {};
    for (const field of ['exit', 'stdout', 'stderrContains']) {
        if (!(field in expect)) continue;
        const value = expect[field];
        const perLeg = value && !Array.isArray(value) && typeof value === 'object'
            && Object.keys(value).every((key) => LEGS.includes(key));
        resolved[field] = perLeg ? value[leg] : value;
    }
    return resolved;
}

// Splits a verdict line into its location and its message.
//
// Relies on a location starting with "/" and a message not, which is a weakness
// of the line format rather than of this function. See CONTRACT.md.
function parseLine(line) {
    if (!line.startsWith('INVALID: ')) return { location: null, message: line };
    const rest = line.slice('INVALID: '.length);
    if (rest.startsWith('/') && rest.includes(': ')) {
        const at = rest.indexOf(': ');
        return { location: rest.slice(0, at), message: rest.slice(at + 2) };
    }
    return { location: '', message: rest };
}

const locations = (stdout) => stdout.map((line) => parseLine(line).location);

module.exports = {
    LEGS, CORPUS_DIR, loadCorpus, materialize, argumentsFor,
    runLeg, runCase, expectedFor, parseLine, locations,
};
