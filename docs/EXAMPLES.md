# K++ 예제 가이드

원본 K++ 파일은 `examples/kpp/`에 있습니다.

## 예제 목록
- `hello.kpp` : Hello World
- `basic_io.kpp` : 기본 입력/출력
- `condition_loop.kpp` : `if/else` + `for`
- `vector_sort_unique.kpp` : `vector`, `sort`, `unique`
- `map_count.kpp` : `map`, `string`, `size`
- `try_catch.kpp` : `try/catch`, `throw`
- `class_basic.kpp` : `class`, 생성자, 멤버 함수

## 빠른 실행
```bash
./kpp --run examples/kpp/hello.kpp
```

Windows:
```powershell
.\kpp.bat --run examples\kpp\hello.kpp
```

## 시작 템플릿 만들기
```bash
./kpp init
./kpp --run main.kpp
```

## 키워드 충돌 방지 모드
```bash
./kpp --safe --run examples/kpp/hello.kpp
```

## 다른 예제 실행
```bash
./kpp --run examples/kpp/vector_sort_unique.kpp
```
