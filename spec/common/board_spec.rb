require 'src/common/board'

describe Board do

  describe "#create_spaces" do

    subject do
      b = Board.new
      b.create_spaces
      b
    end

    it { should have(19).tiles }
    it { should have(72).edges }
    it { should have(54).vtexs }

  end

  describe "#connect_spaces" do

    let(:board) do
      b = Board.new
      b.create_spaces
      b.connect_spaces
      b
    end

    [[ :tile , [1,1]       , :nw , :tile , [2,2]       , :se ],
     [ :tile , [3,5]       , :sw , :vtex , [2,5,:down] , :ne ],
     [ :tile , [4,2]       , :ne , :edge , [5,2,:desc] , :sw ],
     [ :edge , [6,4,:desc] , :nw , :vtex , [5,4,:down] , :se ],

    ].each do |type1, coords1, dir1, type2, coords2, dir2|
      it "connects #{type1} #{coords1} to #{type2} #{coords2}" do
        space1 = board.public_send(type1, coords1)
        space2 = board.public_send(type2, coords2)
        space1.public_send(type2, dir2).should equal(space2)
        space2.public_send(type1, dir1).should equal(space1)
      end
    end

  end

end
