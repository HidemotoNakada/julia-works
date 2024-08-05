macro monitored_async(expr)
    quote
        @async begin
            t = @async $(esc(expr))
            try
                wait(t)
            catch
                display(t)
            end
        end
    end
end