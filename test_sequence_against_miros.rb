begin
  # don't break if someone hasn't installed a debugger
  require "byebug"
end
require 'minitest/spec'
require 'minitest/autorun'
require './sequence.rb'

# copying and pasting this crashes vim :)
# I have to move this block around with Jedit
$miros_trace_plus_garbage = <<EOF
testing(top-entry);                                                                            
testing(top-init);                                                                             
testing(d2-entry);                                                                             
testing(d2-init);                                                                              
testing(d21-entry);                                                                            
testing(d211-entry);                                                                           
[2016-05-25 11:36:48] [under_test] event->entry() top->d211                                    
testing(d21-a-{'y': 0, 'x': 0, 'z': 0, 'tik': 0});                                             
testing(d211-exit-{'y': 0, 'x': 0, 'z': 0, 'tik': 1});                                         
testing(d21-exit-{'y': 0, 'x': 0, 'z': 0, 'tik': 2});                                          
testing(d21-entry-{'y': 0, 'x': 0, 'z': 0, 'tik': 3});                                         
testing(d21-init-{'y': 0, 'x': 0, 'z': 0, 'tik': 4});                                          
testing(d211-entry-{'y': 0, 'x': 0, 'z': 0, 'tik': 5});                                        
[2016-05-25 11:36:48] [under_test] event->a({'y': 0, 'x': 0, 'z': 0, 'tik': 6}) d211->d211     
testing(d21-b);                                                                                
testing(d211-exit);                                                                            
testing(d211-entry);                                                                           
EOF
$target_1 = \
'[ Chart: under_test ] (?)
                   top                                     d211
                    +----------------entry()---------------->|
                    |                  (?)                   |
                    |                                        +
                    |                                         \ (?)
                    |                                         a({"y": 0, "x": 0, "z": 0, "tik": 6})
                    |                                         /
                    |                                        <'
$problem_trace_1 = <<TP
[2013-3-24 12:15:5.200] [00] cTrig->g() s211->s11 
[2013-3-24 12:15:5.201] [00] cTrig->f() s11->s211 
[2013-3-24 12:15:5.205] [00] cTrig->e() s211->s11 
[2013-3-24 12:15:5.206] [00] cTrig->s() s11->s11
[2013-3-24 12:15:5.206] [00] cTrig->c() s11->s211
[2013-3-24 12:15:5.208] [00] cTrig->b() s211->s211
[2013-3-24 12:15:5.209] [00] cTrig->a(Erker!) s211->s211
TP
$target_2 = \
'[ Chart: 00 ] (?)
    s211          s11
      +----g()---->|
      |    (?)     |
      +<---f()-----|
      |    (?)     |
      +----e()---->|
      |    (?)     |
      |            +
      |             \ (?)
      |             s()
      |             /
      |            <
      +<---c()-----|
      |    (?)     |
      +            |
       \ (?)       |
       b()         |
       /           |
      <            |
      +            |
       \ (?)       |
       a(Erker!)   |
       /           |
      <            |'

describe SequenceDiagram do
  before do
  end
  it "should remove junk as expected" do
    @diagram = SequenceDiagram.new( trace: $miros_trace_plus_garbage )
    result = @diagram.to_s.gsub(/\s+$/,'')
    $target_1 = $target_1.gsub(/"/,"'")
    result.must_equal $target_1
  end

  it "should create first signal properly" do
    @diagram = SequenceDiagram.new( trace: $problem_trace_1 )
    @diagram.to_s.gsub(/\s+$/,'').must_equal $target_2
  end
end


