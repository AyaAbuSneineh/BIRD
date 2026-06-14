					 // ============================================================
// BIRD Transaction

`ifndef BIRD_TRANSACTION_SV
`define BIRD_TRANSACTION_SV

class bird_transaction;

  // Traffic type values
 
    typedef enum bit {
    LOCAL_TRAFFIC  = 1'b0,
    REMOTE_TRAFFIC = 1'b1
  } traffic_type_e;

  // Basic transaction fields
  traffic_type_e traffic_type;

  // Payload bytes for this packet/fragment
  byte unsigned payload[$];

  logic [15:0] input_crc;

  // cfg fields
  logic [7:0] payload_len;
  logic [4:0] frag_num;
  logic [4:0] seq_num;

  logic [31:0] cfg;

  logic [31:0] cfg_error_mask;

  string name ;

  // Constructor
  function new(string name = "bird_transaction");
    this.name           = name;

    this.traffic_type   = LOCAL_TRAFFIC;
    this.payload.delete();

    this.input_crc      = 16'h0000;

    this.payload_len    = 8'd0;
    this.frag_num       = 5'd0;
    this.seq_num        = 5'd0;

    this.cfg            = 32'h0000_0000;
    this.cfg_error_mask = 32'h0000_0000;
  endfunction

  function void build_cfg();
    logic [31:0] c;

    c = 32'h0000_0000;

    c[0]     = traffic_type;
    c[15:8]  = payload_len;
    c[20:16] = frag_num;
    c[28:24] = seq_num;

    // Used later for invalid cfg tests.
    c = c | cfg_error_mask;

    cfg = c;
  endfunction

  // Configure this transaction as a valid local packet
  
   function void set_valid_local(
    input byte unsigned payload_bytes[$],
    input logic [15:0]  crc_value = 16'h1234
  );
    traffic_type = LOCAL_TRAFFIC;

    payload.delete();
    foreach (payload_bytes[i]) begin
      payload.push_back(payload_bytes[i]);
    end

    payload_len = payload.size();
    frag_num    = 5'd1;
    seq_num     = 5'd1;
    input_crc   = crc_value;

    cfg_error_mask = 32'h0000_0000;

    build_cfg();
  endfunction

  // Configure this transaction as a remote fragment
  function void set_remote_fragment(
    input byte unsigned payload_bytes[$],
    input logic [4:0]   fragment_number,
    input logic [4:0]   sequence_number,
    input logic [15:0]  crc_value = 16'h0000
  );
    traffic_type = REMOTE_TRAFFIC;

    payload.delete();
    foreach (payload_bytes[i]) begin
      payload.push_back(payload_bytes[i]);
    end

    payload_len = payload.size();
    frag_num    = fragment_number;
    seq_num     = sequence_number;
    input_crc   = crc_value;

    cfg_error_mask = 32'h0000_0000;

    build_cfg();
  endfunction

  function byte unsigned crc_byte_1();
    return input_crc[15:8];
  endfunction

  function byte unsigned crc_byte_2();
    return input_crc[7:0];
  endfunction


  // Print transaction information

  function void print();
    $display("--------------------------------------------------");
    $display("Transaction name : %s", name);
    $display("traffic_type     : %s",
             (traffic_type == LOCAL_TRAFFIC) ? "LOCAL" : "REMOTE");
    $display("payload_len      : %0d", payload_len);
    $display("frag_num         : %0d", frag_num);
    $display("seq_num          : %0d", seq_num);
    $display("input_crc        : 0x%04h", input_crc);
    $display("cfg              : 0x%08h", cfg);

    $write("payload          : ");
    foreach (payload[i]) begin
      $write("%02h ", payload[i]);
    end
    $write("\n");

    $display("--------------------------------------------------");
  endfunction

endclass

`endif
