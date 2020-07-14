//Class for comparison of packets actually received versus packets that were expected to be received
class scoreboard_c;
  
  integer error_source_pkt=0;
  
  config_c pointer_to_config;
  
  packet_c expected_packets[4][$];
  packet_c actual_packets[4][$];
  
  integer num_actual_packets[4];
  integer num_expected_packets[4];
  
  integer mismatch[4];
  integer match[4];
  
  //Takes a packet and push it to the actual queue of the scoreboard
  function add_to_actual(packet_c pkt,integer port);
    integer dest_of_pkt=pkt.destination_address;  
    bit [7:0] tmp_dst_map=0;
    bit [7:0] map=this.pointer_to_config.map_from_reg_agent;
    $display("      add_to_actual (scoreboard_c, function) ->  add_to_actual got: port is ",port,
             ", destination of pkt is ",pkt.destination_address);
    tmp_dst_map=map;
    for(int i=0;i<dest_of_pkt+1;i++)
      begin
        if(i==dest_of_pkt)  
          tmp_dst_map=tmp_dst_map%2;
        else
          tmp_dst_map=tmp_dst_map/2;
      end
    $display("    !!!!!!!!!!!!!!!  add_to_actual (scoreboard_c, function) ->  added to actual queue! destination was %h",
             dest_of_pkt," so the will go to %h", tmp_dst_map, " because map was %h", map);
    actual_packets[(pkt.source_address*2)+tmp_dst_map].push_back(pkt);
    $display(" add_to_actual (scoreboard_c, function) ->  added to actual ",pkt.source_address,"  _",tmp_dst_map);
    num_actual_packets[(pkt.source_address*2)+tmp_dst_map]=num_actual_packets[(pkt.source_address*2)+tmp_dst_map]+1;
    
  endfunction
    
  //Takes a packet and push it to the excepted queue of the scoreboard
  function add_to_expected(packet_c pkt,integer port);
    integer dest_of_pkt=pkt.destination_address;
    bit [7:0] tmp_dst_map=0;
    bit [7:0] map=this.pointer_to_config.map_from_reg_agent;
    $display("      add_to_expected (scoreboard_c, function) ->  add_to_expected got: port is ",port,", source of pkt is ",pkt.source_address);
    tmp_dst_map=map;
    for(int i=0;i<dest_of_pkt+1;i++)
      begin
        if(i==dest_of_pkt)  
          tmp_dst_map=tmp_dst_map%2;
        else
          tmp_dst_map=tmp_dst_map/2;
      end
    $display("      add_to_expected (scoreboard_c, function) ->  added to expected queue! destination was %h",dest_of_pkt," so the will go to %h", tmp_dst_map, " because map was %h", map);
    if(port==0 & pkt.source_address!=0)
      error_source_pkt=error_source_pkt+1;
    if(port==1 & pkt.source_address!=1)
      error_source_pkt=error_source_pkt+1;
    
    expected_packets[(pkt.source_address*2)+tmp_dst_map].push_back(pkt);
    $display(" add_to_expected (scoreboard_c, function) ->  added to expected ",pkt.source_address,"  _",tmp_dst_map);
    num_expected_packets[(pkt.source_address*2)+tmp_dst_map]=num_expected_packets[(pkt.source_address*2)+tmp_dst_map]+1;

   
  endfunction
    
  //Make empty the queues - actual and excepted
  function new(config_c config_pointer);
    
    num_actual_packets={0,0,0,0};
    num_expected_packets={0,0,0,0};
  
    mismatch={0,0,0,0};
    match={0,0,0,0};
    
    pointer_to_config= config_pointer;
    $display("      scoreboard -> Hello! I'm the scoreboard");
  endfunction
    
  task check_phase();
    int j=0;
    bit [7:0] tmp_actual[$];
    bit [7:0] tmp_expected[$];
    packet_c pkt1,pkt2;
    pkt1=new(pointer_to_config);
    pkt2=new(pointer_to_config);
    forever
      begin
        @(this.actual_packets[0].size()!=0||this.actual_packets[1].size()!=0||
          this.actual_packets[2].size()!=0||this.actual_packets[3].size()!=0);
        for(int j=0;j<4;j++) 
          begin
            if(this.actual_packets[j].size()!=0 && this.expected_packets[j].size()!=0)
              begin
                tmp_actual=this.actual_packets[j][0].pack();//make the first packet of the actual queue, a list - bit [7:0] 
                tmp_expected=this.expected_packets[j][0].pack();//make the first packet of the expected queue, a list - bit [7:0]
                pkt1.unpack(tmp_actual);//In order to use the compare function (which takes packets), 
                                  //Do the first element of the actual queue, as a list, a packet
                pkt2.unpack(tmp_expected);//In order to use the compare function (which takes packets), 
                                    //Do the first element of the expected queue, as a list, a packet
                actual_packets[j].delete(0);
                expected_packets[j].delete(0);
                if(pkt1.compare(pkt2))//Chekes the first elements of the queues - actual and expected
                  begin
                    this.match[j]=match[j]+1;
                    $display("      check_phase (scoreboard_c, task) ->  match!!!!");
                  end
                else
                  begin
                    this.mismatch[j]=mismatch[j]+1;
                    $display("      check_phase (scoreboard_c, task) -> mismatch! here are the packets: ");
                    pkt1.print();
                    pkt2.print();
                  end
              end
          end
      end
  endtask
  
  task summary_phase();
    $display(""); 
    $display("***********************SCOREBOARD SUMMARY************************");
    $display(""); 

    $display("Total errors:", error_source_pkt);
    $display("");
    $display("        TOTAL");
    
    $display(" Expected packets:", num_expected_packets[0]+num_expected_packets[1]
             +num_expected_packets[2]+num_expected_packets[3]);
    $display(" Actual packets:", num_actual_packets[0]+num_actual_packets[1]
             +num_actual_packets[2]+num_actual_packets[3]);
    $display("");
    $display(" Match:", match[0]+match[1]+match[2]+match[3]);
    $display(" Mismatch:", mismatch[0]+mismatch[1]+mismatch[2]+mismatch[3]);
    $display("");
    $display("*****************************************************************");
    $display("");
    $display("________________________________________________________________________________________________________");
    $display("|          in       out  |   expected packets  |   actual packets   |      match     |     mismatch     |" );
    for(int i=0;i<4;i++)
      begin
        $display("|________________________|_____________________|____________________|________________|__________________|");
        $write("|",i/2,i%2);
        
        
        $display("  |  ", num_expected_packets[i], "        |  ", num_actual_packets[i], 
                 "       |  ", match[i], "   |  ", mismatch[i],"     |");
      end
    $display("|________________________|_____________________|____________________|________________|__________________|");
  endtask
  
endclass




