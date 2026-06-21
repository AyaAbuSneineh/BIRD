`timescale 1ns/1ps
`ifndef BIRD_OUTPUT_ITEM_SV
`define BIRD_OUTPUT_ITEM_SV

typedef enum int {
  BIRD_OUT_LOCAL_BYTES,
  BIRD_OUT_REMOTE_WORDS,
  BIRD_OUT_LOCAL_ACTIVITY,
  BIRD_OUT_REMOTE_ACTIVITY
} bird_output_kind_e;

class bird_output_item;

  string name;
  bird_output_kind_e kind;

  byte unsigned local_q[$];
  logic [31:0]  remote_q[$];

  int activity_count;
  logic [15:0] drop_cnt;

  function new(string name = "bird_output_item");
    this.name = name;
    this.kind = BIRD_OUT_LOCAL_BYTES;
    this.activity_count = 0;
    this.drop_cnt = 16'd0;
  endfunction

  function void set_local_bytes(
    input byte unsigned q[$],
    input logic [15:0] drop_cnt
  );
    this.kind = BIRD_OUT_LOCAL_BYTES;
    this.local_q.delete();

    foreach (q[i]) begin
      this.local_q.push_back(q[i]);
    end

    this.drop_cnt = drop_cnt;
  endfunction

  function void set_remote_words(
    input logic [31:0] q[$],
    input logic [15:0] drop_cnt
  );
    this.kind = BIRD_OUT_REMOTE_WORDS;
    this.remote_q.delete();

    foreach (q[i]) begin
      this.remote_q.push_back(q[i]);
    end

    this.drop_cnt = drop_cnt;
  endfunction

  function void set_local_activity(
    input int activity_count,
    input logic [15:0] drop_cnt
  );
    this.kind = BIRD_OUT_LOCAL_ACTIVITY;
    this.activity_count = activity_count;
    this.drop_cnt = drop_cnt;
  endfunction

  function void set_remote_activity(
    input int activity_count,
    input logic [15:0] drop_cnt
  );
    this.kind = BIRD_OUT_REMOTE_ACTIVITY;
    this.activity_count = activity_count;
    this.drop_cnt = drop_cnt;
  endfunction

endclass

`endif
