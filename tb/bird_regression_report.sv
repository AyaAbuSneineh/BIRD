`timescale 1ns/1ps
// ============================================================
// BIRD Regression Report Helper
// ------------------------------------------------------------
// This helper records one PASS/FAIL line per test run and prints a
// final regression summary at the end of sim/regression.do.
//
// It uses plain SystemVerilog file I/O so the summary is generated
// inside Active-HDL, not by PowerShell.
// ============================================================

`ifndef BIRD_REGRESSION_REPORT_SV
`define BIRD_REGRESSION_REPORT_SV

class bird_regression_report;

  // Keep this absolute path aligned with sim/regression.do.
  static function string get_results_file();
    return "C:/Users/msi/Desktop/DV_VS/sim/regression_results.txt";
  endfunction


  // ------------------------------------------------------------
  // Clear previous regression results
  // ------------------------------------------------------------
  static function void clear_results();
    int fd;
    string results_file;

    results_file = get_results_file();
    fd = $fopen(results_file, "w");

    if (fd == 0) begin
      $error("[%0t] bird_regression_report: could not clear %s",
             $time, results_file);
      return;
    end

    $fclose(fd);

    $display("========================================");
    $display(" Cleared regression result file:");
    $display(" %s", results_file);
    $display("========================================");
  endfunction


  // ------------------------------------------------------------
  // Record one test result
  // ------------------------------------------------------------
  static function void record_result(
    input string test_name,
    input int    fail_count
  );
    int fd;
    string result;
    string results_file;

    results_file = get_results_file();
    result = (fail_count == 0) ? "PASS" : "FAIL";

    fd = $fopen(results_file, "a");

    if (fd == 0) begin
      $error("[%0t] bird_regression_report: could not append to %s",
             $time, results_file);
      return;
    end

    $fdisplay(fd, "%s %s", result, test_name);
    $fclose(fd);

    $display("========================================");
    $display(" REGRESSION RECORDED: %s %s", result, test_name);
    $display("========================================");
  endfunction


  // ------------------------------------------------------------
  // Print final summary
  // ------------------------------------------------------------
  static function void print_summary();
    int fd;
    int scan_count;
    int total_tests;
    int passed_tests;
    int failed_tests;

    string result;
    string test_name;
    string results_file;
    string failed_names[$];

    results_file = get_results_file();
    fd = $fopen(results_file, "r");

    if (fd == 0) begin
      $error("[%0t] bird_regression_report: could not open %s",
             $time, results_file);
      return;
    end

    total_tests  = 0;
    passed_tests = 0;
    failed_tests = 0;

    while (!$feof(fd)) begin
      result = "";
      test_name = "";
      scan_count = $fscanf(fd, "%s %s\n", result, test_name);

      if (scan_count == 2) begin
        total_tests++;

        if (result == "PASS") begin
          passed_tests++;
        end
        else if (result == "FAIL") begin
          failed_tests++;
          failed_names.push_back(test_name);
        end
      end
    end

    $fclose(fd);

    $display("============================================================");
    $display(" BIRD REGRESSION SUMMARY");
    $display("============================================================");
    $display(" Total tests  : %0d", total_tests);
    $display(" Passed tests : %0d", passed_tests);
    $display(" Failed tests : %0d", failed_tests);

    if (failed_tests == 0) begin
      $display(" Failed list  : none");
    end
    else begin
      $display(" Failed list:");
      foreach (failed_names[i]) begin
        $display("   %s", failed_names[i]);
      end
    end

    $display("============================================================");
  endfunction

endclass


// ============================================================
// Regression Summary Top
// ------------------------------------------------------------
// Run with:
//   asim DV.regression_summary_top +SUMMARY_MODE=clear
//   asim DV.regression_summary_top +SUMMARY_MODE=print
// ============================================================
module regression_summary_top;

  initial begin
    string mode;

    if (!$value$plusargs("SUMMARY_MODE=%s", mode)) begin
      mode = "print";
    end

    if (mode == "clear") begin
      bird_regression_report::clear_results();
    end
    else begin
      bird_regression_report::print_summary();
    end

    $finish;
  end

endmodule

`endif
