class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  wr_data wrd;
  rd_data rdd;
  reset_dut rdut;
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e=env::type_id::create("e",this);
    wrd=wr_data::type_id::create("wrd",this);
    rdd=rd_data::type_id::create("rdd",this);
    rdut=reset_dut::type_id::create("rdut",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rdut.start(e.a.seqr);
    wrd.start(e.a.seqr);
    rdd.start(e.a.seqr);
    phase.drop_objection(this);
  endtask
endclass
