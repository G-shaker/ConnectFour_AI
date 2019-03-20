#Global variables
global num_simulations = 10
global N = 10
global c = 2

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
   function gameBoard(b) #copy constructor
      this = new()
      this.rows = b.rows
      this.cols = b.cols
      this.board = deepcopy(b.board)
      this.lowest= deepcopy(b.lowest)
      return this
   end

end

function copyBoard(b::gameBoard, newb::gameBoard)
   newb.board = deepcopy(b.board)
   newb.lowest = deepcopy(b.lowest)
end


function insert(b::gameBoard, col::Int, disc::Char)::Bool
   # println("\nInserting in column ",col)

   #check column is legal, i.e. not full, and not out of bounds
   if col > b.cols || col < 1 || b.lowest[col] == 0
      # println("illegal column")
      return false
   end

   #insert
   b.board[b.lowest[col],col]= disc

   #update lowest space
   b.lowest[col]-= 1
   # display(b)
   return true
end

function remove(b::gameBoard, col::Int)
   # println("removing from column ",col)
   b.lowest[col]+= 1
   b.board[b.lowest[col],col]= ' '
   # display(b)
end

function display(b::gameBoard)
   for i = 1:b.rows
    for j = 1:b.cols
        print(b.board[i, j],'|')
    end
    println()
   end
   # println(b.lowest)
   # for i = 1:2*b.cols
   #    print("-")
   # end
   # println()
   for i = 1:b.cols
      print(i," ")
   end
   println()

end

#Checks of boards is full and returns true/false
function is_full(b::gameBoard)::Bool
   if maximum(b.lowest) == 0
      # println("full")
      return true
   else
      return false
   end
end

#Tests of player p has four consecutive discs
function test_win(b::gameBoard, d::Char)::Bool
   # println("\ntesting win ", d)
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
            # println("\nhorizontal win at: ",i,",",j," for ",d)
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
            # println("\nvertical win at: ",i,",",j," for ",d)
            return true
         end
      end
   end
   return false
end

#Tests if theres a diagonal win, checks each in-bound disc left to right up diagonal (row wise top to bottom)
function test_diagonal_up(b::gameBoard, d::Char)::Bool
   # println("testing up-diagonal win ", d)
   for i=4:b.rows
      for j=1:b.cols-3
         if b.board[i,j]==d && b.board[i-1,j+1]==d && b.board[i-2,j+2]==d && b.board[i-3,j+3]==d
            # println("\nup-diagonal win at: ",i,",",j," for ",d)
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
      for j= 1:b.cols-3
         if b.board[i,j]==d && b.board[i+1,j+1]==d && b.board[i+2,j+2]==d && b.board[i+3,j+3]==d
            # println("\ndown-diagonal win at: ",i,",",j," for ",d)
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

function results(b::gameBoard)
   println("\n *** GAME ENDED *** \n")
   if test_win(b, 'x')
      println("\tPlayer x won in ",x_moves," moves\n\n")
   elseif test_win(b, 'o')
      println("\tPlayer o won in ",o_moves," moves\n\n")
   elseif is_full(b)
      println("\tDraw game")
   end
end

################       MINIMAX       ################
function minimax(b::gameBoard, l::Int, lookahead::Int, maximizer::Bool, d::Char, lastcol::Int)::Int
   # println("minimax, level: " ,l, " player: ", d," max? ", maximizer,"last played col: ", lastcol)
   # println("In minimax")

   #base case
   if l > lookahead || game_over(b)
      # println("Leaf at level: " , l-1)
      # display(b)
      s = eval_func(b, switch(d), lastcol, !maximizer)
      # println("Score: ",s,"\n")
      return s
   end

   #recursive case
   scores = Array{Int}(undef,1, b.cols)
   if maximizer
      max_score = -1000
      for i=1: b.cols
         new_b = b
         if insert(new_b, i, d)
            # println(d," insertion in ", i)
            score = minimax(new_b,l+1, lookahead, !maximizer, switch(d),i)
            scores[i] = score
            remove(new_b,i)
         else
            score = -1000
            scores[i] = score
         end
         max_score = max(score, max_score)
         # println("propogating: ", max_score)
      end
      # println(scores)
      return max_score

   else
      min_score = 10000
      for i=1: b.cols
         new_b = b
         if insert(new_b, i, d)
            # println(d," insertion in ", i)
            score = minimax(new_b,l+1, lookahead, !maximizer, switch(d),i)
            remove(new_b,i)
         else
            score = 10000
         end
         min_score = min(score, min_score)
      end
      return min_score
   end
end

function eval_func(b::gameBoard, c::Char, col::Int, m::Bool)::Int
   # println("In eval for ", c)
   # display(b)
   max = c
   #assess for maximizer
   if !m
      max = switch(c)
   end
   # println("In eval for ", max)
   if test_win(b,max)
      return 256
   elseif test_win(b,switch(max))   #&& m || test_win(b,c) && !m
      # println("Switched: ", switch(c))
      return -256
   elseif is_full(b) #draw game
      # println("full")
      return 2
   elseif m
      return calculate_score(b,max,col)
   else
      return -calculate_score(b,switch(max),col)
   end
end

function calculate_score(b::gameBoard, c::Char, col::Int)::Int
   # println("Calculating score")
   return vertical_streak(b,c,col)  + horizontal_streak(b,c,col) + updiag_streak(b,c,col)+ downdiag_streak(b,c,col)
end

function vertical_streak(b::gameBoard, c::Char, col::Int)::Int
   count = 1
   row = b.lowest[col]+1
   while row < b.rows && b.board[row+1,col] == c
      count += 1
      row +=1
   end
   # println("vertical streak score: ", count^4)
   return count^4
end

function horizontal_streak(b::gameBoard, c::Char, col::Int)::Int
   count = 1
   row = b.lowest[col]+1
   curr_col = col
   #check horizontal left direction
   while curr_col > 1 && b.board[row,curr_col-1]==c
      count +=1
      curr_col -= 1
   end
   curr_col = col

   #check horizontal right direction
   while curr_col < b.cols && b.board[row, curr_col+1] == c
      count +=1
      curr_col += 1
   end
   # println("horizontal streak score: ", count^4)
   return count^4
end

function updiag_streak(b::gameBoard, c::Char, col::Int)::Int
   count = 1
   row = b.lowest[col]+1
   curr_col = col
   #check up diagonal backward (left direction)
   while curr_col > 1 && row< b.rows && b.board[row+1, curr_col-1]==c
      count +=1
      curr_col -= 1
      row += 1
   end
   row = b.lowest[col]+1
   curr_col = col

   #check up diagonal forward (right direction)
   while curr_col < b.cols && row > 1 &&  b.board[row-1, curr_col+1] == c
      count +=1
      curr_col += 1
      row -=1
   end
   # println("up-diag streak score: ", count^4)

   return count^4
end

function downdiag_streak(b::gameBoard, c::Char, col::Int)::Int
   count = 1
   row = b.lowest[col]+1
   curr_col = col
   #check down diagonal backward (left direction)
   while curr_col > 1 && row>1 && b.board[row-1, curr_col-1]==c
      count +=1
      curr_col -= 1
      row -= 1
   end
   row = b.lowest[col]+1
   curr_col = col

   #check down diagonal forward (right direction)
   while curr_col < b.cols && row < b.rows &&  b.board[row+1, curr_col+1] == c
      count +=1
      curr_col += 1
      row +=1
   end
   # println("down-diag streak score: ", count^4)

   return count^4
end

function switch(c::Char)::Char
   if c == 'o'
      return 'x'
   else
      return 'o'
   end
end

#takes array and return index with max value in array
function max_score_col(a::Array{Int})::Int
   max = a[1]
   ties = Int[] #array of indices

   for i = 1: length(a) #find max value
      if a[i]>max
         index = i
         max = a[i]
         # println("new max: ", max)
      end
   end

   println("max: ", max)
   for i = 1: length(a)  #find all ties and add to array
      if a[i] == max
         max = a[i]
         push!(ties, i)
      end
   end

   return ties[rand(1:length(ties))]
   #return index
end

#function return index of column with max value, i.e. column that should be played
function determine_move(b::gameBoard,c::Char)::Int
   # println("determining move")
   scores = Array{Int}(undef,1, b.cols)
   for i = 1: b.cols
      if insert(b, i, c)
         # println("Calling minimax for ", c," col: ", i)
         scores[i] = minimax(b, 1, 6, false, switch(c),i) ########
         # println("at col:",i," score: ", scores[i])
         remove(b,i)
      else
         scores[i] = -1000
      end
   end
   println("scores array for next move: " , scores)
   return max_score_col(scores)
end


################       Monte Carlo Tree Search      ################
mutable struct state
   board::gameBoard
   cols::Int
   wins::Int
   visits::Int
   prev_state::state
   next_states::Array{state}
   turn::Char

   function state(b::gameBoard,c::Char) #root takes in board
      this = new()
      this.board = gameBoard(b) #constructor
      this.cols = b.cols
      this.wins = 0
      this.visits = 0
      #this.prev_state = nothing
      this.next_states = Array{state}(undef,1, this.cols)
      this.turn = switch(c)
      return this
   end

   function state(prev_state::state,i::Int) #copy from previous state
      this = new()
      this.board = gameBoard(prev_state.board) #constructor
      this.cols = this.board.cols
      this.wins = 0
      this.visits = 0
      this.prev_state = prev_state
      this.next_states = Array{state}(undef,1,this.cols)
      this.turn= switch(prev_state.turn)
      insert(this.board,i,this.turn)
      prev_state.next_states[i] = this
      return this
   end
end
#given a state, check if child column is legal
function legal(s::state, col::Int)Bool
   if insert(s.board,col, ' ')
      remove(s.board,col)
      return true
   end
   return false
end

#return best move
function determine_move_MCTS(b::gameBoard, c::Char)::Int
   n = 1
   max_sim = 1

   #initialize, expand root
   root = state(b,c)
   root.visits += 1
   for i=1:root.cols
      if legal(root,i)
         state(root,i)
      end
   end

   while (n <=  max_sim)
      println("simulation: ", n)
      run_simulations(root,c)
      n += 1
   end
   return 0
end

function run_simulations(s::state,c::Char)

   println("root state:")
   printState(s)
   curr_state = s

   #if leaf node
   # while !leaf(curr_state)
   #    println("selecting")
   #
   # end
   UCT(curr_state)
   #reached a leaf



end


function UCT(s)
   println("N= ", N)
   println("c= ",c)

   return
end

#randomly chooses column to play
function play_rand(b::gameBoard)::Int
   return rand(1:b.cols)
end


function printState(s::state)
   println("board: ")
   display(s.board)
   println("wins: ",s.wins, " visits: ",s.visits)
   if isdefined(s, :prev_state)
      println("parent: ", s.prev_state)
   else
      println("no parent")
   end
   print("children: ")
   for i=1:s.cols
      if isassigned(s.next_states, i)
         print(" ",i)
      end
   end
   println()
end

function leaf(s::state)::Bool
   for i=1:s.cols
      if isassigned(s.next_states, i)
         return false
      end
   end
   return true
end

################       MAIN       ################

b = gameBoard(6,7)
# insert(b, 1, 'x')
# insert(b, 1, 'o')
# # insert(b, 1, 'o')
# # insert(b, 1, 'x')
#
# insert(b, 2, 'x')
# insert(b, 2, 'x')
# # insert(b, 2, 'o')
# insert(b, 2, 'o')
#
# insert(b, 3, 'x')
# insert(b, 3, 'o')
# insert(b, 3, 'x')
# insert(b, 3, 'x')
# insert(b, 3, 'x')
# insert(b, 3, 'o')
# println("testing")
#display(b)

#newb = gameBoard(b)
#display(newb)

# root = state(b)
# display(root.board)
# println(isdefined(root, :prev_state))
# println(root.next_states)
#
# child = state(root,3,'o')
# display(child.board)
# println(isdefined(child, :prev_state))
# println(root.next_states[3].board)
# println(legal(child, 8))
#

determine_move_MCTS(b,'o')


#################     Human VS Human Game   ###############
function H_vs_H()
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
      display(b)

      toggle(player_x, player_o, turn)
   end
   results(b,player_x, player_o)
end


##################    Minimax game     ###############
global turn = 'x'
global x_moves = 0
global o_moves = 0
# insert(b, play_rand(b), turn)
# turn = switch(turn)
# display(b)
#
# insert(b, play_rand(b), turn)
# turn = switch(turn)
# display(b)
#
# insert(b, 1, 'x')
# insert(b, 1, 'o')
# # insert(b, 1, 'o')
# # insert(b, 1, 'x')
#
#
# insert(b, 2, 'x')
# insert(b, 2, 'x')
# # insert(b, 2, 'o')
# insert(b, 2, 'o')
#
# insert(b, 3, 'x')
# insert(b, 3, 'o')
# # insert(b, 3, 'x')
# # insert(b, 3, 'x')
#
# insert(b, 4, 'o')
# insert(b, 4, 'o')
# # insert(b, 4, 'o')
# # insert(b, 4, 'x')
#
# insert(b, 5, 'o')
# insert(b, 5, 'x')
# # insert(b, 5, 'o')
# insert(b, 5, 'x')

# println("initial board")
# display(b)
#
# while (!game_over(b))
#    println("Move: ", moves," Turn: ",turn)
#    ind = determine_move(b, turn)
#    insert(b, ind, turn)
#    println("playing col: ", ind)
#    display(b)
#    global turn = switch(turn)
#    global moves+= 1
#    println("\n\n")
# end
# println("Moves: ",moves)
#


#################       Human VS AI Game   ###############
function H_vs_AI_minimax(lookahead::Int)
   while(!game_over(b))

      println("\nMove: ", x_moves," Turn: ",turn)
      ind = determine_move(b, turn)
      insert(b, ind, turn)
      println("playing col: ", ind)
      display(b)
      global turn = switch(turn)
      global x_moves+= 1

      if game_over(b)
         break
      end

      println("\nMove: ", o_moves," Turn: ",turn)
      valid = false
      while(!valid)
         print("Enter next move for ",":")
         m = parse(Int, readline())
         println("your move: ", m)
         valid = insert(b, m, turn)
         if !valid
            println("illegal column")
         end
      end
      display(b)
      global turn = switch(turn)
      global o_moves+= 1

   end
   results(b)
end



###################   AI vs Random computer ##################
# while(!game_over(b))
#
#    println("\nMove: ", x_moves," Turn: ",turn)
#    ind = determine_move(b, turn)
#    insert(b, ind, turn)
#    println("playing col: ", ind)
#    display(b)
#    global turn = switch(turn)
#    global x_moves+= 1
#
#    if game_over(b)
#       break
#    end
#
#    println("\nMove: ", o_moves," Turn: ",turn)
#    valid = false
#    while(!valid)
#       ind = play_rand(b) # determine_move(b, turn)
#       valid = insert(b, ind, turn)
#       if !valid
#          println("illegal column")
#       end
#    end
#    global turn = switch(turn)
#    global o_moves+= 1
#
# end
# results(b)



### MAIN
# H_vs_AI_minimax(5)
# H_vs_H()
