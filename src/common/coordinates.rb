

module Coords

  SECTOR_W = (3 ** 0.5) / 2.0
  SECTOR_H = 0.5
  BOARD_W = SECTOR_W * 12
  BOARD_H = SECTOR_H * 18
  BOARD_WH_RATIO = BOARD_W / BOARD_H

  def tile_coords_to_board(coords)
    row, col, alignment = coords
    x = (2 * col - row + 3) * SECTOR_W
    y = (3 * row) * SECTOR_H
    return case alignment
           when nil   then [x, y]
           when :vert then [x - SECTOR_W, y]
           when :asc  then [x - SECTOR_W / 2.0, y - SECTOR_H / 2.0]
           when :desc then [x + SECTOR_W / 2.0, y - SECTOR_H / 2.0]
           when :up   then [x, y - SECTOR_H * 2.0]
           when :down then [x, y + SECTOR_H * 2.0]
           else raise "invalid alignment"
           end
  end

  def tile_coords_to_render(coords, scale)
    x, y = tile_coords_to_board(coords)
    return [x * scale, y * scale]
  end

  # Takes a point (x, y) in BOARD SPACE.
  # Returns the [row, col] of the tile under that point.
  def tile_coords_under_point(x, y)
    i, yrem = y.divmod(SECTOR_H)
    j, xrem = x.divmod(SECTOR_W)
    if i % 3 != 1
      row = (i % 3 == 0) ? (i / 3) : (i / 3) + 1
      ascending, above = nil, nil
    else
      ascending = (i % 6 == 1) ? (j % 2 == 1) : (j % 2 == 0)
      if ascending
        above = (SECTOR_H - yrem) / xrem > SECTOR_H / SECTOR_W
      else
        above = yrem / xrem < SECTOR_H / SECTOR_W
      end
      row = above ? (i / 3) : (i / 3) + 1
    end
    col = (j - 2 + row) / 2
    [row, col]
  end

  def nearest_edge(x, y, tile_pos)
    tile_pos ||= tile_under_point(x, y)
    tx, ty = tile_coords_to_board(tile_pos)
    theta = (Math.atan2(y - ty, x - tx) * 180.0 / Math::PI).to_i
    return case theta
           when -180 ... -150 then [row    , col    , :vert]
           when -150 ...  -90 then [row + 1, col    , :desc]
           when  -90 ...  -30 then [row + 1, col + 1, :asc ]
           when  -30 ...   30 then [row    , col + 1, :vert]
           when   30 ...   90 then [row    , col    , :desc]
           when   90 ...  150 then [row    , col    , :asc ]
           when  150 ..   180 then [row    , col    , :vert]
           end
  end

  def nearest_vtex(x, y, tile_pos=nil)
    tile_pos ||= tile_under_point(x, y)
    tx, ty = tile_coords_to_board(tile_pos)
    theta = (Math.atan2(y - ty, x - tx) * 180.0 / Math::PI).to_i
    return case theta
           when -180 ... -120 then [row + 1, col    , :up  ]
           when -120 ...  -60 then [row    , col    , :down]
           when  -60 ...    0 then [row + 1, col + 1, :up  ]
           when    0 ...   60 then [row - 1, col    , :down]
           when   60 ...  120 then [row    , col    , :up  ]
           when  120 ..   180 then [row - 1, col - 1, :down]
           end
  end

end
