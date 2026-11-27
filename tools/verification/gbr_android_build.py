"""GBR Batch 01: isolated debug builds; no installation or APK upload."""
import argparse, difflib, hashlib, json, os, re, shutil, subprocess, sys, tarfile, tempfile
from pathlib import Path
import time
ROOT=Path(__file__).resolve().parents[2]
SHAS={"baseline":"fdbbfc63e9e2f1c095512db2337ce5bbfa150f31","candidate":"feadfb059b0892846b06ecfd42d38f55d2cde290"}
PROD="com.mohamedk.mathchallenge"
DENIED=("android.permission.INTERNET","com.android.vending.BILLING","com.google.android.gms.permission.AD_ID","android.permission.ACCESS_ADSERVICES_AD_ID","android.permission.ACCESS_ADSERVICES_ATTRIBUTION","android.permission.ACCESS_ADSERVICES_TOPICS")
COMPONENTS=("platforms/android-36","build-tools/36.0.0","ndk/28.2.13676358")
def require(ok,reason):
    if not ok: raise RuntimeError(reason)
def dump(p,v):
    p.write_text(json.dumps(v,indent=2,sort_keys=True)+"\n",encoding="utf-8")
def sha(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for part in iter(lambda:f.read(1048576),b""): h.update(part)
    return h.hexdigest()
def run(args,cwd=None,env=None,log=None):
    args=list(map(str,args))
    args[0]=shutil.which(args[0]) or args[0]
    if os.name=="nt" and args[0].lower().endswith((".bat",".cmd")):
        args=[os.environ.get("COMSPEC","cmd.exe"),"/d","/c",subprocess.list2cmdline(args)]
    print("Executing "+Path(args[0]).name+" "+str(args[1:3]),flush=True)
    p=subprocess.run(args,cwd=cwd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding="utf-8",errors="replace")
    if log: log.write_text(p.stdout,encoding="utf-8")
    require(p.returncode==0,"Command failed: "+str(log or p.stdout[-2000:]))
    return p.stdout
def once(s,a,b):
    require(s.count(a)==1,"Isolation anchor drift: "+a)
    return s.replace(a,b)
def inventory(root,sub):
    return {p.relative_to(root).as_posix():sha(p) for p in sorted((root/sub).rglob("*")) if p.is_file()}
def archive(ref,root):
    require(run(["git","rev-parse",ref+"^{commit}"],ROOT).strip()==ref,"SHA mismatch")
    tar=root.parent/(root.name+".tar")
    run(["git","archive","--format=tar","--output="+str(tar),ref],ROOT)
    root.mkdir()
    with tarfile.open(tar) as f:
        for m in f.getmembers():
            require(not m.name.startswith("/") and ".." not in Path(m.name).parts and (m.isfile() or m.isdir()),"Unsafe archive entry")
        f.extractall(root)
    tar.unlink()
def prepare(root,label,ev):
    package=PROD+".gbr"+label
    changes={}
    def edit(rel,fn):
        p=root/rel
        raw=p.read_bytes()
        s=raw.decode("utf-8-sig")
        new=fn(s)
        p.write_text(new,encoding="utf-8",newline="\n")
        changes[rel]={"original_sha256":hashlib.sha256(raw).hexdigest(),"scratch_sha256":sha(p),"diff":"".join(difflib.unified_diff(s.splitlines(True),new.splitlines(True),fromfile=rel,tofile=rel+" (scratch)"))}
    def gradle(s):
        s=once(s,'applicationId = "'+PROD+'"','applicationId = "'+package+'"')
        s=once(s,"signingConfigs {",'''signingConfigs {
        debug {
            storeFile = file("gbr-test-debug.jks")
            storePassword = "android"
            keyAlias = "gbrtest"
            keyPassword = "android"
        }''')
        s=once(s,"buildTypes {","buildTypes {\n        debug { signingConfig = signingConfigs.debug }")
        return once(s,'?: "ca-app-pub-5674349229505017~2144672982"','?: "ca-app-pub-3940256099942544~3347511713"')
    edit("android/app/build.gradle",gradle)
    edit("android/app/src/main/AndroidManifest.xml",lambda s:once(s,'android:label="Math Challenge"','android:label="GBR '+label.upper()+' TEST"'))
    def manifest(s):
        s=once(s,'xmlns:android="http://schemas.android.com/apk/res/android"','xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools"')
        s=once(s,'<uses-permission android:name="android.permission.INTERNET"/>','')
        return once(s,"</manifest>","\n".join('    <uses-permission android:name="'+p+'" tools:node="remove"/>' for p in DENIED)+"\n</manifest>")
    edit("android/app/src/debug/AndroidManifest.xml",manifest)
    edit("android/app/src/main/res/values/strings.xml",lambda s:once(s,">783659889252<",">0<"))
    require(not (root/"android/key.properties").exists() and not (root/"android/local.properties").exists(),"Unexpected signing/local properties")
    dump(ev/"scratch-edits.json",changes)
    return package
def tool(sdk,name):
    ext=(".bat" if name=="apksigner" else ".exe") if os.name=="nt" else ""
    p=sdk/"build-tools"/"36.0.0"/(name+ext)
    require(p.is_file(),"Missing SDK tool "+str(p))
    return p
def build(label,ref,sdk,evidence,work,keep):
    root=work/label
    ev=evidence/label
    ev.mkdir()
    archive(ref,root)
    before={k:inventory(root,k) for k in ("lib","test/goldens","assets/fonts")}
    require(all(before.values()),"Empty source inventory")
    dump(ev/"source-inventory.json",before)
    lock=sha(root/"pubspec.lock")
    package=prepare(root,label,ev)
    env=dict(os.environ,GRADLE_USER_HOME=str(work/(label+"-gradle")),PUB_CACHE=str(work/(label+"-pub")))
    for key in list(env):
        if key.startswith("ORG_GRADLE_PROJECT_"): env.pop(key)
    # Prevent persistent Gradle/Kotlin workers from writing into deleted scratch caches.
    gradle_home=Path(env["GRADLE_USER_HOME"])
    gradle_home.mkdir()
    worker_config="org.gradle.daemon=false\nkotlin.compiler.execution.strategy=in-process\n"
    (gradle_home/"gradle.properties").write_text(worker_config,encoding="utf-8")
    (ev/"gradle-worker-config.txt").write_text(worker_config,encoding="utf-8")
    key=root/"android/app/gbr-test-debug.jks"
    cert=ev/"test-signing-cert.der"
    run(["keytool","-genkeypair","-keystore",key,"-storetype","JKS","-storepass","android","-keypass","android","-alias","gbrtest","-keyalg","RSA","-keysize","2048","-validity","365","-dname","CN=GBR "+label+" verification only"],root,env,ev/"keygen.log")
    run(["keytool","-exportcert","-keystore",key,"-storepass","android","-alias","gbrtest","-file",cert],root,env,ev/"keycert.log")
    digest=sha(cert)
    run(["flutter","pub","get","--enforce-lockfile"],root,env,ev/"pub-get.log")
    require(sha(root/"pubspec.lock")==lock,"Lockfile changed")
    cmd=["flutter","build","apk","--debug","--no-pub","--target","lib/main.dart","--dart-define=ADMOB_USE_TEST_ADS=false","--dart-define=ADMOB_BANNER_ID=","--dart-define=ADMOB_INTERSTITIAL_ID=","--dart-define=ADMOB_REWARDED_ID="]
    dump(ev/"build-input.json",{"source_sha":ref,"package":package,"command":cmd,"lock_sha256":lock,"certificate_sha256":digest,"signing":"ephemeral verification-only debug key"})
    run(cmd,root,env,ev/"build.log")
    require(before=={k:inventory(root,k) for k in before} and sha(root/"pubspec.lock")==lock,"Source inventory or lockfile changed")
    apk=root/"build/app/outputs/flutter-apk/app-debug.apk"
    require(apk.is_file(),"No APK")
    aapt=tool(sdk,"aapt2")
    badging=run([aapt,"dump","badging",apk],root,env,ev/"badging.txt")
    perms=run([aapt,"dump","permissions",apk],root,env,ev/"permissions.txt")
    manifest=run([aapt,"dump","xmltree",apk,"--file","AndroidManifest.xml"],root,env,ev/"manifest-tree.txt")
    sig=run([tool(sdk,"apksigner"),"verify","--verbose","--print-certs",apk],root,env,ev/"signature.txt")
    require("package: name='"+package+"'" in badging and "application-debuggable" in badging and "GBR "+label.upper()+" TEST" in badging,"Package/debug/label check failed")
    require(not any(x in perms for x in DENIED),"Forbidden APK permission")
    require("ca-app-pub-3940256099942544~3347511713" in manifest and "ca-app-pub-5674349229505017~2144672982" not in manifest,"Wrong AdMob app ID")
    require(re.search(r"allowBackup[^\n]*=(?:\(type 0x12\))?0x0(?:\s|$)",manifest) or re.search(r"allowBackup[^\n]*=false",manifest),"Backup isolation unverified")
    signer=re.search(r"Signer #1 certificate SHA-256 digest:\s*([a-fA-F0-9:]+)",sig)
    require(signer and signer.group(1).replace(":","").lower()==digest and "Number of signers: 1" in sig,"Signing certificate mismatch")
    result={"status":"BUILD_VERIFIED_NOT_DEVICE_VALIDATED","source_sha":ref,"package":package,"apk_sha256":sha(apk),"apk_bytes":apk.stat().st_size,"certificate_sha256":digest,"signing":"ephemeral debug verified","command":cmd,"lock_sha256":lock,"source_inventories_unchanged":True,"forbidden_permissions_absent":True,"backup_disabled":True}
    dump(ev/"result.json",result)
    if keep:
        dest=evidence.parent/"apks"
        dest.mkdir(exist_ok=True)
        target=dest/(label+"-"+ref[:12]+"-debug.apk")
        shutil.copyfile(apk,target)
        require(sha(target)==result["apk_sha256"],"APK copy mismatch")
    print(label+" verified "+result["apk_sha256"],flush=True)
    return result
def main():
    p=argparse.ArgumentParser()
    p.add_argument("--out",required=True,type=Path)
    p.add_argument("--keep-local-apks",action="store_true")
    a=p.parse_args()
    out=a.out.resolve()
    require(not out.exists(),"Use fresh output directory")
    require(not (os.environ.get("GITHUB_ACTIONS")=="true" and a.keep_local_apks),"CI APK retention forbidden")
    ev=out/"evidence"
    ev.mkdir(parents=True)
    try:
        sdk=Path(os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME") or "")
        require(sdk.is_absolute() and sdk.is_dir(),"Set ANDROID_SDK_ROOT or ANDROID_HOME")
        for comp in COMPONENTS: require((sdk/comp/"source.properties").is_file(),"Missing "+comp)
        version=json.loads(run(["flutter","--version","--machine"]))
        require(version["frameworkVersion"]=="3.47.5" and version["frameworkRevision"]=="6a19cca56475dbfba1478ee68d7bd0c2ef891da1" and version["engineRevision"]=="af7e796e161ae0bb1ff0758c71a7105418bd9ded" and version["dartSdkVersion"].startswith("3.13.4"),"SDK pin mismatch")
        java=run(["java","-version"])
        require(re.search(r'version "17(?:[."]|$)',java),"JDK 17 required")
        dump(ev/"environment.json",{"flutter":version,"java":java,"platform":sys.platform,"sdk_components":{p:(sdk/p/"source.properties").read_text() for p in COMPONENTS},"gradle_expected":"8.14","source_shas":SHAS,"note":"Toolchain record, not bit-identical build claim."})
        work=Path(tempfile.mkdtemp(prefix="gbr-android-"))
        try:
            results={label:build(label,ref,sdk,ev,work,a.keep_local_apks) for label,ref in SHAS.items()}
        finally:
            # Single-use workers can still be exiting. Retry bounded cleanup;
            # never report successful cleanup if any scratch files remain.
            cleanup_errors=[]
            for attempt in range(6):
                try:
                    if work.exists(): shutil.rmtree(work)
                    if not work.exists(): break
                except OSError as exc:
                    cleanup_errors.append(str(exc))
                if attempt<5: time.sleep(2)
            dump(ev/"cleanup.json",{"removed":not work.exists(),"errors":cleanup_errors})
            require(not work.exists(),"Scratch cleanup failed; no successful batch or usable partial pair")
        require(results["baseline"]["package"]!=results["candidate"]["package"],"Package isolation failed")
        dump(ev/"batch-result.json",{"status":"BUILDS_VERIFIED_NOT_DEVICE_VALIDATED","results":results,"apk_retention":"local only" if a.keep_local_apks else "discarded after CI verification","golden_authority":"UNCHANGED","physical_android":"PENDING","owner_acceptance":"PENDING","cloud_scenes":"UNRESOLVED; safe fixture route separately authorized if unreachable"})
    except Exception as exc:
        if (out/"apks").exists(): shutil.rmtree(out/"apks")
        dump(ev/"blocker.json",{"status":"BLOCKED","error":str(exc)})
        raise
if __name__=="__main__":
    main()
