---- High scoring boggle board generator. Pretty naive.
---- Requires: BoggleBoardSolver.lua and one dictionary file called "dictionary.txt" in the working directory with one word per line.
---- Author: Avi Kelman, 9/15/2008
---- 

require "BoggleBoardSolver"

function toStr( tbl )
   result = ""
   for _,v in ipairs(tbl) do
      result = table.concat({result,table.concat(v),"\n"})
   end
   return result
end

--- initialize the boggle grid randomly
function init_grid(grid)
   math.randomseed( os.time() )
   for row = 1,5 do
      for col = 1,5 do
         grid[row][col] = alphabet[math.random(1,26)] -- generates random letters to fill the grid
      end
   end
end

-- randomly change values in the grid
function random_change()
   ylocs={}
   xlocs={}
   chars={}
   num_changes = math.random(25)
   for i=1,num_changes do
      grid_loc = math.random(25)
      xlocs[i] = ((grid_loc-1) % 5) + 1
      ylocs[i] = math.ceil(grid_loc/5)
      chars[i] = grid[ylocs[i]][xlocs[i]]
      grid[ylocs[i]][xlocs[i]] = alphabet[math.random(1,26)]
   end
end

-- local alphabetical greedy optimization internals
function alpha_optimize_internals(row,col)
   local previous = ""
   local best_score = 0
   for _,letter in ipairs(alphabet) do
      previous = grid[row][col]
      grid[row][col] = letter
      evaluate_grid()
      if total_score < best_score then
         grid[row][col] = previous
      else
         best_score = total_score
      end
   end
   total_score = best_score
end

-- local alphabetical greedy optimization 
function alpha_optimize()
   for row=1,5 do
      for col=1,5 do
         alpha_optimize_internals(row,col)
      end
   end
   for row=5,1,-1 do
      for col=5,1,-1 do
         alpha_optimize_internals(row,col)
      end
   end
end

----------------------------
--- Program starts here. ---
----------------------------

-- First initialize storage.
word_count = 0
total_score = 0

init_grid(grid)
print(toStr(grid))

evaluate_grid()
print("word count = " .. word_count)
print("score = " .. total_score)
last_changed_at = 0
change_function = 1
num_functions = 2
top_score = 0
local file = io.open("FinalTablesFromLocalOptimization.txt", "w")
file:write("")
file:close()
counter = 0

while true do -- runs until you kill it
   counter = counter + 1

   -- new high score
   if top_score < total_score then
      print("New high score = " .. total_score, "word count = " .. word_count)
      top_score = total_score
      last_changed_at = counter
      local file = io.open("FinalTablesFromLocalOptimization.txt","w")
      file:write("Score="..total_score.."\n"..toStr(grid).."\n")
      file:close()
   end

   -- stale for too long
   if (counter - last_changed_at) > 100000 then
      print("Re-initializing the grid!")
      init_grid(grid)
      evaluate_grid()
      last_changed_at = counter
      top_score = total_score
   end

   if (change_function == 1)  then
      if (counter % 10000 == 0) then
         change_function = (change_function % num_functions) + 1  -- change between random walk and local optimization every 10,000 steps
      end
      if ((counter-1) % 1000 == 0) then
         print("iter:" .. counter .. "       current_score: " .. total_score .."     top_score: " .. top_score)
      end
      previous_score = total_score
      random_change()
      evaluate_grid()
      if (total_score < (previous_score*0.97)) then
         for i=num_changes,1,-1 do
            grid[ylocs[i]][xlocs[i]] = chars[i]
         end
         total_score = previous_score
      elseif (total_score > top_score) then
         print("score = " .. total_score, "word count = " .. word_count)
      end
   else
      change_function = (change_function % num_functions) + 1
      alpha_optimize()
      print ("Total score for all words: ", total_score)
   end
end
