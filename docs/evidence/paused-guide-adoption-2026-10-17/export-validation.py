from pathlib import Path
import subprocess,tarfile,io,tempfile,hashlib,json
root=Path(subprocess.check_output(['git','rev-parse','--show-toplevel'],text=True).strip())
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
w=Path(tempfile.mkdtemp(prefix='starfall-production-guide-'))
with tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['git','archive',head],cwd=root))) as archive:
 for member in archive:
  if member.isdir():continue
  if not member.isfile() or Path(member.name).is_absolute() or '..' in Path(member.name).parts: raise RuntimeError(member.name)
  p=w/member.name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(archive.extractfile(member).read());p.chmod(member.mode)
owned=['App/FallingSkyView.swift','App/FallingSkyStore.swift','UITests/FallingSkyInteractionTests.swift','UITests/ObservatoryInteractionTests.swift']
for name in owned:(w/name).write_bytes((root/name).read_bytes())
p=w/'Config/Clean.xcconfig';s=p.read_text();a='PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype';assert s.count(a)==1;p.write_text(s.replace(a,'PRODUCT_BUNDLE_IDENTIFIER = com.starfall.validation.guide\nINFOPLIST_KEY_CFBundleDisplayName = Guide Review'))
files={}
for folder in ['App','AppTests','UITests','Sources','Config','Starfall.xcodeproj']:
 for p in (w/folder).rglob('*'):
  if p.is_file():files[str(p.relative_to(w))]=hashlib.sha256(p.read_bytes()).hexdigest()
meta={'head':head,'workspace':str(w),'overlaid':owned,'rootDirtyStatus':subprocess.check_output(['git','status','--short'],cwd=root,text=True),'bundle':'com.starfall.validation.guide','files':files}
(w/'GUIDE-VALIDATION-SOURCE.json').write_text(json.dumps(meta,indent=2,sort_keys=True)+'\n')
print(w)
