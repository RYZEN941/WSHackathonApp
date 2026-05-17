#!/usr/bin/env node
// add_guest_gifting_files.js
// Adds new GuestGifting Swift files + Info.plist to the Xcode project (project.pbxproj)

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PBXPROJ = path.join(__dirname, 'WSHackathonApp.xcodeproj/project.pbxproj');

const NEW_SWIFT = [
  'WSHackathonApp/Features/GuestGifting/Models/GuestGiftingModels.swift',
  'WSHackathonApp/Features/GuestGifting/Engine/GiftabilityEngine.swift',
  'WSHackathonApp/Features/GuestGifting/Views/ShareRegistrySheet.swift',
  'WSHackathonApp/Features/GuestGifting/Views/GuestRegistryView.swift',
  'WSHackathonApp/Features/GuestGifting/Views/GiftabilityItemCard.swift',
  'WSHackathonApp/Features/GuestGifting/Views/GuestProductDetailView.swift',
  'WSHackathonApp/Features/GuestGifting/Views/GuestCheckoutView.swift',
  'WSHackathonApp/Features/GuestGifting/Views/PurchaseSuccessView.swift',
];
const NEW_PLIST = 'WSHackathonApp/Info.plist';
const ALL_FILES = [...NEW_SWIFT, NEW_PLIST];

function genId() { return crypto.randomBytes(12).toString('hex').toUpperCase(); }

let content = fs.readFileSync(PBXPROJ, 'utf8');

// --- Generate IDs ---
const fileRefIds = {};
const buildFileIds = {};
ALL_FILES.forEach(p => { fileRefIds[p] = genId(); });
NEW_SWIFT.forEach(p => { buildFileIds[p] = genId(); });
const plistBuildId = genId();

const gids = {
  GuestGifting: genId(), Models: genId(), Engine: genId(), Views: genId()
};

// --- 1. PBXFileReference ---
let fileRefBlock = '';
ALL_FILES.forEach(p => {
  const fid = fileRefIds[p];
  const name = path.basename(p);
  const lkft = p.endsWith('.swift') ? 'sourcecode.swift' : 'text.plist.xml';
  fileRefBlock += `\t\t${fid} = {isa = PBXFileReference; lastKnownFileType = ${lkft}; path = "${name}"; sourceTree = "<group>"; };\n`;
});
content = content.replace('/* End PBXFileReference section */', fileRefBlock + '\t\t/* End PBXFileReference section */');

// --- 2. PBXBuildFile (swift) ---
let buildFileBlock = '';
NEW_SWIFT.forEach(p => {
  const bid = buildFileIds[p];
  const fid = fileRefIds[p];
  const name = path.basename(p);
  buildFileBlock += `\t\t${bid} = {isa = PBXBuildFile; fileRef = ${fid} /* ${name} */; };\n`;
});
// plist build file
buildFileBlock += `\t\t${plistBuildId} = {isa = PBXBuildFile; fileRef = ${fileRefIds[NEW_PLIST]} /* Info.plist */; };\n`;
content = content.replace('/* End PBXBuildFile section */', buildFileBlock + '\t\t/* End PBXBuildFile section */');

// --- 3. Add swift files to Sources build phase ---
let sourcesInsert = '';
NEW_SWIFT.forEach(p => {
  const bid = buildFileIds[p];
  const name = path.basename(p);
  sourcesInsert += `\t\t\t\t${bid} /* ${name} in Sources */,\n`;
});
content = content.replace(
  /(isa = PBXSourcesBuildPhase;[\s\S]*?files = \()([\s\S]*?)(\);)/,
  (m, a, b, c) => a + b + sourcesInsert + c
);

// --- 4. Groups ---
const viewFiles  = NEW_SWIFT.filter(p => p.includes('/Views/'));
const modelFiles = NEW_SWIFT.filter(p => p.includes('/Models/'));
const engineFiles= NEW_SWIFT.filter(p => p.includes('/Engine/'));

function childList(paths) {
  return paths.map(p => `\t\t\t\t${fileRefIds[p]} /* ${path.basename(p)} */,`).join('\n') + '\n';
}

const groupBlock = `
\t\t${gids.GuestGifting} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t${gids.Models} /* Models */,
\t\t\t\t${gids.Engine} /* Engine */,
\t\t\t\t${gids.Views} /* Views */,
\t\t\t);
\t\t\tpath = GuestGifting;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t${gids.Models} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
${childList(modelFiles)}\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t${gids.Engine} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
${childList(engineFiles)}\t\t\t);
\t\t\tpath = Engine;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t${gids.Views} = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
${childList(viewFiles)}\t\t\t);
\t\t\tpath = Views;
\t\t\tsourceTree = "<group>";
\t\t};
`;
content = content.replace('/* End PBXGroup section */', groupBlock + '\t\t/* End PBXGroup section */');

// --- 5. Attach GuestGifting to Features group ---
const featuresMatch = content.match(/(children = \([^)]*?\)\s*;\s*(?:name|path) = Features;)/s);
if (featuresMatch) {
  const old = featuresMatch[1];
  const updated = old.replace('children = (', `children = (\n\t\t\t\t${gids.GuestGifting} /* GuestGifting */,`);
  content = content.replace(old, updated);
  console.log('✅ Attached GuestGifting group to Features');
} else {
  console.warn('⚠️  Could not find Features group. Add GuestGifting manually in Xcode.');
}

// --- 6. Add Info.plist file ref to the WSHackathonApp source group ---
// (look for children=(...) near 'path = WSHackathonApp;')
const wsAppMatch = content.match(/(children = \([^)]*?\)\s*;\s*(?:name|path) = WSHackathonApp;)/s);
if (wsAppMatch) {
  const old = wsAppMatch[1];
  const infoRef = `\t\t\t\t${fileRefIds[NEW_PLIST]} /* Info.plist */,\n`;
  const updated = old.replace('children = (', 'children = (\n' + infoRef);
  content = content.replace(old, updated);
  console.log('✅ Added Info.plist to WSHackathonApp source group');
} else {
  console.warn('⚠️  Could not find WSHackathonApp source group. Add Info.plist manually.');
}

// --- 7. Disable generated Info.plist + point to ours ---
const count = (content.match(/GENERATE_INFOPLIST_FILE = YES;/g) || []).length;
content = content.replaceAll(
  'GENERATE_INFOPLIST_FILE = YES;',
  'GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = WSHackathonApp/Info.plist;'
);
console.log(`✅ Switched ${count} build configs to custom Info.plist`);

// --- Write back ---
fs.writeFileSync(PBXPROJ, content, 'utf8');
console.log(`\n✅ Done! Registered ${ALL_FILES.length} files in ${PBXPROJ}`);
console.log('Open Xcode and press ⌘B to build.');
