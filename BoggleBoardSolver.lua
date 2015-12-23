---- 5x5 Boggle board solver with slightly simplified structure. There is no "Qu" tile, only "Q".
---- Requires: one dictionary file called "dictionary.txt" in the working directory with one word per line.
---- Requires: one 5x5 boggle grid file called "grid.txt" in the working directory formatted without spaces or punctuation.
---- Author: Avi Kelman, 9/15/2008

alphabet = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}

--- Convert the dictionary into a trie for fast lookups
-- Required input: a dictionary file containing words, one per line, with no numbers or punctuation.
function build_dictionary(file_name, dictionary)
   --
   -- Simple trie structure example:
   --
   -- [a]-[b]-[c]-[-]
   --     / \
   --   [-] [d]-[-]
   --        |
   --       [e]-[-]
   --
   -- Words (terminated by "-") in this example are: ab, abc, abd, abde 
   --
   local current_char = ""
   for line in io.lines(file_name) do
      pointer = dictionary
      if #line > 2 then -- Boggle rules say that words must be 3 or more letters
         for i = 1,#line do
            current_char = string.lower(string.sub(line,i,i))
            if pointer[current_char] == nil then
               pointer[current_char] = {}
            end
            pointer = pointer[current_char]
         end
         pointer[0] = '-' -- marks a word boundary
      end
   end
end

--- Store the boggle grid
function build_grid(file_name)
   row = 2
   for line in io.lines(file_name) do
      for col = 1,#line do
         grid[row][col+1] = string.lower(string.sub(line,col,col))
      end
      row = row+1
   end
end

score_chart = {1,1,1,1,2,3,5}

--- All work is done here. Recursively traverse the grid according to available dictionary pathways.
--- Mark and score at word boundaries in the dictionary tree.
function recursive_word_finder(row, col, pointer, word_size)
   local point = pointer[grid[row][col]] -- branch current location in the dictionary
   local word_size = word_size+1
   local vis = visited[row]
   vis[col] = 1
   if (point[0] == '-') then
      total_score = total_score + (score_chart[word_size] or 11)
      word_count = word_count+1
      point[0] = '+'
      pointer_table[word_count] = point
   end

   -- unrolled loop over 8-connected neighbors
   local rowminus = row-1
   local rowplus = row+1
   local colminus = col-1
   local colplus = col+1
   if visited[rowminus][colminus] == 0 and point[grid[rowminus][colminus]] ~= nil then
      recursive_word_finder(rowminus, colminus, point, word_size)
   end
   if visited[rowminus][col] == 0 and point[grid[rowminus][col]] ~= nil then
      recursive_word_finder(rowminus, col, point, word_size)
   end
   if visited[rowminus][colplus] == 0 and point[grid[rowminus][colplus]] ~= nil then
      recursive_word_finder(rowminus, colplus, point, word_size)
   end
   if vis[colminus] == 0 and point[grid[row][colminus]] ~= nil then
      recursive_word_finder(row, colminus, point, word_size)
   end
   if vis[colplus] == 0 and point[grid[row][colplus]] ~= nil then
      recursive_word_finder(row, colplus, point, word_size)
   end
   if visited[rowplus][colminus] == 0 and point[grid[rowplus][colminus]] ~= nil then
      recursive_word_finder(rowplus, colminus, point, word_size)
   end
   if visited[rowplus][col] == 0 and point[grid[rowplus][col]] ~= nil then
      recursive_word_finder(rowplus, col, point, word_size)
   end
   if visited[rowplus][colplus] == 0 and point[grid[rowplus][colplus]] ~= nil then
      recursive_word_finder(rowplus, colplus, point, word_size)
   end
   vis[col] = 0
end

--- Words are deactivated during processing so that they don't get added more than once. 
--- Pointers are stored for later re-activation.
--- This is where they get reactivated.
function reset_dictionary_word_markers()
   for i,v in ipairs(pointer_table) do
      v[0] = '-'
   end
   pointer_table = {}
end

rowcoords = {}
colcoords = {}
for slot=0,24 do
   rowcoords[slot] = slot%5+2
   colcoords[slot] = math.floor(slot*0.2)+2
end

-- get the score for the current grid
function evaluate_grid()
   total_score = 0
   word_count = 0
   for slot=0,24 do
      recursive_word_finder(rowcoords[slot], colcoords[slot], dictionary, 0)
   end
   reset_dictionary_word_markers()
end

-- First initialize storage.
pointer_table = {} -- stores pointers to word boundaries
dictionary = {} -- stores the optimized dictionary
grid = {{{},{},{},{},{},{}},{{},{},{},{},{},{}},{{},{},{},{},{},{}},{{},{},{},{},{},{}},{{},{},{},{},{},{}},{{},{},{},{},{},{}},{{},{},{},{},{},{}}} -- prefab template for simplicity
visited = {{1,1,1,1,1,1,1},{1,0,0,0,0,0,1},{1,0,0,0,0,0,1},{1,0,0,0,0,0,1},{1,0,0,0,0,0,1},{1,0,0,0,0,0,1},{1,1,1,1,1,1,1}} -- prefab template for simplicity

print("\nOptimizing the dictionary. This only needs to be done once ever, so it's not fair to include this part in the execution time.")
build_dictionary("dictionary.txt", dictionary)
print("Dictionary build complete.\n")

----------------------------
--- Program starts here. ---
----------------------------

build_grid("grid.txt", grid)
local ntimes = 500 -- run 500 times

print("Performing board solution "..ntimes.." times just to demonstrate solution performance.\n")

timer = os.clock()
for counter=1,ntimes do
   evaluate_grid()
end
timer = os.clock() - timer

print ("Total elapsed solving time: ", timer, " Seconds")
print ("Time per solution: ", timer/ntimes, " Seconds")
print ("Total number of words: ", word_count)
print ("Total score for all words: ", total_score)
print ("Average seconds per word: ", timer/ntimes/word_count)
print ("Average seconds per point: ", timer/ntimes/total_score)

