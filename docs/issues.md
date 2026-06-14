# BIRD Verification Known Issues

This file documents mismatches found between the expected behavior and the DUT behavior during verification.

---

## BUG_01: Remote payload length greater than 2 is not handled correctly

### Test Name

`remote_multi_byte_test`

### Test Description

This test sends one valid remote fragment with four payload bytes.

### Input Transaction

```text
traffic_type = REMOTE
payload_len  = 4
frag_num     = 1
seq_num      = 1
payload      = AA BB CC DD
input_crc    = 12 34
