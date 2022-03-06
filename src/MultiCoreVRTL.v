//========================================================================
// 1-Core Processor-Cache-Network
//========================================================================

`ifndef LAB5_MCORE_MULTI_CORE_V
`define LAB5_MCORE_MULTI_CORE_V

`include "vc/mem-msgs.v"
`include "vc/trace.v"

`include "lab5_mcore/MemNetVRTL.v"
`include "lab2_proc/ProcAltVRTL.v"
`include "lab3_mem/BlockingCacheAltVRTL.v"
`include "lab5_mcore/McoreDataCacheVRTL.v"

//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
// LAB TASK: Include components
//''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

module lab5_mcore_MultiCoreVRTL
(
  input  logic                       clk,
  input  logic                       reset,

  input  logic [c_num_cores-1:0][31:0] mngr2proc_msg,
  input  logic [c_num_cores-1:0]       mngr2proc_val,
  output logic [c_num_cores-1:0]       mngr2proc_rdy,

  output logic [c_num_cores-1:0][31:0] proc2mngr_msg,
  output logic [c_num_cores-1:0]       proc2mngr_val,
  input  logic [c_num_cores-1:0]       proc2mngr_rdy,

  output mem_req_16B_t                 imemreq_msg,
  output logic                         imemreq_val,
  input  logic                         imemreq_rdy,

  input  mem_resp_16B_t                imemresp_msg,
  input  logic                         imemresp_val,
  output logic                         imemresp_rdy,

  output mem_req_16B_t                 dmemreq_msg,
  output logic                         dmemreq_val,
  input  logic                         dmemreq_rdy,

  input  mem_resp_16B_t                dmemresp_msg,
  input  logic                         dmemresp_val,
  output logic                         dmemresp_rdy,

  //  Only takes Core 0's stats_en to the interface
  output logic                         stats_en,
  output logic [c_num_cores-1:0]       commit_inst,
  output logic [c_num_cores-1:0]       icache_miss,
  output logic [c_num_cores-1:0]       icache_access,
  output logic [c_num_cores-1:0]       dcache_miss,
  output logic [c_num_cores-1:0]       dcache_access
);

  localparam c_num_cores = 4;

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Instantiate modules and wires
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  // Wires
  mem_req_16B_t  [c_num_cores-1:0]  imemreq_msg4; // Cpnnect MemNet and Main Memory
  logic          [c_num_cores-1:0]  imemreq_val4; // Cpnnect MemNet and Main Memory
  logic          [c_num_cores-1:0]  imemreq_rdy4; // Cpnnect MemNet and Main Memory

  mem_resp_16B_t [c_num_cores-1:0]  imemresp_msg4; // Cpnnect MemNet and Main Memory
  logic          [c_num_cores-1:0]  imemresp_val4; // Cpnnect MemNet and Main Memory
  logic          [c_num_cores-1:0]  imemresp_rdy4; // Cpnnect MemNet and Main Memory

  mem_req_4B_t   [c_num_cores-1:0]  icache_req_msg; // Connect ICache and Processor
  logic          [c_num_cores-1:0]  icache_req_val; // Connect ICache and Processor
  logic          [c_num_cores-1:0]  icache_req_rdy; // Connect ICache and Processor

  mem_resp_4B_t  [c_num_cores-1:0]  icache_resp_msg; // Connect ICache and Processor
  logic          [c_num_cores-1:0]  icache_resp_val; // Connect ICache and Processor
  logic          [c_num_cores-1:0]  icache_resp_rdy; // Connect ICache and Processor

  mem_req_4B_t   [c_num_cores-1:0]  dcache_req_msg; // Connect DCache and Processor
  logic          [c_num_cores-1:0]  dcache_req_val; // Connect DCache and Processor
  logic          [c_num_cores-1:0]  dcache_req_rdy; // Connect DCache and Processor

  mem_resp_4B_t  [c_num_cores-1:0]  dcache_resp_msg; // Connect DCache and Processor
  logic          [c_num_cores-1:0]  dcache_resp_val; // Connect DCache and Processor
  logic          [c_num_cores-1:0]  dcache_resp_rdy; // Connect DCache and Processor

  mem_req_16B_t  [c_num_cores-1:0]  icache_mem_req_msg; // Connect MemNet and ICache
  logic          [c_num_cores-1:0]  icache_mem_req_val; // Connect MemNet and ICache
  logic          [c_num_cores-1:0]  icache_mem_req_rdy; // Connect MemNet and ICache

  mem_resp_16B_t [c_num_cores-1:0]  icache_mem_resp_msg; // Connect MemNet and ICache
  logic          [c_num_cores-1:0]  icache_mem_resp_val; // Connect MemNet and ICache
  logic          [c_num_cores-1:0]  icache_mem_resp_rdy; // Connect MemNet and ICache
  
  logic          [c_num_cores-1:0][31:0] numbers;
  logic          [c_num_cores-1:0]  stats_en_wire; // Take stats_en, only care about 0's

  // MemNet


  lab5_mcore_MemNetVRTL mnet
  (
    .clk(clk),
    .reset(reset),

    .memreq_msg(icache_mem_req_msg), // ICache
    .memreq_val(icache_mem_req_val), // ICache
    .memreq_rdy(icache_mem_req_rdy), // ICache

    .memresp_msg(icache_mem_resp_msg), // ICache
    .memresp_val(icache_mem_resp_val), // ICache
    .memresp_rdy(icache_mem_resp_rdy), // ICache

    .mainmemreq_msg(imemreq_msg4), // Main Memory
    .mainmemreq_val(imemreq_val4), // Main Memory
    .mainmemreq_rdy(imemreq_rdy4), // Main Memory

    .mainmemresp_msg(imemresp_msg4), // Main Memory
    .mainmemresp_val(imemresp_val4), // Main Memory
    .mainmemresp_rdy(imemresp_rdy4)  // Main Memory
  );

  assign imemreq_msg = imemreq_msg4[0];
  assign imemreq_val = imemreq_val4[0];
  assign imemresp_rdy = imemresp_rdy4[0];
  
  assign imemreq_rdy4  = {1'b0,1'b0,1'b0,imemreq_rdy};
  assign imemresp_msg4[0] = imemresp_msg;
  assign imemresp_val4 = {1'b0,1'b0,1'b0,imemresp_val};  
  assign numbers = {32'd3,32'd2,32'd1,32'd0}; // Used to select correct core number

  // Processors

 generate
  genvar i;
  
    for ( i = 0; i < c_num_cores; i = i + 1 ) begin: CORES_CACHES
    
    lab2_proc_ProcAltVRTL
    #(
      .p_num_cores (4)
    )
    proc
    (
      .clk           (clk),
      .reset         (reset),

      .core_id       (numbers[i]),

      .imemreq_msg   (icache_req_msg[i]), // Connection to ICache
      .imemreq_val   (icache_req_val[i]), // Connection to ICache
      .imemreq_rdy   (icache_req_rdy[i]), // Connection to ICache
  
      .imemresp_msg  (icache_resp_msg[i]), // Connection to ICache
      .imemresp_val  (icache_resp_val[i]), // Connection to ICache
      .imemresp_rdy  (icache_resp_rdy[i]), // Connection to ICache

      .dmemreq_msg   (dcache_req_msg[i]), // Connection to DCache
      .dmemreq_val   (dcache_req_val[i]), // Connection to DCache
      .dmemreq_rdy   (dcache_req_rdy[i]), // Connection to DCache

      .dmemresp_msg  (dcache_resp_msg[i]), // Connection to DCache
      .dmemresp_val  (dcache_resp_val[i]), // Connection to DCache
      .dmemresp_rdy  (dcache_resp_rdy[i]), // Connection to DCache

      .mngr2proc_msg (mngr2proc_msg[i]),
      .mngr2proc_val (mngr2proc_val[i]),
      .mngr2proc_rdy (mngr2proc_rdy[i]),

      .proc2mngr_msg (proc2mngr_msg[i]),
      .proc2mngr_val (proc2mngr_val[i]),
      .proc2mngr_rdy (proc2mngr_rdy[i]),

      .stats_en      (stats_en_wire[i]), // Only Take from Processor 0 // maybe make 0
      .commit_inst   (commit_inst[i])
    );

  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: Instantiate caches and connect them to cores
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  
    lab3_mem_BlockingCacheAltVRTL
    #(
      .p_num_banks   (1) 
    )
    icache
    (
      .clk           (clk),
      .reset         (reset),

      .cachereq_msg  (icache_req_msg[i]), // Processor
      .cachereq_val  (icache_req_val[i]), // Processor
      .cachereq_rdy  (icache_req_rdy[i]), // Processor

      .cacheresp_msg (icache_resp_msg[i]), // Processor
      .cacheresp_val (icache_resp_val[i]), // Processor
      .cacheresp_rdy (icache_resp_rdy[i]), // Processor

      .memreq_msg    (icache_mem_req_msg[i]), // Mnet
      .memreq_val    (icache_mem_req_val[i]), // Mnet
      .memreq_rdy    (icache_mem_req_rdy[i]), // Mnet

      .memresp_msg   (icache_mem_resp_msg[i]), // Mnet
      .memresp_val   (icache_mem_resp_val[i]), // Mnet
      .memresp_rdy   (icache_mem_resp_rdy[i])  // Mnet

    );
    end
  endgenerate

  lab5_mcore_McoreDataCacheVRTL dcache
  (
    .clk(clk),
    .reset(reset),

    .procreq_msg(dcache_req_msg), // Processor
    .procreq_val(dcache_req_val), // Processor
    .procreq_rdy(dcache_req_rdy), // Processor

    .procresp_msg(dcache_resp_msg), // Processor
    .procresp_val(dcache_resp_val), // Processor
    .procresp_rdy(dcache_resp_rdy), // Processor

    .mainmemreq_msg(dmemreq_msg), // Main Memory
    .mainmemreq_val(dmemreq_val), // Main Memory
    .mainmemreq_rdy(dmemreq_rdy), // Main Memory

    .mainmemresp_msg(dmemresp_msg), // Main Memory
    .mainmemresp_val(dmemresp_val), // Main Memory
    .mainmemresp_rdy(dmemresp_rdy), // Main Memory

    // Ports used for statistics gathering
    .dcache_miss(dcache_miss), 
    .dcache_access(dcache_access)
  );


  // Only takes proc0's stats_en
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  // LAB TASK: hook up stats and add icache stats
  //''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


  assign stats_en = stats_en_wire[0];
  generate
  genvar j;
  for ( j = 0; j < c_num_cores; j = j + 1 )begin
    assign icache_miss[j] = icache_resp_val[j] & icache_resp_rdy[j] & ~icache_resp_msg[j].test[0];
    assign icache_access[j] = icache_req_val[j] & icache_req_rdy[j];
  end
  endgenerate
  // assign icache_miss   = {icache_resp_val[3] & icache_resp_rdy[3] & ~icache_resp_msg[3].test[0],icache_resp_val[2] & icache_resp_rdy[2] & ~icache_resp_msg[2].test[0],icache_resp_val[1] & icache_resp_rdy[1] & ~icache_resp_msg[1].test[0],icache_resp_val[0] & icache_resp_rdy[0] & ~icache_resp_msg[0].test[0]};
  // assign icache_access = {icache_req_val[3] & icache_req_rdy[3],icache_req_val[2] & icache_req_rdy[2],icache_req_val[1] & icache_req_rdy[1],icache_req_val[0] & icache_req_rdy[0]};

  `VC_TRACE_BEGIN
  begin

    // This is staffs' line trace, which assume the processors and icaches
    // are instantiated in using generate statement, and the data cache
    // system is instantiated with the name dcache. You can add net to the
    // line trace.
    // Feel free to revamp it or redo it based on your need.

    CORES_CACHES[0].icache.line_trace( trace_str );
    CORES_CACHES[0].proc.line_trace( trace_str );
    CORES_CACHES[1].icache.line_trace( trace_str );
    CORES_CACHES[1].proc.line_trace( trace_str );
    CORES_CACHES[2].icache.line_trace( trace_str );
    CORES_CACHES[2].proc.line_trace( trace_str );
    CORES_CACHES[3].icache.line_trace( trace_str );
    CORES_CACHES[3].proc.line_trace( trace_str );

   // dcache.line_trace( trace_str );
  end
  `VC_TRACE_END

endmodule

`endif /* LAB5_MCORE_MULTI_CORE_V */
