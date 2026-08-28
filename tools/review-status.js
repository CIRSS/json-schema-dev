#!/usr/bin/env node
// Reports which files a person has read, and whether they read the version
// now on disk.
//
//     npm run review              every file
//     npm run review -- --stale   only what needs a reader
//     npm run review:md           regenerate REVIEW.md

'use strict';

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
const MANIFEST = path.join(REPO, 'review-manifest.json');

const STATES = {
    reviewed: { mark: 'ok  ', icon: '✅', label: 'a person read exactly this content' },
    stale: { mark: 'STALE', icon: '⚠️', label: 'a person read an earlier version; this one is unread' },
    unread: { mark: 'unread', icon: '❌', label: 'no review recorded' },
    exempt: { mark: '--  ', icon: '⚙️', label: 'framework; not ours to review' },
    missing: { mark: 'GONE', icon: '❓', label: 'listed but not on disk' },
};

function hashOf(file) {
    try {
        return execFileSync('git', ['hash-object', file],
            { cwd: REPO, encoding: 'utf8' }).trim();
    } catch {
        return null;
    }
}

function statusOf(entry) {
    const current = hashOf(path.join(REPO, entry.path));
    if (current === null) return { state: 'missing' };

    const match = entry.reviews.find((review) => review.hash === current);
    if (match) return { state: 'reviewed', review: match };

    if (entry.reviews.length) {
        const latest = entry.reviews[entry.reviews.length - 1];
        return { state: 'stale', review: latest };
    }
    if (entry.origin === 'framework') return { state: 'exempt' };
    return { state: 'unread' };
}

const manifest = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
const onlyStale = process.argv.includes('--stale');

const rows = manifest.files.map((entry) => ({ entry, ...statusOf(entry) }));

if (process.argv.includes('--markdown')) {
    process.stdout.write(renderMarkdown(rows));
    process.exit(0);
}

const width = Math.max(...rows.map((row) => row.entry.path.length));
const counts = {};

console.log();
for (const row of rows) {
    counts[row.state] = (counts[row.state] || 0) + 1;
    if (onlyStale && (row.state === 'reviewed' || row.state === 'exempt')) continue;

    const { mark } = STATES[row.state];
    const origin = row.entry.origin === 'authored' ? '' : ` (${row.entry.origin})`;
    const who = row.review ? `  ${row.review.by}, ${row.review.date}` : '';
    console.log(`  ${mark.padEnd(6)} ${row.entry.path.padEnd(width)}${origin}${who}`);
}

console.log();
for (const [state, { label }] of Object.entries(STATES)) {
    if (counts[state]) console.log(`  ${String(counts[state]).padStart(3)}  ${label}`);
}

const needsReader = (counts.unread || 0) + (counts.stale || 0);
if (needsReader) {
    console.log(`\n  ${needsReader} file${needsReader === 1 ? '' : 's'} `
        + 'no person has read at its current version.');
    console.log('  "no review recorded" means the record is absent, not that nobody looked;');
    console.log('  anything older than the manifest predates the record.');
}
console.log();

// Renders the manifest as Markdown for committing.
//
// Omits the manifest's per-file notes. Names the manifest hash it was built
// from, since the status column is a snapshot and only that claim stays true.
function renderMarkdown(rows) {
    const manifestHash = hashOf(MANIFEST);
    const counts = {};
    for (const row of rows) counts[row.state] = (counts[row.state] || 0) + 1;

    const reviewer = (row) => (row.review ? `${row.review.by}, ${row.review.date}` : '');

    const author = (entry) => (!entry.authoredBy || entry.authoredBy === 'unknown'
        ? '—' : entry.authoredBy);

    const lines = [];
    lines.push('# Who has read what');
    lines.push('');
    lines.push(`*Generated from \`review-manifest.json\` (\`${manifestHash}\`) by \`npm run review:md\`. `
        + 'The status column is a snapshot taken when this was generated; `npm run review` recomputes '
        + 'it against the files as they are now.*');
    lines.push('');

    lines.push('| | Files | Meaning |');
    lines.push('| --- | ---: | --- |');
    for (const [state, { icon, label }] of Object.entries(STATES)) {
        if (counts[state]) lines.push(`| ${icon} | ${counts[state]} | ${label} |`);
    }
    lines.push('');
    lines.push(`${STATES.unread.icon} means no review has been *recorded*, which is not the same as nobody having read `
        + 'the file. Anything older than the manifest predates the record.');
    lines.push('');

    lines.push('| | File | Origin | Authored by | Last read by |');
    lines.push('| --- | --- | --- | --- | --- |');
    for (const row of rows) {
        const { entry } = row;
        lines.push(`| ${STATES[row.state].icon} | \`${entry.path}\` | ${entry.origin} `
            + `| ${author(entry)} | ${reviewer(row)} |`);
    }
    lines.push('');

    const generated = rows.filter((row) => row.entry.generatedBy);
    if (generated.length) {
        lines.push('## Generated files');
        lines.push('');
        lines.push('Produced entirely by a tool, and reviewed by reviewing the tool rather '
            + 'than the output. A file a person writes is authored even where a tool fills '
            + 'parts of it in, and belongs in the table above.');
        lines.push('');
        lines.push('| File | Generated by |');
        lines.push('| --- | --- |');
        for (const { entry } of generated) {
            lines.push(`| \`${entry.path}\` | \`${entry.generatedBy}\` |`);
        }
        lines.push('');
    }

    return lines.join('\n');
}
