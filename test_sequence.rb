begin
  # don't break if someone hasn't installed a debugger
  require "byebug"
end
require 'minitest/spec'
require 'minitest/autorun'
require './sequence.rb'

$dump_file_name = "bob.txt"
$ordered_time_blob = [
  ["2012-10-16 13:30:25 -0700", "31", "U(606)", "U", "606", "EngagingAcGood", "AcGood", "[2012-10-16 13:30:25] [31] Trig->U(606) EngagingAcGood->AcGood"], 
  ["2012-10-16 13:30:25 -0700", "31", "Init(3)", "Init", "3", "AcGood", "EngagingCharge", "[ 2012-10-16 13:30:25] [31] Trig->Init(3) AcGood->EngagingCharge"], 
  ["2012-10-16 13:30:25 -0700", "31", "M(558)", "M", "558" , "EngagingCharge", "XfrmReset", "[2012-10-16 13:30:25] [31] Trig->M(558) EngagingCharge->XfrmReset"], 
  ["2012-10-16 13:30 :25 -0700", "31", "XRC(649)", "XRC", "649", "XfrmReset", "Charge", "[2012-10-16 13:30:25] [31] Trig->XRC(649) XfrmReset-> Charge"], 
  ["2012-10-16 13:30:25 -0700", "31", "Init(3)", "Init", "3", "Charge", "EngagingBulk", "[2012-10-16 13:30:25] [31 ] Trig->Init(3) Charge->EngagingBulk"]
]

$un_ordered_time_blob = [
  ["2012-10-16 13:30:25 -0700", "31", "Init(3)", "Init", "3", "Charge", "EngagingBulk", "[2012-10-16 13:30:25] [31 ] Trig->Init(3) Charge->EngagingBulk"],
  ["2012-10-16 13:30:25 -0700", "31", "U(606)", "U", "606", "EngagingAcGood", "AcGood", "[2012-10-16 13:30:25] [31] Trig->U(606) EngagingAcGood->AcGood"], 
  ["2012-10-16 13:30:25 -0700", "31", "M(558)", "M", "558" , "EngagingCharge", "XfrmReset", "[2012-10-16 13:30:25] [31] Trig->M(558) EngagingCharge->XfrmReset"], 
  ["2012-10-16 13:30:25 -0700", "31", "Init(3)", "Init", "3", "AcGood", "EngagingCharge", "[ 2012-10-16 13:30:25] [31] Trig->Init(3) AcGood->EngagingCharge"], 
  ["2012-10-16 13:30 :25 -0700", "31", "XRC(649)", "XRC", "649", "XfrmReset", "Charge", "[2012-10-16 13:30:25] [31] Trig->XRC(649) XfrmReset-> Charge"] 
]
# this is a scrabbled trace, you won't see anything this bad coming out of the
# CSW
$simple_trace = <<EOS
[2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
[2012-10-16 13:30:24] [00] Trig->PPP(549) PendingAcGood->EngagingAcGood
[2012-10-16 13:30:24] [00] Trig->P(522) QualifyingAC->PendingAcGood
[2012-10-16 13:30:24] [31] Trig->PPP(549) PendingAcGood->EngagingAcGood
[2012-10-16 13:30:25] [31] Trig->U(606) EngagingAcGood->AcGood
[2012-10-16 13:30:25] [00] Trig->U(606) EngagingAcGood->AcGood
[2012-10-16 13:30:25] [00] Trig->Init(3) AcGood->EngagingCharge
[2012-10-16 13:30:25] [31] Trig->Init(3) AcGood->EngagingCharge
[2012-10-16 13:30:25] [31] Trig->M(558) EngagingCharge->XfrmReset
[2012-10-16 13:30:26] [00] Trig->XRC(649) XfrmReset->Charge
[2012-10-16 13:30:25] [31] Trig->XRC(649) XfrmReset->Charge
[2012-10-16 13:30:25] [31] Trig->Init(3) Charge->EngagingBulk
[2012-10-16 13:30:25] [00] Trig->M(558) EngagingCharge->XfrmReset
[2012-10-16 13:30:26] [31] Trig->KK(670) EngagingBulk->Bulk
[2012-10-16 13:30:26] [00] Trig->Init(3) Charge->EngagingBulk
[2012-10-16 13:30:26] [00] Trig->KK(670) EngagingBulk->Bulk
EOS

$indented_simple_trace = <<EOS
    [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
    [2012-10-16 13:30:24] [00] Trig->PPP(549) PendingAcGood->EngagingAcGood
    [2012-10-16 13:30:24] [00] Trig->P(522) QualifyingAC->PendingAcGood
    [2012-10-16 13:30:24] [31] Trig->PPP(549) PendingAcGood->EngagingAcGood
    [2012-10-16 13:30:25] [31] Trig->U(606) EngagingAcGood->AcGood
    [2012-10-16 13:30:25] [00] Trig->U(606) EngagingAcGood->AcGood
    [2012-10-16 13:30:25] [00] Trig->Init(3) AcGood->EngagingCharge
    [2012-10-16 13:30:25] [31] Trig->Init(3) AcGood->EngagingCharge
    [2012-10-16 13:30:25] [31] Trig->M(558) EngagingCharge->XfrmReset
    [2012-10-16 13:30:26] [00] Trig->XRC(649) XfrmReset->Charge
    [2012-10-16 13:30:25] [31] Trig->XRC(649) XfrmReset->Charge
    [2012-10-16 13:30:25] [31] Trig->Init(3) Charge->EngagingBulk
    [2012-10-16 13:30:25] [00] Trig->M(558) EngagingCharge->XfrmReset
    [2012-10-16 13:30:26] [31] Trig->KK(670) EngagingBulk->Bulk
    [2012-10-16 13:30:26] [00] Trig->Init(3) Charge->EngagingBulk
    [2012-10-16 13:30:26] [00] Trig->KK(670) EngagingBulk->Bulk
EOS
$simple_trace_expected_order_of_states = [
  "QualifyingAC",
  "PendingAcGood",
  "EngagingAcGood",
  "AcGood",
  "EngagingCharge",
  "XfrmReset",
  "Charge",
  "EngagingBulk",
  "Bulk"
]
$hard_trace =<<EOHT
[2012-10-18 08:21:25] [31] uiErrNum->2 siErrVal->555 FAULT: AC Output Over Voltage
[2012-10-18 08:21:25] [31] Trig->BB(514) ActiveTestComplete->InvertRampDown
[2012-10-18 08:21:25] [00] uiErrNum->74 siErrVal->0 FAULT: Other Unit Invert Fault
[2012-10-18 08:21:25] [00] Trig->BB(514) InvertSupport->QualifyingAC
[2012-10-18 08:21:25] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
[2012-10-18 08:21:25] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:25] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:26] [31] Trig->IRDC(646) InvertRampDown->QualifyingAC
[2012-10-18 08:21:40] [31] Trig->DD(51) QualifyingAC->QualifyingAC
[2012-10-18 08:21:40] [31] Trig->N(559) EngagingInvert->EngagingInvert
[2012-10-18 08:21:40] [31] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:40] [31] Trig->Init(3) InvertSelect->EngagingInvert
[2012-10-18 08:21:40] [31] Trig->BFT(651) Invert->ActiveTestofRelays 
[2012-10-18 08:21:42] [31] Trig->BFTC(652) ActiveTestofRelays->ActiveTestComplete
[2012-10-18 08:21:42] [00] Trig->DD(51) InvertSupport->QualifyingAC
[2012-10-18 08:21:42] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:42] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:42] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
EOHT

$hard_trace_states_31 = [
    "ActiveTestComplete",
    "InvertRampDown",
    "QualifyingAC",
    "QualifyingAC",
    "InvertSelect",
    "EngagingInvert",
    "Invert",
    "ActiveTestofRelays",
    "ActiveTestComplete",
]
$hard_trace_states_00 = [
    "InvertSupport",
    "QualifyingAC",
    "InvertSelect",
    "EngagingInvertSupport",
    "InvertSupport",
    "QualifyingAC",
    "InvertSelect",
    "EngagingInvertSupport",
    "InvertSupport"
]
$tiny_hard_trace_1 =<<THT
[2012-10-18 08:21:40] [31] Trig->DD(51) QualifyingAC->QualifyingAC
[2012-10-18 08:21:40] [31] Trig->N(559) EngagingInvert->Invert
[2012-10-18 08:21:40] [31] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:40] [31] Trig->Init(3) InvertSelect->EngagingInvert
[2012-10-18 08:21:40] [31] Trig->BFT(651) Invert->ActiveTestofRelays 
THT

$tiny_hard_trace_2 =<<THT
[2012-10-18 08:21:25] [00] Trig->BB(514) InvertSupport->QualifyingAC
[2012-10-18 08:21:25] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
[2012-10-18 08:21:25] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:25] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:42] [00] Trig->DD(51) InvertSupport->QualifyingAC
[2012-10-18 08:21:42] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:42] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:42] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
THT
$sequence_diagram = <<EOD
Unit: 00
 QualifyingAC PendingAcGood EngagingAcGood AcGood EngagingCharge XfrmReset Charge EngagingBulk Bulk
      |             |              |         |          |            |        |        |        |
EOD
#31
# QualifyingAC PendingAcGood EngagingAcGood AcGood EngagingCharge XfrmReset Charge EngagingBulk Bulk
#EOD
describe UnitBlobs do
  include OrderTrace
  before do
    @seq = UnitBlobs.new(trace: $simple_trace.dup )
    @seq2 = UnitBlobs.new( trace: $hard_trace )
    @seq3 = UnitBlobs.new( trace: $indented_simple_trace.dup )
  end

  # HELPER FUNCTIONS ( USED BY THE FOLLOWING TESTS )
  def create_fake_unit_blob(array)
      unit_blob = []
      array.each{|pair|
        bs = pair[0]
      es = pair[1]
      unit_blob += create_fake_unit_trace(
                    :bs=>bs,
                    :es=>es )
    }
    unit_blob
  end

  def create_fake_unit_trace(spec)
    bs = spec[:bs]
    es = spec[:es]
    trace = []
    trace[OrderTrace::BEGINNING_STATE]=bs
    trace[OrderTrace::END_STATE]=es
    trace[OrderTrace::SIGNAL]="D(123)"
    trace[OrderTrace::SIGNAL_NUMBER]="123"
    trace[OrderTrace::SIGNAL_NAME]="D"
    trace[OrderTrace::TIME]="2012-10-18 08:21:42"
    [ trace ]
  end

  # UnitBlobs class TESTS 
  it "should have the ability to get the states and the initial state out of a unit_blob" do
    unit_blob = [
      ["2012-10-16 13:30:18 -0700", "31", "P(522)", "P", "522", "QualifyingAC", "PendingAcGood", 
        '[2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood'], 
      ["2012-10-16 13:30:24 -0700", "31", "PPP(549)", "PPP", "549", "PendingAcGood", "EngagingAcGood", 
        '[2012-10-16 13:30:24] [31] Trig->PPP(549) PendingAcGood->EngagingAcGood'],
      ["2012-10-16 13:30:26 -0700", "31", "KK(670)", "KK", "670", "EngagingBulk", "Bulk", 
        '[2012-10-16 13:30:26] [31] Trig->KK(670) EngagingBulk->Bulk']
    ] 
     
    states = @seq.get_states(:unit_blob=>unit_blob)
    states = [
      "QualifyingAC", 
      "PendingAcGood", 
      "EngagingAcGood", 
      "EngagingBulk", 
      "Bulk"
    ]

    states.must_equal ["QualifyingAC", "PendingAcGood", "EngagingAcGood", "EngagingBulk", "Bulk"]

    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal "QualifyingAC"
    states = [
      "PendingAcGood", 
      "EngagingAcGood", 
      "QualifyingAC", 
      "EngagingBulk", 
      "Bulk"
    ]
    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal "QualifyingAC"

    # now for something a bit more complicated
    
    states = [
      "PendingAcGood", 
      "EngagingAcGood", 
      "QualifyingAC", 
      "EngagingBulk", 
      "Bulk"
    ]
    unit_blob = []
    unit_blob += create_fake_unit_trace(:bs=>"QualifyingAC",:es=>"QualifyingAC") 
    unit_blob += create_fake_unit_trace(:bs=>"QualifyingAC",:es=>"QualifyingAC") 
    unit_blob += create_fake_unit_trace(:bs=>"EngagingAc",:es=>"EngagingAcGood")
    unit_blob += create_fake_unit_trace(:bs=>"EngagingAcGood",:es=>"PendingAcGood")
    unit_blob += create_fake_unit_trace(:bs=>"PendingAcGood",:es=>"EngagingBulk")
    unit_blob += create_fake_unit_trace(:bs=>"QualifyingAC",:es=>"EngagingAc")
    unit_blob += create_fake_unit_trace(:bs=>"EngagingBulk",:es=>"Bulk")
    unit_blob.size.must_equal 7
    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal "QualifyingAC"

    states = [
      "A", 
      "B", 
      "C", 
      "D", 
      "E"
    ]

    unit_blob = create_fake_unit_blob([ 
                                      [ "A", "A" ],
                                      [ "C", "D" ],
                                      [ "A", "B" ],
                                      [ "B", "C" ],
                                      [ "D", "E" ]
                                      ])

    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal("A")


    unit_blob = create_fake_unit_blob([ 
                                      [ "C", "D" ],
                                      [ "A", "B" ],
                                      [ "B", "B" ],
                                      [ "D", "E" ],
                                      [ "B", "C" ]
                                      ])
    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal("A")

    unit_blob = create_fake_unit_blob([ 
                                      [ "C", "D" ],
                                      [ "B", "B" ],
                                      [ "D", "E" ],
                                      [ "E", "E" ],
                                      [ "B", "C" ],
                                      [ "A", "B" ]
                                      ])
    init = @seq.recursively_find_init_state(:unit_blob=>unit_blob,
                                        :states=>states)
    init.must_equal("A")
  end

  it "should have to ability to order unit_blobs" do
    
    states = [ "A", "B", "C", "D", "E" ]
    unordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "A" ],
                                                  [ "C", "D" ],
                                                  [ "A", "B" ],
                                                  [ "B", "C" ],
                                                  [ "D", "E" ]
                                                ])
    
    ordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "A" ],
                                                  [ "A", "B" ],
                                                  [ "B", "C" ],
                                                  [ "C", "D" ],
                                                  [ "D", "E" ]
                                                ])
    result = @seq.recursively_build_blob(
              :unit_blob => unordered_unit_blob )
    result.must_equal(ordered_unit_blob )

    states = [ "A", "B", "C", "D", "E" ]
    unordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "C", "D" ],
                                                  [ "B", "B" ],
                                                  [ "D", "E" ],
                                                  [ "B", "C" ]
                                                ])
    
    ordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "B", "B" ],
                                                  [ "B", "C" ],
                                                  [ "C", "D" ],
                                                  [ "D", "E" ]
                                                ])
    result = @seq.recursively_build_blob(
              :unit_blob => unordered_unit_blob )
    result.must_equal(ordered_unit_blob )
    # new code here
    # Adding a loop... here we see that the sequence starts with
    # A and ends with A... if you can't see it reference the
    # following ordered_unit_blob object to see how it should be
    # ordered
    unordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "B", "C" ],
                                                  [ "C", "B" ],
                                                ])
    ordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "B", "C" ],
                                                  [ "C", "B" ]
                                                ])

    result = @seq.recursively_build_blob(
              :unit_blob => unordered_unit_blob )
    result.must_equal(ordered_unit_blob )
    unordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "C", "D" ],
                                                  [ "B", "B" ],
                                                  [ "D", "E" ],
                                                  [ "E", "A" ],
                                                  [ "B", "C" ]
                                                ])
    ordered_unit_blob = create_fake_unit_blob([ 
                                                  [ "A", "B" ],
                                                  [ "B", "B" ],
                                                  [ "B", "C" ],
                                                  [ "C", "D" ],
                                                  [ "D", "E" ],
                                                  [ "E", "A" ]
                                                ])
    result = @seq.recursively_build_blob(
              :unit_blob => unordered_unit_blob )
    result.must_equal(ordered_unit_blob )
  end

  it "should have separate unit_blobs" do
    @seq.unit_blobs.each_index{ |index|
      unit_blob = @seq.unit_blobs[index]
      unit = unit_blob[0][OrderTrace::UNIT]
      unit_blob.each{|trace|
        trace[OrderTrace::UNIT].must_equal unit
      }
    }
  end

  it "should have ordered unit_blobs" do 
    unit_blobs = @seq.unit_blobs
    unit_blobs.each{|unit_blob|
      unit_blob.each_index{|index|
        trace = unit_blob[index]
        trace[OrderTrace::BEGINNING_STATE].must_equal $simple_trace_expected_order_of_states[index]
      }
    }
    unit_blobs = @seq3.unit_blobs
    unit_blobs.each{|unit_blob|
      unit_blob.each_index{|index|
        trace = unit_blob[index]
        trace[OrderTrace::BEGINNING_STATE].must_equal $simple_trace_expected_order_of_states[index]
      }
    }
  end

  #it "should be able to sort a hard trace" do 
  #  unit_blob = @seq2.unit_blobs[1]
  #  index = 0
  #  unit_blob.each{|trace|
  #    bs = trace[OrderTrace::BEGINNING_STATE]
  #    t = $hard_trace_states_00[index]
  #    bs.must_equal t 
  #    index += 1
  #  }
  #  @seq2.unit_blobs.size.must_equal 2
  #  unit_blob = @seq2.unit_blobs[0]
  #  index = 0
  #  unit_blob.each{|trace|
  #    bs = trace[OrderTrace::BEGINNING_STATE]
  #    t = $hard_trace_states_31[index]
  #    bs.must_equal t 
  #    index += 1
  #  }
  #end

  it "should construct a sequence line" do
    @seq2 = UnitBlobs.new( trace: $hard_trace )
    #fs = @seq2.get_states(:unit_blob=>@seq2.unit_blobs[0])
    #ss = @seq2.get_states(:unit_blob=>@seq2.unit_blobs[1])
    top_sequence_1 = @seq2.blob_for("31").get_top_sequence
    top_sequence_2 = @seq2.blob_for("00").get_top_sequence
    # top_sequence_1 = @seq2.get_top_sequences()[0] 
    ts1 = top_sequence_1
    ts2 = top_sequence_2
    fp = File.new("bob2.txt","w")
    fp.puts ts1
    fp.close
    # get_top_sequence
    # @seq2.blob_for("31").get_top_sequence
    # place 'debugger' here to see the output of this command
    fp = File.new($dump_file_name,"w+")
    fp.puts top_sequence_1
    fp.close
    # place 'debugger' here to see the output of this command
t1 =<<TOP_STRING_1
ActiveTestComplete   InvertRampDown      QualifyingAC       InvertSelect      EngagingInvert         Invert       ActiveTestofRelays 
TOP_STRING_1
    top_sequence_1.must_equal t1

    fp = File.new("bob2.txt","w")
    fp.puts ts2
    fp.close
t2 =<<TOP_STRING_2
    InvertSupport        QualifyingAC         InvertSelect     EngagingInvertSupport
TOP_STRING_2
    top_sequence_2.must_equal t2
    File.delete("bob2.txt")
  end
 
  it "should return the unit number for a given index" do
    @seq.unit(0).must_equal "31"
    @seq.unit(1).must_equal "00"
  end 

  it "should return the index for a given unit number" do
    @seq.index_for_unit("31").must_equal 0
    @seq.index_for_unit("00").must_equal 1
    @seq.index_for_unit("3094").must_equal nil
  end
  
  it "should be able to return the states for a given blob" do
    fs1 = @seq2.get_states(
      :unit_blob =>@seq2.unit_blobs[@seq2.index_for_unit("31")]) 
    fs2 = @seq2.blob_for("31").states
    fs1.must_equal fs2
    fs3 = @seq2.get_states(
      :unit_blob =>@seq2.unit_blobs[@seq2.index_for_unit("00")]) 
    fs4 = @seq2.blob_for("00").states
    fs3.must_equal fs4
    us1 = @seq2.unique_states[@seq2.index_for_unit("31")]
    us2 = @seq2.blob_for("31").unique_states
    us3 = @seq2.unique_states[@seq2.index_for_unit("00")]
    us4 = @seq2.blob_for("00").unique_states
    us3.must_equal us4
  end

  it "should have a get_max for UnitBlob" do 
    @seq2.blob_for("31").get_max_state_or_signal_width.must_equal 19
  end

  it "should return transition information for a given index" do 
    @seq2 = UnitBlobs.new( trace: $hard_trace )
    trans31 = @seq2.blob_for("31").transitions
    trans31.size.must_equal 8
    trans31[0].full_signal.must_equal "BB(514)"
  end
end

describe SequenceString do
  include OrderTrace
  before(:each) do
    @signal = "BB(514)"
    @depth  = 3 
    @sequence_width = 19
    @ss = SequenceString.new(
      signal: @signal, 
      depth:  @depth,
      sequence_width:  @sequence_width )
  end
  it "should be able to return and empty_sequence_block" do 
    expected_string_1=<<EXPECTED_STRING_1
|                 
|                 
|                 
EXPECTED_STRING_1
    fp = File.open("#{$dump_file_name}", "w" ) 
    @ss.empty_sequence_block().split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    @ss.empty_sequence_block().must_equal expected_string_1
    ss = SequenceString.new(
      signal: @signal,
      depth:  @depth,
      sequence_width: @sequence_width,
      is_empty: true )
    ss.draw_sequence_block().must_equal expected_string_1

  end
  it "shoul be able to return a sequence_block" do 
    expected_string_2=<<EXPECTED_STRING_2
+-----BB(514)---->
|       (?)       
|                 
EXPECTED_STRING_2
    fp = File.open("#{$dump_file_name}", "w" ) 
    @ss.sequence_block().split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    @ss.sequence_block().must_equal expected_string_2
    ss = SequenceString.new(
      signal: @signal,
      depth:  @depth,
      sequence_width: @sequence_width )
    ss.draw_sequence_block().must_equal expected_string_2
  end
  it "should be able to return a sequence blobk to self" do
    expected_string_3=<<EXPECTED_STRING_3
+                 
 \\ (?)            
 BB(514)          
 /                
<                 
EXPECTED_STRING_3
    fp = File.open("#{$dump_file_name}", "w" ) 
    @ss.sequence_block_to_self().split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    @ss.sequence_block_to_self().must_equal expected_string_3
    ss = SequenceString.new(
      signal: @signal,
      depth:  @depth,
      sequence_width: @sequence_width,
      is_self_reference: true )
    ss.draw_sequence_block().must_equal expected_string_3
  end
end

describe RightNamedSignal do
  include OrderTrace
  it "should output the expected strings" do
    @signal = "BB(514)"
    @depth  = 5 
    @sequence_width = 19
    spec = {
      signal: @signal,
      depth:  @depth,
      sequence_width: @sequence_width }
    rns = RightNamedSignal.new(spec)
    lns = LeftUnnamedSignal.new(spec)
    ns = NamedSignal.new(spec)
    us  = UnnamedSignal.new(spec)
    rus = RightUnnamedSignal.new(spec)
    nds  = DownNamedSignal.new(spec)
    bs  = BlankSignal.new(spec)
    lus = LeftUnnamedSignal.new(spec)
    fp = File.new("#{$dump_file_name}", "w")
    fp.puts "Left Unnamed Signal"
    fp.puts lus.to_s
    fp.puts "Right Named Signal"
    fp.puts rns.to_s
    fp.puts "Left Named Signal"
    fp.puts lns.to_s
    fp.puts "Named Siganal"
    fp.puts ns.to_s
    fp.puts "Unnamed Signal"
    fp.puts us.to_s
    fp.puts "Right Unnamed Signal"
    fp.puts rus.to_s
    fp.puts "Down Named Signal"
    fp.puts nds.to_s
    fp.puts "Blank Signal"
    fp.puts bs.to_s
    fp.close
  end
end

describe SequenceLineWriter do
  before(:each) do 
    @blobs = UnitBlobs.new( trace: $hard_trace )
    @blob = @blobs.blob_for("31")
    @unique_states = @blob.unique_states
    @transitions   = @blob.transitions
    @width         = @blob.max_state_or_signal_width()
    @signal = "BB(514)"
    @depth  = 5 
    @sequence_width = 19
    spec = {
      signal: @signal,
      depth:  @depth,
      sequence_width: @sequence_width }
    @rns = RightNamedSignal.new(spec)
    @lns = LeftNamedSignal.new(spec)
    @ns  = NamedSignal.new(spec)
    @us  = UnnamedSignal.new(spec)
    @rs  = RightUnnamedSignal.new(spec)
    @ls  = LeftUnnamedSignal.new(spec)
    @dns = DownNamedSignal.new(spec)
    @bs  = BlankSignal.new(spec)
    @cap = Cap.new(spec)
  end
  it "should be able to point right" do
    @slw = SequenceLineWriter.new(
     width: @width,
     unique_states: @unique_states,
     transition: @transitions[0] )
    ins = @slw.instructions
    us = @unique_states
    tr = @transitions 
    @slw.instructions.must_equal "rns + bs + bs + bs + bs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    @slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    tr = create_fake_transition(
      :first_state => "A",
      :last_state => "B" )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 7,
      :index_of_first_state => 0,
      :index_of_second_state => 1,
      :name_of_first_state   => "A",
      :name_of_second_state  => "B" )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "rns + bs + bs + bs + bs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_1=<<TARGET_1
+------B(223)----->|                  |                  |                  |                  |                  |
|       (?)        |                  |                  |                  |                  |                  |
TARGET_1
    slw.to_sequence_block.to_s.must_equal target_1
    tr = create_fake_transition(
      :first_state => "A",
      :last_state => "B" )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 0,
      :index_of_second_state => 4,
      :name_of_first_state   => "A",
      :name_of_second_state  => "B" )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    slw.instructions.must_equal "ns + us + us + rs + cap"
    target_2=<<TARGET_2
+------B(223)------+------------------+------------------+----------------->|
|       (?)        |                  |                  |                  |
TARGET_2
    slw.to_sequence_block.to_s.must_equal target_2
    tr = create_fake_transition(
      :first_state => "A",
      :last_state => "B" )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 1,
      :index_of_second_state => 3,
      :name_of_first_state   => "A",
      :name_of_second_state  => "B" )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + ns + rs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_3=<<TARGET_3
|                  +------B(223)------+----------------->|                  |
|                  |       (?)        |                  |                  |
TARGET_3
    slw.to_sequence_block.to_s.must_equal target_3
    ss = @bs +  @ns + @rs +  @bs + @cap 
    tr = create_fake_transition(
      :first_state => "A",
      :last_state => "B" )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 0,
      :index_of_second_state => 4,
      :name_of_first_state   => "A",
      :name_of_second_state  => "B" )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "ns + us + us + rs + cap"
    ss = @ns +  @us + @us + @rs + @cap 
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_4=<<TARGET_4
+------B(223)------+------------------+------------------+----------------->|
|       (?)        |                  |                  |                  |
TARGET_4
    slw.to_sequence_block.to_s.must_equal target_4
    tr = create_fake_transition(
      :first_state => "A",
      :last_state => "B" )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 3,
      :index_of_second_state => 4,
      :name_of_first_state   => "A",
      :name_of_second_state  => "B" )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + bs + bs + rns + cap"
    ss = @bs + @bs + @bs + @rns + @cap
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_4=<<TARGET_4
|                  |                  |                  +------B(223)----->|
|                  |                  |                  |       (?)        |
TARGET_4
    slw.to_sequence_block.to_s.must_equal target_4
  end
  it "should be able to point left" do
    fs = "A"
    ls = "B" 
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 1,
      :index_of_second_state => 0,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "lns + bs + bs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_5=<<TARGET_5
+<-----B(223)------|                  |                  |                  |
|       (?)        |                  |                  |                  |
TARGET_5
    slw.to_sequence_block.to_s.must_equal target_5
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 4,
      :index_of_second_state => 0,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "ls + us + us + ns + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
#    target_6=<<TARGET_6
#+<-----------------+------------------+------------------+-------B(223)-----|
#|                  |                  |                  |       (?)        |
#TARGET_6
#    slw.to_sequence_block.to_s.must_equal target_6
    ss = @ls + @us + @us + @ns + @cap 
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 3,
      :index_of_second_state => 1,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + ls + ns + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_7=<<TARGET_7
|                  +<-----------------+------B(223)------|                  |
|                  |                  |       (?)        |                  |
TARGET_7
    slw.to_sequence_block.to_s.must_equal target_7
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 4,
      :index_of_second_state => 3,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + bs + bs + lns + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_8=<<TARGET_8
|                  |                  |                  +<-----B(223)------|
|                  |                  |                  |       (?)        |
TARGET_8
    slw.to_sequence_block.to_s.must_equal target_8
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 2,
      :index_of_second_state => 1,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + lns + bs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_9=<<TARGET_9
|                  +<-----B(223)------|                  |                  |
|                  |       (?)        |                  |                  |
TARGET_9
    slw.to_sequence_block.to_s.must_equal target_9
  end
  
  it "should create a down arrow" do
    fs = "A"
    ls = "A" 
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 0,
      :index_of_second_state => 0,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "dns + bs + bs + bs + cap"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_10=<<TARGET_10
+                  |                  |                  |                  |
 \\ (?)             |                  |                  |                  |
 B(223)            |                  |                  |                  |
 /                 |                  |                  |                  |
<                  |                  |                  |                  |
TARGET_10
    slw.to_sequence_block.to_s.must_equal target_10
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 4,
      :index_of_second_state => 4,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + bs + bs + bs + dns"
    fp = File.open("#{$dump_file_name}", "w" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_11=<<TARGET_11
|                  |                  |                  |                  +                  
|                  |                  |                  |                   \\ (?)             
|                  |                  |                  |                   B(223)            
|                  |                  |                  |                   /                 
|                  |                  |                  |                  <                  
TARGET_11
    slw.to_sequence_block.to_s.must_equal target_11
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 2,
      :index_of_second_state => 2,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + bs + dns + bs + cap"
    fp = File.open("#{$dump_file_name}", "w+" ) 
    slw.to_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_12=<<TARGET_12
|                  |                  +                  |                  |
|                  |                   \\ (?)             |                  |
|                  |                   B(223)            |                  |
|                  |                   /                 |                  |
|                  |                  <                  |                  |
TARGET_12
    slw.to_sequence_block.to_s.must_equal target_12
    tr = create_fake_transition(
      :first_state => fs,
      :last_state => ls )
    us = create_fake_unique_states(
      :total_number_of_unique_states => 5,
      :index_of_first_state => 2,
      :index_of_second_state => 2,
      :name_of_first_state   => fs,
      :name_of_second_state  => ls )
    slw = SequenceLineWriter.new(
      width: @width,
      unique_states: us,
      transition: tr )
    slw.instructions.must_equal "bs + bs + dns + bs + cap"
    fp = File.open("#{$dump_file_name}", "w+" ) 
    slw.to_padded_sequence_block.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_13=<<TARGET_13
         |                  |                  +                  |                  |
         |                  |                   \\ (?)             |                  |
         |                  |                   B(223)            |                  |
         |                  |                   /                 |                  |
         |                  |                  <                  |                  |
TARGET_13
    slw.to_padded_sequence_block.to_s.must_equal target_13
    $dout = slw.to_padded_sequence_block.to_s
  end
  Ftransition = Struct.new(:first_state, :last_state, :full_signal )

  def create_fake_transition( spec ) 
    first_state = spec[:first_state]
    last_state  = spec[:last_state]
    signal      = "B(223)" 
    Ftransition.new( first_state, last_state, signal)
  end

  def create_fake_unique_states(spec)
    total_number_of_unique_states = spec[:total_number_of_unique_states]
    index_of_first_state          = spec[:index_of_first_state]
    index_of_second_state         = spec[:index_of_second_state]
    name_of_first_state           = spec[:name_of_first_state]
    name_of_second_state          = spec[:name_of_second_state]
    fake_unique_states = Array.new(total_number_of_unique_states)
    fake_unique_states[index_of_first_state] = name_of_first_state
    fake_unique_states[index_of_second_state] = name_of_second_state
    fake_unique_states
  end
end
describe SequenceDiagramForBlob do
  before do
   debugging_thing =  UnitBlobs.new( trace: $hard_trace )
   @blob_31 = debugging_thing.blob_for("31")
   @blob_00 = debugging_thing.blob_for("00")
  end
  it "should create a sequence diagram for a blob" do
    sdfb = SequenceDiagramForBlob.new( blob: @blob_31 )
    fp = File.open("#{$dump_file_name}", "w+" ) 
    sdfb.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_14=<<TARGET_14
ActiveTestComplete   InvertRampDown      QualifyingAC       InvertSelect      EngagingInvert         Invert       ActiveTestofRelays 
         +------BB(514)---->|                  |                  |                  |                  |                  |
         |       (?)        |                  |                  |                  |                  |                  |
         |                  +-----IRDC(646)--->|                  |                  |                  |                  |
         |                  |       (?)        |                  |                  |                  |                  |
         |                  |                  +                  |                  |                  |                  |
         |                  |                   \\ (?)             |                  |                  |                  |
         |                  |                   DD(51)            |                  |                  |                  |
         |                  |                   /                 |                  |                  |                  |
         |                  |                  <                  |                  |                  |                  |
         |                  |                  +------Init(3)---->|                  |                  |                  |
         |                  |                  |       (?)        |                  |                  |                  |
         |                  |                  |                  +------Init(3)---->|                  |                  |
         |                  |                  |                  |       (?)        |                  |                  |
         |                  |                  |                  |                  +                  |                  |
         |                  |                  |                  |                   \\ (?)             |                  |
         |                  |                  |                  |                   N(559)            |                  |
         |                  |                  |                  |                   /                 |                  |
         |                  |                  |                  |                  <                  |                  |
         |                  |                  |                  |                  |                  +-----BFT(651)---->|
         |                  |                  |                  |                  |                  |       (?)        |
         +<-----------------+------------------+------------------+------------------+------------------+-----BFTC(652)----|
         |                  |                  |                  |                  |                  |       (?)        |
TARGET_14
    sdfb.to_s.must_equal target_14 
    sdfb = SequenceDiagramForBlob.new( blob: @blob_00 )
    fp = File.open("#{$dump_file_name}", "w+" ) 
    sdfb.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_15=<<TARGET_15
    InvertSupport        QualifyingAC         InvertSelect     EngagingInvertSupport
          +-------BB(514)----->|                    |                    |
          |        (?)         |                    |                    |
          |                    +-------Init(3)----->|                    |
          |                    |        (?)         |                    |
          |                    |                    +-------Init(3)----->|
          |                    |                    |        (?)         |
          +<-------------------+--------------------+-------N(559)-------|
          |                    |                    |        (?)         |
          +-------DD(51)------>|                    |                    |
          |        (?)         |                    |                    |
          |                    +-------Init(3)----->|                    |
          |                    |        (?)         |                    |
          |                    |                    +-------Init(3)----->|
          |                    |                    |        (?)         |
          +<-------------------+--------------------+-------N(559)-------|
          |                    |                    |        (?)         |
TARGET_15
    sdfb.to_s.must_equal target_15
  end
end
describe SequenceDiagram do
  before do
  hard_trace =<<HARD_TRACE
[2012-10-18 08:21:25] [31] uiErrNum->2 siErrVal->555 FAULT: AC Output Over Voltage
[2012-10-18 08:21:25] [31] Trig->BB(514) ActiveTestComplete->InvertRampDown
[2012-10-18 08:21:25] [00] uiErrNum->74 siErrVal->0 FAULT: Other Unit Invert Fault
[2012-10-18 08:21:25] [00] Trig->BB(514) InvertSupport->QualifyingAC
[2012-10-18 08:21:25] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
[2012-10-18 08:21:25] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:25] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:26] [31] Trig->IRDC(646) InvertRampDown->QualifyingAC
[2012-10-18 08:21:40] [31] Trig->DD(51) QualifyingAC->QualifyingAC
[2012-10-18 08:21:40] [31] Trig->N(559) EngagingInvert->EngagingInvert
[2012-10-18 08:21:40] [31] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:40] [31] Trig->Init(3) InvertSelect->EngagingInvert
[2012-10-18 08:21:40] [31] Trig->BFT(651) Invert->ActiveTestofRelays 
[2012-10-18 08:21:42] [31] Trig->BFTC(652) ActiveTestofRelays->ActiveTestComplete
[2012-10-18 08:21:42] [00] Trig->DD(51) InvertSupport->QualifyingAC
[2012-10-18 08:21:42] [00] Trig->Init(3) QualifyingAC->InvertSelect
[2012-10-18 08:21:42] [00] Trig->Init(3) InvertSelect->EngagingInvertSupport
[2012-10-18 08:21:42] [00] Trig->N(559) EngagingInvertSupport->InvertSupport
HARD_TRACE
    @diagram = SequenceDiagram.new( trace: $hard_trace )
  end

  it "should look as expected" do
    fp = File.open("#{$dump_file_name}", "w+" ) 
    @diagram.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_16=<<TARGET_16
[ Unit: 31 ] (?)
ActiveTestComplete   InvertRampDown      QualifyingAC       InvertSelect      EngagingInvert         Invert       ActiveTestofRelays 
         +-----BB(514)----->|                  |                  |                  |                  |                  |
         |       (?)        |                  |                  |                  |                  |                  |
         |                  +----IRDC(646)---->|                  |                  |                  |                  |
         |                  |       (?)        |                  |                  |                  |                  |
         |                  |                  +                  |                  |                  |                  |
         |                  |                   \\ (?)             |                  |                  |                  |
         |                  |                   DD(51)            |                  |                  |                  |
         |                  |                   /                 |                  |                  |                  |
         |                  |                  <                  |                  |                  |                  |
         |                  |                  +-----Init(3)----->|                  |                  |                  |
         |                  |                  |       (?)        |                  |                  |                  |
         |                  |                  |                  +-----Init(3)----->|                  |                  |
         |                  |                  |                  |       (?)        |                  |                  |
         |                  |                  |                  |                  +                  |                  |
         |                  |                  |                  |                   \\ (?)             |                  |
         |                  |                  |                  |                   N(559)            |                  |
         |                  |                  |                  |                   /                 |                  |
         |                  |                  |                  |                  <                  |                  |
         |                  |                  |                  |                  |                  +----BFT(651)----->|
         |                  |                  |                  |                  |                  |       (?)        |
         +<-----------------+------------------+------------------+------------------+------------------+----BFTC(652)-----|
         |                  |                  |                  |                  |                  |       (?)        |

[ Unit: 00 ] (?)
    InvertSupport        QualifyingAC         InvertSelect     EngagingInvertSupport
          +------BB(514)------>|                    |                    |
          |        (?)         |                    |                    |
          |                    +------Init(3)------>|                    |
          |                    |        (?)         |                    |
          |                    |                    +------Init(3)------>|
          |                    |                    |        (?)         |
          +<-------------------+--------------------+------N(559)--------|
          |                    |                    |        (?)         |
          +------DD(51)------->|                    |                    |
          |        (?)         |                    |                    |
          |                    +------Init(3)------>|                    |
          |                    |        (?)         |                    |
          |                    |                    +------Init(3)------>|
          |                    |                    |        (?)         |
          +<-------------------+--------------------+------N(559)--------|
          |                    |                    |        (?)         |

TARGET_16
    #@diagram.to_s.must_equal target_16
  end
  it "should be able to have padded output" do
    
    @diagram = SequenceDiagram.new( trace: $indented_simple_trace )
    fp = File.open("#{$dump_file_name}", "w+" ) 
    @diagram.to_s.split("\n").each{|line|
      fp.puts line
    }
    fp.close
    # place 'debugger' here to see the output of this command
    target_17=<<TARGET_17
    [ Unit: 31 ] (?)
    [Statechart: 31] (?)
     QualifyingAC   PendingAcGood EngagingAcGood     AcGood     EngagingCharge    XfrmReset       Charge      EngagingBulk       Bulk
           +---P(522)---->|              |              |              |              |              |              |              |
           |     (?)      |              |              |              |              |              |              |              |
           |              +--PPP(549)--->|              |              |              |              |              |              |
           |              |     (?)      |              |              |              |              |              |              |
           |              |              +---U(606)---->|              |              |              |              |              |
           |              |              |     (?)      |              |              |              |              |              |
           |              |              |              +---Init(3)--->|              |              |              |              |
           |              |              |              |     (?)      |              |              |              |              |
           |              |              |              |              +---M(558)---->|              |              |              |
           |              |              |              |              |     (?)      |              |              |              |
           |              |              |              |              |              +--XRC(649)--->|              |              |
           |              |              |              |              |              |     (?)      |              |              |
           |              |              |              |              |              |              +---Init(3)--->|              |
           |              |              |              |              |              |              |     (?)      |              |
           |              |              |              |              |              |              |              +---KK(670)--->|
           |              |              |              |              |              |              |              |     (?)      |

    [Statechart: 00] (?)
     QualifyingAC   PendingAcGood EngagingAcGood     AcGood     EngagingCharge    XfrmReset       Charge      EngagingBulk       Bulk
           +---P(522)---->|              |              |              |              |              |              |              |
           |     (?)      |              |              |              |              |              |              |              |
           |              +--PPP(549)--->|              |              |              |              |              |              |
           |              |     (?)      |              |              |              |              |              |              |
           |              |              +---U(606)---->|              |              |              |              |              |
           |              |              |     (?)      |              |              |              |              |              |
           |              |              |              +---Init(3)--->|              |              |              |              |
           |              |              |              |     (?)      |              |              |              |              |
           |              |              |              |              +---M(558)---->|              |              |              |
           |              |              |              |              |     (?)      |              |              |              |
           |              |              |              |              |              +--XRC(649)--->|              |              |
           |              |              |              |              |              |     (?)      |              |              |
           |              |              |              |              |              |              +---Init(3)--->|              |
           |              |              |              |              |              |              |     (?)      |              |
           |              |              |              |              |              |              |              +---KK(670)--->|
           |              |              |              |              |              |              |              |     (?)      |    

TARGET_17
    # debugger
    # @diagram.to_s.must_equal target_17
  end
end

#MiniTest::Unit.after_tests{
#  File.delete("bob.txt")
#  #p $dout
#}
#
describe SequenceDiagram do
  before do
  $hard_trace =<<HARD_SNOOP_TRACE
  [+t] [2018-05-04 09:23:29.177773] [04ccc_ao] e->start_at() top->outer
  [+t] [2018-05-04 09:23:28.954560] [2771f_ao] e->start_at() top->outer
  [+t] [2018-05-04 09:23:34.178157] [04ccc_ao] e->to_inner() outer->inner
  [+t] [2018-05-04 09:23:34.256485] [2771f_ao] e->other_to_inner() outer->inner
  [+t] [2018-05-04 09:23:37.178813] [04ccc_ao] e->to_outer() inner->outer
  [+t] [2018-05-04 09:23:37.182660] [2771f_ao] e->other_to_outer() inner->outer
  [+t] [2018-05-04 09:23:39.180004] [04ccc_ao] e->to_inner() outer->inner
  [+t] [2018-05-04 09:23:39.191635] [2771f_ao] e->to_inner() outer->inner
  [+t] [2018-05-04 09:23:44.181613] [04ccc_ao] e->to_outer() inner->outer
  [+t] [2018-05-04 09:23:44.257442] [2771f_ao] e->other_to_outer() inner->outer
  [+t] [2018-05-04 09:23:49.183205] [04ccc_ao] e->to_inner() outer->inner
  [+t] [2018-05-04 09:23:49.233582] [2771f_ao] e->other_to_inner() outer->inner
HARD_SNOOP_TRACE
  $target_18 =<<TARGET_18
  [Statechart: 04ccc_ao] (?)
        top           outer          inner     
         +--start_at()->|              |
         |     (?)      |              |
         |              +--to_inner()->|
         |              |     (?)      |
         |              +<-to_outer()--|
         |              |     (?)      |
         |              +--to_inner()->|
         |              |     (?)      |
         |              +<-to_outer()--|
         |              |     (?)      |
         |              +--to_inner()->|
         |              |     (?)      |

  [Statechart: 2771f_ao] (?)
           top                 outer                inner
            +-----start_at()---->|                    |
            |        (?)         |                    |
            |                    +--other_to_inner()->|
            |                    |        (?)         |
            |                    +<-other_to_outer()--|
            |                    |        (?)         |
            |                    +-----to_inner()---->|
            |                    |        (?)         |
            |                    +<-other_to_outer()--|
            |                    |        (?)         |
            |                    +--other_to_inner()->|
            |                    |        (?)         |

TARGET_18
    @diagram = SequenceDiagram.new( trace: $hard_trace )
  end

  it "should look as expected" do
    result =  @diagram.to_s.split("\n").map(&:rstrip).join("\n")
    target = $target_18.split("\n").map(&:rstrip).join("\n") + "\n\n"
    result.must_equal target
    #puts(@diagram.to_s)
  end
end
