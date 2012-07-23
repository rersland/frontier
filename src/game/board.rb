require_relative 'game'

def define_nbor_accessors(type, idx_map)
  idx_map_name = "#{type.to_s.upcase}_IDX_MAP"
  idx_meth = "#{type}_idx"
  getter = "#{type}"
  setter = "set_#{type}"
  list_name = "#{type}s"

  module_eval %Q{
    attr_reader :#{list_name}

    #{idx_map_name} = #{idx_map.inspect}

    def #{idx_meth}(idx)
      (idx.is_a? Fixnum) ? idx : #{idx_map_name}[idx]
    end

    def #{getter}(idx)
      #{list_name}[#{idx_meth}(idx)]
    end

    def #{setter}(idx, val)
      #{list_name}[#{idx_meth}(idx)] = val
    end
  }

  idx_map.each do |dir, idx|
    module_eval %Q{
      def #{dir}_#{type}()
        #{list_name}[#{idx}]
      end
      def #{dir}_#{type}=(val)
        #{list_name}[#{idx}] = val
      end
    }
  end
end

class Tile
  attr_accessor :row, :col, :type, :counter

  define_nbor_accessors(:tile, :w=>0, :nw=>1, :ne=>2, :e=>3, :se=>4, :sw=>5)
  define_nbor_accessors(:vtex, :nw=>0, :n=>1, :ne=>2, :se=>3, :s=>4, :sw=>5)
  define_nbor_accessors(:edge, :w=>0, :nw=>1, :ne=>2, :e=>3, :se=>4, :sw=>5)

  include IdObject

  def initialize()
    @tiles, @edges, @vtexs = [], [], []
  end
end

class Vtex
  attr_accessor :alignment, :row, :col

  define_nbor_accessors(:tile, :nw=>0, :n=>0, :ne=>1, :se=>1, :s=>2, :sw=>2)
  define_nbor_accessors(:edge, :nw=>0, :n=>0, :ne=>1, :se=>1, :s=>2, :sw=>2)

  include IdObject

  def initialize()
    @tiles, @edges = [], []
  end
end

class Edge
  attr_accessor :alignment, :row, :col

  define_nbor_accessors(:tile, :left=>0, :right=>1,
                        :sw=>0, :w=>0, :nw=>0, :ne=>1, :e=>1, :se=>1)
  define_nbor_accessors(:vtex, :up=>0, :down=>1,
                        :nw=>0, :n=>0, :ne=>0, :se=>1, :s=>1, :sw=>1)

  include IdObject

  def initialize()
    @tiles, @vtexs = [], []
  end
end

class Board
  attr_reader(:tiles, :tile_map,
              :vtexs, :vtex_map,
              :edges, :edge_map,
              :up_vtexs, :up_vtex_map,
              :down_vtexs, :down_vtex_map,
              :asc_edges, :asc_edge_map,
              :desc_edges, :desc_edge_map,
              :vert_edges, :vert_edge_map)

  # access the tile at (row, col)
  def tile(row, col)
    tile_map[[row, col]]
  end

  # access the edge at (row, col) with alignment :asc, :desc, or :vert
  def edge(alignment, row, col)
    edge_map[[alignment, row, col]]
  end

  # access the :up or :down vertex at (row, col)
  def vtex(alignment, row, col)
    vtex_map[[alignment, row, col]]
  end

  # create the Tile, Edge, Vtex objects that compose the map
  def create_spaces
    ((@tiles, @tile_map),
     (@up_vtexs, @up_vtex_map),
     (@down_vtexs, @down_vtex_map),
     (@asc_edges, @asc_edge_map),
     (@desc_edges, @desc_edge_map),
     (@vert_edges, @vert_edge_map)) =
      [[Tile, nil,   1..5, [3,4,5,4,3],   [1..3, 1..4, 1..5, 2..5, 3..5]],
       [Vtex, :up,   1..6, [3,4,5,6,5,4], [1..3, 1..4, 1..5, 1..6, 2..6, 3..6]],
       [Vtex, :down, 0..5, [4,5,6,5,4,3], [0..3, 0..4, 0..5, 1..5, 2..5, 3..5]],
       [Edge, :asc,  1..6, [3,4,5,5,4,3], [1..3, 1..4, 1..5, 2..6, 3..6, 4..6]],
       [Edge, :desc, 1..6, [3,4,5,5,4,3], [1..3, 1..4, 1..5, 1..5, 2..5, 3..5]],
       [Edge, :vert, 1..5, [4,5,6,5,4],   [1..4, 1..5, 1..6, 2..6, 3..6]]
      ].map {|cls, align, row_interval, row_counts, col_intervals|
      rows = row_counts.zip(row_interval.to_a).map {|c, r| [r]*c}.flatten
      cols = col_intervals.map {|ival| ival.to_a}.flatten
      count = rows.length
      list = (0...count).to_a.map {|i| cls.new}
      list.each {|obj| obj.alignment = align} if not align.nil?
      list.zip(rows, cols).each {|obj, row, col| obj.row, obj.col = row, col}
      map = Hash[list.map {|obj| [[obj.row, obj.col], obj]}]
      [list, map]
    }

    @vtexs = @up_vtexs + @down_vtexs
    @edges = @asc_edges + @desc_edges + @vert_edges
    @all_spaces = @tiles + @vtexs + @edges

    @vtex_map = Hash[@vtexs.map {|v| [[v.alignment, v.row, v.col], v]}]
    @edge_map = Hash[@edges.map {|e| [[e.alignment, e.row, e.col], e]}]

    @all_spaces.zip((0...(@all_spaces.length)).to_a).each do |obj, id|
      obj.id = id
    end
  end

  # link the Tile, Edge and Vtex objects to their neighbors
  def connect_spaces

    # set the tile-tile, tile-vtex, and tile-edge links
    @tiles.each do |tile|
      r, c = tile.row, tile.col

      # link the tile with its 6 neighboring tiles
      [[[r-1, c-1], :nw, :se],
       [[r-1, c  ], :ne, :sw],
       [[r  , c+1], :e , :w ],
       [[r+1, c+1], :se, :nw],
       [[r+1, c  ], :sw, :ne],
       [[r  , c-1], :w , :e ]
      ].each do |coords, dir1, dir2|
        other = @tile_map[coords]
        tile.set_tile(dir1, other)
        other.set_tile(dir2, tile) if not other.nil?
      end

      # link the tile with its 6 neighboring vertexes
      [[[:down, r-1, c-1], :nw, :se],
       [[:up  , r  , c  ], :n , :s ],
       [[:down, r-1, c  ], :ne, :sw],
       [[:up  , r+1, c+1], :se, :nw],
       [[:down, r  , c  ], :s , :n ],
       [[:up  , r+1, c  ], :sw, :ne]
      ].each do |coords, dir1, dir2|
        vtex = @vtex_map[coords]
        tile.set_vtex(dir1, vtex)
        vtex.set_tile(dir2, tile) if not vtex.nil?
      end

      # link the tile with its 6 neighboring edges
      [[[:vert, r  , c  ], :w , :e ],
       [[:asc , r  , c  ], :nw, :se],
       [[:desc, r  , c  ], :ne, :sw],
       [[:vert, r  , c+1], :e , :w ],
       [[:asc , r+1, c+1], :se, :nw],
       [[:desc, r+1, c  ], :sw, :ne]
      ].each do |coords, dir1, dir2|
        edge = @edge_map[coords]
        tile.set_edge(dir1, edge)
        edge.set_tile(dir2, tile) if not edge.nil?
      end
    end

    # link the :up vertexes with neighboring edges
    @up_vtexs.each do |vtex|
      r, c = vtex.row, vtex.col
      [[[:vert, r-1, c  ], :n , :s ],
       [[:desc, r  , c  ], :se, :nw],
       [[:asc , r  , c  ], :sw, :ne]
      ].each do |coords, dir1, dir2|
        edge = @edge_map[coords]
        vtex.set_edge(dir1, edge)
        edge.set_vtex(dir2, vtex) if not edge.nil?
      end
    end

    # link the :down vertexes with neighboring edges
    @down_vtexs.each do |vtex|
      r, c = vtex.row, vtex.col
      [[[:desc, r+1, c  ], :nw, :se],
       [[:asc , r+1, c+1], :ne, :sw],
       [[:vert, r+1, c+1], :s , :n ]
      ].each do |coords, dir1, dir2|
        edge = @edge_map[coords]
        vtex.set_edge(dir1, edge)
        edge.set_vtex(dir2, vtex) if not edge.nil?
      end
    end
  end

  # randomly distribute the tiles
  def shuffle_tile_types()
    types = ([FOREST]*4 + [PLAINS]*4 + [HILLS]*4 + [MOUNTAIN]*3 +
             [PASTURE]*3 + [DESERT])
    types.shuffle.zip(tiles).each {|type, tile| tile.type = type}
  end
end

$b = Board.new
$b.create_spaces
$b.connect_spaces
$b.shuffle_tile_types
