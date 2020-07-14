
//********************//CLASS FOR PACKETS//*******************//
//A class that defines a packet that is sent to the DUT.
typedef bit [7:0] data_list [$];

// Class for Packets
class packet_c;
  rand bit [3:0] packet_length;
       bit       source_address;
  rand bit [2:0] destination_address;
  rand bit [7:0] payload[$];
  rand bit [7:0] ipg;
  
  config_c l_config_pointer;

  constraint c1 
  {
    payload.size() == packet_length;
  }
  
  constraint c2 
  {
    ipg > 2;
    ipg < 10;
  }
  
 /* constraint length_of_pkt
  {
    packet_length<=l_config_pointer.max_length_pkt;
    packet_length>=l_config_pointer.min_length_pkt;
  }*/
  
  //Return the list of bytes of the packet called
  function data_list get_data();
    var bit[7:0] pkt_hdr;
    pkt_hdr[7:4] = packet_length;
    pkt_hdr[3:3] = source_address;
    pkt_hdr[2:0] = destination_address;
    get_data.push_back(pkt_hdr);
    for(int i = 0 ; i < payload.size; i++) 
      begin
        get_data.push_back(payload[i]);
      end
  endfunction
  
  function new(config_c config_pointer, bit port = 0);
    l_config_pointer=config_pointer;
    this.source_address = port;
    assert(this.randomize());
  endfunction

  
  function data_list pack();//takes packet (-this) and return it as a list
    var bit[7:0] pkt_hdr;
    pkt_hdr[7:4] = packet_length;
    pkt_hdr[3:3] = source_address;
    pkt_hdr[2:0] = destination_address;
    pack.push_back(pkt_hdr);
    for(int i = 0 ; i < payload.size; i++) 
      begin
        pack.push_back(payload[i]);
      end
  endfunction
  
  function packet_c unpack(bit [7:0] data[$]);//takes a list and return it as a packet into this
    bit [7:0] header=data.pop_front();
    integer size_of_data;
    if(!this)
      $display("      unpack (packet_c, function) ->  get null pointer");
    while(this.payload.size()!=0)//make empty payload array of the packet (-this)
      begin
        this.payload.pop_front();
      end
    for(int i=0;i<data.size();i++)
    this.packet_length=header[7:4];
    this.source_address= header[3:3];
    this.destination_address= header[2:0];
    size_of_data=data.size();
    for(int i=0;i<size_of_data;i++)
      begin
        this.payload[i]=data.pop_front();
      end
  endfunction 
  
  function integer compare(packet_c pkt2);//takes 2 packets (this - called the function and pkt2 - parameter) and cheks if equality exist
    bit [7:0] first_pkt[$]=this.pack();//do the packet a list
    bit [7:0] second_pkt[$]=pkt2.pack();//do the packet a list
    for(int j=0;j<second_pkt.size();j++)
      if(first_pkt.size()!=second_pkt.size())
        return 0;
    for(int k=0;k<first_pkt.size();k++)
      if(first_pkt[k]!=second_pkt[k])
        begin
          //$display("no! first, ",first_pkt[k]," , not = second, ",second_pkt[k]," , i is: ",k);
          return 0;
        end
    return 1;
  endfunction
  
  function print();//prints a packet, opening the header of the packet.
    $display("      print (packet_c, function) ->  packet length is: ",this.packet_length," packet came from port ",this.source_address," packet have to go to ",this.destination_address," the data is: ");
    $write("         ");
    for(int i=0;i<packet_length;i++)
      $write("%h",this.payload[i], "  ");
    $display("");
  endfunction
  
  
endclass

