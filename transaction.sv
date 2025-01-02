class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  randc logic [6:0]addr;
  rand logic [7:0]din;
  logic wr;
  logic [7:0]datard;
  logic done;
  logic [1:0]op;
  
  constraint addr_c{addr<=10;}
  
  function new(string path="trans");
    super.new(path);
  endfunction
endclass
