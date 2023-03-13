module Test
export @mylog

macro mylog(expr)
    return :(_mylog($(esc(expr))))
end

function _mylog(val)
    println("$val")
end 

end

##
using .Test

a = "value"
@macroexpand @mylog("test $a")
@mylog("test $a")

