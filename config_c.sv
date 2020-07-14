//A class that all classes know and which defines the parameters that affect how DUT works.                                                                        
class config_c;
  
  bit [15:0] map_from_reg_agent;
  integer priority_service;
  integer round_rub_in=1;
  
  integer max_length_pkt=15;
  integer min_length_pkt=1;
  
  event config_pointer_new_ev;
  
  covergroup map_cover @(config_pointer_new_ev);
    
    map_not_null: coverpoint map_from_reg_agent
    {
      bins not_null ={[1:255]};
    }
    
  endgroup
  
  function new();
    $display("      config_c -> there are a new config instance  %h", map_from_reg_agent);
    $display(map_from_reg_agent);
    ->config_pointer_new_ev;
  endfunction
  
endclass