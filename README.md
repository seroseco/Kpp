# K++ (Korean C++)
프로그래밍은 잘하는데 영어가 어렵다면?
K++로 한글 키워드를 C++ 코드로 변환해보세요.

## ✨ 기능
- `.kpp` 파일의 한글 키워드를 C++ 키워드로 변환
- 문자열/문자 리터럴, 주석 내부는 치환하지 않음
- 결과를 `.cpp` 파일로 출력
- `--run` 시 자주 쓰는 표준 헤더 누락을 자동으로 보정
- 컴파일 실패 시 한국어 오류와 `파일:줄:열` 위치 표시
- `kpp init` 으로 시작용 `.kpp` 템플릿 생성
- `--safe` 모드로 키워드 충돌(이름 겹침) 사전 감지

## 📁 데이터 구조
- `examples/kpp/` : K++ 원본 파일(`.kpp`)
- `generated/cpp/` : 변환된 C++ 파일(`.cpp`)
- `generated/bin/` : 컴파일된 실행 파일

## 🛠️ 빌드
```bash
./kpp --help
```

## 📦 설치(간단)
macOS/Linux:
```bash
./install.sh
```

Windows (PowerShell):
```powershell
.\install.ps1
```

Windows (CMD):
```bat
install.bat
```

설치 후:
```bash
kpp --help
```

## 💡 사용법
macOS/Linux:
```bash
./kpp examples/kpp/hello.kpp
g++ generated/cpp/hello.cpp -o generated/bin/hello
./generated/bin/hello
```

Windows (PowerShell/CMD):
```powershell
.\kpp.bat examples\kpp\hello.kpp
g++ generated\cpp\hello.cpp -o generated\bin\hello.exe
.\generated\bin\hello.exe
```

`./kpp`는 내부적으로 `kppc`가 없으면 자동으로 빌드한 뒤 변환합니다.
Windows에서는 `.\kpp.bat` 또는 `kpp`(설치 후)로 동일하게 사용할 수 있습니다.

한 번에 변환 + 컴파일 + 실행:
```bash
./kpp --run examples/kpp/hello.kpp
```

Windows:
```powershell
.\kpp.bat --run examples\kpp\hello.kpp
```

시작 파일 생성:
```bash
./kpp init
```

키워드 충돌 검사 모드:
```bash
./kpp --safe --run examples/kpp/hello.kpp
```

## ✅ 테스트
macOS/Linux:
```bash
./tests/run_all.sh
```

Windows에서는 동일한 테스트를 PowerShell용으로 추후 추가할 수 있고,
현재는 예제 실행으로 동작을 확인할 수 있습니다.

## 📚 문서
- 키워드 레퍼런스: `docs/KEYWORDS.md`
- 예제 가이드: `docs/EXAMPLES.md`
