//********************//CLASSES DEFINITION FOR REGS //*******************//
//A class that defines registers for configuration


//The purpose is to make a generic class for regs
class switch_reg_c;
  rand bit [3:0] adrs;
  rand bit [15:0] data;
  string name;
  
  function new();
  endfunction
  
  function print_reg();
    $display("      print_reg (switch_reg_c, function) ->  Address of the reg is: ", adrs, "data is: ", data, "the name is ",name);
  endfunction
  
endclass

//The purpose is to make a specific class for regs for maping
class adrs_map_reg_c extends switch_reg_c;
    
  constraint c_address
  {
    adrs==0;
  }
  
  constraint c_data
  {
    data[15:8]==0;
  }
  
  function new();
    super.new();
    assert(this.randomize());
    name="reg for address maping";
  endfunction

endclass
  
//The purpose is to make a specific class for regs for strict or priority
class strict_priority_reg_c extends switch_reg_c;
    
  constraint c_address_stric
  {
    adrs==1;
  }
    
  constraint c_data_stric
  {
    data[15:2]==0;
  }
  
  function new();
    super.new();
    assert(this.randomize());
    name="reg for strict or priority";
  endfunction
  
endclass  

//A class for lists of regs of both types. possible to make list of different regs
class regs_list;
  switch_reg_c rg_list[$];
  strict_priority_reg_c stric_reg;
  adrs_map_reg_c map_reg;
    
  function new();
    stric_reg=new();
    map_reg=new();
    rg_list.push_back(stric_reg);
    $display("      new (regs_list, function) ->  stric_reg rand now! adrs is: %h", rg_list[0].adrs, " data is: %h", rg_list[0].data);
    rg_list.push_back(map_reg);
    $display("      new (regs_list, function) ->  map is rand now! adrs is: %h", rg_list[1].adrs, " data is: %h", rg_list[1].data);
  endfunction
    
endclass