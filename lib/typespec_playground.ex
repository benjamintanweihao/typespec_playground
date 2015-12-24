defmodule TypespecPlayground do
  
  ###############################################
  # The discrepancies that Dialyzer can pick up #
  ###############################################

  #######################
  # 1. Wrong use of BIF #
  #######################

  # Function weird/0 has no local return
  # The call erlang:'+'(1,'atom') will never return since it differs in the 2nd argument from the success typing arguments: (number(),number())
  def weird do
    1 + :atom
  end

  #####################################
  # 2. Code that will not be executed #
  #####################################

  # The pattern 42 can never match the type atom()
  def foo(x) when is_atom(x) do
    case x do
      42 -> true
      _  -> false
    end
  end

  ##################################
  # 3. Invalid type specifications #
  ##################################

  # Invalid type specification for function 'Elixir.TypespecPlayground':tuple_sum/1. 
  # The success typing is ({number(),number(),number()}) -> number()
  @spec tuple_sum({:atom, :atom, :atom}) :: :atom
  def tuple_sum({x,y,z}) do
    x + y + z
  end

  @spec whats_my_type(:crap) :: :crap
  def whats_my_type(x) do
    1 + x
  end

  ###########################################################
  #  Getting Dialyzer to show it's inferred success typings #
  ###########################################################

  defmodule List do

    # NOTE: This is one way to show force Dialyzer to tell 
    # us what the typings are

    # Invalid type specification for function 'Elixir.TypespecPlayground.List':suffix/2. The success typing is (_,_) -> boolean()
    @spec suffix_1(none, none) :: none

    def suffix_1(suffix, suffix), do: true

    def suffix_1(suffix, [_|tail]) do
      suffix_1(suffix, tail)
    end

    def suffix_1(_, []), do: false

    ######################################################

    # NOTE: This is Dialyzer telling us that the type defined is too general.
    # Type specification 'Elixir.TypespecPlayground.List':suffix_2(any(),any()) -> any() is a supertype of the success typing: 'Elixir.TypespecPlayground.List':suffix_2(_,_) -> boolean()
    @spec suffix_2(any, any) :: any

    def suffix_2(suffix, suffix), do: true

    def suffix_2(suffix, [_|tail]) do
      suffix_2(suffix, tail)
    end

    def suffix_2(_, []), do: false

    ######################################################

    # NOTE: So, what happens when we add a guard clause?
    # We first add this, and see what Dialyzer tells us.
    @spec suffix_3(none, none) :: none

    # after adding length(suffix), we would have expected
    # that we get a success typing of 
    # 
    #   ([any()],[any()]) -> boolean()
    # 
    # but instead we get
    #
    #   (_,[any()]) -> boolean()
    #
    def suffix_3(suffix, suffix) when length(suffix) >= 0 do
      true
    end

    def suffix_3(suffix, [_|tail]) do
      suffix_3(suffix, tail)
    end

    # _suffix is the cause! You can try turning this off and
    # see the result
    def suffix_3(_suffix, []), do: false

  end

  #######################
  # Handling Exceptions #
  #######################

  #   The specification for 'Elixir.TypespecPlayground':
  #   clause_with_exit/0 states that the function might also return any() but the inferred return is none()
  #   Function clause_with_exit/0 only terminates with explicit exception
  #
  # NOTE: Since the inferred return type is none(), this means
  # that Dialyzer was not able to infer a success typing.
  # Therefore, it complains.
  @spec clause_with_exit :: any
  def clause_with_exit do
    exit(:error)
  end


  # Let's another clause
  @spec clause_with_possible_exit(none) :: none
  def clause_with_possible_exit(x) when is_atom(x) do
    exit(:error) 
  end

  def clause_with_possible_exit(x) when is_pid(x) do
    {x}
  end

  # This results in 
  #
  #   The success typing is (pid()) -> {pid()}
  #
  # Notice that the first clause is entirely ignored, since it
  # doesn't contibute to the success typing.

end
