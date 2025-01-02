class env extends uvm_env;
  `uvm_component_utils(env);
  agent a;
  sco sc;
  
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a=agent::type_id::create("a",this);
    sc=sco::type_id::create("sc",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(sc.recv);
  endfunction
endclass
