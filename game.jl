#Global variables
global N = 20000
global c = 2
global turn = 'x'
global x_moves = 0
global o_moves = 0

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
   #check column is legal, i.e. not full, and not out of bounds
   if col > b.cols || col < 1 || b.lowest[col] == 0
      return false
   end
   b.board[b.lowest[col],col]= disc
   #update lowest space
   b.lowest[col]-= 1
   return true
end

function remove(b::gameBoard, col::Int)
   b.lowest[col]+= 1
   b.board[b.lowest[col],col]= ' '
end

function display(b::gameBoard)
   for i = 1:b.rows
    for j = 1:b.cols
        print(b.board[i, j],'|')
    end
    println()
   end
   for i = 1:b.cols
      print(i," ")
   end
   println()
end

#Checks of boards is full and returns true/false
function is_full(b::gameBoard)::Bool
   if maximum(b.lowest) == 0
      return true
   else
      return false
   end
end

#Tests of player p has four consecutive discs
function test_win(b::gameBoard, d::Char)::Bool
   if test_horizontal(b,d) || test_vertical(b,d) || test_diagonal_up(b,d) || test_diagonal_down(b,d)
      return true
   end
   return false
end

#Tests if theres a horizontal win, checks rows top to bottom
function test_horizontal(b::gameBoard, d::Char)::Bool
   for i = 1:b.rows
      for j= 1: b.cols-3
         if b.board[i,j]==d && b.board[i,j+1]==d && b.board[i,j+2]==d && b.board[i,j+3]==d
            return true
         end
      end
   end
   return false
end

#Tests if theres a vertical win, checks cols left to right
function test_vertical(b::gameBoard, d::Char)::Bool
   for j=1: b.cols
      for i= 1 : b.rows-3
         if b.board[i,j]==d && b.board[i+1,j]==d && b.board[i+2,j]==d && b.board[i+3,j]==d
            return true
         end
      end
   end
   return false
end

#Tests if theres a diagonal win, checks each in-bound disc left to right up diagonal (row wise top to bottom)
function test_diagonal_up(b::gameBoard, d::Char)::Bool
   for i=4:b.rows
      for j=1:b.cols-3
         if b.board[i,j]==d && b.board[i-1,j+1]==d && b.board[i-2,j+2]==d && b.board[i-3,j+3]==d
            return true
         end
      end
   end
   return false
end

#Tests if there's a down-diagonal win
function test_diagonal_down(b::gameBoard, d::Char)::Bool
   for i=1:b.rows - 3
      for j= 1:b.cols-3
         if b.board[i,j]==d && b.board[i+1,j+1]==d && b.board[i+2,j+2]==d && b.board[i+3,j+3]==d
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
   #base case
   if l > lookahead || game_over(b)
      s = eval_func(b, switch(d), lastcol, !maximizer)
      return s
   end

   #recursive case
   scores = Array{Int}(undef,1, b.cols)
   if maximizer
      max_score = -1000
      for i=1: b.cols
         new_b = b
         if insert(new_b, i, d)
            score = minimax(new_b,l+1, lookahead, !maximizer, switch(d),i)
            scores[i] = score
            remove(new_b,i)
         else
            score = -1000
            scores[i] = score
         end
         max_score = max(score, max_score)
      end
      return max_score

   else
      min_score = 10000
      for i=1: b.cols
         new_b = b
         if insert(new_b, i, d)
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
   max = c
   #assess for maximizer
   if !m
      max = switch(c)
   end
   if test_win(b,max)
      return 256
   elseif test_win(b,switch(max))   #&& m || test_win(b,c) && !m
      return -256
   elseif is_full(b) #draw game
      return 2
   elseif m
      return calculate_score(b,max,col)
   else
      return -calculate_score(b,switch(max),col)
   end
end

function calculate_score(b::gameBoard, c::Char, col::Int)::Int
   return vertical_streak(b,c,col)  + horizontal_streak(b,c,col) + updiag_streak(b,c,col)+ downdiag_streak(b,c,col)
end

function vertical_streak(b::gameBoard, c::Char, col::Int)::Int
   count = 1
   row = b.lowest[col]+1
   while row < b.rows && b.board[row+1,col] == c
      count += 1
      row +=1
   end
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
      end
   end
   for i = 1: length(a)  #find all ties and add to array
      if a[i] == max
         max = a[i]
         push!(ties, i)
      end
   end
   return ties[rand(1:length(ties))]
end

#function return index of column with max value, i.e. column that should be played
function determine_move(b::gameBoard,c::Char)::Int
   scores = Array{Int}(undef,1, b.cols)
   for i = 1: b.cols
      if insert(b, i, c)
         scores[i] = minimax(b, 1, 6, false, switch(c),i) ########
         remove(b,i)
      else
         scores[i] = -1000
      end
   end
   return max_score_col(scores)
end


################       Monte Carlo Tree Search      ################
mutable struct state
   board::gameBoard
   cols::Int
   wins::Float64
   visits::Int
   prev_state::state
   next_states::Array{state}
   turn::Char
   legal::Array{Int} #hold indices of legal cols

   function state(b::gameBoard,c::Char) #root takes in board
      this = new()
      this.board = gameBoard(b) #constructor
      this.cols = b.cols
      this.wins = 0
      this.visits = 0
      #this.prev_state = nothing
      this.next_states = Array{state}(undef,1, this.cols)
      this.turn = switch(c) #last played, current turn reflected in children
      this.legal = Array{state}(undef,0)
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
      this.legal = Array{state}(undef,0)
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
#give a state, return all legal next states (fill legal array with col indices)
function getLegalCols(s::state)
   for i=1:s.cols
      if insert(s.board,i, ' ')
         remove(s.board,i)
         push!(s.legal, i)
      end
   end
end
function getLegalCols(b::gameBoard, legal::Array{Int} )
   # legal = Int[] #array of indices
   for i=1:b.cols
      if insert(b,i, ' ')
         remove(b,i)
         push!(legal, i)
      end
   end
end
#return best move
function determine_move_MCTS(b::gameBoard, c::Char)::Int
   #initialize, expand root and create children states
   root = state(b,c)
   getLegalCols(root)
   for i in eachindex(root.legal)
      state(root,root.legal[i])
   end
   return run_simulations(root,c)
end

function run_simulations(s::state,c::Char)::Int
   curr_state = s
   n = 0
   while n < N
         #if leaf node
         while !leaf(curr_state)
            #calculate UCT for all children and select max
            max = curr_state.legal[1]  #col index of first child
            max_val = UCT(curr_state.next_states[curr_state.legal[1]])
            for i=2:length(curr_state.legal)
               m = UCT(curr_state.next_states[curr_state.legal[i]])
               if m > max_val
                  max = curr_state.legal[i]
                  max_val = m
               end
            end
            curr_state = curr_state.next_states[max]
         end

         #reached a leaf: if not visited before: rollout, else expand
         result = ' '
         if curr_state.visits == 0
            result = rollout(curr_state)
         elseif length(curr_state.legal) == 0
            result = rollout(curr_state)
         else
            getLegalCols(curr_state)
            for i in eachindex(curr_state.legal)
               state(curr_state, curr_state.legal[i])
            end
            ind = curr_state.legal[rand(1:length(curr_state.legal))]
            curr_state = curr_state.next_states[ind]
            result = rollout(curr_state)
         end

         #update stats for terminal node then back-propagate to root
         curr_state.visits += 1
         if result == curr_state.turn
            curr_state.wins += 1
         end
         while isdefined(curr_state, :prev_state)
            curr_state = curr_state.prev_state
            curr_state.visits += 1
            if curr_state.turn == result
               curr_state.wins += 1
            elseif result == 'd'
               curr_state.wins += 0.5
            end
         end
         n+=1
   end

   #calculate UCT for all children and select max and return
   max = curr_state.legal[1]  #col index of first child
   max_val = UCT(curr_state.next_states[curr_state.legal[1]])
   for i=2:length(curr_state.legal)
      m = UCT(curr_state.next_states[curr_state.legal[i]])
      if m > max_val
         max = curr_state.legal[i]
         max_val = m
      end
   end
   return max
end

function rollout(s::state)::Char
   b_copy = gameBoard(s.board) #board copy for rollout
   legal = Int[]
   turn = switch(s.turn)

   while !game_over(b_copy)
      getLegalCols(b,legal)
      ind = legal[rand(1:length(legal))]
      insert(b_copy, ind, turn)
      turn = switch(turn)
   end

   #whats the value of the rollout??
   if test_win(b_copy, 'x')
      return 'x'
   elseif test_win(b_copy, 'o')
      return 'o'
   elseif is_full(b_copy)
      return 'd'
   end
end

function UCT(s::state)::Float64
   if s.visits == 0
      return c*sqrt(log(N)/s.visits)
   else
      return s.wins/s.visits + c*sqrt(log(N)/s.visits)
   end
end

#randomly chooses column to play
function play_rand(b::gameBoard)::Int
   return rand(1:b.cols)
end


function printState(s::state)
   println("\n state board: ")
   display(s.board)
   println("turn: ", s.turn)
   println("wins: ",s.wins, " visits: ",s.visits)
   if isdefined(s, :prev_state)
      # println("parent: ")
      # display(s.prev_state.board)
   else
      println("no parent")
   end
   print("children: ")
   for i=1:s.cols
      if isassigned(s.next_states, i)
         print(" ",i)
      end
   end
   println("\n")
end

function leaf(s::state)::Bool
   for i=1:s.cols
      if isassigned(s.next_states, i)
         return false
      end
   end
   return true
end

#################     Human VS Human Game   ###############
function H_vs_H(b::gameBoard)
   player_x = Human('x',false)
   player_o = Human('o',false)
   turn = Human(player_x.disc, false)
   while(!game_over(b))
      valid = false
      while(!valid)
         print("\nEnter next move for ",turn.disc,":")
         m = parse(Int, readline())
         valid = insert(b, m, turn.disc)
      end
      if turn.disc == 'x'
         global x_moves += 1
      else
         global o_moves += 1
      end
      display(b)
      toggle(player_x, player_o, turn)
   end
   results(b)
end
#################       Human VS AI Game   ###############
function H_vs_AI(b::gameBoard, mode::Int)
   while(!game_over(b))
      println("\nPlayer x: AI ")
      print("AI thinking . . .  ")

      if mode == 2
         ind = determine_move(b, turn)
      else
         ind = determine_move_MCTS(b, turn)
      end

      insert(b, ind, turn)
      println("playing column ", ind)
      display(b)
      global turn = switch(turn)
      global x_moves+= 1

      if game_over(b)
         break
      end

      println("\nPlayer o:")
      valid = false
      while(!valid)
         print("Enter your move:")
         m = parse(Int, readline())
         valid = insert(b, m, turn)
         if !valid
            println("please enter a legal column\n")
         end
      end
      display(b)
      global turn = switch(turn)
      global o_moves+= 1
   end
   results(b)
end

################       MAIN       ################

b = gameBoard(6,7)
println("\n\n############################################\n\n")
println("     WELCOME TO THE GAME OF CONNECT FOUR\n      ")
println("\n############################################\n\n")
println("     Human, please choose your opponent:

         (1) Another human
         (2) AI - Minimax
         (3) AI - MCTS\n")
opp = readline()
if opp == "r"
   println("random!")
else
   m = parse(Int, opp)
   println("next move: ", m)
end

println("\tStarting game\n")
if opp == 1
   H_vs_H(b)
elseif opp ==2
   println("\tNote: for the random move option, enter r")
   H_vs_AI(b, 2)
else
   H_vs_AI(b, 3)
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
