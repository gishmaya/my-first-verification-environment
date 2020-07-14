//Agent to configurate the DUT  . The class uses the sequencer, driver and monitor departments

//A class that putes on the lines the packet used to write registers. The class uses a virtual instance of the configuration interface.                                     
class reg_driver_c;
  
  virtual interface conf_if l_conf_if;
  regs_list packets[$]; 
  
  function new(virtual interface conf_if conf_if_i);
    $display("      reg_driver -> Hello! I'm the driver");
    l_conf_if=conf_if_i;
  endfunction
  
  task run_phase();
    integer i=0;
    //forever
     // begin
    while(i<1)
          begin
            this.l_conf_if.write_reg(packets[i].rg_list[0]);
            @(posedge l_conf_if.clk);
            this.l_conf_if.write_reg(packets[i].rg_list[1]);
            $display("      reg_driver -> sended reg_packet!");
            i++;
          end
     // end
  endtask
    
endclass

//A class that creates a packet that defines writing registries to send to DUT. Gets the pointer to the config class to do the register writing according to what is defined there.                              
class reg_sequencer_c;
  
  bit [7:0] l_map;
  config_c l_config_pointer;
  regs_list packet_for_config;
  
  function new(config_c config_pointer);
    $display("      reg_sequencer -> I am the reg_sequencer!");
    l_map=config_pointer.map_from_reg_agent;
    l_config_pointer=config_pointer;
  endfunction
  
  task run_phase(reg_driver_c driver);
    packet_for_config=new();
    driver.packets.push_back(packet_for_config);
  endtask
  
endclass

//A class that listens to the registers writing and updates by the config pointer the appropriate fields according to the packet created by the sequencer
class reg_in_monitor_c;
  
  virtual interface conf_if in_l_conf_if;
    config_c l_config_pointer;
    bit [3:0]  last_conf_adrs;
    bit [15:0] conf_data;
    bit        map_config_flag=0;
    bit        service_config_flag=0;
  
    function new(virtual interface conf_if conf_if_i, config_c config_pointer);
    in_l_conf_if=conf_if_i;
    l_config_pointer=config_pointer;
    $display("      reg_in_monitor -> Hello! I'm the reg_in_monitor");
  endfunction
  
  task run_phase();
    forever
      begin
        @(posedge in_l_conf_if.conf_data_valid)
        if(map_config_flag==0 || service_config_flag==0)
          begin
            last_conf_adrs=in_l_conf_if.conf_address;
            conf_data=in_l_conf_if.conf_data_write;
            @(posedge in_l_conf_if.clk);
          end
        if(last_conf_adrs==0 & map_config_flag==0)//Configuration of the map, member at config_c
          begin
            l_config_pointer.map_from_reg_agent=conf_data;
            $display("      reg_in_monitor   ->   its seems to be a configuration for map!  ");
            map_config_flag=1;
          end
        if(last_conf_adrs==1 & service_config_flag==0)//Configuration of the service, members at config_c
          begin
            if(last_conf_adrs==1)
              begin
                $display("      reg_in_monitor   ->   its seems to be a configuration for service!  ");
                @(posedge in_l_conf_if.clk);
                l_config_pointer.round_rub_in=in_l_conf_if.conf_data_write;
                if(l_config_pointer.round_rub_in==1)
                  l_config_pointer.priority_service=in_l_conf_if.conf_data_write%2;
                service_config_flag=1;
              end
          end  
      end
    
  endtask
  
endclass

// A class for the agent that configurate the registers. Incorporates and runs the classes that participate in the DUT configuration.                            
class reg_agent_c;
  
  virtual interface conf_if l_conf_if;
  config_c l_config_pointer;
  reg_sequencer_c sequencer;
  reg_driver_c driver;
  reg_in_monitor_c reg_in_monitor;
  
  function new(virtual interface conf_if conf_if_i, config_c config_pointer);
    l_conf_if=conf_if_i;
    l_config_pointer=config_pointer;
    sequencer=new(l_config_pointer);
    driver=new(l_conf_if);
    reg_in_monitor=new(l_conf_if, l_config_pointer);
  endfunction
  
  task run_phase();
    fork
      sequencer.run_phase(driver);
      driver.run_phase();
      reg_in_monitor.run_phase();
    join_none
  endtask
    
endclass            