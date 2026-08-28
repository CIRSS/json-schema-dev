// Checks that review-manifest.json is valid and lists exactly the files git sees.

'use strict';

const assert = require('node:assert');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { LEGS, runLeg } = require('./corpus-case');

const REPO = path.resolve(__dirname, '..');
const MANIFEST = path.join(REPO, 'review-manifest.json');
const SCHEMA = path.join(__dirname, 'review-manifest.schema.json');

// Returns the paths git sees: tracked, plus untracked ones that are not ignored.
function filesGitSees() {
    const listed = execFileSync(
        'git', ['ls-files', '--cached', '--others', '--exclude-standard'],
        { cwd: REPO, encoding: 'utf8' },
    );
    return new Set(listed.split('\n').filter(Boolean));
}

describe('the review manifest', function () {
    const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));

    for (const leg of LEGS) {
        it(`is valid under ${leg}`, function () {
            const result = runLeg(leg, {}, {
                schema: SCHEMA, instance: MANIFEST, refs: [], directory: REPO,
            });
            assert.deepStrictEqual(result.stdout, ['VALID'],
                `review-manifest.json does not conform to its schema:\n  `
                + result.stdout.join('\n  '));
        });
    }

    it('lists every file in the repository', function () {
        const listed = new Set(manifest.files.map((entry) => entry.path));
        const missing = [...filesGitSees()].filter((file) => !listed.has(file)).sort();
        assert.deepStrictEqual(missing, [],
            'files in the repository with no manifest entry — a review report that '
            + 'omits a file is worse than none:\n  ' + missing.join('\n  '));
    });

    it('lists nothing that is not in the repository', function () {
        const seen = filesGitSees();
        const orphaned = manifest.files
            .map((entry) => entry.path)
            .filter((file) => !seen.has(file))
            .sort();
        assert.deepStrictEqual(orphaned, [],
            'manifest entries for files git does not see:\n  ' + orphaned.join('\n  '));
    });

    it('names a person for every review', function () {
        // An agent writing a file is not a review of it.
        const agentish = /\b(claude|agent|assistant|ai|bot)\b/i;
        const offenders = manifest.files.flatMap((entry) => entry.reviews
            .filter((review) => agentish.test(review.by))
            .map((review) => `${entry.path}: reviewed by "${review.by}"`));
        assert.deepStrictEqual(offenders, [], offenders.join('\n  '));
    });

    it('has a current Markdown rendering committed beside it', function () {
        // Only the manifest hash can be checked: the status column is a snapshot.
        const rendered = fs.readFileSync(path.join(REPO, 'REVIEW.md'), 'utf8');
        const claimed = rendered.match(/Generated from `review-manifest\.json` \(`([0-9a-f]{40})`\)/);
        assert.ok(claimed, 'REVIEW.md does not say which manifest it was generated from');

        const current = execFileSync('git', ['hash-object', 'review-manifest.json'],
            { cwd: REPO, encoding: 'utf8' }).trim();
        assert.strictEqual(claimed[1], current,
            'REVIEW.md was generated from an older manifest; run `npm run review:md`');
    });

    it('records a hash that is a real object for every review', function () {
        const bad = manifest.files.flatMap((entry) => entry.reviews
            .filter((review) => {
                try {
                    execFileSync('git', ['cat-file', '-e', `${review.hash}^{blob}`],
                        { cwd: REPO, stdio: 'pipe' });
                    return false;
                } catch {
                    return true;
                }
            })
            .map((review) => `${entry.path}: ${review.hash} is not a blob in this repository`));
        assert.deepStrictEqual(bad, [], bad.join('\n  '));
    });
});
