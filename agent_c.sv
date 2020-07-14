//Classes of agent for running the DUT. The agent uses the sequencer, driver in_monitor and out_monitor classes

//A class that puts packets on the lines. That uses an interface virtual instance to access DUT
class driver_c;
    
  virtual interface packet_if l_if;
  packet_c packets[$];
    
  function new(virtual interface packet_if my_packet_if);
    l_if=my_packet_if;
    while(this.packets.size()!=0)//make empty payload array of the packet (-this)
      this.packets.pop_front();
    $display("      driver -> Hello! I'm the driver");
  endfunction
    
  task run_phase();
    integer i=0;
    //forever 
      //begin
        while(i<5)
          begin
            l_if.send_packet(packets[i].pack());//using the virtual instance of packet interface to put the packet on the lines          
            $display("      driver -> Packet was sended!!"); 
            @(posedge l_if.clk);
            i++;
          end
     // end
  endtask
    
    //function reset();
     // pkt_if_0.before_writing();
   // endfunction
    
endclass

//A class that creates packets to send to DUT. Gets the port number to generate packets with appropriate source address.
class sequencer_c;
    
  integer port_of_DUT;
  packet_c pkt;
  config_c l_config_pointer;
    
  //make a packet for the interface of the packets
  task run_phase(driver_c driver);
    for(int i=0;i<5;i++)
      begin
        this.pkt=new(l_config_pointer, this.port_of_DUT);//send a config pointer
        $display("      sequencer -> my port is:",port_of_DUT,", and new packet was born! here is it:");
        this.pkt.print();
        driver.packets.push_back(this.pkt);
      end
  endtask
    
  function new(integer port, config_c config_pointer);
    port_of_DUT=port;
    l_config_pointer=config_pointer;
    $display("      sequencer -> Hello! I'm the sequenser");
  endfunction
    
endclass

//A class that listens to the lines entering DUT and calculates for each packet that the driver has putes on the lines, what packet should be received as a result. The calculation result is sent to the scoreboard class as an expected packet    
class in_monitor_c;
    
  integer port_num;
  scoreboard_c l_scoreboard;
  virtual interface packet_if in_l_if;
  packet_c ready_pkt; 
  
  config_c l_config_pointer;
    
  event header_accepted_ev;
    
  covergroup header_checking @(header_accepted_ev);
    
    length_coverpoint: coverpoint ready_pkt.packet_length
    {
      bins min = {1};
      bins average = {[2:14]};
      bins max = {15};
    }
      
    source_address_coverpoint: coverpoint ready_pkt.source_address
    {
      bins first_port = {0};
      bins second_port = {1};
    }
    
  endgroup
    
  function new(virtual interface packet_if my_packet_if, config_c config_pointer);
    in_l_if=my_packet_if;
    l_config_pointer=config_pointer;
    $display("      in_monitor -> Hello! I'm the in_monitor");
  endfunction

    
  function data_list predict(bit [7:0] pkt_as_queue[$]);
    $display("      in_monitor -> predict done!");
    return pkt_as_queue;
  endfunction
      
  task run_phase();
    integer length;
    bit [7:0] header;
    bit [7:0] source;
    bit [7:0] in_pkt_as_queue[$];
    
    config_c l_config_pointer;
    
    forever
      begin
        //make the queue empty, before the in_monitor will fill it. the queue will be the packet which have listened
        while(in_pkt_as_queue.size()!=0)
          in_pkt_as_queue.pop_back();
        @(posedge in_l_if.packet_in_start)
        $display("      in_monitor -> packet_in_start!!");
        in_pkt_as_queue[0]=in_l_if.packet_in;
        header=in_l_if.packet_in;
        $display("      in_monitor -> header is here!!  %h",header);
        source=header[3:3];
        $display("      in_monitor -> source is here!!  %h",source," and port is ",port_num);
        length=header[7:4];
        $display("      in_monitor -> length is here!!  %h",length);
        @(posedge in_l_if.clk)
        for(int i=1;i<(length+1);i++)
          begin
            @(posedge in_l_if.clk)
            in_pkt_as_queue[i]=in_l_if.packet_in;
            $display("      in_monitor -> i is:",i," here is the byte was be sent right now: %h",in_pkt_as_queue[i]);
          end
       // for(int i=0;i<in_pkt_as_queue.size();i++)
         // $write("   in_monitor -> before predict -> %h",in_pkt_as_queue[i],"  ");
        $display("");  
        in_pkt_as_queue=this.predict(in_pkt_as_queue);
        ready_pkt=new(l_config_pointer);
        ready_pkt.unpack(in_pkt_as_queue);
        ->header_accepted_ev;
        if(length!=0)
          begin
            l_scoreboard.add_to_expected(ready_pkt,this.port_num);
          end
      end
  endtask
    
endclass    

//A class that listens to the lines that go out of DUT and sends each packet to the scoreboard class as a packet actually received.                                                    
class out_monitor_c;
    
  virtual interface packet_if out_l_if;
  config_c l_config_pointer;
  integer port_num;
  scoreboard_c l_scoreboard;    
  //packet_c ready_pkt; 
      
  function new(virtual interface packet_if my_packet_if, config_c config_pointer);
    out_l_if=my_packet_if;
    l_config_pointer=config_pointer;
    $display("      out_monitor -> Hello! I'm the out_monitor");
  endfunction
      
  task run_phase();
    integer length;
    bit [7:0] header;
    bit [7:0] source;
    bit [7:0] out_pkt_as_queue[$];
    packet_c actual_pkt=new(l_config_pointer);
    forever
      begin
        while(out_pkt_as_queue.size()!=0)
          out_pkt_as_queue.pop_back();
        @(posedge out_l_if.packet_out_start)
        $display("      out_monitor -> packet_out_start!!");
        if(out_l_if.read_data_valid)
          begin
            $display("      out_monitor -> there is valid together with the packet_out_start");
            header=out_l_if.packet_out;
          end
        out_pkt_as_queue[0]=header;
        $display("      out_monitor -> header is here!!  %h",header);
        source=header[3:3];
        $display("      out_monitor -> source is here!!  %h",source," and port is ",port_num);
        length=header[7:4];
        $display("      out_monitor -> length is here!!  %h",length);
        @(posedge out_l_if.clk)
        for(int i=1;i<(length+1);i++)//length+1 because length is without the header
          begin
            @(posedge out_l_if.clk)
            if(out_l_if.read_data_valid)
              begin
                out_pkt_as_queue[i]=out_l_if.packet_out;
                $display("      out_monitor -> i is:",i," here is the byte received  right now: %h",out_pkt_as_queue[i]);
              end
          end
        actual_pkt.unpack(out_pkt_as_queue);
        if(length)
          l_scoreboard.add_to_actual(actual_pkt,this.port_num);
        else
          $display("                                                                      out_monitor -> A packet with length 0!");
      end
    
  endtask

endclass    

//Class for agent. Incorporates and runs the classes used by the agent     
class agent_c;
  
  integer port_num;
  virtual interface packet_if l_if;
  config_c l_config_pointer;
  sequencer_c sequencer;
  driver_c driver;
  in_monitor_c in_monitor;
  out_monitor_c out_monitor;
  scoreboard_c l_scoreboard;
    
    //define a consructor for class agengt. takes an virtual instance of the interface and an integer which is 
  //the number of port for source_address - will transfer to the sequencer
    function new(integer port, virtual interface packet_if my_packet_if, config_c config_pointer);
    l_if=my_packet_if;
    l_config_pointer=config_pointer;
    port_num=port;
    sequencer=new(port,l_config_pointer);
    driver=new(l_if);
      in_monitor=new(l_if,l_config_pointer);
      out_monitor=new(l_if,l_config_pointer);
    $display("      agent ->    my port is",port);
  endfunction
  
  task run_phase();
    bit [7:0] tmp_list[$];
    fork
      sequencer.run_phase(driver);
      driver.run_phase();
      in_monitor.run_phase();
      out_monitor.run_phase();
    join_none
  endtask
  

  function connect_phase();
    in_monitor.l_scoreboard=l_scoreboard;
    in_monitor.port_num=port_num;
    out_monitor.l_scoreboard=l_scoreboard;
    out_monitor.port_num=port_num;
  endfunction

endclass


