
//**************//TESTBENCH//********************//

`include "config.sv"
`include "packet.sv"
`include "regs.sv"
`include "interfaces.sv"
`include "miniscoreboard.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "reg_agent.sv"
`include "env.sv"
module tb4;
  reg  	     rst,clk;
  //Instances of intefaces of packets and config
  packet_if  pkt_if_0 (.clk(clk),.rst(rst));
  packet_if  pkt_if_1 (.clk(clk),.rst(rst));
  conf_if    conf_if_i(.clk(clk),.rst(rst));
  
  //Make an instance of the DUT
  switch_packet switch_packet_i(
      .rst                (rst),
      .clk                (clk),
      .packet_in_0        (pkt_if_0.packet_in), 
      .packet_in_1        (pkt_if_1.packet_in),
      .packet_in_start_0  (pkt_if_0.packet_in_start),
      .packet_in_start_1  (pkt_if_1.packet_in_start),
      .packet_ack_0       (pkt_if_0.packet_ack),
      .packet_ack_1       (pkt_if_1.packet_ack),
      .packet_out_0       (pkt_if_0.packet_out),
      .packet_out_1       (pkt_if_1.packet_out),
      .read_data_valid_0  (pkt_if_0.read_data_valid), 
      .read_data_valid_1  (pkt_if_1.read_data_valid),
      .packet_out_start_0 (pkt_if_0.packet_out_start),
      .packet_out_start_1 (pkt_if_1.packet_out_start),
      .conf_address       (conf_if_i.conf_address),
      .conf_data_write    (conf_if_i.conf_data_write),
      .conf_data_read     (conf_if_i.conf_data_read),
      .conf_data_valid    (conf_if_i.conf_data_valid),
      .conf_read_write    (conf_if_i.conf_read_write));

  event reset_done, init_done, packets_done;
  packet_c packet;
  regs_list reg_list;
  initial 
    begin
     // packet = new();
      run_task();
    end	
  
  //basic 
  task run_task();
    $dumpfile("dump.vcd");
    $dumpvars;
    @(posedge clk)
    #2500 $finish;
  endtask
 
 //clk
 initial 
    begin 
      clk = 0;
      forever #10 clk = ~clk;
    end
  
  initial 
    begin
      reset_dut();
    end	
  
  //reset (rst)
  task reset_dut();
    rst = 1;
    #1 rst = 0;
    #21 rst = 1;
    -> reset_done;
  endtask
  
//******************//CONFIGURATION//******************//
  
  initial 
    begin 
      @(reset_done);
      #10;
      config_DUT();
    end
  
  //Resets befor configuration and use the interface instance for configuration
  task config_DUT();
    conf_if_i.reset_configuration();
    #30;
    @(posedge clk);
   /* reg_list = new();
    for(int i = 0; i < reg_list.rg_list.size(); i++) 
      begin
        conf_if_i.write_reg(reg_list.rg_list[i]);
      end*/
    -> init_done;
  endtask 
    
  initial 
    begin
      packet_c pkt0,pkt1,pkt3,pkt4,pkt5;
      static bit [7:0] data[7]={8'h6,8'h3,8'h5,8'h9,8'h4,8'h11,8'h6F};   
      bit [7:0] data1[$];
      bit [7:0] tmp_queue_actual[$];
      packet_c queue_tmp_for_packets;
      env_c env;
      env=new(pkt_if_0,pkt_if_1,conf_if_i);
      env.connect_phase();
      env.run_phase();
      env.check_phase();
      #2500;
      env.summary_phase();
    end
  
endmodule



















