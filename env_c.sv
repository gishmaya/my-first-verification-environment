//A class that creates and operates the agents that work with the DUT. The class makes the connections to the interface and the appropriate pointers.  
class env_c;
  
  //start working uvm
  virtual interface packet_if l_if0;
  virtual interface packet_if l_if1;  
  virtual interface conf_if l_conf_if;
  config_c config_pointer;
  agent_c agent0,agent1;
  reg_agent_c regs_agent;
  scoreboard_c scoreboard;
  
  function new(virtual interface packet_if my_packet_if0, virtual interface packet_if my_packet_if1, virtual interface conf_if conf_if_i);
    l_if0= my_packet_if0;
    l_if1= my_packet_if1;
    l_conf_if=conf_if_i;
    config_pointer=new();   
    scoreboard=new(config_pointer);
    agent0=new(0,l_if0,config_pointer);
    agent1=new(1,l_if1,config_pointer);
    regs_agent=new(l_conf_if,config_pointer);
  endfunction
      
  task run_phase();
    fork
      regs_agent.run_phase();
      agent0.run_phase();
      agent1.run_phase();
    join_none
  endtask
    
  function check_phase();
    fork
      scoreboard.check_phase();
    join_none
  endfunction
  
  function connect_phase();
    agent0.l_scoreboard=scoreboard;
    agent0.connect_phase();
    agent1.l_scoreboard=scoreboard;
    agent1.connect_phase();
    //regs_agent.connect_phase();
  endfunction

  function summary_phase();
    scoreboard.summary_phase();    
  endfunction
      
endclass