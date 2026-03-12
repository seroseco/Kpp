#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

assert_contains() {
  local text="$1"
  local expected="$2"
  if [[ "$text" != *"$expected"* ]]; then
    echo "[FAIL] expected output to contain: $expected" >&2
    echo "[INFO] actual output:" >&2
    echo "$text" >&2
    exit 1
  fi
}

run_and_capture() {
  local file="$1"
  ./kpp --safe --run "$file"
}

echo "[TEST] hello.kpp"
out="$(run_and_capture examples/kpp/hello.kpp)"
assert_contains "$out" "안녕 세상!"

echo "[TEST] vector_sort_unique.kpp"
out="$(run_and_capture examples/kpp/vector_sort_unique.kpp)"
assert_contains "$out" "정렬 + 중복제거 결과: 1 2 4 8"

echo "[TEST] map_count.kpp"
out="$(run_and_capture examples/kpp/map_count.kpp)"
assert_contains "$out" "apple: 5"
assert_contains "$out" "banana: 5"
assert_contains "$out" "키 개수: 2"

echo "[TEST] class_basic.kpp"
out="$(run_and_capture examples/kpp/class_basic.kpp)"
assert_contains "$out" "이름: Kim, 나이: 20"

echo "[TEST] try_catch.kpp"
out="$(run_and_capture examples/kpp/try_catch.kpp)"
assert_contains "$out" "예외: 0으로 나눌 수 없습니다"

echo "[TEST] condition_loop.kpp"
out="$(printf '4\n' | ./kpp --safe --run examples/kpp/condition_loop.kpp)"
assert_contains "$out" "2 는 짝수"
assert_contains "$out" "3 는 홀수"

echo "[TEST] basic_io.kpp"
out="$(printf '7 8\n' | ./kpp --safe --run examples/kpp/basic_io.kpp)"
assert_contains "$out" "합계: 15"

echo "[PASS] all example smoke tests passed"
