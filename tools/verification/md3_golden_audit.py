"""GBR verification-only runner. Never writes mounted source checkouts."""
import collections
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

SOURCE = Path("/sources")
OUT = Path("/evidence")
WORK = Path("/work")
SHAS = {"baseline": "fdbbfc63e9e2f1c095512db2337ce5bbfa150f31", "candidate": "feadfb059b0892846b06ecfd42d38f55d2cde290"}
REPLACEMENTS = [["void expectQuickPracticeSemantics() {\n  for (final label in [\n    'Addition',\n    'Subtraction',\n    'Multiplication',\n    'Division',\n    'Missing Operation',\n    'Mixed Operations',\n  ]) {\n    expect(find.text(label), findsOneWidget);\n  }\n\n  expect(find.text('🧮'), findsOneWidget);\n  expect(find.text('MISSING NUMBER'), findsNothing);\n  expect(find.text('Training Arena'), findsOneWidget);\n  expect(find.text('🚀'), findsOneWidget);\n}\n\n","Future<void> expectHomeAndPracticeSemantics(\n  WidgetTester tester, GameState state,\n) async {\n  final master = find.text('Master Challenge');\n  final target = find.byKey(const Key('target-clash-challenge-entry'));\n  final daily = find.byKey(const Key('daily-mental-math-row'));\n  final boss = find.text(state.dailyBoss?.name ?? 'Daily Boss');\n  final training = find.byKey(const Key('weak-skills-practice-row'));\n  final practice = find.byKey(const Key('practice-menu-entry'));\n  for (final finder in [master, target, daily, boss, training, practice]) {\n    expect(finder, findsOneWidget);\n  }\n  expect(find.text('Target Clash'), findsOneWidget);\n  expect(find.text('Daily IQ Spark'), findsOneWidget);\n  expect(find.text('Training Arena'), findsOneWidget);\n  expect(find.text('Practice'), findsOneWidget);\n  expect(find.text('Operation Quest'), findsNothing);\n  expect(find.text('➕'), findsNothing);\n  expect(tester.getCenter(master).dx, lessThan(tester.getCenter(target).dx));\n  expect(tester.getCenter(daily).dx, lessThan(tester.getCenter(boss).dx));\n  expect(tester.getCenter(master).dy, lessThan(tester.getCenter(daily).dy));\n  expect(tester.getCenter(target).dy, lessThan(tester.getCenter(boss).dy));\n  expect(tester.getCenter(daily).dy, lessThan(tester.getCenter(training).dy));\n  expect(tester.getCenter(training).dy, lessThan(tester.getCenter(practice).dy));\n  expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);\n  await tester.ensureVisible(practice);\n  await tester.tap(practice);\n  await tester.pumpAndSettle();\n  expect(state.currentScreen, GameScreen.practice);\n  final quest = find.byKey(const Key('operation-quest-practice-entry'));\n  expect(quest, findsOneWidget);\n  expect(find.text('Operation Quest'), findsOneWidget);\n  expect(find.byIcon(Icons.explore_rounded), findsOneWidget);\n  for (final label in [\n    'Addition', 'Subtraction', 'Multiplication', 'Division',\n    'Missing Operation', 'Mixed Operations',\n  ]) {\n    expect(find.text(label), findsOneWidget);\n  }\n  expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);\n  expect(find.text('MISSING NUMBER'), findsNothing);\n  await tester.ensureVisible(quest);\n  await tester.tap(quest);\n  await tester.pumpAndSettle();\n  expect(state.currentModal, GameModal.operationQuest);\n  expectNoVisualException(tester);\n  state.closeModal();\n  await tester.pumpAndSettle();\n  final back = find.byKey(const Key('practice-menu-back'));\n  await tester.ensureVisible(back);\n  await tester.tap(back);\n  await tester.pumpAndSettle();\n  expect(state.currentScreen, GameScreen.menu);\n  expectNoVisualException(tester);\n}\n\n"],["      final master = find.text('Master Challenge');\n      final dailyBoss = find.text(state.dailyBoss!.name);\n      final operationQuest = find.text('Operation Quest');\n      expect(master, findsOneWidget);\n      expect(dailyBoss, findsOneWidget);\n      expect(operationQuest, findsOneWidget);\n      expect(tester.getTopLeft(master).dy,\n          lessThan(tester.getTopLeft(dailyBoss).dy));\n      expect(tester.getTopLeft(dailyBoss).dy,\n          lessThan(tester.getTopLeft(operationQuest).dy));\n      expectQuickPracticeSemantics();\n      expect(find.text('🧭'), findsOneWidget);\n      expect(find.text('➕'), findsNothing);\n","      await expectHomeAndPracticeSemantics(tester, state);\n"],["      expect(find.text('Operation Quest'), findsOneWidget);\n      expectQuickPracticeSemantics();","      await expectHomeAndPracticeSemantics(tester, state);"],["      expectQuickPracticeSemantics();","      await expectHomeAndPracticeSemantics(tester, state);"],["      final dailyCard = find.byKey(const Key('daily-mental-math-row'));\n      await tester.ensureVisible(dailyCard);","      await expectHomeAndPracticeSemantics(tester, state);\n      final dailyCard = find.byKey(const Key('daily-mental-math-row'));\n      await tester.ensureVisible(dailyCard);"],["      expect(find.text('Operation Quest'), findsOneWidget);\n      expect(\n        tester.getTopLeft(find.text('Daily Boss')).dy,\n        lessThan(tester.getTopLeft(find.text('Daily IQ Spark')).dy),\n      );\n      expect(\n        tester.getTopLeft(find.text('Daily IQ Spark')).dy,\n        lessThan(tester.getTopLeft(find.text('Operation Quest')).dy),\n      );","      expect(find.text('Operation Quest'), findsNothing);\n      expect(\n        tester.getCenter(find.text('Daily IQ Spark')).dx,\n        lessThan(tester.getCenter(find.text('Daily Boss')).dx),\n      );"]]
COUNTS = [1,1,2,1,1,1]
EXPECTED_TESTS = 64
EXPECTED_IMAGES = ["goldens/20_skills_dashboard_phone_light.png","goldens/20_skills_dashboard_phone_dark.png","goldens/21_skills_dashboard_tablet.png","goldens/22_skills_dashboard_recommendation.png","goldens/01_menu_phone_light.png","goldens/01_menu_phone_dark.png","goldens/02_menu_tablet_light.png","goldens/02_menu_tablet_dark.png","goldens/02b_operation_quest_map_phone.png","goldens/03_numtype_locked_unlocked.png","goldens/04_config_1p.png","goldens/30_deep_thinking_config.png","goldens/04b_missing_operation_config.png","goldens/05_config_2p_standard_only.png","goldens/16_weak_skills_config_focused.png","goldens/17_weak_skills_config_fallback.png","goldens/18_weak_skills_popup_focused.png","goldens/18_weak_skills_popup_focused_dark.png","goldens/19_weak_skills_popup_fallback.png","goldens/06_player_setup_1p.png","goldens/07_player_setup_2p.png","goldens/08_gameplay_light.png","goldens/08_gameplay_dark.png","goldens/31_deep_thinking_gameplay.png","goldens/32_time_bank_config.png","goldens/33_time_bank_gameplay.png","goldens/34_time_bank_gameplay_warning.png","goldens/35_time_bank_result.png","goldens/36_practice_style_phone_light.png","goldens/36_practice_style_phone_dark.png","goldens/50_training_arena_practice_style.png","goldens/38_mental_math_countdown_light.png","goldens/38_mental_math_countdown_dark.png","goldens/39_mental_math_gameplay_flow.png","goldens/40_mental_math_gameplay_challenge.png","goldens/41_mental_math_gameplay_recovery.png","goldens/42_mental_math_result_mastery.png","goldens/43_mental_math_result_practice_complete.png","goldens/44_mental_math_result_training_complete.png","goldens/51_training_arena_iq_result.png","goldens/45_daily_mental_math_menu.png","goldens/46_daily_mental_math_modal.png","goldens/47_daily_mental_math_first_clear.png","goldens/48_daily_mental_math_perfect_day.png","goldens/49_daily_mental_math_modal_details.png","goldens/50_daily_mental_math_first_clear_metrics.png","goldens/51_daily_mental_math_perfect_day_metrics.png","goldens/09_daily_boss_modal.png","goldens/09_daily_boss_modal_dark.png","goldens/10_win_modal.png","goldens/11_avatar_builder_modal.png","goldens/12_coin_shop_modal.png","goldens/12_coin_shop_modal_dark.png","goldens/13_settings_modal_light.png","goldens/13_settings_modal_dark.png","goldens/14_missing_operation_gameplay.png","goldens/15_true_false_gameplay.png","goldens/23_toast_banner_light.png","goldens/23_toast_banner_dark.png","goldens/24_achievement_feedback_light.png","goldens/24_achievement_feedback_dark.png","goldens/25_master_gameplay_timer_normal_dark.png","goldens/25_master_gameplay_timer_warning_dark.png","goldens/26_adult_gate_dark.png","goldens/27_cloud_save_settings_light.png","goldens/27_cloud_save_settings_dark.png","goldens/29_cloud_save_reset_everywhere_light.png","goldens/29_cloud_save_reset_everywhere_dark.png","goldens/28_cloud_save_conflict_ordinary_light.png","goldens/28_cloud_save_conflict_ordinary_dark.png","goldens/28_cloud_save_conflict_native_light.png"]
EXPECTED_FONT_HASHES = {
    "assets/fonts/Baloo2-Bold.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/Baloo2-ExtraBold.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/Baloo2-Black.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/PlusJakartaSans-Medium.ttf": "57f73e11f51999432bf7ab22ce55b6f945d5eca1bf824404cfa9ec2e3718c84e",
    "assets/fonts/PlusJakartaSans-SemiBold.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/PlusJakartaSans-Bold.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/PlusJakartaSans-ExtraBold.ttf": "a4c5bc453ca281d90ea079e596da7ae0dfeb5777497c29ec254e76d97ff6f890",
    "assets/fonts/OpenDyslexic-Regular.otf": "32f5840fb2bf844bdabafe372591ddfb9286e98117f5b21950aaf54ea856919a",
}

def require(ok, reason):
    if not ok:
        raise RuntimeError(reason)

def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def command(args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()

def file_hashes(root, paths):
    return {str(p.relative_to(root)): sha(p) for p in sorted(paths) if p.is_file()}

def tracked(root, prefix):
    raw = subprocess.check_output(["git", "-c", "safe.directory=" + str(root),
        "ls-files", "-z", "--", prefix], cwd=root)
    paths = [os.fsdecode(p) for p in raw.split(b"\0") if p]
    require(bool(paths), "Empty inventory: " + prefix)
    return {p: sha(root / p) for p in sorted(paths)}

def source_snapshot(root):
    return {"goldens": tracked(root, "test/goldens"),
            "fonts": tracked(root, "assets/fonts"),
            "harness": sha(root / "test/visual_parity_test.dart"),
            "lock": sha(root / "pubspec.lock")}

def environment():
    version = json.loads(command(["flutter", "--version", "--machine"]))
    require(version["frameworkVersion"] == "3.47.5" and
            version["dartSdkVersion"].startswith("3.13.4") and
            version["frameworkRevision"] == "6a19cca56475dbfba1478ee68d7bd0c2ef891da1" and
            version["engineRevision"] == "af7e796e161ae0bb1ff0758c71a7105418bd9ded",
            "SDK pin mismatch")
    fonts = sorted(set(command(["fc-list", "--format", "%{file}\\n"]).splitlines()))
    require(bool(fonts) and any("NotoColorEmoji" in p for p in fonts),
            "Missing system or emoji font")
    font_hashes = {p: sha(Path(p)) for p in fonts}
    package_versions = sorted(command(["dpkg-query", "-W", "-f", "${Package}=${Version}\\n"]).splitlines())
    deb_hashes = json.loads(Path("/pins/debs.json").read_text())
    require(bool(deb_hashes) and bool(package_versions), "Missing package pins")
    return {"sdk": version, "os": Path("/etc/os-release").read_text(),
            "architecture": command(["uname", "-m"]),
            "locale": command(["locale"]), "timezone": os.environ["TZ"],
            "system_fonts": font_hashes, "packages": package_versions,
            "downloaded_package_hashes": deb_hashes,
            "font_config_hashes": file_hashes(Path("/etc/fonts"), Path("/etc/fonts").rglob("*")),
            "renderer": "native flutter_tester; original harness settings"}

def run(args, root, path, env):
    with path.open("w") as out:
        proc = subprocess.Popen(args, cwd=root, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout:
            out.write(line)
        code = proc.wait()
    print(f"{root.name}: {args[-1]} exit={code}", flush=True)
    return code

def events(path):
    names, done, errors = {}, {}, collections.defaultdict(list)
    complete = False
    for line in path.read_text(errors="replace").splitlines():
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if not isinstance(e, dict):
            continue
        kind = e.get("type")
        if kind == "testStart":
            names[e["test"]["id"]] = e["test"]["name"]
        elif kind == "testDone":
            done[e["testID"]] = e
        elif kind in ("error", "print"):
            errors[e.get("testID")].append(e.get("error", e.get("message", "")))
        elif kind == "done":
            complete = True
    cases = {}
    for tid, event in done.items():
        if event.get("hidden"):
            continue
        name = names[tid]
        require(name not in cases, "Duplicate test name")
        cases[name] = {"result": "skipped" if event.get("skipped") else event["result"],
                       "messages": errors.get(tid, [])}
    return {"complete": complete, "cases": cases,
            "counts": dict(collections.Counter(v["result"] for v in cases.values())),
            "unfinished": [n for i,n in names.items() if i not in done]}

def patch(root):
    path = root / "test/visual_parity_test.dart"
    source = path.read_text()
    for (old, new), count in zip(REPLACEMENTS, COUNTS):
        require(source.count(old) == count, "Menu patch anchor drift")
        source = source.replace(old, new)
    require(len(re.findall(r"testWidgets\(", source)) == EXPECTED_TESTS, "Test inventory drift")
    require(re.findall(r"matchesGoldenFile\(\s*'([^']+)'", source) == EXPECTED_IMAGES, "Golden inventory drift")
    path.write_text(source)
    return sha(path)

def execute(label, iteration, mode, pins, snapshots):
    out = OUT / label / iteration / mode
    out.mkdir(parents=True)
    src = SOURCE / label
    root = WORK / (label + "-" + iteration + "-" + mode)
    require(environment() == pins, "Environment pin drift before " + root.name)
    shutil.copytree(src, root, ignore=shutil.ignore_patterns(".git", ".dart_tool", "build", "failures"))
    require(not (root / "test/failures").exists(), "Stale failure artifacts")
    patched_hash = patch(root)
    dump(out / "inputs.json", {"source": SHAS[label], "source_snapshot": snapshots[label], "patched_harness": patched_hash})
    env = dict(os.environ, HOME=str(WORK / (root.name + "-home")),
               PUB_CACHE=str(WORK / (root.name + "-pub-cache")))
    Path(env["HOME"]).mkdir()
    Path(env["PUB_CACHE"]).mkdir()
    pub = run(["flutter", "pub", "get", "--enforce-lockfile"], root, out / "pub-get.log", env)
    require(pub == 0 and sha(root / "pubspec.lock") == snapshots[label]["lock"], "Dependency pin mismatch")
    if mode == "generate":
        # Only disposable scratch copies are modified. Delete the named files
        # so that every generated image must be newly produced by this run.
        for name in EXPECTED_IMAGES:
            (root / "test" / name).unlink()
    args = ["flutter", "test", "--no-pub", "--reporter", "json", "--concurrency=1"]
    if mode == "generate":
        args.append("--update-goldens")
    args.append("test/visual_parity_test.dart")
    exit_code = run(args, root, out / "tests.jsonl", env)
    result = events(out / "tests.jsonl")
    result["exit"] = exit_code
    result["patched_harness"] = patched_hash
    if (root / "test/failures").exists():
        shutil.copytree(root / "test/failures", out / "failures")
    result["failure_hashes"] = file_hashes(out, (out / "failures").rglob("*"))
    if mode == "generate":
        images = out / "images"
        images.mkdir()
        for name in EXPECTED_IMAGES:
            image = root / "test" / name
            if image.is_file():
                target = images / Path(name).name
                shutil.copyfile(image, target)
        result["image_hashes"] = file_hashes(images, images.rglob("*.png"))
        result["missing_images"] = sorted(set(Path(p).name for p in EXPECTED_IMAGES) -
                                          set(result["image_hashes"]))
    else:
        require(all(sha(root / p) == h for p,h in snapshots[label]["goldens"].items()),
                "Comparison changed scratch goldens")
    require(source_snapshot(src) == snapshots[label], "Mounted source mutation")
    require(environment() == pins, "Environment pin drift after " + root.name)
    dump(out / "result.json", result)
    shutil.rmtree(root)
    shutil.rmtree(env["HOME"])
    shutil.rmtree(env["PUB_CACHE"])
    return result

def statuses(r):
    return {k:v["result"] for k,v in r["cases"].items()}

def complete(r):
    return r["complete"] and not r["unfinished"] and len(r["cases"]) == EXPECTED_TESTS

def main():
    OUT.mkdir(exist_ok=True)
    WORK.mkdir(exist_ok=True)
    pins = environment()
    require(pins["architecture"] == "x86_64", "Unexpected architecture")
    dump(OUT / "environment.json", pins)
    snapshots = {}
    for label, ref in SHAS.items():
        root = SOURCE / label
        require(command(["git","-c","safe.directory="+str(root),"rev-parse","HEAD"], root)==ref, "SHA mismatch")
        snapshots[label] = source_snapshot(root)
        for path, expected in EXPECTED_FONT_HASHES.items():
            require(snapshots[label]["fonts"].get(path) == expected, "App font pin mismatch: " + path)
    require(snapshots["baseline"] == snapshots["candidate"], "Source golden/font/harness/lock drift")
    dump(OUT / "source-snapshots.json", snapshots)
    results = {}
    for label in SHAS:
        for iteration in ("run-01", "run-02"):
            for mode in ("verify", "generate"):
                results[label,iteration,mode] = execute(label, iteration, mode, pins, snapshots)
    reproducibility = {}
    for label in SHAS:
        for mode in ("verify", "generate"):
            a,b = (results[label,i,mode] for i in ("run-01","run-02"))
            reproducibility[label+"-"+mode] = {
                "complete": complete(a) and complete(b),
                "named_results_equal": statuses(a)==statuses(b),
                "exit_equal": a["exit"]==b["exit"],
                "failure_hashes_equal": a["failure_hashes"]==b["failure_hashes"],
                "image_hashes_equal": a.get("image_hashes")==b.get("image_hashes"),
                "all_images_present": not a.get("missing_images") and not b.get("missing_images"),
            }
    dump(OUT/"comparisons/reproducibility.json", reproducibility)
    b,c = (results[label,"run-01","verify"] for label in SHAS)
    bs,cs = statuses(b),statuses(c)
    regressions = sorted(n for n,v in cs.items() if v in ("error","failure") and bs.get(n)=="success")
    generated = {label: results[label,"run-01","generate"]["image_hashes"] for label in SHAS}
    rows = []
    from PIL import Image, ImageChops
    image_out = OUT / "comparisons/images"
    image_out.mkdir(parents=True)
    for name in sorted(set(generated["baseline"]) | set(generated["candidate"])):
        paths = {"committed": SOURCE/"baseline"/"test/goldens"/name,
                 **{label: OUT/label/"run-01/generate/images"/name for label in SHAS}}
        row = {"image": name, "classification": "UNREVIEWED", "hashes": {}}
        if all(p.is_file() for p in paths.values()):
            ims = {k: Image.open(p).convert("RGBA") for k,p in paths.items()}
            row["hashes"] = {k:sha(p) for k,p in paths.items()}
            row["sizes"] = {k:list(im.size) for k,im in ims.items()}
            if ims["baseline"].size == ims["candidate"].size:
                diff = ImageChops.difference(ims["baseline"].convert("RGB"), ims["candidate"].convert("RGB"))
                pixels = sum(1 for p in diff.getdata() if p != (0,0,0))
                row["baseline_candidate_different_pixels"] = pixels
                row["baseline_candidate_diff_percent"] = 100*pixels/(diff.width*diff.height)
                if pixels:
                    diff.save(image_out/(Path(name).stem+"-baseline-candidate-diff.png"))
            if len({im.size for im in ims.values()}) == 1:
                canvas = Image.new("RGB", (ims["baseline"].width*3,ims["baseline"].height), "white")
                for i,k in enumerate(("committed","baseline","candidate")):
                    canvas.paste(ims[k].convert("RGB"), (i*ims[k].width,0))
                canvas.save(image_out/(Path(name).stem+"-committed-baseline-candidate.png"))
        rows.append(row)
    stable = all(all(v.values()) for v in reproducibility.values())
    generation_ok = all(r["exit"]==0 and complete(r) and not r["missing_images"]
                        and all(v=="success" for v in statuses(r).values())
                        for k,r in results.items() if k[2]=="generate")
    dump(OUT/"comparisons/differences.json", {"baseline_counts":b["counts"],"candidate_counts":c["counts"],
        "candidate_only_regressions":regressions,"named_inventory_equal":bs.keys()==cs.keys(),
        "shared_failures":sorted(n for n,v in bs.items() if v in ("failure","error") and cs.get(n) in ("failure","error")),
        "images":rows,"stable":stable,"generation_ok":generation_ok})
    dump(OUT/"acceptance-manifest.json", {"status":"PENDING_HUMAN_AND_OWNER_APPROVAL",
        "source_shas":SHAS,"stable":stable,"generation_ok":generation_ok,
        "images":rows,"coverage_limit":"Existing 64 tests, not full 05F-03 matrix. No replacement or acceptance implied."})
    for label in SHAS:
        require(source_snapshot(SOURCE/label)==snapshots[label], "Final mounted source mutation")
    print(json.dumps({"stable":stable,"generation_ok":generation_ok,"candidate_only_regressions":regressions,
                      "legacy_golden_parity":"PASS" if b["exit"]==c["exit"]==0 else "BLOCKED",
                      "human_acceptance":"PENDING"}), flush=True)
    # Preserve legacy verification failures; generated evidence is not a parity pass.
    return 0 if stable and generation_ok and not regressions and b["exit"]==c["exit"]==0 else 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        dump(OUT/"blocker.json", {"error":repr(exc)})
        raise
