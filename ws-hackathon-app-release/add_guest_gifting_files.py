#!/usr/bin/env python3
"""
Adds the new GuestGifting Swift files + Info.plist to the Xcode project.
Run from the ws-hackathon-app-release directory.
"""

import re, uuid, sys, os

PBXPROJ = "WSHackathonApp.xcodeproj/project.pbxproj"

NEW_FILES = [
    "WSHackathonApp/Features/GuestGifting/Models/GuestGiftingModels.swift",
    "WSHackathonApp/Features/GuestGifting/Engine/GiftabilityEngine.swift",
    "WSHackathonApp/Features/GuestGifting/Views/ShareRegistrySheet.swift",
    "WSHackathonApp/Features/GuestGifting/Views/GuestRegistryView.swift",
    "WSHackathonApp/Features/GuestGifting/Views/GiftabilityItemCard.swift",
    "WSHackathonApp/Features/GuestGifting/Views/GuestProductDetailView.swift",
    "WSHackathonApp/Features/GuestGifting/Views/GuestCheckoutView.swift",
    "WSHackathonApp/Features/GuestGifting/Views/PurchaseSuccessView.swift",
    "WSHackathonApp/Info.plist",
]

def gen_id():
    return uuid.uuid4().hex[:24].upper()

with open(PBXPROJ, "r") as f:
    content = f.read()

# Find the main group that holds "Features" — search for the Features group ref
# We'll find the PBXGroup that contains "Features" and add a new child group to it.
# Strategy: add file refs + build file refs + a new group, then attach to main group.

# Collect generated IDs
file_ref_ids = {path: gen_id() for path in NEW_FILES}
build_file_ids = {path: gen_id() for path in NEW_FILES if path.endswith(".swift")}
group_ids = {
    "GuestGifting": gen_id(),
    "Models": gen_id(),
    "Engine": gen_id(),
    "Views": gen_id(),
}

# ---- 1. Insert PBXFileReference entries ----
file_ref_block = ""
for path in NEW_FILES:
    fid = file_ref_ids[path]
    name = os.path.basename(path)
    if path.endswith(".swift"):
        last_type = "sourcecode.swift"
    else:
        last_type = "text.plist.xml"
    file_ref_block += f'\t\t{fid} = {{isa = PBXFileReference; lastKnownFileType = {last_type}; path = "{name}"; sourceTree = "<group>"; }};\n'

# Insert before the end of PBXFileReference section
content = content.replace(
    "/* End PBXFileReference section */",
    file_ref_block + "\t\t/* End PBXFileReference section */"
)

# ---- 2. Insert PBXBuildFile entries (Swift files only) ----
build_file_block = ""
for path, bid in build_file_ids.items():
    fid = file_ref_ids[path]
    name = os.path.basename(path)
    build_file_block += f'\t\t{bid} = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};\n'

content = content.replace(
    "/* End PBXBuildFile section */",
    build_file_block + "\t\t/* End PBXBuildFile section */"
)

# ---- 3. Add build files to Sources build phase ----
sources_ref = "\t\t\t\t/* Sources */,"
sources_insert = ""
for path, bid in build_file_ids.items():
    name = os.path.basename(path)
    sources_insert += f'\t\t\t\t{bid} /* {name} in Sources */,\n'

# Find "files = (" inside PBXSourcesBuildPhase
src_phase_pattern = r'(isa = PBXSourcesBuildPhase;.*?files = \()(.*?)(\);)'
def add_sources(m):
    return m.group(1) + m.group(2) + sources_insert + m.group(3)
content = re.sub(src_phase_pattern, add_sources, content, flags=re.DOTALL, count=1)

# ---- 4. Insert PBXGroup entries for GuestGifting / Models / Engine / Views ----
views_files = [p for p in NEW_FILES if "/Views/" in p]
models_files = [p for p in NEW_FILES if "/Models/" in p]
engine_files = [p for p in NEW_FILES if "/Engine/" in p]
info_files = [p for p in NEW_FILES if "Info.plist" in p]

def children_list(paths):
    lines = ""
    for path in paths:
        fid = file_ref_ids[path]
        name = os.path.basename(path)
        lines += f'\t\t\t\t{fid} /* {name} */,\n'
    return lines

group_block = f"""
\t\t{group_ids["GuestGifting"]} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{group_ids["Models"]} /* Models */,
\t\t\t\t{group_ids["Engine"]} /* Engine */,
\t\t\t\t{group_ids["Views"]} /* Views */,
\t\t\t);
\t\t\tpath = GuestGifting;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{group_ids["Models"]} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_list(models_files)}\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{group_ids["Engine"]} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_list(engine_files)}\t\t\t);
\t\t\tpath = Engine;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{group_ids["Views"]} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_list(views_files)}\t\t\t);
\t\t\tpath = Views;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

content = content.replace(
    "/* End PBXGroup section */",
    group_block + "\t\t/* End PBXGroup section */"
)

# ---- 5. Add Info.plist file ref to Resources build phase ----
resources_phase_pattern = r'(isa = PBXResourcesBuildPhase;.*?files = \()(.*?)(\);)'
info_plist_fid = file_ref_ids["WSHackathonApp/Info.plist"]
info_build_file_id = gen_id()
# Add build file for plist
plist_build_entry = f'\t\t{info_build_file_id} = {{isa = PBXBuildFile; fileRef = {info_plist_fid} /* Info.plist */; }};\n'
content = content.replace(
    "/* End PBXBuildFile section */",
    plist_build_entry + "\t\t/* End PBXBuildFile section */"
)
def add_resources(m):
    return m.group(1) + m.group(2) + f'\t\t\t\t{info_build_file_id} /* Info.plist in Resources */,\n' + m.group(3)
content = re.sub(resources_phase_pattern, add_resources, content, flags=re.DOTALL, count=1)

# ---- 6. Find the "Features" group and add GuestGifting as child ----
# Look for children = ( ... ) inside a group that has "Features" path
features_pattern = r'(path = Features;.*?children = \()(.*?)(\);)'
gg_ref = f'\t\t\t\t{group_ids["GuestGifting"]} /* GuestGifting */,\n'
def add_to_features(m):
    return m.group(1) + m.group(2) + gg_ref + m.group(3)

# The Features group in the pbxproj has children listed before path.
# Let's use a lookahead approach: find the children block of a group that contains "Features" nearby.
# Safer: find 'path = Features' and walk backwards to find children = (
features_match = re.search(r'(children = \([^)]*?\)\s*;\s*(?:name|path) = Features;)', content, re.DOTALL)
if features_match:
    old_block = features_match.group(1)
    new_block = old_block.replace("children = (", "children = (\n" + gg_ref)
    content = content.replace(old_block, new_block, 1)
    print("✅ Added GuestGifting to Features group")
else:
    print("⚠️  Could not find Features group — add GuestGifting manually in Xcode")

# ---- 7. Add Info.plist to the main WSHackathonApp group ----
# Find App group or root WSHackathonApp group and add the Info.plist ref
app_group_pattern = r'(children = \([^)]*?\)\s*;\s*(?:name|path) = WSHackathonApp;)'
info_ref = f'\t\t\t\t{info_plist_fid} /* Info.plist */,\n'
app_match = re.search(app_group_pattern, content, re.DOTALL)
if app_match:
    old = app_match.group(1)
    new = old.replace("children = (", "children = (\n" + info_ref)
    content = content.replace(old, new, 1)
    print("✅ Added Info.plist to WSHackathonApp group")
else:
    print("⚠️  Could not find WSHackathonApp group — add Info.plist manually")

# ---- 8. Disable GENERATE_INFOPLIST_FILE (so our Info.plist takes precedence) ----
content = content.replace("GENERATE_INFOPLIST_FILE = YES;", "GENERATE_INFOPLIST_FILE = NO;\n\t\t\t\tINFOPLIST_FILE = WSHackathonApp/Info.plist;")
print("✅ Switched to custom Info.plist")

with open(PBXPROJ, "w") as f:
    f.write(content)

print(f"\n✅ Done! Added {len(NEW_FILES)} files to {PBXPROJ}")
print("Rebuild in Xcode to pick up the changes.")
