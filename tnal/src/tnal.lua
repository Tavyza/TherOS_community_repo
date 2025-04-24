-- TNAL assembler written in Lua for opencomputers
-- TNAL (or Tavyza Number Assembly Language) is a very basic low level programming language that compiles to a long string of numbers.
-- Might eventually write an OS to use this
local args = {...};
local sysvars = {
    CA="9000", --cache
    MEMx="9xxx" -- memory register x (001-999)
};
local instruct = {
    USE ="01", -- get a dependency in a specific memory register, USE 01. grabs the file at register 1 and loads it into the program
    READ="02", -- copy specified memory register to cache
    WRIT="03", -- write cache to specified memory register
    ADD ="04", -- add number to cache, ADD 20. would add 20 to the number in cache
    SUB ="05", -- subtract number from cache, SUB 20. would subtract 20 from the number in cache
    DRAW="06", -- draw a character at a specific location, DRAW 12 50 CA. would draw the number in cache to the screen at 12, 50 (alternatively you can just set a pixel to a color from 0-25 (black to white))
    FILL="07", -- fill an area with characters, FILL 0 0 25 25 0. sets the area between 0, 0 and 25, 25 to black
    SET ="08", -- set the cache to a specific value
    HALT="09", -- pause the program for a specified amount of time
    ["."]   ="97", -- End of line
    EQU ="00", -- equal, EQU CA 9 [DRAW 12 50 CA.] would draw the number in cache to 12, 50 if cache equals 9
    LST ="10", -- less than, same as EQU, number goes first, comparison goes next
    MRT ="11", -- more than, same as EQU, number goes first, comparison goes next
    LOOP="12", -- loop recursively, LOOP [EQU ]
    BRK ="13", -- break a loop
    -- everything between 14 and 96 (which gives 82 instructions for every program) can be used by dependencies, either system or user defined
    -- the TNAL system will have a folder of "header files" that can only contain dependencies, and the assembler will include any specified headers in the program
    -- these dependencies can also hold instructions to run themselves, when you call the instruction it runs the program
    ["["] ="98",
    ["]"] ="99"
};
local numbers = {001, 002, 003, 004, 005, 006, 007, 008, 009, 000}
-- note: ; for comments
local inputfile = io.open(args[1]);
function parse(file) -- (oops wrong comment) function to run through the file and parse it
    local ftable = {};
    local newfile = "";
    for line in file.read("*a"):gmatch("[^.]+") do -- push it into a table
        table.insert(ftable, line);
    end
    -- now we parse
    for i, line in ipairs(ftable) do
        if line:sub(1, 1) == ";" or line:match(";.*$") then -- we need to support comments that are after instructions
            ftable[i] = line:match(";.*$") and line:sub(1, line:find(";") - 1) or "";
        end
        if line:sub(1, 4):match("use") then
            ftable[i] = "01" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("read") then
            ftable[i] = "02" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("writ") then
            ftable[i] = "03" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("add") then
            ftable[i] = "04" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("sub") then
            ftable[i] = "05" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("draw") then
            ftable[i] = "06" .. line:sub(4, 6).format("%03d") .. line:sub(7, 9).format("%03d") .. line:sub(10);
        elseif line:sub(1, 4):match("fill") then
            ftable[i] = "06" .. line:sub(4, 6).format("%03d") .. line:sub(7, 9).format("%03d") .. line:sub(10, 12).format("%03d") .. line:sub(13, 15).format("%03d") .. line:sub(16, 18).format("%03d") .. line:sub(19);
        elseif line:sub(1, 4):match("set") then
            ftable[i] = "08" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("halt") then
            ftable[i] = "09" .. line:sub(3).format("%03d");
        elseif line:sub(1, 4):match("equ") then
            ftable[i] = "00" .. line:sub(3).format("%03d") .. line:sub(6).format("%03d");
        elseif line:sub(1, 4):match("lst") then
            ftable[i] = "10" .. line:sub(3).format("%03d") .. line:sub(6).format("%03d");
        elseif line:sub(1, 4):match("mrt") then
            ftable[i] = "11" .. line:sub(3).format("%03d") .. line:sub(6).format("%03d");
        elseif line:sub(1, 4):match("loop") then
            ftable[i] = "12" .. line:sub(4).format("%03d");
        
    end
end