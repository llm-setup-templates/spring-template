#!/bin/bash
# rtm-lint — RTM(docs/requirements/RTM.md) 무결성 검사
# validate.sh의 V_rtm 절이 호출한다. 단독 실행: bash scripts/rtm-lint.sh <repo-root> [rtm-file]
# 이 검사는 템플릿 저작 검증 층이다(생성 프로젝트에는 포함되지 않음 — scaffold가 validate.sh를 제거하는 것은 설계).
#
# 열 인식: 헤더 행(필수 열 FR ID/Summary/Component(s)/Test(s)/Status를 전부 가진 첫 표 행)에서
#   열 이름으로 인덱스를 찾는다(헤더 구동). "FR ID"만 보면 문서 상단의 안내 표가 가로챈다.
#   따라서 10열(spring, python — Owner 포함)과 11열(typescript — Screen 포함) RTM을
#   같은 스크립트가 처리하고, Screen 열은 존재할 때만 검사한다(자동 감지).
#   단일 표 전제(NFR 행 통합 스키마). 분리된 구표(별도 NFR 표)는 첫 헤더 기준으로 읽힌다.
#
# 출력 규약: VIOLATION은 exit 1을 만든다. WARN은 exit에 반영되지 않는다(정보성).
#   WARN은 하나뿐이다 — unknown-status(알 수 없는 상태 표기, 행이 게이트 밖임을 알림).
#
# 검사하는 것:
#   1. FR와 NFR ID 형식 (FR-{DOMAIN}-{NNN}, NFR-{CATEGORY}-{NNN}, 3자리)과 ID 중복
#   2. 행의 셀 수가 "그 행이 속한 표의 헤더"와 일치하는가 — 불일치 행은 VIOLATION 후
#      나머지 검사 생략 (셀 안 파이프가 열을 밀어 게이트를 회피하는 경로를 차단.
#      표가 여러 개면 표별 헤더 기준이라 열 수가 다른 별도 표는 오탐 없음)
#   3. FR 표 블록 안에 있으나 ID로 파싱되지 않는 데이터 행 — VIOLATION unparsed-row
#      (볼드 ID 등 서식 장식으로 행이 비가시화되는 경로를 차단)
#   4. 상태별 완성도 게이트 (방안 18) — 상태 비교는 대소문자 무시(표기 규범은 Title Case):
#      Draft, Design   - ID, Summary, Status만 필수. 경로 요구 없음
#      Implementing    - 경로 선택(부분 허용). 기입된 백틱 경로만 실재성 검사
#      Done            - Component와 Test에 백틱 경로 각 1개 이상 필수 + 실재성 검사
#      Deprecated      - Draft 수준. 경로 실재성 면제, 단 위생 검사(절대경로, 상위 이탈)는 적용
#      그 외 상태      - 게이트 미적용, WARN만 (상태 어휘 자체는 검사하지 않음)
#      공통 원칙: 어느 상태든 "쓴 경로는 실재해야 한다"(Deprecated는 실재성만 면제).
#   5. 경로 규칙: Component와 Test 셀의 백틱 경로만 검사(다른 셀의 백틱은 무시).
#      절대경로 거부, 상위 이탈(..) 거부, 파일만 인정(-f, 디렉토리 거부)
#   6. Test 셀의 TC 토큰 형식 (TC-{DOMAIN}-{NNN}) - 토큰이 있을 때만
#   7. Screen 열이 있으면(typescript) 값 형식 {DEVICE}-{AREA}-{SCREEN}-{NN}
#      (대문자 세그먼트 3개 + 2자리 숫자, 쉼표 복수 허용). n/a 허용. 열이 없으면 건너뜀
#   8. <!-- --> 주석 블록 안의 행(예시 행 포함)은 검사 대상에서 제외
#
# 지원하지 않는 것 (파싱 한계 — 다른 표기를 쓰라):
#   - 표 셀 안의 파이프 문자(이스케이프 \| 포함) — 열 수 불일치로 거부된다(검사 2).
#     경로나 요약에 파이프가 필요하면 파이프 없는 표기로 바꿔라
#   - 이중 백틱(``...``) 코드 스팬 — 단일 백틱만 파싱
#   - 헤더 열 이름 변경(예: Component(s)를 Components로) — 필수 열을 전부 가진 표 행이
#     없으면 VIOLATION rtm-header-not-found로 실패한다(exit 1). 조용히 꺼지지 않는다.
#     검사를 끄려면 validate.sh의 V_rtm 호출 줄을 지운다(RTM.md 파일 자체가 없으면 SKIP exit 0)
#   - FR/NFR 행을 가진 표가 여러 개일 때: 셀 수 검증은 표별 헤더 기준(오탐 없음)이나,
#     열 의미(Status, Component 등 위치)는 첫 "FR ID" 표의 헤더 기준으로 읽힌다 —
#     헤더 구성이 다른 두 번째 표의 행은 게이트가 부정확(unknown-status WARN 등).
#     FR/NFR 행은 한 표에 모으는 것을 권장
#
# 검사하지 않는 것 (이 검사의 통과가 아래를 보증하지 않는다):
#   - Status 어휘 오타 (알 수 없는 상태는 게이트 미적용 WARN만. 대소문자 변형은 수용)
#   - TC ID의 중복
#   - 백틱 없이 맨 텍스트로 적힌 경로
#   - ADR, Issue, API(operationId), Owner 열 값의 실재성과 유효성
#   - Screen 약어가 실제 화면정의서와 대응하는지 (형식만 검사)
#   - 도메인 접두사가 RTM 상단 Domain prefixes 표에 등재됐는지
#   - RTM 밖 문서(DFD, 브리핑 템플릿 등)의 FR 참조 드리프트
#   - 코드 PR에서 RTM을 갱신하지 않는 것 - "같은 PR 갱신" 규율은 여전히 사람의 몫이다
# 주의: 경로 실재성은 로컬(대소문자 무시 FS)과 CI(민감)가 다를 수 있어 로컬 green, CI red 가능.

set -u
ROOT="${1:?usage: rtm-lint.sh <repo-root> [rtm-file]}"
RTM="${2:-$ROOT/docs/requirements/RTM.md}"
BT=$(printf '\140')
fail=0
warn=0

[ -f "$RTM" ] || { echo "V_rtm SKIP: no RTM at $RTM"; exit 0; }

# 주석 블록(<!-- -->) 제거, CR 제거
stripped=$(/usr/bin/awk '
  BEGIN { inc = 0 }
  {
    line = $0
    out = ""
    while (length(line) > 0) {
      if (inc == 0) {
        s = index(line, "<!--")
        if (s == 0) { out = out line; line = "" }
        else {
          out = out substr(line, 1, s - 1)
          line = substr(line, s + 4)
          e = index(line, "-->")
          if (e > 0) { line = substr(line, e + 3) } else { line = ""; inc = 1 }
        }
      } else {
        e = index(line, "-->")
        if (e > 0) { line = substr(line, e + 3); inc = 0 } else { line = "" }
      }
    }
    gsub(/\r$/, "", out)
    print out
  }' "$RTM")

# 헤더 = 필수 열을 "전부" 가진 첫 표 행. "FR ID"만 보면 How to use 안내 표가 가로챈다.
header=$(echo "$stripped" | /usr/bin/awk -F'|' '
  /^\|/ {
    have_id = have_sum = have_comp = have_test = have_stat = 0
    for (i = 1; i <= NF; i++) {
      f = $i; gsub(/^[[:space:]]+|[[:space:]]+$/, "", f)
      if (f == "FR ID")        have_id = 1
      if (f == "Summary")      have_sum = 1
      if (f == "Component(s)") have_comp = 1
      if (f == "Test(s)")      have_test = 1
      if (f == "Status")       have_stat = 1
    }
    if (have_id && have_sum && have_comp && have_test && have_stat) { print; exit }
  }')
# 데이터 행에 "그 행이 속한 표의 헤더 셀 수"를 탭으로 태깅 (표마다 열 수가 달라도 오탐 없게)
rows=$(echo "$stripped" | /usr/bin/awk -F'|' '
  {
    is_tbl = ($0 ~ /^\|/)
    if (is_tbl && !prev_tbl) { curnf = NF }   # 각 표의 첫 행 = 그 표의 헤더
    if (is_tbl && $0 ~ /^\|[[:space:]]*N?FR-/) {
      if (curnf == 0) curnf = NF
      print curnf "\t" $0
    }
    prev_tbl = is_tbl
  }')

# RTM 파일이 존재하는데 유효 헤더가 없으면 위반이다. 조용한 skip은 거짓 초록을 만든다.
# (파일 자체가 없을 때만 SKIP exit 0 — 위의 -f 검사가 그 경우다)
[ -z "$header" ] && {
  echo "VIOLATION rtm-header-not-found: no table header carrying all of FR ID/Summary/Component(s)/Test(s)/Status"
  exit 1
}

col() { # 열 이름 -> awk 필드 번호 (없으면 빈 문자열)
  echo "$header" | /usr/bin/awk -F'|' -v name="$1" '
    { for (i = 1; i <= NF; i++) { f = $i
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", f)
        if (f == name) { print i; exit } } }'
}
ID_I=$(col "FR ID"); SUM_I=$(col "Summary"); COMP_I=$(col "Component(s)")
TEST_I=$(col "Test(s)"); STAT_I=$(col "Status"); SCREEN_I=$(col "Screen")
# 필수 열은 헤더 감지에서 이미 보장된다(전부 있는 행만 header가 된다).

# 검사 3: FR 표 블록의 미파싱 데이터 행 (헤더 다음부터 표가 끝날 때까지)
while IFS= read -r bad; do
  [ -z "$bad" ] && continue
  echo "VIOLATION unparsed-row: ${bad:0:60}"; fail=1
done < <(echo "$stripped" | /usr/bin/awk -v hdr="$header" '
  $0 == hdr { inblk = 1; next }
  inblk {
    if ($0 !~ /^\|/) { inblk = 0; next }
    if ($0 ~ /^[|:[:space:]-]+$/) next
    if ($0 ~ /^\|[[:space:]]*N?FR-/) next
    print
  }')

# 행 0건 판정은 검사 3 뒤에 둔다 — 표 블록에 미파싱 위반 행만 있는 경우를 NOTE로 놓치지 않게
if [ -z "$rows" ]; then
  [ "$fail" -eq 0 ] && echo "V_rtm NOTE: no FR/NFR rows found (empty RTM is valid)"
  exit $fail
fi

declare -A seen_ids
trim() { echo "$1" | /usr/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
field() { echo "$2" | /usr/bin/awk -F'|' -v i="$1" '{print $i}'; }

while IFS= read -r tagged; do
  [ -z "$tagged" ] && continue
  tbl_nf=${tagged%%$'\t'*}
  row=${tagged#*$'\t'}
  id=$(trim "$(field "$ID_I" "$row")")
  summary=$(trim "$(field "$SUM_I" "$row")")

  # 1. ID 형식과 중복 (첫 셀은 열 밀림과 무관하므로 먼저 검사)
  echo "$id" | /usr/bin/grep -qE '^(FR|NFR)-[A-Z]+-[0-9]{3}$' \
    || { echo "VIOLATION id-format: '$id'"; fail=1; }
  if [ -n "${seen_ids[$id]:-}" ]; then
    echo "VIOLATION id-duplicate: $id"; fail=1
  else
    seen_ids[$id]=1
  fi
  [ -n "$summary" ] || { echo "VIOLATION empty-summary: $id"; fail=1; }

  # 2. 셀 수 검증 — 행이 속한 표의 헤더와 비교(표가 여러 개라도 오탐 없음).
  #    불일치면 열이 밀린 것(셀 안 파이프 등). 오파싱 연쇄 방지 위해 중단
  row_nf=$(echo "$row" | /usr/bin/awk -F'|' '{print NF}')
  if [ "$row_nf" -ne "$tbl_nf" ]; then
    echo "VIOLATION column-count ($id): expected $((tbl_nf-2)) cells, found $((row_nf-2)) - pipe inside a cell?"
    fail=1
    continue
  fi

  comp_cell=$(field "$COMP_I" "$row")
  test_cell=$(field "$TEST_I" "$row")
  status=$(trim "$(field "$STAT_I" "$row")")
  status=${status//$BT/}

  # 4. 상태별 게이트 분기 (대소문자 무시 — 표기 규범은 Title Case)
  status_lc=$(echo "$status" | /usr/bin/tr '[:upper:]' '[:lower:]')
  case "$status_lc" in
    draft|design|implementing|done|deprecated) gate="$status_lc" ;;
    *) echo "WARN unknown-status ($id): '$status' - row not gated"; warn=$((warn+1)); gate="unknown" ;;
  esac

  # 5. 경로 추출과 검사 (Component와 Test 셀만, 공백 경로 안전한 while read)
  comp_cnt=0; test_cnt=0
  for which in comp test; do
    if [ "$which" = comp ]; then cell="$comp_cell"; else cell="$test_cell"; fi
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      if [ "$which" = comp ]; then comp_cnt=$((comp_cnt+1)); else test_cnt=$((test_cnt+1)); fi
      # 위생 검사(절대경로, 상위 이탈)는 Deprecated에도 적용
      case "$p" in
        /*|[A-Za-z]:*) echo "VIOLATION path-absolute ($id): $p"; fail=1; continue ;;
      esac
      case "/$p/" in
        */../*) echo "VIOLATION path-escape ($id): $p"; fail=1; continue ;;
      esac
      [ "$gate" = "deprecated" ] && continue   # 폐기 행은 실재성만 면제
      if [ -d "$ROOT/$p" ]; then
        echo "VIOLATION path-is-directory ($id): $p"; fail=1
      elif [ ! -f "$ROOT/$p" ]; then
        echo "VIOLATION path-missing ($id): $p"; fail=1
      fi
    done < <(echo "$cell" | /usr/bin/grep -oE "${BT}[^${BT}]+${BT}" | /usr/bin/tr -d "$BT")
  done

  # Done 필수 열 게이트
  if [ "$gate" = "done" ]; then
    [ "$comp_cnt" -ge 1 ] || { echo "VIOLATION done-missing-component-path: $id"; fail=1; }
    [ "$test_cnt" -ge 1 ] || { echo "VIOLATION done-missing-test-path: $id"; fail=1; }
  fi

  # 6. Test 셀의 TC 토큰 형식 (백틱 스팬 제거 후 검사)
  nocode=$(echo "$test_cell" | /usr/bin/sed "s/${BT}[^${BT}]*${BT}//g")
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
    echo "$tok" | /usr/bin/grep -qE '^TC-[A-Z]+-[0-9]{3}$' \
      || { echo "VIOLATION tc-format ($id): $tok"; fail=1; }
  done < <(echo "$nocode" | /usr/bin/grep -oE 'TC-[[:alnum:]_-]+' || true)

  # 7. Screen 열 형식 (열이 있을 때만 — typescript 프로파일 자동 감지)
  if [ -n "$SCREEN_I" ]; then
    sc=$(trim "$(field "$SCREEN_I" "$row")")
    sc=${sc//$BT/}
    if [ -n "$sc" ] && [ "$sc" != "n/a" ] && [ "$sc" != "—" ] && [ "$sc" != "-" ]; then
      IFS=',' read -ra toks <<< "$sc"
      for tok in "${toks[@]}"; do
        tok=$(trim "$tok")
        [ -z "$tok" ] && continue
        echo "$tok" | /usr/bin/grep -qE '^[A-Z]+-[A-Z]+-[A-Z]+-[0-9]{2}$' \
          || { echo "VIOLATION screen-format ($id): $tok"; fail=1; }
      done
    fi
  fi
done <<< "$rows"

if [ "$fail" -eq 0 ]; then
  echo "V_rtm PASS (warnings: $warn)"
fi
exit $fail
