#Global variables


abstract type Player end
mutable struct Human <: Player
   disc::Char
   won::Bool
end

mutable struct AI <: Player
   disc::Char
   won::Bool
   maximizer::Bool
end


################       Basic gameBoard Functions      ################
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

function insert(b::gameBoard, col::Int, disc::Char)::Bool
   println("\nInserting in column ",col)

   #check column is legal, i.e. not full, and not out of bounds
   if col > b.cols || col < 1 || b.lowest[col] == 0
      println("illegal column")
      return false
   end

   #insert
   b.board[b.lowest[col],col]= disc

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

#Checks of boards is full and returns true/false
function is_full(b::gameBoard)::Bool
   if maximum(b.lowest) == 0
      println("full")
      return true
   else
      return false
   end
end

#Tests of player p has four consecutive discs
function test_win(b::gameBoard, d::Char)::Bool
   # println("\ntesting win ", p)
   if test_horizontal(b,d) || test_vertical(b,d) || test_diagonal_up(b,d) || test_diagonal_down(b,d)
      return true
   end
   return false
end

#Tests if theres a horizontal win, checks rows top to bottom
function test_horizontal(b::gameBoard, d::Char)::Bool
   # println("testing horizontal win")
   for i = 1:b.rows
      for j= 1: b.cols-3
         if b.board[i,j]==d && b.board[i,j+1]==d && b.board[i,j+2]==d && b.board[i,j+3]==d
            println("\nhorizontal win at: ",i,",",j," for ",d)
            return true
         end
      end
   end
   return false
end

#Tests if theres a vertical win, checks cols left to right
function test_vertical(b::gameBoard, d::Char)::Bool
   # println("testing vertical win")
   for j=1: b.cols
      for i= 1 : b.rows-3
         if b.board[i,j]==d && b.board[i+1,j]==d && b.board[i+2,j]==d && b.board[i+3,j]==d
            println("\nvertical win at: ",i,",",j," for ",d)
            return true
         end
      end
   end
   return false
end

#Tests if theres a diagonal win, checks each in-bound disc left to right up diagonal (row wise top to bottom)
function test_diagonal_up(b::gameBoard, d::Char)::Bool
   # println("testing up-diagonal win")
   for i=4:b.rows
      for j=1:b.cols-3
         if b.board[i,j]==d && b.board[i-1,j+1]==d && b.board[i-2,j+2]==d && b.board[i-3,j+3]==d
            println("\nup-diagonal win at: ",i,",",j," for ",d)
            return true
         end
      end
   end
   return false
end

#Tests if there's a down-diagonal win
function test_diagonal_down(b::gameBoard, d::Char)::Bool
   # println("testing down-diagonal win")
   for i=1:b.rows - 3
      for j= 4:b.cols
         if b.board[i,j]==d && b.board[i+1,j-1]==d && b.board[i+2,j-2]==d && b.board[i+3,j-3]==d
            println("\ndown-diagonal win at: ",i,",",j," for ",d)
            return true
         end
      end
   end
   return false
end

#Tests if game is over
function game_over(b::gameBoard)::Bool
   if test_win(b,'x') || test_win(b,'o') || is_full(b)
      return true
   end
   return false
end
################     end gameBoard functions      ################


#switch turn
function toggle(p1::Player, p2::Player, curr::Player)
   if curr.disc == p1.disc
      curr.disc = p2.disc
   else
      curr.disc = p1.disc
   end
end

function results(b::gameBoard, p1::Player, p2::Player)
   println("\n *** GAME ENDED *** \n")
   if p1.won == true
      println("\tPlayer ", p1.disc, " won")
   elseif p2.won ==true
      println("\tPlayer ", p2.disc, " won")
   elseif is_full(b)
      println("\tDraw game")
   end
end

################       MINIMAX       ################
function minimax(b::gameBoard, l::Int, lookahead::Int, p::Player)
   println("minimax, level: " ,l)

   #base case
   if l == lookahead || game_over(b)
      println("base case: " , l)
      #evaluate and return score

      return
   end

   #recursive case
   minimax(b,l+1, lookahead, p)

end

function eval_func(b::gameBoard, c::Char)::Int

end

################       MAIN       ################
b = gameBoard(5,5)
player_x = Human('x',false)
player_o = Human('o',false)
turn = Human(player_x.disc, false)

while(!game_over(b))

   valid = false
   while(!valid)
      print("Enter next move for ",turn.disc,":")
      m = parse(Int, readline())
      println("your move: ", m)
      valid = insert(b, m, turn.disc)
   end

   toggle(player_x, player_o, turn)
end

results(b,player_x, player_o)


# p_x = AI('x',false, true)
# p_o = AI('o',false, false)
#
# println("testing minimax ")
# minimax(b, 0, 3, p_x)
