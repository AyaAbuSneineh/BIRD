#!/bin/bash

cd "$(dirname "$0")/.." || exit 1

COV_METRICS="line+cond+tgl+fsm+branch"

COV_DB="cov/vcs_cov.vdb"
URG_REPORT="cov/urg_report"

SUMMARY_DIR="logs/vcs_cov_all"
DIRECTED_DIR="logs/vcs_cov_directed"
RANDOM_DIR="logs/vcs_cov_random"
EXTRA_DIR="logs/vcs_cov_extra"

SUMMARY_FILE="$SUMMARY_DIR/summary.txt"
TEST_LIST_FILE="$SUMMARY_DIR/test_list.txt"

mkdir -p "$SUMMARY_DIR" "$DIRECTED_DIR" "$RANDOM_DIR" "$EXTRA_DIR" cov

rm -f "$SUMMARY_FILE" "$TEST_LIST_FILE"
rm -rf "$COV_DB" "$URG_REPORT"
rm -rf simv_cov simv_cov.daidir csrc ucli.key

echo "============================================================"
echo " BIRD FULL CODE COVERAGE RUN - CLEAN SCRIPT"
echo "============================================================"

# ------------------------------------------------------------
# Extract tests from tb_top
# ------------------------------------------------------------
grep -oE 'testname[[:space:]]*==[[:space:]]*"[^"]+"' top/tb_top.sv \
  | sed -E 's/.*"([^"]+)".*/\1/' \
  | awk '!seen[$0]++' \
  > "$TEST_LIST_FILE"

echo "Tests found in tb_top:"
cat "$TEST_LIST_FILE"
echo "Total tb_top tests: $(wc -l < "$TEST_LIST_FILE")"

if [ ! -s "$TEST_LIST_FILE" ]; then
  echo "ERROR: no tests found in top/tb_top.sv"
  exit 1
fi

# ------------------------------------------------------------
# Compile with code coverage
# ------------------------------------------------------------
echo "============================================================"
echo " Compile with code coverage"
echo "============================================================"

vcs -full64 \
  -sverilog \
  -timescale=1ns/1ps \
  -debug_access+all \
  -cm "$COV_METRICS" \
  -cm_dir "$COV_DB" \
  -f sim/filelist.f \
  -l "$SUMMARY_DIR/compile_cov.log" \
  -o simv_cov

if [ $? -ne 0 ]; then
  echo "ERROR: coverage compile failed"
  echo "Check: $SUMMARY_DIR/compile_cov.log"
  exit 1
fi

# ------------------------------------------------------------
# Summary header
# ------------------------------------------------------------
echo "============================================================" > "$SUMMARY_FILE"
echo "BIRD FULL CODE COVERAGE SUMMARY" >> "$SUMMARY_FILE"
echo "============================================================" >> "$SUMMARY_FILE"

pass=0
fail=0
noresult=0
test_total=0
cov_only_total=0

run_test_and_classify() {
  local t="$1"
  local log_file="$2"
  local cm_name="$3"
  local extra_plusargs="$4"

  test_total=$((test_total + 1))

  echo "------------------------------------------------------------"
  echo "Coverage run: $t"
  echo "------------------------------------------------------------"

  ./simv_cov +TESTNAME="$t" $extra_plusargs \
    -cm "$COV_METRICS" \
    -cm_dir "$COV_DB" \
    -cm_name "$cm_name" \
    -l "$log_file" \
    > /dev/null 2>&1

  sim_status=$?

  if grep -Eq "TEST RESULT[[:space:]]*:[[:space:]]*PASS" "$log_file"; then
    echo "$t : PASS" | tee -a "$SUMMARY_FILE"
    pass=$((pass + 1))

  elif grep -Eq "TEST RESULT[[:space:]]*:[[:space:]]*FAIL" "$log_file"; then
    echo "$t : FAIL" | tee -a "$SUMMARY_FILE"
    fail=$((fail + 1))

  else
    echo "$t : NO TEST RESULT FOUND / sim_status=$sim_status" | tee -a "$SUMMARY_FILE"
    noresult=$((noresult + 1))
  fi
}

# ------------------------------------------------------------
# Run directed tests
# ------------------------------------------------------------
while read -r t; do
  [ -z "$t" ] && continue

  # random_all_cases_test is run separately below
  if [ "$t" = "random_all_cases_test" ]; then
    continue
  fi

  run_test_and_classify \
    "$t" \
    "$DIRECTED_DIR/${t}.log" \
    "$t" \
    "+NUM_PER_CASE=${NUM_PER_CASE:-2}"

done < "$TEST_LIST_FILE"

# ------------------------------------------------------------
# tb_top coverage-only cases
# ------------------------------------------------------------
echo "============================================================"
echo " Running tb_top coverage-only cases"
echo "============================================================"

cov_only_total=$((cov_only_total + 1))
./simv_cov \
  -cm "$COV_METRICS" \
  -cm_dir "$COV_DB" \
  -cm_name "tbtop_no_plusarg_default" \
  -l "$EXTRA_DIR/tbtop_no_plusarg_default.log" \
  > /dev/null 2>&1
echo "tbtop_no_plusarg_default : DONE" | tee -a "$SUMMARY_FILE"

cov_only_total=$((cov_only_total + 1))
./simv_cov +TESTNAME=unknown_testname_for_coverage \
  -cm "$COV_METRICS" \
  -cm_dir "$COV_DB" \
  -cm_name "tbtop_unknown_testname" \
  -l "$EXTRA_DIR/tbtop_unknown_testname.log" \
  > /dev/null 2>&1
echo "tbtop_unknown_testname : DONE" | tee -a "$SUMMARY_FILE"

# ------------------------------------------------------------
# Run random_all_cases_test if present
# ------------------------------------------------------------
if grep -qx "random_all_cases_test" "$TEST_LIST_FILE"; then
  echo "============================================================"
  echo " Running random_all_cases_test"
  echo "============================================================"

  run_test_and_classify \
    "random_all_cases_test" \
    "$RANDOM_DIR/random_all_cases_test.log" \
    "random_all_cases_test" \
    "+NUM_PER_CASE=${NUM_PER_CASE:-2}"
fi

# ------------------------------------------------------------
# Generate URG report
# ------------------------------------------------------------
echo "============================================================"
echo " Generating URG report"
echo "============================================================"

urg -full64 \
  -dir "$COV_DB" \
  -format both \
  -report "$URG_REPORT" \
  -l "$SUMMARY_DIR/urg.log"

urg_status=$?

echo "============================================================" | tee -a "$SUMMARY_FILE"
echo "Coverage simulations run : $((test_total + cov_only_total))" | tee -a "$SUMMARY_FILE"
echo "Checked tests            : $test_total" | tee -a "$SUMMARY_FILE"
echo "Coverage-only runs       : $cov_only_total" | tee -a "$SUMMARY_FILE"
echo "PASS                     : $pass" | tee -a "$SUMMARY_FILE"
echo "FAIL                     : $fail" | tee -a "$SUMMARY_FILE"
echo "NO RESULT                : $noresult" | tee -a "$SUMMARY_FILE"
echo "URG status               : $urg_status" | tee -a "$SUMMARY_FILE"
echo "Report                   : $URG_REPORT/dashboard.html" | tee -a "$SUMMARY_FILE"
echo "============================================================" | tee -a "$SUMMARY_FILE"

echo ""
echo "Summary:"
echo "  $SUMMARY_FILE"
echo ""
echo "Coverage report:"
echo "  $URG_REPORT/dashboard.html"
echo ""
