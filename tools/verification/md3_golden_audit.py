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
REPLACEMENTS = [["void expectQuickPracticeSemantics() {\n  for (final label in [\n    'Addition',\n    'Subtraction',\n    'Multiplication',\n    'Division',\n    'Missing Operation',\n    'Mixed Operations',\n  ]) {\n    expect(find.text(label), findsOneWidget);\n  }\n\n  expect(find.text('🧮'), findsOneWidget);\n  expect(find.text('MISSING NUMBER'), findsNothing);\n  expect(find.text('Training Arena'), findsOneWidget);\n  expect(find.text('🚀'), findsOneWidget);\n}\n\n","Future<void> expectHomeAndPracticeSemantics(\n  WidgetTester tester, GameState state,\n) async {\n  final master = find.text('Master Challenge');\n  final target = find.byKey(const Key('target-clash-challenge-entry'));\n  final daily = find.byKey(const Key('daily-mental-math-row'));\n  final boss = find.text(state.dailyBoss?.name ?? 'Daily Boss');\n  final training = find.byKey(const Key('weak-skills-practice-row'));\n  final practice = find.byKey(const Key('practice-menu-entry'));\n  for (final finder in [master, target, daily, boss, training, practice]) {\n    expect(finder, findsOneWidget);\n  }\n  expect(find.text('Target Clash'), findsOneWidget);\n  expect(find.text('Daily IQ Spark'), findsOneWidget);\n  expect(find.text('Training Arena'), findsOneWidget);\n  expect(find.text('Practice'), findsOneWidget);\n  expect(find.text('Operation Quest'), findsNothing);\n  expect(find.text('➕'), findsNothing);\n  expect(tester.getCenter(master).dx, lessThan(tester.getCenter(target).dx));\n  expect(tester.getCenter(daily).dx, lessThan(tester.getCenter(boss).dx));\n  expect(tester.getCenter(master).dy, lessThan(tester.getCenter(daily).dy));\n  expect(tester.getCenter(target).dy, lessThan(tester.getCenter(boss).dy));\n  expect(tester.getCenter(daily).dy, lessThan(tester.getCenter(training).dy));\n  expect(tester.getCenter(training).dy, lessThan(tester.getCenter(practice).dy));\n  expect(find.text('🚀'), findsOneWidget);\n  await tester.ensureVisible(practice);\n  await tester.tap(practice);\n  await tester.pumpAndSettle();\n  expect(state.currentScreen, GameScreen.practice);\n  final quest = find.byKey(const Key('operation-quest-practice-entry'));\n  expect(quest, findsOneWidget);\n  expect(find.text('Operation Quest'), findsOneWidget);\n  expect(find.byIcon(Icons.explore_rounded), findsOneWidget);\n  for (final label in [\n    'Addition', 'Subtraction', 'Multiplication', 'Division',\n    'Missing Operation', 'Mixed Operations',\n  ]) {\n    expect(find.text(label), findsOneWidget);\n  }\n  expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);\n  expect(find.text('MISSING NUMBER'), findsNothing);\n  await tester.ensureVisible(quest);\n  await tester.tap(quest);\n  await tester.pumpAndSettle();\n  expect(state.currentModal, GameModal.operationQuest);\n  expectNoVisualException(tester);\n  state.closeModal();\n  await tester.pumpAndSettle();\n  final back = find.byKey(const Key('practice-menu-back'));\n  await tester.ensureVisible(back);\n  await tester.tap(back);\n  await tester.pumpAndSettle();\n  expect(state.currentScreen, GameScreen.menu);\n  expectNoVisualException(tester);\n}\n\n"],["      final master = find.text('Master Challenge');\n      final dailyBoss = find.text(state.dailyBoss!.name);\n      final operationQuest = find.text('Operation Quest');\n      expect(master, findsOneWidget);\n      expect(dailyBoss, findsOneWidget);\n      expect(operationQuest, findsOneWidget);\n      expect(tester.getTopLeft(master).dy,\n          lessThan(tester.getTopLeft(dailyBoss).dy));\n      expect(tester.getTopLeft(dailyBoss).dy,\n          lessThan(tester.getTopLeft(operationQuest).dy));\n      expectQuickPracticeSemantics();\n      expect(find.text('🧭'), findsOneWidget);\n      expect(find.text('➕'), findsNothing);\n","      await expectHomeAndPracticeSemantics(tester, state);\n"],["      expect(find.text('Operation Quest'), findsOneWidget);\n      expectQuickPracticeSemantics();","      await expectHomeAndPracticeSemantics(tester, state);"],["      expectQuickPracticeSemantics();","      await expectHomeAndPracticeSemantics(tester, state);"],["      final dailyCard = find.byKey(const Key('daily-mental-math-row'));\n      await tester.ensureVisible(dailyCard);","      await expectHomeAndPracticeSemantics(tester, state);\n      final dailyCard = find.byKey(const Key('daily-mental-math-row'));\n      await tester.ensureVisible(dailyCard);"],["      expect(find.text('Operation Quest'), findsOneWidget);\n      expect(\n        tester.getTopLeft(find.text('Daily Boss')).dy,\n        lessThan(tester.getTopLeft(find.text('Daily IQ Spark')).dy),\n      );\n      expect(\n        tester.getTopLeft(find.text('Daily IQ Spark')).dy,\n        lessThan(tester.getTopLeft(find.text('Operation Quest')).dy),\n      );","      expect(find.text('Operation Quest'), findsNothing);\n      expect(\n        tester.getCenter(find.text('Daily IQ Spark')).dx,\n        lessThan(tester.getCenter(find.text('Daily Boss')).dx),\n      );"]]
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

def execute(label, iteration, mode, pins, snapshots, font_mode="C"):
    out = OUT / label / iteration / mode
    out.mkdir(parents=True)
    src = SOURCE / label
    root = WORK / (label + "-" + iteration + "-" + mode)
    require(environment() == pins, "Environment pin drift before " + root.name)
    shutil.copytree(src, root, ignore=shutil.ignore_patterns(".git", ".dart_tool", "build", "failures"))
    require(not (root / "test/failures").exists(), "Stale failure artifacts")
    patched_hash = patch(root)
    patched_hash = recovery_patch(root)
    dump(out / "inputs.json", {"source": SHAS[label], "source_snapshot": snapshots[label], "patched_harness": patched_hash})
    env = dict(os.environ, HOME=str(WORK / (root.name + "-home")),
               PUB_CACHE=str(WORK / (root.name + "-pub-cache")))
    Path(env["HOME"]).mkdir()
    Path(env["PUB_CACHE"]).mkdir()
    env["GBR_FONT_MODE"] = font_mode
    env["GBR_EMOJI_FONT"] = str(EMOJI_FONT)
    if mode == "generate":
        (out/"layouts").mkdir()
        env["GBR_LAYOUT_OUTPUT"] = str(out/"layouts")
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
        result["layout_hashes"] = file_hashes(out/"layouts", (out/"layouts").glob("*.json"))
        result["font_mode"] = font_mode
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
    verify_prior(pins, snapshots)
    results = {}
    controls = {}
    # Run A controls, then screen the first corrected generation before proceeding.
    for label in SHAS:
        controls[label] = execute(label, "control-A", "generate", pins, snapshots, "A")
        verify_control(label, controls[label])
        for iteration in ("run-01", "run-02"):
            results[label,iteration,"generate"] = execute(label, iteration, "generate", pins, snapshots, "C")
            drift_guard(label, iteration, controls[label], results[label,iteration,"generate"])
            results[label,iteration,"verify"] = execute(label, iteration, "verify", pins, snapshots, "C")
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
                "layout_hashes_equal": a.get("layout_hashes")==b.get("layout_hashes"),
                "all_images_present": not a.get("missing_images") and not b.get("missing_images"),
            }
    dump(OUT/"comparisons/reproducibility.json", reproducibility)
    b,c = (results[label,"run-01","verify"] for label in SHAS)
    bs,cs = statuses(b),statuses(c)
    regressions = sorted(n for n,v in cs.items() if v in ("error","failure") and bs.get(n)=="success")
    generated = {label: results[label,"run-01","generate"]["image_hashes"] for label in SHAS}
    changed = {name for name in generated["baseline"] if generated["baseline"][name]!=generated["candidate"].get(name)}
    dump(OUT/"comparisons/changed-scenes.json", {"previous":sorted(PRIOR_CHANGED),"current":sorted(changed),
        "newly_changed":sorted(changed-PRIOR_CHANGED),"classification":"PENDING_RENDERED_REVIEW"})
    require(not changed-PRIOR_CHANGED,"New baseline/candidate difference outside prior four scenes")
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
        "images":rows,"font_mode":"C","prior_recovery":46040044238,"physical_android":"NOT_VALIDATED",
        "scene_classifications":"PENDING_HUMAN_REVIEW","coverage_limit":"Existing 64 tests, not full 05F-03 matrix. No replacement or acceptance implied."})
    for label in SHAS:
        require(source_snapshot(SOURCE/label)==snapshots[label], "Final mounted source mutation")
    print(json.dumps({"stable":stable,"generation_ok":generation_ok,"candidate_only_regressions":regressions,
                      "legacy_golden_parity":"PASS" if b["exit"]==c["exit"]==0 else "BLOCKED",
                      "human_acceptance":"PENDING"}), flush=True)
    # Preserve legacy verification failures; generated evidence is not a parity pass.
    return 0 if stable and generation_ok and not regressions and b["exit"]==c["exit"]==0 else 1



# Full recovery uses the previously reviewed C fallback only in the temporary
# test harness. An instrumented A control must reproduce prior raw images.
RECOVERY_DART = "\nconst _gbrEmoji = 'NotoColorEmoji';\nbool get _gbrCorrected => Platform.environment['GBR_FONT_MODE'] == 'C';\nFuture<void> _gbrLoadEmoji() async {\n  if (!_gbrCorrected) return;\n  final data = File(Platform.environment['GBR_EMOJI_FONT']!).readAsBytesSync();\n  final loader = FontLoader(_gbrEmoji)\n    ..addFont(Future<ByteData>.value(ByteData.sublistView(data)));\n  await loader.load();\n}\nTextStyle? _gbrStyle(TextStyle? s) {\n  if (s == null || !_gbrCorrected) return s;\n  final existing = s.fontFamilyFallback ?? const <String>[];\n  if (existing.contains(_gbrEmoji)) return s;\n  return s.copyWith(fontFamilyFallback: [...existing, _gbrEmoji]);\n}\nTextTheme _gbrTextTheme(TextTheme t) => t.copyWith(\n  displayLarge: _gbrStyle(t.displayLarge), displayMedium: _gbrStyle(t.displayMedium),\n  displaySmall: _gbrStyle(t.displaySmall), headlineLarge: _gbrStyle(t.headlineLarge),\n  headlineMedium: _gbrStyle(t.headlineMedium), headlineSmall: _gbrStyle(t.headlineSmall),\n  titleLarge: _gbrStyle(t.titleLarge), titleMedium: _gbrStyle(t.titleMedium),\n  titleSmall: _gbrStyle(t.titleSmall), bodyLarge: _gbrStyle(t.bodyLarge),\n  bodyMedium: _gbrStyle(t.bodyMedium), bodySmall: _gbrStyle(t.bodySmall),\n  labelLarge: _gbrStyle(t.labelLarge), labelMedium: _gbrStyle(t.labelMedium),\n  labelSmall: _gbrStyle(t.labelSmall),\n);\nThemeData _gbrTheme(ThemeData t) => !_gbrCorrected ? t : t.copyWith(\n  textTheme: _gbrTextTheme(t.textTheme),\n  primaryTextTheme: _gbrTextTheme(t.primaryTextTheme),\n);\nclass _GbrGolden {\n  const _GbrGolden(this.name, this.matcher);\n  final String name;\n  final dynamic matcher;\n}\n_GbrGolden matchesGoldenFile(String name) =>\n    _GbrGolden(name, gbr.matchesGoldenFile(name));\n// Capture the same nearest repaint boundary as the widget golden matcher.\n// Material icon private-use glyphs and ordinary text are protected, not masked.\nbool _gbrSymbol(int cp) =>\n    (cp >= 0x1f000 && cp <= 0x1faff) ||\n    (cp >= 0x2600 && cp <= 0x27bf) ||\n    cp == 0x2b50 || cp == 0x2b55 || cp == 0x231a || cp == 0x231b;\nbool _gbrJoin(int cp) => cp == 0xfe0f || cp == 0xfe0e || cp == 0x200d || cp == 0x20e3;\ndouble _gbrRound(double d) => (d * 10000).roundToDouble() / 10000;\nList<double> _gbrRect(Rect r) => [r.left,r.top,r.right,r.bottom].map(_gbrRound).toList();\nvoid _gbrCapture(Finder finder, String name, String directory) {\n  RenderObject boundary = finder.evaluate().single.findRenderObject()!;\n  while (!boundary.isRepaintBoundary) {\n    boundary = boundary.parent! as RenderObject;\n  }\n  final box = boundary as RenderBox;\n  final visible = Offset.zero & box.size;\n  final protected = <Map<String, Object?>>[];\n  final symbols = <Map<String, Object?>>[];\n  void walk(RenderObject node) {\n    if (node is RenderParagraph && node.hasSize && node.attached) {\n      final text = node.text.toPlainText(includeSemanticsLabels: false);\n      final matrix = node.getTransformTo(boundary);\n      var offset = 0;\n      var start = 0;\n      bool? symbol;\n      void record(int end) {\n        if (start == end) return;\n        final rects = <List<double>>[];\n        for (final selected in node.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))) {\n          final rect = MatrixUtils.transformRect(matrix, selected.toRect());\n          if (!rect.isFinite) continue;\n          final clipped = rect.intersect(visible);\n          if (!clipped.isEmpty) rects.add(_gbrRect(clipped));\n        }\n        if (rects.isNotEmpty) {\n          final value = {'text': text.substring(start, end), 'rects': rects};\n          (symbol == true ? symbols : protected).add(value);\n        }\n      }\n      for (final cp in text.runes) {\n        final next = _gbrJoin(cp) ? (symbol ?? false) : _gbrSymbol(cp);\n        if (symbol != null && next != symbol) {\n          record(offset);\n          start = offset;\n        }\n        symbol = next;\n        offset += cp > 0xffff ? 2 : 1;\n      }\n      record(offset);\n    }\n    node.visitChildren(walk);\n  }\n  walk(boundary);\n  final out = File('$directory/${name.split('/').last}.json');\n  out.writeAsStringSync(jsonEncode({\n    'size': [box.size.width, box.size.height],\n    'protected': protected, 'symbol_candidates': symbols,\n  }));\n}\nFuture<void> expectLater(dynamic actual, _GbrGolden matcher) async {\n  final directory = Platform.environment['GBR_LAYOUT_OUTPUT'];\n  if (directory != null) _gbrCapture(actual as Finder, matcher.name, directory);\n  await gbr.expectLater(actual, matcher.matcher);\n}\n"
PRIOR = Path("/prior")
PRIOR_HASHES = {
    "environment.json": "c916f24a77c2434e2cd7d04c3104c19ec0fe79bcdb3bc1cb565e4ae3e68c0d4f",
    "acceptance-manifest.json": "95f39b2e9ee954b5a8f09c033e86ca4f0d2780330187d95d7bb2b24a6d6e19ad",
    "source-snapshots.json": "b76e66b696bba0533eeea08b3bcd80c5fb9dd192be95ae763e37e972177d996d",
    "comparisons/differences.json": "1ba074d3a83596f62c754f5e3ad85bcb9962d5794deaa03494b18c9b85fa6d9f",
    "baseline/run-01/generate/result.json": "61b5e9bf096268bdd9fe18223aaabae2545207bc933dd0ec409ba366b2fef09d",
    "candidate/run-01/generate/result.json": "c0c5f5482a1a14e9802f655b077d52af5c3eb35bbedf333eeaf3489ed2010042",
}
PRIOR_CHANGED = {"10_win_modal.png", "28_cloud_save_conflict_native_light.png",
                 "28_cloud_save_conflict_ordinary_dark.png", "28_cloud_save_conflict_ordinary_light.png"}
EMOJI_FONT = Path("/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf")
EMOJI_HASH = "93cdc4ee9aa40e2afceecc63da0ca05ec7aab4bec991ece51a6b52389f48a477"

def verify_prior(pins, snapshots):
    for name, expected in PRIOR_HASHES.items():
        require((PRIOR/name).is_file() and sha(PRIOR/name)==expected, "Prior evidence hash mismatch: "+name)
    require(json.loads((PRIOR/"environment.json").read_text())==pins, "Environment differs from prior validated A/C runs")
    require(json.loads((PRIOR/"source-snapshots.json").read_text())==snapshots, "Prior source snapshot mismatch")
    require(EMOJI_FONT.is_file() and sha(EMOJI_FONT)==EMOJI_HASH, "Emoji font hash mismatch")
    prior = json.loads((PRIOR/"acceptance-manifest.json").read_text())
    require(prior["source_shas"]==SHAS and prior["stable"] and prior["generation_ok"], "Prior recovery invalid")
    for label in SHAS:
        result = json.loads((PRIOR/label/"run-01/generate/result.json").read_text())
        require(complete(result) and result["exit"]==0 and len(result["image_hashes"])==len(EXPECTED_IMAGES), "Prior inventory invalid")
        for name, digest in result["image_hashes"].items():
            require(sha(PRIOR/label/"run-01/generate/images"/name)==digest, "Prior image mismatch: "+name)
    dump(OUT/"prior-evidence.json", {"run":46040044238,"artifact":15220595002,
        "validated_hashes":PRIOR_HASHES,"emoji_font_sha256":EMOJI_HASH})

def recovery_patch(root):
    path = root/"test/visual_parity_test.dart"
    source = path.read_text()
    edits = [
        ("import 'dart:convert';", "import 'dart:convert';\\nimport 'dart:io';"),
        ("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\\nimport 'package:flutter/rendering.dart';"),
        ("import 'package:flutter_test/flutter_test.dart';",
         "import 'package:flutter_test/flutter_test.dart' hide matchesGoldenFile, expectLater;\\nimport 'package:flutter_test/flutter_test.dart' as gbr;"),
        ("  await fontLoader2.load();", "  await fontLoader2.load();\\n  await _gbrLoadEmoji();"),
        ("theme: AppTheme.light(s),", "theme: _gbrTheme(AppTheme.light(s)),"),
        ("darkTheme: AppTheme.dark(s),", "darkTheme: _gbrTheme(AppTheme.dark(s)),"),
    ]
    for old,new in edits:
        require(source.count(old)==1, "Recovery patch anchor drift: "+old)
        source = source.replace(old,new.replace("\\n","\n"))
    require(source.count("void main() {")==1,"Main anchor drift")
    source = source.replace("void main() {", RECOVERY_DART+"\nvoid main() {")
    require(len(re.findall(r"testWidgets\(",source))==EXPECTED_TESTS,"Test inventory drift")
    require(re.findall(r"matchesGoldenFile\(\s*'([^']+)'",source)==EXPECTED_IMAGES,"Golden inventory drift")
    path.write_text(source)
    return sha(path)

def valid_generation(r):
    return (r["exit"]==0 and complete(r) and not r["missing_images"]
            and all(v=="success" for v in statuses(r).values())
            and len(r.get("layout_hashes",{}))==len(EXPECTED_IMAGES))

def drift_guard(label, iteration, control, corrected):
    from PIL import Image, ImageChops, ImageDraw
    import math
    require(valid_generation(control) and valid_generation(corrected),"Incomplete A/C generation")
    before = OUT/label/"control-A/generate"
    after = OUT/label/iteration/"generate"
    destination = OUT/"comparisons"/"fallback-drift"/label/iteration
    destination.mkdir(parents=True)
    rows = []
    def rectangles(data, key):
        return [r for item in data[key] for r in item["rects"]]
    def draw_rect(draw, rect, fill, size, pad=0):
        l,t,r,b=rect
        coords=(max(0, math.floor(l)-pad),max(0,math.floor(t)-pad),
                min(size[0]-1,math.ceil(r)-1+pad),min(size[1]-1,math.ceil(b)-1+pad))
        if coords[0]<=coords[2] and coords[1]<=coords[3]:
            draw.rectangle(coords,fill=fill)
    for name in sorted(control["image_hashes"]):
        a=Image.open(before/"images"/name).convert("RGBA")
        b=Image.open(after/"images"/name).convert("RGBA")
        l1=json.loads((before/"layouts"/(name+".json")).read_text())
        l2=json.loads((after/"layouts"/(name+".json")).read_text())
        row={"image":name,"A_sha256":control["image_hashes"][name],"C_sha256":corrected["image_hashes"][name],
             "same_dimensions":a.size==b.size,"protected_geometry_equal":l1["protected"]==l2["protected"],
             "layout_size_matches":l1["size"]==list(a.size) and l2["size"]==list(b.size)}
        if a.size==b.size and row["layout_size_matches"]:
            diff=ImageChops.difference(a,b)
            channels=diff.split()
            changed=channels[0]
            for ch in channels[1:]:
                changed=ImageChops.lighter(changed,ch)
            changed=changed.point(lambda x:255 if x else 0)
            mask=Image.new("L",a.size,0)
            draw=ImageDraw.Draw(mask)
            for rect in rectangles(l1,"symbol_candidates")+rectangles(l2,"symbol_candidates"):
                draw_rect(draw,rect,255,a.size,2)
            # Never exempt ordinary glyphs/Material private-use icon boxes.
            for rect in rectangles(l1,"protected")+rectangles(l2,"protected"):
                draw_rect(draw,rect,0,a.size)
            unexplained=ImageChops.multiply(changed,ImageChops.invert(mask))
            row["different_pixels"]=changed.histogram()[255]
            row["unexplained_pixels"]=unexplained.histogram()[255]
            if row["different_pixels"]:
                canvas=Image.new("RGB",(a.width*3,a.height),"white")
                canvas.paste(a.convert("RGB"),(0,0))
                canvas.paste(b.convert("RGB"),(a.width,0))
                canvas.paste(diff.convert("RGB"),(a.width*2,0))
                canvas.save(destination/(Path(name).stem+"-A-C-diff.png"))
                unexplained.save(destination/(Path(name).stem+"-unexplained-mask.png"))
        row["guard_pass"]=(row["same_dimensions"] and row["layout_size_matches"]
             and row["protected_geometry_equal"] and row.get("unexplained_pixels")==0)
        row["classification"]="SYMBOL_REGION_ONLY_PENDING_VISUAL_REVIEW" if row["guard_pass"] else "BLOCKED_UNEXPLAINED_DRIFT"
        rows.append(row)
    dump(destination/"report.json",{"all_pass":all(r["guard_pass"] for r in rows),"images":rows,
         "limit":"Symbol-range masks are conservative screening, not proof of glyph correctness or human acceptance."})
    require(all(r["guard_pass"] for r in rows),"Unexplained pixel/ordinary text or icon geometry drift: "+label+" "+iteration)

def verify_control(label, result):
    require(valid_generation(result),"A control incomplete: "+label)
    prior=json.loads((PRIOR/label/"run-01/generate/result.json").read_text())
    require(result["image_hashes"]==prior["image_hashes"],"A control does not reproduce prior evidence: "+label)
    require(statuses(result)==statuses(prior),"A control test results differ: "+label)


# Diagnostic only: isolated synthetic probe using the original font loader.
# Never select a font correction or replace a golden from this experiment.
PROBE_DART = "import 'dart:convert';\nimport 'dart:io';\nimport 'dart:typed_data';\nimport 'dart:ui' as ui;\nimport 'package:flutter/material.dart';\nimport 'package:flutter/rendering.dart';\nimport 'package:flutter/services.dart';\nimport 'package:flutter_test/flutter_test.dart';\nimport 'package:math_challenge/services/settings.dart';\nimport 'package:math_challenge/theme.dart';\nimport 'visual_parity_test.dart' as existing;\n\nconst samples = <String>[\n  'Math 123 + -',\n  '🚀', '🧮', '🎓', '🏆', '🧠⚡', '🎯', '🐲', '🧭',\n  '➕', '✖️', '⭐', 'IQ 56',\n];\nconst families = <String?>['Baloo2', 'PlusJakartaSans', null];\n\nvoid main() {\n  final mode = Platform.environment['GBR_PROBE_MODE']!;\n  final output = Platform.environment['GBR_PROBE_OUTPUT']!;\n  setUpAll(() async {\n    TestWidgetsFlutterBinding.ensureInitialized();\n    await existing.loadAppFonts();\n    if (mode != 'A') {\n      final bytes = File(Platform.environment['GBR_PROBE_FONT']!).readAsBytesSync();\n      final emoji = FontLoader('NotoColorEmoji')\n        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));\n      await emoji.load();\n    }\n  });\n  testWidgets('temporary glyph probe', (tester) async {\n    await existing.setTestDevice(tester, logicalSize: const Size(390, 844));\n    final settings = SettingsService()\n      ..load(dark: false, sound: false, vibration: false, dyslexia: false,\n        colorblind: false, lowPerf: true, reduceMotion: true, animSpeed: 1);\n    addTearDown(settings.dispose);\n    final key = GlobalKey();\n    Map<String, Object?>? metadata;\n    await tester.pumpWidget(MaterialApp(\n      debugShowCheckedModeBanner: false,\n      theme: AppTheme.light(settings),\n      home: RepaintBoundary(\n        key: key,\n        child: Scaffold(\n          backgroundColor: Colors.white,\n          body: Builder(builder: (context) {\n            metadata = {\n              'mode': mode,\n              'explicit_registration': mode != 'A',\n              'explicit_fallback': mode == 'C',\n              'locale': Localizations.localeOf(context).toLanguageTag(),\n              'platform_locale': tester.binding.platformDispatcher.locale.toLanguageTag(),\n              'text_scale_at_1': MediaQuery.textScalerOf(context).scale(1),\n              'logical_size': [MediaQuery.sizeOf(context).width, MediaQuery.sizeOf(context).height],\n              'device_pixel_ratio': tester.view.devicePixelRatio,\n              'default_family': DefaultTextStyle.of(context).style.fontFamily,\n              'families': families,\n              'samples': samples,\n              'row_height': 60,\n              'renderer': 'native flutter_tester',\n            };\n            return Column(\n              children: [\n                for (final sample in samples)\n                  SizedBox(height: 60, child: Row(\n                    children: [\n                      for (final family in families)\n                        Expanded(child: Center(child: Text(\n                          sample,\n                          maxLines: 1,\n                          style: TextStyle(\n                            fontFamily: family,\n                            fontFamilyFallback: mode == 'C' ? const ['NotoColorEmoji'] : null,\n                            fontSize: 22,\n                            fontWeight: FontWeight.w700,\n                            color: Colors.black,\n                          ),\n                        ))),\n                    ],\n                  )),\n              ],\n            );\n          }),\n        ),\n      ),\n    ));\n    await tester.pumpAndSettle();\n    expect(tester.takeException(), isNull);\n    expect(metadata, isNotNull);\n    await tester.runAsync(() async {\n      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;\n      final image = await boundary.toImage(pixelRatio: 1);\n      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;\n      File('$output/probe.png').writeAsBytesSync(\n          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));\n      image.dispose();\n      File('$output/render.json').writeAsStringSync(jsonEncode(metadata));\n    });\n    expect(File('$output/probe.png').existsSync(), isTrue);\n    expect(tester.takeException(), isNull);\n  });\n}\n"
PROBE_SAMPLES = ["Math 123 + -","🚀","🧮","🎓","🏆","🧠⚡","🎯","🐲","🧭","➕","✖️","⭐","IQ 56"]

def glyph_inventory(path):
    result = subprocess.run(["fc-query", "--format", "%{family}\\n%{charset}\\n", str(path)],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    lines = result.stdout.splitlines()
    intervals = []
    if result.returncode == 0:
        for line in lines[1::2]:
            for token in line.split():
                bounds = token.split("-")
                try:
                    intervals.append((int(bounds[0], 16), int(bounds[-1], 16)))
                except ValueError:
                    pass
    points = sorted({ord(ch) for sample in PROBE_SAMPLES for ch in sample})
    return {"sha256": sha(path), "fc_query_exit": result.returncode,
            "raw_fontconfig": result.stdout, "stderr": result.stderr,
            "codepoint_coverage": {f"U+{p:04X}": any(a <= p <= b for a,b in intervals)
                                   for p in points},
            "limit": "Codepoint coverage is not proof of shaped sequence or renderer coverage."}

def emoji_probe():
    from PIL import Image, ImageChops
    OUT.mkdir(exist_ok=True)
    WORK.mkdir(exist_ok=True)
    pins = environment()
    require(pins["architecture"] == "x86_64", "Unexpected architecture")
    dump(OUT / "environment.json", pins)
    snapshots = {}
    for label, ref in SHAS.items():
        root = SOURCE / label
        require(command(["git", "-c", "safe.directory="+str(root), "rev-parse", "HEAD"], root) == ref,
                "SHA mismatch")
        snapshots[label] = source_snapshot(root)
        for path, expected in EXPECTED_FONT_HASHES.items():
            require(snapshots[label]["fonts"].get(path) == expected, "App font pin mismatch: "+path)
        source = (root / "test/visual_parity_test.dart").read_text()
        require(len(re.findall(r"testWidgets\(", source)) == EXPECTED_TESTS, "Test inventory drift")
        require(re.findall(r"matchesGoldenFile\(\s*'([^']+)'", source) == EXPECTED_IMAGES, "Golden inventory drift")
    require(snapshots["baseline"] == snapshots["candidate"], "Source input drift")
    dump(OUT / "source-snapshots.json", snapshots)
    fonts = [Path(p) for p in pins["system_fonts"] if Path(p).name == "NotoColorEmoji.ttf"]
    require(len(fonts) == 1, "Expected one pinned NotoColorEmoji file")
    font = fonts[0]
    require(sha(font) == pins["system_fonts"][str(font)], "Emoji font hash mismatch")
    coverage = {"system_emoji": glyph_inventory(font),
                "app_fonts": {p: glyph_inventory(SOURCE/"baseline"/p) for p in EXPECTED_FONT_HASHES},
                "fontconfig_match": {sample: command(["fc-match", "-f", "%{file} %{family}", sample])
                                     for sample in ("Noto Color Emoji", "Baloo2", "PlusJakartaSans", ":charset=1f680")}}
    dump(OUT / "glyph-coverage.json", coverage)
    require(coverage["system_emoji"]["fc_query_exit"] == 0, "Emoji coverage query failed")
    results = {}
    for label in SHAS:
        for mode in ("A", "B", "C"):
            out = OUT / "emoji-probes" / label / mode
            out.mkdir(parents=True)
            root = WORK / ("probe-"+label+"-"+mode)
            require(environment() == pins, "Environment changed before probe")
            shutil.copytree(SOURCE/label, root, ignore=shutil.ignore_patterns(".git", ".dart_tool", "build", "failures"))
            probe = root / "test/gbr_temporary_emoji_probe_test.dart"
            probe.write_text(PROBE_DART)
            env = dict(os.environ, HOME=str(WORK/(root.name+"-home")),
                       PUB_CACHE=str(WORK/(root.name+"-cache")),
                       GBR_PROBE_MODE=mode, GBR_PROBE_FONT=str(font), GBR_PROBE_OUTPUT=str(out))
            Path(env["HOME"]).mkdir()
            Path(env["PUB_CACHE"]).mkdir()
            pub = run(["flutter","pub","get","--enforce-lockfile"], root, out/"pub-get.log", env)
            require(pub == 0 and sha(root/"pubspec.lock") == snapshots[label]["lock"], "Dependency pin mismatch")
            rc = run(["flutter","test","--no-pub","--reporter","json","--concurrency=1",
                      "test/gbr_temporary_emoji_probe_test.dart"], root, out/"tests.jsonl", env)
            result = events(out/"tests.jsonl")
            result.update({"source_sha": SHAS[label], "exit": rc, "mode": mode,
                           "probe_sha256": sha(probe), "emoji_font_sha256": sha(font)})
            if (out/"probe.png").exists() and (out/"render.json").exists():
                result["image_sha256"] = sha(out/"probe.png")
                result["render"] = json.loads((out/"render.json").read_text())
            require(sha(root/"test/visual_parity_test.dart") == snapshots[label]["harness"], "Harness changed")
            require(all(sha(root/p)==h for p,h in snapshots[label]["goldens"].items()), "Scratch golden mutation")
            require(source_snapshot(SOURCE/label)==snapshots[label], "Source mutation")
            require(environment()==pins, "Environment drift after probe")
            dump(out/"result.json", result)
            results[label,mode] = result
            shutil.rmtree(root)
            shutil.rmtree(env["HOME"])
            shutil.rmtree(env["PUB_CACHE"])
    def valid(r):
        return (r["exit"] == 0 and r["complete"] and not r["unfinished"]
                and r["counts"] == {"success": 1} and bool(r.get("image_sha256")))
    all_valid = all(valid(r) for r in results.values())
    comparison = {"all_probes_completed": all_valid, "source_shas": SHAS,
                  "mode_semantics": {"A":"original loader", "B":"explicit registration",
                                     "C":"explicit registration and sample TextStyle fallback"},
                  "selection": "NONE_PENDING_IMAGE_REVIEW", "physical_android": "NOT_VALIDATED",
                  "coverage_limit": "Synthetic glyph samples using actual app font loader; not full-screen parity, not device evidence.",
                  "pairs": []}
    def compare(left, right):
        im1 = Image.open(OUT/"emoji-probes"/left[0]/left[1]/"probe.png").convert("RGB")
        im2 = Image.open(OUT/"emoji-probes"/right[0]/right[1]/"probe.png").convert("RGB")
        require(im1.size == im2.size == (390,844), "Unexpected probe image dimensions")
        diff = ImageChops.difference(im1,im2)
        rows = []
        for i,sample in enumerate(PROBE_SAMPLES):
            columns = []
            for j in range(3):
                tile = diff.crop((j*130,i*60,(j+1)*130,(i+1)*60))
                columns.append(sum(1 for p in tile.getdata() if p != (0,0,0)))
            rows.append({"sample": sample, "different_pixels_by_family": columns})
        name = "-".join(left)+"_vs_"+"-".join(right)
        diff_path = OUT/"emoji-probes"/(name+"-diff.png")
        diff.save(diff_path)
        return {"left": list(left), "right": list(right),
                "sha_equal": results[left]["image_sha256"]==results[right]["image_sha256"],
                "diff_sha256": sha(diff_path), "rows":rows}
    if all_valid:
        for label in SHAS:
            for mode in ("B","C"):
                comparison["pairs"].append(compare((label,"A"),(label,mode)))
            canvas = Image.new("RGB", (1170,844), "white")
            for i,mode in enumerate(("A","B","C")):
                with Image.open(OUT/"emoji-probes"/label/mode/"probe.png") as im:
                    canvas.paste(im.convert("RGB"), (390*i,0))
            canvas.save(OUT/"emoji-probes"/(label+"-A-B-C.png"))
        for mode in ("A","B","C"):
            comparison["pairs"].append(compare(("baseline",mode),("candidate",mode)))
    dump(OUT/"emoji-probes/comparison.json", comparison)
    dump(OUT/"acceptance-manifest.json", {"status":"BLOCKED_PENDING_GLYPH_REVIEW_AND_PHYSICAL_ANDROID",
         "source_shas":SHAS,"probe_success":all_valid,"golden_replacement":"NOT_AUTHORIZED",
         "legacy_recovery_run":46040044238,"scene_classifications":"UNRESOLVED",
         "note":"No full-suite font correction selected or applied; 64 original tests and 71 golden references untouched."})
    for label in SHAS:
        require(source_snapshot(SOURCE/label)==snapshots[label], "Final source mutation")
    print(json.dumps({"emoji_probe_complete":all_valid,"physical_android":"NOT_VALIDATED",
                      "golden_acceptance":"BLOCKED"}),flush=True)
    return 0 if all_valid else 1

if __name__ == "__main__":
    try:
        sys.exit(emoji_probe() if sys.argv[1:] == ["--emoji-probe"] else main())
    except Exception as exc:
        dump(OUT/"blocker.json", {"error":repr(exc)})
        raise
