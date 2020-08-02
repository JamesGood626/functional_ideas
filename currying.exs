defmodule Currying do
  # TODO: write a blog post...
  def curry(func, args \\ []) do
    if args |> length === arity?(func) do
      # invoke func
      apply(func, args |> Enum.reverse)
    else
      # continue currying
      # [args | [x]] |> List.flatten()
      fn x -> curry(func, [x | args]) end
    end
  end

  def arity?(func), do:
    :erlang.fun_info(func)[:arity]
end

# Currying.arity?(fn _x, y -> IO.puts(y) end) => 2
# Currying.curry(fn x, y -> x + y end, [1]).(2) # => 3
# Currying.curry(fn x, y, z -> x + y + z end, [1]).(2).(7) => 10

# Ready to go for pipelines!
