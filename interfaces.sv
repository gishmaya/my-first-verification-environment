//Interfaces for physical access to DUT

//*********//INTERFACE FOR PACKETS//***************//

interface packet_if( input wire clk, rst);
  logic     [7:0] 	packet_in;
  logic             packet_in_start;
  logic             packet_ack;
  logic             packet_out_start;
  logic     [7:0]   packet_out;
  logic     [7:0]   read_data_valid;

  // Resets before sending packets. 
  task before_writing();
    packet_in_start<=0;
  endtask

  //Takes a packet as a list and send to DUT
  task send_packet(bit [7:0] data [$]);
    int i;
    @(posedge clk);
    packet_in_start <= 1;
    if(!(data.size()))
      $display("      send_packet (packet_if, task) ->  get a null list instead a packet to send!");
    packet_in <= data.pop_front();
    @(posedge clk);
    packet_in_start <= 0;
    while (data.size() != 0) 
      begin
        packet_in <= data.pop_front();
        $display("");
        @(posedge clk);
      end
    //packet_in = 0;
    @(posedge clk);
    $display();
  endtask
 
endinterface

//*********//INTERFACE FOR CONFIGURATION//***************//
interface conf_if(input wire clk, rst);
  logic		[3:0]	conf_address; 	
  logic				conf_data_valid;
  logic				conf_read_write;
  logic		[15:0]	conf_data_write;
  logic  	[15:0]  conf_data_read; 

  //Resets befor configuration
  task reset_configuration();
    conf_address	 <= 4'h0;
    conf_data_write	 <= 16'h0;
	conf_data_valid  <= 1'h0;
    conf_read_write  <= 1'h0; // 0 for write (1 is for read)
  endtask
   
  //Takes a reg for the write. Used for configuration
  task write_reg(switch_reg_c reg_to_write);
    if(!reg_to_write)
      $display("      write_reg (conf_if, task) ->  get null switch_reg_c to write!");
    @(posedge clk);
    conf_address     <=  reg_to_write.adrs;
    conf_data_write  <=  reg_to_write.data;
    conf_data_valid  <= 1;
    conf_read_write  <= 1'h0;
    @(posedge clk);
    reset_configuration();    
  endtask   

endinterface

