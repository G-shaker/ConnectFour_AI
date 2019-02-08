abstract type Player end
mutable struct Human <: Player
   disc::Char
   won::Bool
end

mutable struct gameBoard
   rows::Int
   cols::Int
   board::Array{Char}
   lowest::Array{Int}

   function gameBoard(n,m)
      this = new()
      this.rows = n
      this.cols = m
      this.board = Array{Char}(undef,n,m)
      fill!(this.board,' ')
      this.lowest= Array{Int}(undef,1,m)
      fill!(this.lowest, n)
      return this
   end
end

function insert(b::gameBoard, col::Int, p::Player)::Bool
   println("Inserting in column ",col)

   #check column is legal, i.e. not full
   if b.lowest[col] == 0
      println("illegal column")
      return false
   end

   #insert
   b.board[b.lowest[col],col]= p.disc

   #update lowest space
   b.lowest[col]-= 1
   display(b)
   return true
end

function remove(b::gameBoard, col::Int)
   println("removing from column ",col)
   b.lowest[col]+= 1
   b.board[b.lowest[col],col]= ' '
   display(b)
end

function display(b::gameBoard)
   for i = 1:b.rows
    for j = 1:b.cols
        print(b.board[i, j],'|')
    end
    println()
   end
   println(b.lowest)
end

#Tests of player p has four consecutive stones
function test_win(b::gameBoard, p::Player)::Bool
   println("testing win")
   return false
end


##  Main  ##
board1 = gameBoard(5,5)
player1 = Human('x',false)
player2 = Human('o',false)

insert(board1,2,player1)
insert(board1,2,player1)
insert(board1,2,player2)
insert(board1,2,player1)
remove(board1,2)
