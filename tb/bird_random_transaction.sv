`timescale 1ns/1ps
`ifndef BIRD_RANDOM_TRANSACTION_SV
`define BIRD_RANDOM_TRANSACTION_SV

class bird_random_transaction extends bird_transaction;

  rand bit        r_traffic_type;
  rand bit [7:0]  r_payload_len;
  rand bit [4:0]  r_frag_num;
  rand bit [4:0]  r_seq_num;
  rand bit [15:0] r_input_crc;
  rand byte unsigned r_payload[];

  constraint valid_random_packet_c {
    r_payload_len inside {[1:255]};
    r_frag_num    inside {[1:31]};
    r_seq_num     inside {[1:31]};

    r_payload.size() == r_payload_len;
  }
pwd
  constraint payload_byte_c {
    foreach (r_payload[i]) {
      r_payload[i] inside {[8'h00:8'hff]};
    }
  }

  constraint payload_len_dist_c {
    r_payload_len dist {
      [1:8]     := 70,
      [9:64]    := 20,
      [65:254]  := 8,
      255       := 2
    };
  }

  function new(string name = "bird_random_transaction");
    super.new(name);
  endfunction

  function void post_randomize();

    if (!$cast(traffic_type, r_traffic_type)) begin
      $fatal(1, "[%0t] bird_random_transaction: traffic_type cast failed",
             $time);
    end

    payload_len = r_payload_len;
    frag_num    = r_frag_num;
    seq_num     = r_seq_num;
    input_crc   = r_input_crc;

    payload.delete();

    foreach (r_payload[i]) begin
      payload.push_back(r_payload[i]);
    end

    cfg = {
      3'b000,          // [31:29] Reserved
      r_seq_num,       // [28:24] SEQ NUM
      3'b000,          // [23:21] Reserved
      r_frag_num,      // [20:16] FRAG NUM
      r_payload_len,   // [15:8]  PAYLOAD LEN
      7'b0000000,      // [7:1]   Reserved
      r_traffic_type   // [0]     TRAFFIC TYPE
    };

  endfunction

endclass

`endif
