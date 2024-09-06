local crypt = {}

local function convert( chars, dist, inv )
  return string.char( ( string.byte( chars ) - 32 + ( inv and -dist or dist ) ) % 95 + 32 )
end

function crypt.string2key(str)
  tmpTable = {}
  for i = 1, string.len(str) do
    tmpTable[i] = string.byte(str,i)
  end
  while #tmpTable < 5 do
    table.insert(tmpTable,100)
  end
  return tmpTable
end


function crypt.crypt(str, k, inv)
  if not k then
    k = {1,2,3,4,5}
  end
  while #k < 5 do
    table.insert(k,100)
  end
  local enc= "";
  for i=1,#str do
    if(#str-k[#k] >= i or not inv)then
      for inc=0,3 do
	if(i%4 == inc)then
	  enc = enc .. convert(string.sub(str,i,i),k[inc+1],inv);
	  break;
	end
      end
    end
  end
  if(not inv)then
    for i=1,k[#k] do
      enc = enc .. string.char(math.random(32,126));
    end
  end
  return enc;
end


return crypt
