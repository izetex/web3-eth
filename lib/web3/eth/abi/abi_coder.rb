# -*- encoding : ascii-8bit -*-

require 'web3/eth/abi/type'
require 'web3/eth/abi/constant'
require 'web3/eth/abi/exceptions'
require 'web3/eth/abi/utils'

module Web3::Eth::Abi

  ##
  # Contract ABI encoding and decoding.
  #
  # @see https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI
  #
  module AbiCoder

    extend self

    include Constant

    class EncodingError < StandardError; end
    class DecodingError < StandardError; end
    class ValueOutOfBounds < ValueError; end

    ##
    # Encodes multiple arguments using the head/tail mechanism.
    #
    def encode_abi(types, args)
      parsed_types = types.map {|t| Type.parse(t) }

      head_size = (0...args.size)
        .map {|i| parsed_types[i].size || 32 }
        .reduce(0, &:+)

      head, tail = '', ''
      args.each_with_index do |arg, i|
        if parsed_types[i].dynamic?
          head += encode_type(Type.size_type, head_size + tail.size)
          tail += encode_type(parsed_types[i], arg)
        else
          head += encode_type(parsed_types[i], arg)
        end
      end

      "#{head}#{tail}"
    end
    alias :encode :encode_abi

    ##
    # Encodes a single value (static or dynamic).
    #
    # @param type [Ethereum::ABI::Type] value type
    # @param arg [Object] value
    #
    # @return [String] encoded bytes
    #
    def encode_type(type, arg)
      if %w(string bytes).include?(type.base) && type.sub.empty?
        encode_primitive_type type, arg
      elsif type.dynamic?
        raise ArgumentError, "arg must be an array" unless arg.instance_of?(Array)

        head, tail = '', ''
        if type.dims.last == 0
          head += encode_type(Type.size_type, arg.size)
        else
          raise ArgumentError, "Wrong array size: found #{arg.size}, expecting #{type.dims.last}" unless arg.size == type.dims.last
        end

        sub_type = type.subtype
        sub_size = type.subtype.size
        arg.size.times do |i|
          if sub_size.nil?
            head += encode_type(Type.size_type, 32*arg.size + tail.size)
            tail += encode_type(sub_type, arg[i])
          else
            head += encode_type(sub_type, arg[i])
          end
        end

        "#{head}#{tail}"
      else # static type
        if type.dims.empty?
          encode_primitive_type type, arg
        else
          arg.map {|x| encode_type(type.subtype, x) }.join
        end
      end
    end

    def encode_primitive_type(type, arg)
      case type.base
      when 'uint'
        begin
          real_size = type.sub.to_i
          i = get_uint arg

          raise ValueOutOfBounds, arg unless i >= 0 && i < 2**real_size
          Utils.zpad_int i
        rescue EncodingError
          raise ValueOutOfBounds, arg
        end
      when 'bool'
        raise ArgumentError, "arg is not bool: #{arg}" unless arg.instance_of?(TrueClass) || arg.instance_of?(FalseClass)
        Utils.zpad_int(arg ? 1 : 0)
      when 'int'
        begin
          real_size = type.sub.to_i
          i = get_int arg

          raise ValueOutOfBounds, arg unless i >= -2**(real_size-1) && i < 2**(real_size-1)
          Utils.zpad_int(i % 2**type.sub.to_i)
        rescue EncodingError
          raise ValueOutOfBounds, arg
        end
      when 'ufixed'
        high, low = type.sub.split('x').map(&:to_i)

        raise ValueOutOfBounds, arg unless arg >= 0 && arg < 2**high
        Utils.zpad_int((arg * 2**low).to_i)
      when 'fixed'
        high, low = type.sub.split('x').map(&:to_i)

        raise ValueOutOfBounds, arg unless arg >= -2**(high - 1) && arg < 2**(high - 1)

        i = (arg * 2**low).to_i
        Utils.zpad_int(i % 2**(high+low))
      when 'string'
        if arg.encoding.name == 'UTF-8'
          arg = arg.b
        else
          begin
            arg.unpack('U*')
          rescue ArgumentError
            raise ValueError, "string must be UTF-8 encoded"
          end
        end

        if type.sub.empty? # variable length type
          raise ValueOutOfBounds, "Integer invalid or out of range: #{arg.size}" if arg.size >= TT256
          size = Utils.zpad_int arg.size
          value = Utils.rpad arg, BYTE_ZERO, Utils.ceil32(arg.size)
          "#{size}#{value}"
        else # fixed length type
          sub = type.sub.to_i
          raise ValueOutOfBounds, "invalid string length #{sub}" if arg.size > sub
          raise ValueOutOfBounds, "invalid string length #{sub}" if sub < 0 || sub > 32
          Utils.rpad(arg, BYTE_ZERO, 32)
        end
      when 'bytes'
        raise EncodingError, "Expecting string: #{arg}" unless arg.instance_of?(String)
        arg = arg.b

        if type.sub.empty? # variable length type
          raise ValueOutOfBounds, "Integer invalid or out of range: #{arg.size}" if arg.size >= TT256
          size = Utils.zpad_int arg.size
          value = Utils.rpad arg, BYTE_ZERO, Utils.ceil32(arg.size)
          "#{size}#{value}"
        else # fixed length type
          sub = type.sub.to_i
          raise ValueOutOfBounds, "invalid bytes length #{sub}" if arg.size > sub
          raise ValueOutOfBounds, "invalid bytes length #{sub}" if sub < 0 || sub > 32
          Utils.rpad(arg, BYTE_ZERO, 32)
        end
      when 'hash'
        size = type.sub.to_i
        raise EncodingError, "too long: #{arg}" unless size > 0 && size <= 32

        if arg.is_a?(Integer)
          Utils.zpad_int(arg)
        elsif arg.size == size
          Utils.zpad arg, 32
        elsif arg.size == size * 2
          Utils.zpad_hex arg
        else
          raise EncodingError, "Could not parse hash: #{arg}"
        end
      when 'address'
        if arg.is_a?(Integer)
          Utils.zpad_int arg
        elsif arg.size == 20
          Utils.zpad arg, 32
        elsif arg.size == 40
          Utils.zpad_hex arg
        elsif arg.size == 42 && arg[0,2] == '0x'
          Utils.zpad_hex arg[2..-1]
        else
          raise EncodingError, "Could not parse address: #{arg}"
        end
      else
        raise EncodingError, "Unhandled type: #{type.base} #{type.sub}"
      end
    end


    def min_data_size types
      types.size*32
    end
    
    ##
    # Decodes multiple arguments using the head/tail mechanism.
    #
    def decode_abi types, data, raise_errors = false
      parsed_types = types.map {|t| Type.parse(t) }

      outputs = [nil] * types.size
      start_positions = [nil] * types.size + [data.size]

      # TODO: refactor, a reverse iteration will be better
      pos = 0
      parsed_types.each_with_index do |t, i|
        # If a type is static, grab the data directly, otherwise record its
        # start position
        if t.dynamic?

          if raise_errors && pos>data.size-1
            raise DecodingError, "Position out of bounds #{pos}>#{data.size-1}"
          end

          start_positions[i] = Utils.big_endian_to_int(data[pos, 32])

          if raise_errors && start_positions[i]>data.size-1
            raise DecodingError, "Start position out of bounds #{start_positions[i]}>#{data.size-1}"
          end

          j = i - 1
          while j >= 0 && start_positions[j].nil?
            start_positions[j] = start_positions[i]
            j -= 1
          end

          pos += 32
        else
          outputs[i] = zero_padding data, pos, t.size, start_positions
          pos += t.size
        end
      end

      # We add a start position equal to the length of the entire data for
      # convenience.
      j = types.size - 1
      while j >= 0 && start_positions[j].nil?
        start_positions[j] = start_positions[types.size]
        j -= 1
      end

      if raise_errors && pos > data.size
        raise DecodingError, "Not enough data for head"
      end


      parsed_types.each_with_index do |t, i|
        if t.dynamic?
          offset, next_offset = start_positions[i, 2]
          if offset<=data.size && next_offset<=data.size
            outputs[i] = data[offset...next_offset]
          end
        end
      end

      if raise_errors && outputs.include?(nil)
        raise DecodingError, "Not all data can be parsed"
      end

      parsed_types.zip(outputs).map {|(type, out)| decode_type(type, out) }
    end
    alias :decode :decode_abi

    def zero_padding data, pos, count, start_positions
      if pos >= data.size
        start_positions[start_positions.size-1] += count
        "\x00"*count
      elsif pos + count > data.size
        start_positions[start_positions.size-1] += ( count - (data.size-pos))
        data[pos,data.size-pos] + "\x00"*( count - (data.size-pos))
      else
        data[pos, count]
      end
    end

    def decode_typed_data type_name, data
      decode_primitive_type Type.parse(type_name), data
    end

    def decode_type(type, arg)
      return nil if arg.nil? || arg.empty?
      if type.kind_of?(Tuple) && type.dims.empty?
        arg ? decode_abi(type.types, arg) : []
      elsif %w(string bytes).include?(type.base) && type.sub.empty?
        l = Utils.big_endian_to_int arg[0,32]
        data = arg[32..-1]
        data[0, l]
      elsif type.dynamic?
        l = Utils.big_endian_to_int arg[0,32]
        raise DecodingError, "Too long length: #{l}" if l>100000
        subtype = type.subtype

        if subtype.dynamic?
          raise DecodingError, "Not enough data for head" unless arg.size >= 32 + 32*l

          start_positions = (1..l).map {|i| 32+Utils.big_endian_to_int(arg[32*i, 32]) }
          start_positions.push arg.size

          outputs = (0...l).map {|i| arg[start_positions[i]...start_positions[i+1]] }

          outputs.map {|out| decode_type(subtype, out) }
        else
          (0...l).map {|i| decode_type(subtype, arg[32 + subtype.size*i, subtype.size]) }
        end
      elsif !type.dims.empty? # static-sized arrays
        l = type.dims.last
        subtype = type.subtype

        (0...l).map {|i| decode_type(subtype, arg[subtype.size*i, subtype.size]) }
      else
        decode_primitive_type type, arg
      end
    end

    def decode_primitive_type(type, data)
      case type.base
      when 'address'
        Utils.encode_hex data[12..-1]
      when 'string', 'bytes'
        if type.sub.empty? # dynamic
          if data.length==32
            data[0..32]
          else
            size = Utils.big_endian_to_int data[0,32]
            data[32..-1][0,size]
          end
        else # fixed
          data[0, type.sub.to_i]
        end
      when 'hash'
        data[(32 - type.sub.to_i), type.sub.to_i]
      when 'uint'
        Utils.big_endian_to_int data
      when 'int'
        u = Utils.big_endian_to_int data
        u >= 2**(type.sub.to_i-1) ? (u - 2**type.sub.to_i) : u
      when 'ufixed'
        high, low = type.sub.split('x').map(&:to_i)
        Utils.big_endian_to_int(data) * 1.0 / 2**low
      when 'fixed'
        high, low = type.sub.split('x').map(&:to_i)
        u = Utils.big_endian_to_int data
        i = u >= 2**(high+low-1) ? (u - 2**(high+low)) : u
        i * 1.0 / 2**low
      when 'bool'
        data[-1] == BYTE_ONE
      else
        raise DecodingError, "Unknown primitive type: #{type.base}"
      end
    end

    private

    def get_uint(n)
      case n
      when Integer
        raise EncodingError, "Number out of range: #{n}" if n > UINT_MAX || n < UINT_MIN
        n
      when String
        i = if n.size == 40
              Utils.decode_hex(n)
            elsif n.size <= 32
              n
            else
              raise EncodingError, "String too long: #{n}"
            end
        i = Utils.big_endian_to_int i

        raise EncodingError, "Number out of range: #{i}" if i > UINT_MAX || i < UINT_MIN
        i
      when true
        1
      when false, nil
        0
      else
        raise EncodingError, "Cannot decode uint: #{n}"
      end
    end

    def get_int(n)
      case n
      when Integer
        raise EncodingError, "Number out of range: #{n}" if n > INT_MAX || n < INT_MIN
        n
      when String
        i = if n.size == 40
              Utils.decode_hex(n)
            elsif n.size <= 32
              n
            else
              raise EncodingError, "String too long: #{n}"
            end
        i = Utils.big_endian_to_int i

        i = i > INT_MAX ? (i-TT256) : i
        raise EncodingError, "Number out of range: #{i}" if i > INT_MAX || i < INT_MIN
        i
      when true
        1
      when false, nil
        0
      else
        raise EncodingError, "Cannot decode int: #{n}"
      end
    end

  end

end
