# coding: utf-8
include Math
require './Matrix.rb'
require './MatrixUtils.rb'
require './VectorUtils.rb'

module Utils

  def self.restrict(n, bot: 0, top: 255)
    return [[n, top].min, bot].max
  end

  # Calculates light at a point using Phong Reflection Model
  def self.calc_light(view, normal)
    v = VectorUtils.normalize(view)
    n = VectorUtils.normalize(normal)
    l = VectorUtils.normalize($POINT_LIGHT[0])

    ambient = $AMBIENT_LIGHT.zip($Ka).map{|x, y| x * y}
    diffuse = $POINT_LIGHT[1].zip($Kd).map{|x, y| x * y}
    specular = $POINT_LIGHT[1].zip($Ks).map{|x, y| x * y}
    costheta = VectorUtils.dot_product(l, n)
    temp = VectorUtils.dot_product(n, l)
    cosalpha = [VectorUtils.dot_product(n.map{|a| a*temp*2}.zip(l).map{|a, b| a - b}, v), 0].max**8

    diffuse  = diffuse.map{|x| x*costheta}
    specular = specular.map{|x| x*cosalpha}

    return specular.zip(ambient.zip(diffuse).map{|x, y| x + y}).map{|x, y| x + y}.map{|x| restrict(x)} #exhales slowly
  end

  def self.write_out(file: $OUTFILE)
    $SCREEN.write_out(file: $OUTPUT_FOLDER + file)
  end

  def self.display(tempfile: $TEMPFILE)
    write_out(file: tempfile)
    puts %x[display #{$OUTPUT_FOLDER + tempfile}]
    puts %x[rm #{$OUTPUT_FOLDER + tempfile}]
  end

  def self.format_compyled_code(code)
    code = code.gsub(",)", ", nil)")
    code = code.gsub("None", "nil")
    code = code.gsub("(", "[")
    code = code.gsub(")", "]")
    return eval(code) #¯\_(ツ)_/¯
  end

  def self.parse_file(filename: $INFILE)
    puts %x[python compyler/main.py #{filename}]

    file = File.new($COMPYLED_CODE_LOC, "r")
    code = format_compyled_code(file.gets)
    file.close
    puts %x[rm #$COMPYLED_CODE_LOC]

    for line in code[0]
      puts "Executing: " + line.to_s if $DEBUGGING
      case line[0]
      when "line"
        if line[1].class == String #Down the rabbit hole
          if line[5].class == String
            args = line[2..4] + line[6..8]
          else
            args = line[2..7]
          end
        else
          if line[4].class == String
            args = line[1..3] + line[5..7]
          else
            args = line[1..6]
          end
        end
        for i in (0...6); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4,0)
        temp.add_col([args[0], args[1], args[2], 1])
        temp.add_col([args[3], args[4], args[5], 1])
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_edge_matrix(temp)
      when "box"
        if line[1].class == String
          args = line[2..7]
        else
          args = line[1..6]
        end
        for i in (0...6); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.box(args[0], args[1], args[2], args[3], args[4], args[5], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_polygon_matrix(temp)
      when "sphere"
        if line[1].class == String
          args = line[2..5]
        else
          args = line[1..4]
        end
        for i in (0...4); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.sphere(args[0], args[1], args[2], args[3], temp)
        Draw.push_polygon_matrix(MatrixUtils.multiply($COORDSYS.peek(), temp))
      when "torus"
        if line[1].class == String
          args = line[2..6]
        else
          args = line[1..5]
        end
        for i in (0...5); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        temp = Matrix.new(4, 0)
        Draw.torus(args[0], args[1], args[2], args[3], args[4], temp)
        MatrixUtils.multiply($COORDSYS.peek(), temp)
        Draw.push_polygon_matrix(temp)
      when "clear"
        $SCREEN = Screen.new($RESOLUTION)
      when "scale"
        args = line[1..3]
        for i in (0...3); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        scale = MatrixUtils.dilation(args[0], args[1], args[2])
        $COORDSYS.modify_top(scale);
      when "move"
        args = line[1..3]
        for i in (0...3); args[i] = args[i].to_f end
        puts "With arguments: "  + args.to_s if $DEBUGGING
        move = MatrixUtils.translation(args[0], args[1], args[2])
        $COORDSYS.modify_top(move);
      when "rotate"
        args = line[1..2]
        puts "With arguments: "  + args.to_s if $DEBUGGING
        rotate = MatrixUtils.rotation(args[0], args[1].to_f)
        $COORDSYS.modify_top(rotate);
      when "pop"
        $COORDSYS.pop()
      when "push"
        $COORDSYS.push()
      when "display"
        display();
      when "save"
        write_out(file: line[1]+line[2])
      when "quit", "exit"
        exit 0

      # OLD FUNCTIONS: (NOW UNUSABLE)

      # when "circle"
      #   args = file.gets.chomp.split(" ")
      #   for i in (0...4); args[i] = args[i].to_f end
      #   puts "With arguments: "  + args.to_s if $DEBUGGING
      #   temp = Matrix.new(4, 0)
      #   Draw.circle(args[0], args[1], args[2], args[3], temp)
      #   MatrixUtils.multiply($COORDSYS.peek(), temp)
      #   Draw.push_edge_matrix(temp)
      # when "hermite"
      #   args = file.gets.chomp.split(" ")
      #   for i in (0...8); args[i] = args[i].to_f end
      #   puts "With arguments: "  + args.to_s if $DEBUGGING
      #   temp = Matrix.new(4, 0)
      #   Draw.hermite(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], temp)
      #   MatrixUtils.multiply($COORDSYS.peek(), temp)
      #   Draw.push_edge_matrix(temp)
      # when "bezier"
      #   args = file.gets.chomp.split(" ")
      #   for i in (0...8); args[i] = args[i].to_f end
      #   puts "With arguments: "  + args.to_s if $DEBUGGING
      #   temp = Matrix.new(4, 0)
      #   Draw.bezier(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], temp)
      #   MatrixUtils.multiply($COORDSYS.peek(), temp)
      #   Draw.push_edge_matrix(temp)
      else
        puts "ERROR: Unrecognized command: " + line.to_s
      end
    end
  end

end
