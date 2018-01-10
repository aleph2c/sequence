begin
  # don't break if someone hasn't installed a debugger
  require "byebug"
end

require "time"
require "optparse"
module PackageConfiguration
  # none self referencing signal depth
  DEFAULT_SEQUENCE_DIAGRAM_DEPTH = 2

  # glyphs used in the sequence diagram
  SEQUENCE_DIAGRAM_STATE_BAR = "|"
  EMPTY_SPACE                = " "
  NEW_LINE                   = "\n"
  SIGNAL_START               = "+"
  SIGNAL_RIGHT_ARROW         = ">"
  SIGNAL_LEFT_ARROW          = "<"
  SIGNAL_ARROW_SHAFT         = "-"
end

module OrderTrace
  TIME            = 0
  UNIT            = 1
  SIGNAL          = 2
  SIGNAL_NUMBER   = 3
  SIGNAL_NAME     = 4
  BEGINNING_STATE = 5
  END_STATE       = 6
  COMPLETE        = 7

  def filter_trace(spec)
   trace = spec[:trace]
   trace_array = parse_and_filter_trace_trace(trace)
   trace_array
  end

  def parse_and_filter_trace_trace(trace_string)
   item_number = 0
   trace_array = []
   trace_hash = {}
   # break up the input based on there newline characters
   trace_string.split("\n").each{|t_string|
    # find 2012-10-16 13:30:18 in
    # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
    $user_padding = t_string.match(/^([ ]+)\[/)[1] rescue $user_padding = ""
    begin
      time_string   = t_string.match(/^ *\[(.+?)\]/)[1]
    rescue
      next
    end
    # find 31 in
    # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
    t_unit = t_string.match(/\[#{time_string}\] \[([0-9a-zA-Z_.]+)+\]/)[1]
    # find P(522) in
    # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
    t_signal = t_string.match(/(.)?->(.+?\))/)[2] rescue nil
    if( t_signal )
      # find P in
      # P(522)
      signal_name = t_signal.match(/(.+?)\(/)[1]
      # find 522 in
      # P(522)
      signal_number = t_signal.match(/\((.+)\)/)[1] rescue ""
      # fine QualifyingAC in
      # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
      t_beginning_string = t_string.match(/#{signal_number}\) (.+?)->/)[1]
      # fine PendingAcGood in
      # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
      t_ending_string = t_string.match(/#{t_beginning_string}->(.+)/)[1]
      trace_hash[item_number] = { :time=>Time.parse(time_string),
              :unit=>t_unit,
              :signal=>t_signal,
              :signal_name=>signal_name,
              :signal_number=>signal_number,
              :beginning_state=>t_beginning_string,
              :ending_state=>t_ending_string,
              :string=>t_string}
      time = Time.parse(time_string)
      trace_array << [
       time,
       t_unit,
       t_signal,
       signal_name,
       signal_number,
       t_beginning_string,
       t_ending_string,
       t_string ]

      item_number += 1
    end
   }
   trace_array
  end

  # This unit blobs are just a collection of items that contain
  # information all relating to the same unit number, for instance, in the
  # following trace item, the unit would be 31.
  # [2012-10-16 13:30:18] [31] Trig->P(522) QualifyingAC->PendingAcGood
  # This and all other trace items with this same number would have their
  # information
  def create_unit_blobs(spec)
   # use a hash to index the units
   unit_blob_index = {}
   trace = spec[:trace]
   trace.each{|reading|
    if( unit_blob_index.has_key?(reading[UNIT]) )
      unit_blob_index[reading[UNIT]] << reading
    else
      # initialize the hash with an array with one item
      unit_blob_index[reading[UNIT]] = [reading]
    end
   }
   # transfer the hash results into an array
   unit_blobs = []
   unit_index = 0
   unit_blob_index.each_key{|unit_number|
    unit_blobs[unit_index] = unit_blob_index[unit_number]
    unit_index += 1
   }
   # return the unit_blobs array
   unit_blobs
  end

  def get_state_ordered_time_blobs(spec)
   unit_blob = spec[:unit_blob]
   time_blob_index = {}
   unit_blob.each{|trace|
    if( time_blob_index.has_key?(trace[TIME]) )
      time_blob_index[trace[TIME]] << trace
    else
      time_blob_index[trace[TIME]] = [ trace ]
    end
   }
   time_blobs = []
   time_blob_index.each_key{|time|
     # each of these small unit_blobs in the time_blob_index[time] all have the
     # same time stamp, therefore we need to recursively parse it into a series
     # that is temporally truthful without the timestamp
     time_blobs += recursively_build_blob( :unit_blob => time_blob_index[time] )
   }
   time_blobs
  end

  def recursively_find_init_state(spec)
    # initialize our state to nil so we can return nil,
    # if there is nothing to be found
    init_state = nil
    unit_blob = spec[:unit_blob]

    # ensure the caller does not have to populate the
    # specification with :states, since they probably don't
    # care about this
    states = ( spec.has_key?(:states ) ) ?
      states = spec[:states].dup :
      get_states(:unit_blob => unit_blob )

    # for each state
    states.each{|state|
      # assume we have found the state
      init_state = state
      unit_blob.each{|trace|
        # continue our search if we have disqualified this
        # state as a potential init_state, but, only do this
        # if the value isn't self referencing, or a loop
        # back trace
        if( state == trace[OrderTrace::END_STATE] )
          unless( state == trace[OrderTrace::BEGINNING_STATE] )
            # we are sure that this is not the correct initial
            # state, so we delete it from our list of contenders
            # and call this function again to find the answer
            states.delete(state)
            init_state = recursively_find_init_state(
                          :unit_blob => spec[:unit_blob],
                          :states    => states )
          end
        end
      }
      # we have found what we are looking for, break out of the
      # unit_blob iterator with the answer
      break
    }
    init_state
  end

  def order_unit_blobs(spec)
    filtered_trace = filter_trace(:trace=>spec[:trace])
    @filtered_trace = filtered_trace
    @trace = spec[:trace]
    unit_blobs = create_unit_blobs(:trace=>filtered_trace)
    unit_blobs
  end

  def recursively_build_blob(spec)
    # ensure that a caller can call without :unit_blob_so_far
    # populated or named
    unit_blob_so_far = ( spec.has_key?(:unit_blob_so_far ) ) ?
      spec[:unit_blob_so_far] : []

    # create a copy of the spec since we will be changing it
    # and since things are passed by reference we do not want
    # to affect the caller's object
    unit_blob = spec[:unit_blob].dup

    # find the initial state for this unit_blob
    init_state =
      recursively_find_init_state( :unit_blob => unit_blob )

    # dealing with loops
    if( init_state.nil? )
      # if the first state loops around to itself, we will
      # have a nil in our current init_state and there will
      # be no next_initial_candidate in our spec
      if( spec[:next_initial_candidate].nil? )
        # just use our first state as our init state and
        # continue
        init_state = unit_blob[0][OrderTrace::BEGINNING_STATE]
      else
        # we have found a loop within our list at a
        # recursion level greater than 1
        init_state = spec[:next_initial_candidate]
      end
    end

    # for each trace in the unit blob
    spec[:unit_blob].each{|trace|
      tbs = trace[OrderTrace::BEGINNING_STATE]
      # we have found the initial state for this
      # unit blob, add it to our results, snip
      # our working copy of the unit_blob and call
      # this method to find the rest of the result
      if( tbs == init_state )
        next_initial_candidate = trace[OrderTrace::END_STATE]
        unit_blob_so_far += [ trace ]
        unit_blob.delete(trace)
        unit_blob_so_far = recursively_build_blob(
                    :unit_blob => unit_blob,
                    :unit_blob_so_far => unit_blob_so_far,
                    :next_initial_candidate => next_initial_candidate )
        # we have found everything we were looking for, so
        # break and return what we have
        break
      end
    }
    unit_blob_so_far
  end

end
class Transition
  include OrderTrace
  attr_reader :full_signal, :signal_number, :signal_letter, :first_state, :last_state, :time_stamp, :depth

  def initialize(spec)
    @trace_obj = spec[:trace_obj]
    @full_signal   = @trace_obj[OrderTrace::SIGNAL].strip
    @signal_number = @trace_obj[OrderTrace::SIGNAL_NUMBER].strip
    @signal_letter = @trace_obj[OrderTrace::SIGNAL_NAME].strip
    @first_state   = @trace_obj[OrderTrace::BEGINNING_STATE].strip
    @last_state    = @trace_obj[OrderTrace::END_STATE].strip
    @time_stamp    = @trace_obj[OrderTrace::TIME].to_s.strip
  end

  def to_s
    output = ""
    newline = "\n"
    output += "full_signal: " + @full_signal.to_s
    output += newline
    output += "first_state: " + @first_state.to_s
    output += newline
    output += "last_state:  " + @last_state.to_s
    output += newline
    output
  end

end
module SequenceGlyphs
  @@delimiter        = "|"
  @@empty            = " "
  @@new_line         = "\n"

  @@number           = "(%{number})"
  @@signal_start     = "+"
  @@signal_end_right = ">"
  @@signal_end_left  = "<"
  @@self_signal_end  = "<"
  @@signal_dash      = "-"
  @@down_slash       = '\\'
  @@up_slash         = "/"
end
class SequenceBlock
  include SequenceGlyphs
  include PackageConfiguration
  DEFAULT_DEPTH = DEFAULT_SEQUENCE_DIAGRAM_DEPTH
  SELF_REFERENCE_DEPTH = 5
  attr_reader :width, :number, :depth, :block

  def initialize(spec)
    if( spec.has_key?(:redraw)!=true )
      @block = nil
      @is_self_reference = spec[:is_self_reference]
      @is_empty          = spec[:is_empty]
      @signal = spec[:signal]
      @width  = spec[:sequence_width]
      @number = ( spec.has_key?(:number) == true ) ? spec[:number].to_s : "?"
      if( @is_self_reference == true )
        @depth = SELF_REFERENCE_DEPTH
      else
        @depth  = ( spec.has_key?(:depth) == true ) ? spec[:depth] : DEFAULT_DEPTH
      end
      @block = draw()
    else
      @block = spec[:block]
      @depth = spec[:depth]
    end
  end

  def +(other)
    raise "other has to be a type of #{self.class}" unless other.kind_of?(self.class.superclass)
    raise "blocks must have the same depth" unless other.depth == self.depth
    this_block_array  = @block.split("\n")
    other_block_array = other.block.split("\n")
    result = ""
    this_block_array.each_index{|line_index|
      this_line = this_block_array[line_index]
      other_line = other_block_array[line_index]
      re  = this_line
      re += other_line
      re += @@new_line
      result += re
    }
    SequenceBlock.new( block: result, depth: @depth, redraw: true )
  end

  def to_s
    @block
  end

  def draw
    raise "this needs to be implemented in your class"
  end

  def signal_draw(spec)
    direction = spec[:direction]
    named     = spec[:named]

    second_from_left_point   = @@signal_dash
    left_attach_glyph        = @@signal_start
    if( direction==:right )
      right_attach_glyph     = @@signal_end_right
    elsif( direction==:left )
      right_attach_glyph     = @@signal_dash
      second_from_left_point = @@signal_end_left
    else
      right_attach_glyph     = @@signal_dash
    end

    block = ""
    1.upto(@depth){|line|
      if( line == 1 )
        if( named == true )
          b = @signal.center(@width, @@signal_dash )
        else
          b = @@signal_dash*@width
        end
        b[ 0]  = left_attach_glyph
        b[ 1]  = second_from_left_point
        b[-1]  = right_attach_glyph
        b     += @@new_line
        block += b
      elsif( line == 2 )
        if ( named == true )
          b = ( @@number % { :number => @number } ).center(@width)
        else
          b      = " ".center(@width)
        end
        b[0]   = @@delimiter
        b     += @@new_line
        block += b
      else
        b      = " ".center(@width)
        b[0]   = @@delimiter
        b     += @@new_line
        block += b
      end
    }
    block
  end
end
# Right Named Signal
# +-----BB(514)---->
# |       (?)
# |
class RightNamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :right, named: true )
  end
end
# Named Siganal
# +-----BB(514)-----
# |       (?)
# |
class NamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :none, named: true )
  end
end
# Left Named Signal
# +<----BB(514)----+
# |       (?)
# |
class LeftNamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :left, named: true )
  end
end
# Unnamed Signal
# +-----------------
# |
# |
class UnnamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :none )
  end
end
# Right Unnamed Signal
# +---------------->
# |
# |
class RightUnnamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :right )
  end
end

class LeftUnnamedSignal < SequenceBlock
  def draw
    signal_draw(direction: :left )
  end
end
# Blank Signal
# |
# |
# |
class BlankSignal < SequenceBlock
  def draw
    block = ""
    1.upto(@depth){|line|
      b      = " ".center(@width)
      b[0]   = @@delimiter
      b     += @@new_line
      block += b
    }
    block
  end
end
# Down Named Signal
# +
#  \ (?)
#  BB(514)
#  /
# <
class DownNamedSignal < SequenceBlock
  def initialize(spec)
    super(spec)
    @depth = SELF_REFERENCE_DEPTH
  end
  def draw
    block = ""
    1.upto(SELF_REFERENCE_DEPTH){|line|
      if( line == 1 )
        b      = " ".center(@width)
        b[ 0]  = @@signal_start
        b     += @@new_line
        block += b
      elsif( line == 2 )
        b      = " ".center(@width)
        b[1]   = @@down_slash
        b[3]   = @@number % { :number => @number }
        b.slice! @width..-1
        b     += @@new_line
        block += b
      elsif( line == 3 )
        b      = " ".center(@width)
        b[1]   = @signal
        b.slice! @width..-1
        b     += @@new_line
        block += b
      elsif( line == 4 )
        b      = " ".center(@width)
        b[1]   = @@up_slash
        b     += @@new_line
        block += b
      elsif( line == SELF_REFERENCE_DEPTH )
        b      = " ".center(@width)
        b[0]   = @@self_signal_end
        b     += @@new_line
        block += b
      else
        raise "we shouldn't get here"
      end
    }
    block
  end
end
class Cap < SequenceBlock
  def draw
    block = (@@delimiter+@@new_line)*@depth
    block
  end
end
class Pad < SequenceBlock
  def draw
    half_width = @width/2
    block  = " "*half_width
    block += @@new_line
    block *= @depth
  end
end

class SequenceLineWriter
  attr_reader :instructions
  @@signal_classes = {
    :rns => RightNamedSignal,
    :lns => LeftNamedSignal,
    :dns => DownNamedSignal,
    :bs  => BlankSignal,
    :us  => UnnamedSignal,
    :ns  => NamedSignal,
    :rs  => RightUnnamedSignal,
    :ls  => LeftUnnamedSignal,
    :cap => Cap,
    :pad => Pad
  }
  def initialize(spec)
    @width      = spec[:width]
    @transition = spec[:transition]
    @unique_states = spec[:unique_states]
    @instruction_set = create_instruction_set(
                        first_state_index:
                          @unique_states.find_index(@transition.first_state),
                        last_state_index:
                          @unique_states.find_index(@transition.last_state),
                        instructions_needed:
                          @unique_states.size )
    # for testing purposes we create this object variable
    @instructions = @instruction_set.map{|x| x.to_s }.join(" + ")
    @pad          = @@signal_classes[:pad].new(create_signal_spec())
  end

  def create_signal_spec()
    signal_spec = {}
    signal_spec[:depth] = ( @instruction_set.include?(:dns.to_s) )?
      SequenceBlock::SELF_REFERENCE_DEPTH :
      SequenceBlock::DEFAULT_DEPTH
    signal_spec[:signal] = @transition.full_signal
    raise "signal can not be nil" unless signal_spec[:signal]!=nil
    signal_spec[:sequence_width] = @width
    signal_spec
  end

  def create_all_signals()
    spec = create_signal_spec()
    signals = {}
    @@signal_classes.each_key{|instr|
      signals[instr] = @@signal_classes[instr].new(spec)
    }
    signals
  end

  def to_sequence_block()
    all_signals = create_all_signals()
    signals_needed = @instruction_set.map{|s|
      all_signals[s.to_sym]
    }
    full_sequence_string = signals_needed.inject{|sequence_string,n| sequence_string + n }
    full_sequence_string
  end

  def to_padded_sequence_block()
    padded_sequence_block = @pad + to_sequence_block()
    padded_sequence_block
  end

  def create_instruction_set(spec)
    first_state_index = spec[:first_state_index]
    last_state_index   = spec[:last_state_index]
    instructions_needed = spec[:instructions_needed]

    if( first_state_index == last_state_index )
      instruction_set =
        create_down_arrow_instruction_set(spec)
    elsif( first_state_index < last_state_index )
      instruction_set =
        create_right_arrow_instruction_set(spec)
    else
      instruction_set =
        create_left_array_instruction_set(spec)
    end
    instruction_set
  end

  def create_down_arrow_instruction_set(spec)
    first_state_index   = spec[:first_state_index]
    last_state_index    = spec[:last_state_index]
    instructions_needed = spec[:instructions_needed]
  end

  def create_right_arrow_instruction_set(spec)
    first_state_index = spec[:first_state_index]
    last_state_index   = spec[:last_state_index]
    instructions_needed = spec[:instructions_needed]-1
    instruction_set     = Array.new(instructions_needed, :bs.to_s )
    if( last_state_index == first_state_index+1 )
      instruction_set[first_state_index] = :rns.to_s
    else
      first_state_index.upto(last_state_index-1){|index|
        if( first_state_index - index == 0 )
          instruction_set[index] = :ns.to_s
        else
          instruction_set[index] = :us.to_s
        end
      }
      instruction_set[last_state_index-1] = :rs.to_s
    end
    instruction_set.push(:cap.to_s)
    instruction_set
  end

  def create_left_array_instruction_set(spec)
    first_state_index = spec[:first_state_index]
    last_state_index   = spec[:last_state_index]
    instructions_needed = spec[:instructions_needed]-1
    instruction_set     = Array.new(instructions_needed,:bs.to_s)
    if( last_state_index == first_state_index-1 )
      if( first_state_index != instructions_needed-1 )
        instruction_set[last_state_index] = :lns.to_s
      else
        instruction_set[first_state_index] = :lns.to_s
      end
    else
      last_state_index.upto(first_state_index-1){|index|
        if( last_state_index - index == 0 )
          instruction_set[index] = :ls.to_s
        else
          instruction_set[index] = :us.to_s
        end
      }
      instruction_set[first_state_index-1] = :ns.to_s
    end
    instruction_set.push(:cap.to_s)
    instruction_set
  end

  def create_down_arrow_instruction_set(spec)
    signal = spec[:signal]
    first_state_index = spec[:first_state_index]
    last_state_index   = spec[:last_state_index]
    instructions_needed = spec[:instructions_needed]
    instruction_set     = Array.new(instructions_needed,:bs.to_s )
    if( instructions_needed-1 == first_state_index )
      instruction_set[first_state_index] = :dns.to_s
    else
      instruction_set[first_state_index] = :dns.to_s
      instruction_set[-1] = :cap.to_s
    end
    instruction_set
  end
end

class SequenceDiagramForBlob
  def initialize(spec)
    @blob = spec[:blob]
    @diagram = [ @blob.get_top_sequence() ]
    @blob.transitions.each{|transition|
      @diagram.push SequenceLineWriter.new(
        width: @blob.get_max_state_or_signal_width(),
        unique_states: @blob.unique_states,
        transition: transition ).to_padded_sequence_block.to_s
    }
    @result = ""
    @diagram.each{|element| @result += element }
  end

  def to_s
    @result
  end
end

class SequenceDiagram
  attr_reader :unit_blobs
  def initialize(spec)
    @unit_blobs = UnitBlobs.new(spec)
    @sequence_diagram = $user_padding
    @unit_blobs.each{|unit_blob|
      @sequence_diagram += "[ Chart: %{unit_blob_number} ]" % {:unit_blob_number => unit_blob.unit_number }
      @sequence_diagram += " (?)"
      @sequence_diagram += "\n"
      @sequence_diagram += $user_padding
      SequenceDiagramForBlob.new(blob: unit_blob)
        .to_s.split("\n").each{|line|
          @sequence_diagram += line
          @sequence_diagram += "\n"
          @sequence_diagram += $user_padding
      }
      @sequence_diagram += "\n"
      @sequence_diagram += $user_padding
    }
  end

  def to_s
    @sequence_diagram
  end
end

class SequenceString
  include PackageConfiguration
  DEFAULT_DEPTH = DEFAULT_SEQUENCE_DIAGRAM_DEPTH
  SELF_REFERENCE_DEPTH = 5
  attr_reader :width, :number

  @@delimiter        = SEQUENCE_DIAGRAM_STATE_BAR
  @@empty            = EMPTY_SPACE
  @@new_line         = NEW_LINE

  @@number           = "(%{number})"
  @@signal_start     = SIGNAL_START
  @@signal_end_right = SIGNAL_RIGHT_ARROW
  @@self_signal_end  = SIGNAL_LEFT_ARROW
  @@signal_dash      = SIGNAL_ARROW_SHAFT
  @@down_slash       = '\\'
  @@up_slash         = "/"

  def initialize(spec)
    @is_self_reference = spec[:is_self_reference]
    @is_empty          = spec[:is_empty]
    @signal = spec[:signal]
    @width  = spec[:sequence_width]
    @number = ( spec.has_key?(:number) == true ) ? spec[:number].to_s : "?"
    if( @is_self_reference == true )
      @depth = SELF_REFERENCE_DEPTH
    else
      @depth  = ( spec.has_key?(:depth) == true ) ? spec[:depth] : DEFAULT_DEPTH
    end
  end

  def draw_sequence_block
    block = ""
    if( @is_empty == true )
      block = empty_sequence_block()
    elsif( @is_self_reference == true )
      block = sequence_block_to_self()
    else
      block = sequence_block
    end
    block
  end

  def empty_sequence_block
    block = ""
    1.upto(@depth){|line|
      b      = " ".center(@width)
      b[0]   = @@delimiter
      b[-1]  = @@new_line
      block += b
    }
    block
  end

  def sequence_block
    block = ""
    1.upto(@depth){|line|
      if( line == 1 )
        b      = @signal.center(@width, @@signal_dash )
        b[ 0]  = @@signal_start
        b[-2]  = @@signal_end_right
        b[-1]  = @@new_line
        block += b
      elsif( line == 2 )
        b      = ( @@number % { :number => @number } ).center(@width)
        b[0]   = @@delimiter
        b[-1]  = @@new_line
        block += b
      else
        b      = " ".center(@width)
        b[0]   = @@delimiter
        b[-1]  = @@new_line
        block += b
      end
    }
    #fp = File.new("bob.txt","w")
    #fp.puts block
    #fp.close
    block
  end

  def sequence_block_to_self
    block = ""
    1.upto(SELF_REFERENCE_DEPTH){|line|
      if( line == 1 )
        b      = " ".center(@width)
        b[ 0]  = @@signal_start
        b[-1]  = @@new_line
        block += b
      elsif( line == 2 )
        b      = " ".center(@width)
        b[1]   = @@down_slash
        b[3]   = @@number % { :number => @number }
        b.slice! @width..-1
        b[-1]  = @@new_line
        block += b
      elsif( line == 3 )
        b      = " ".center(@width)
        b[1]   = @signal
        b.slice! @width..-1
        b[-1]  = @@new_line
        block += b
      elsif( line == 4 )
        b      = " ".center(@width)
        b[1]   = @@up_slash
        b[-1]  = @@new_line
        block += b
      elsif( line == SELF_REFERENCE_DEPTH )
        b      = " ".center(@width)
        b[0]   = @@self_signal_end
        b[-1]  = @@new_line
        block += b
      else
        raise "we shouldn't get here"
      end
    }
    block
  end
end

class UnitBlob
  include OrderTrace
  attr_reader :transitions, :states, :unique_states, :max_state_or_signal_width
  def initialize(spec)
    @unit_blob = spec[:unit_blob]
    @transitions = []
    @unit_blob.each{|trace|
      @transitions << Transition.new(:trace_obj=>trace)
    }
    @states = get_states
    @unique_states = @states.uniq
    @max_state_or_signal_width = get_max_state_or_signal_width
  end

  def unit_number( )
    @unit_blob[0][OrderTrace::UNIT]
  end

  def each_trace(spec=nil, &block)
    @unit_blob.each{|trace|
      yield trace
    }
  end

  def get_max_state_or_signal_width(spec=nil)
    max_state_width = 0
    spec ||= {}
    max_state_width = get_max(:item=>OrderTrace::BEGINNING_STATE)
    max_state_width = get_max(:item=>OrderTrace::END_STATE,
                              :previous_max => max_state_width )
    # the signal name needs a padding of two, to be displayed
    # correctly
    max_state_width = get_max(:item=>OrderTrace::SIGNAL,
                              :previous_max => max_state_width,
                              :padding => 3 )
    max_state_width
  end

  def get_max(spec)
    item = spec[:item]
    max = ( spec.has_key?(:previous_max) == false ) ?
      0 : spec[:previous_max]
    padding = ( spec.has_key?(:padding) == false ) ?
      0 : spec[:padding]
    self.each_trace{|trace|
      if( trace[item].size + padding > max )
        max = trace[item].size + padding
      end
    }
    if( max % 2 == 0 )
      max += 1
    end
    max
  end

  def get_states()
    states = []
    @transitions.each{|transition|
      bs = transition.first_state
      es = transition.last_state
      unless( states.include?(bs) )
        states += [ bs ]
      end
      unless( states.include?(es) )
        states += [ es ]
      end
    }
    states
  end

  def center_state(spec)
    word_width  = spec[:word_width]
    state       = spec[:state]
    result = state.center(word_width)
    result
  end

  def get_top_sequence()
    word_width = max_state_or_signal_width()
    sequence = ""
    @unique_states.each{|state|
      centered_state_string = center_state(
        :word_width => word_width,
        :state => state )
        sequence += centered_state_string
    }
    sequence += "\n"
    sequence
  end

  def create_sequence(trace)
    fs = trace.first_state
    ls = trace.last_state
    us = self.unique_states

    if( fs == ls )
      # create a self referencing sequence block
      us.each{|state|

      }
    else
      # create a transition sequence block
    end
  end
end

class UnitBlobs
  include OrderTrace
  attr_reader :unit_blobs, :states, :unique_states

  def initialize(spec)
    unit_blobs = order_unit_blobs(:trace=>spec[:trace])
    ordered_unit_blobs = []
    unit_blobs.each{|unit_blob|
      ordered_unit_blobs << get_state_ordered_time_blobs(:unit_blob=>unit_blob)
    }
    @unit_blobs = ordered_unit_blobs
    @unit_blob_object = []
    @unit_blobs.each{ |unit_blob|
      @unit_blob_object << UnitBlob.new(:unit_blob=>unit_blob)
    }
    @states, @unique_states = [],[]
    @unit_blobs.each{|blob|
      blob_states = get_states(:unit_blob=>blob)
      blob_unique_states = blob_states.uniq
      if( @states.size == 0 )
        @states[0]=blob_states
        @unique_states[0] = blob_unique_states
      else
        @states.push blob_states
        @unique_states.push blob_unique_states
      end
    }
  end
  def each()
    @unit_blob_object.each{|blob|
      yield blob
    }
  end

  def unit( index )
    @unit_blobs[index][0][OrderTrace::UNIT]
  end

  def index_for_unit( unit_string )
    index = nil
    @unit_blobs.each_index{|unit_blob_index|
      unit_blob = @unit_blobs[unit_blob_index]
      if ( unit_blob[0][OrderTrace::UNIT] == unit_string )
        index = unit_blob_index
        break
      end
    }
    index
  end

  def blob_for( unit_string )
    blob_index = index_for_unit(unit_string)
    @unit_blob_object[blob_index]
  end

  def get_states(spec)
    unit_blob = spec[:unit_blob]
    unit_blob = ( unit_blob.class != UnitBlob ) ?
                UnitBlob.new(unit_blob: unit_blob ) :
                unit_blob
    unit_blob.get_states
  end

  #end of new methods
  def each_blob(&block)
    @unit_blobs.each{|blob|
      block.call(blob)
    }
  end

  def each_trace(spec=nil, &block)
    if spec == nil
      self.each_blob{|blob|
        blob.each{|trace|
          block.call(trace)
        }
      }
    else
      raise unless spec.has_key?(:blob)
      spec[:blob].each{|trace|
        block.call(trace)
      }
    end
  end
end

class InputParser
  def initialize
    parser, user_options = get_parser_and_user_options()
    file_handles         = get_file_handles(user_options)
    deliver_output( options: user_options,
                    parser: parser,
                    file_handles: file_handles )
  end

  def deliver_output( spec )
    parser       = spec[:parser]
    file_handles = spec[:file_handles]
    options      = spec[:options]

    if file_handles[:input_file_handle] == nil
      puts "ERROR: There is an issue with your #{:input_file.to_sym}"
      options[:help] = true
    end

    # output the help to the user
    if( options[:help] )
      puts parser.help if options[:help]
    else
      @diagram =
        SequenceDiagram.new(trace: file_handles[:input_file_handle].read).to_s
      file_handles[:input_file_handle].close

      # if there is not output file, just deliver a string
      if( file_handles[:output_file_handle].nil? )
        puts @diagram
      else
        # write our diagram to the output file
        @diagram.split("\n").each{|line|
          file_handles[:output_file_handle].puts line
        }
        file_handles[:output_file_handle].close
      end
    end
  end

  def get_parser_and_user_options()
    options = {}
    parser = OptionParser.new do |opts|
      opts.on('-i INPUT_FILE',
              'file containing the trace (required)' ) do |input_file|
        options[:input_file] = input_file
      end
      opts.on("-o OUTPUT_FILE",
              'file to which the sequence diagram is printed (optional)' ) do |output_file|
        options[:output_file] = output_file
      end
      opts.on("-h", "--help",
              'help command' ) do
        options[:help] = true
      end
    end
    parser.parse!
    [ parser, options ]
  end

  def get_file_handles( options )
    output = {}

    begin
      output[:output_file_handle] = File.new(options[:output_file], "w" )
    rescue
      output[:output_file_handle] = nil
    end

    begin
      output[:input_file_handle] = File.new(options[:input_file], "r" )
    rescue
      output[:input_file_handle] = nil
    end

    return output
  end
end

InputParser.new()

