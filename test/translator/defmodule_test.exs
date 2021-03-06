defmodule ElixirScript.Translator.Defmodule.Test do
  use ShouldI
  import ElixirScript.TestHelper

  should "translate empty module" do
    ex_ast = quote do
      defmodule Elephant do
      end
    end

    js_code = """
    const __MODULE__ = Erlang.atom('Elephant');
    """

    assert_translation(ex_ast, js_code)
  end

  should "translate defmodules" do
    ex_ast = quote do
      defmodule Elephant do
        @ul JQuery.("#todo-list")

        def something() do
          @ul
        end

        defp something_else() do
        end
      end
    end

    js_code = """
      const __MODULE__ = Erlang.atom('Elephant');

      let something_else = fun([
        [], 
        function(){
          return null;
        }
      ]);


      let something = fun([
        [], 
        function(){
          return ul;
        }
      ]);

      const ul = JQuery('#todo-list');

      export default { something: something };
    """

    assert_translation(ex_ast, js_code)

    ex_ast = quote do
      defmodule Elephant do
        alias Icabod.Crane

        def something() do
        end

        defp something_else() do
        end
      end
    end

    js_code = """
     import Crane from 'icabod/crane';
     const __MODULE__ = Erlang.atom('Elephant');

      let something_else = fun([
        [], 
        function(){
          return null;
        }
      ]);


      let something = fun([
        [], 
        function(){
          return null;
        }
      ]);

     export default { something: something };
    """

    assert_translation(ex_ast, js_code)
  end

  should "translate modules with inner modules" do
    ex_ast = quote do
      defmodule Animals do

        defmodule Elephant do
          defstruct trunk: true
        end


        def something() do
          %Elephant{}
        end

        defp something_else() do
        end

      end
    end

    js_code = """
      import Elephant from 'animals/elephant';
      const __MODULE__ = Erlang.atom('Animals');

      let something_else = fun([[], function() {
        return null;
      }]);

      let something = fun([[], function() {
        return Elephant.defstruct();
      }]);

      export default {
        something: something
      };

      const __MODULE__ = Erlang.atom('Elephant');
      function defstruct(trunk = true) {
        return {
          __struct__: __MODULE__,
          trunk: trunk
        };
      }

      export default {defstruct: defstruct};

    """

    assert_translation(ex_ast, js_code)
  end

  should "translate modules with 2 inner modules" do
    ex_ast = quote do
      defmodule Animals do

        defmodule Elephant do
          defstruct trunk: true
        end

        defmodule Bear do
          defstruct trunk: true
        end


        def something() do
          %Elephant{}
        end

        defp something_else() do
        end

      end
    end

    js_code = """
      import Elephant from 'animals/elephant';
      import Bear from 'animals/bear';
      const __MODULE__ = Erlang.atom('Animals');


      let something_else = fun([[], function() {
        return null;
      }]);

      let something = fun([[], function() {
        return Elephant.defstruct();
      }]);

      export default {
        something: something
      };

      const __MODULE__ = Erlang.atom('Elephant');

      function defstruct(trunk = true) {
        return {
          __struct__: __MODULE__,
          trunk: trunk
        };
      }

      export default {defstruct: defstruct};

      const __MODULE__ = Erlang.atom('Bear');
      function defstruct(trunk = true) {
        return {
          __struct__: __MODULE__,
          trunk: trunk
        };
      }

      export default {defstruct: defstruct};
    """

    assert_translation(ex_ast, js_code)
  end


  should "translate modules with inner module that has inner module" do
    ex_ast = quote do
      defmodule Animals do

        defmodule Elephant do
          defstruct trunk: true

          defmodule Bear do
            defstruct trunk: true
          end
        end


        def something() do
          %Elephant{}
        end

        defp something_else() do
        end

      end
    end

    js_code = """
     import Elephant from 'animals/elephant';
     const __MODULE__ = Erlang.atom('Animals');
     let something_else = fun([[], function(){return null;}]);
     let something = fun([[], function(){return Elephant.defstruct();}]);

     export default {something: something};
     import Bear from 'animals/elephant/bear';

     const __MODULE__ = Erlang.atom('Elephant');
     function defstruct(trunk = true){return {__struct__: __MODULE__, trunk: trunk};}
     export default {defstruct: defstruct};

     const __MODULE__ = Erlang.atom('Bear');
     function defstruct(trunk = true){return {__struct__: __MODULE__, trunk: trunk};}
     export default {defstruct: defstruct};
    """

    assert_translation(ex_ast, js_code)
  end


  should "Pull out module references and make them into imports" do
    ex_ast = quote do
      defmodule Animals do
        Lions.Tigers.Bears.oh_my()
      end
    end 

    js_code = """
    import Bears from 'lions/tigers/bears';
    const __MODULE__ = Erlang.atom('Animals');

     JS.get_property_or_call_function(Bears, 'oh_my');

     export default {};
    """

    assert_translation(ex_ast, js_code)
  end

  should "Only add one import per module reference" do
    ex_ast = quote do
      defmodule Animals do
        Lions.Tigers.Bears.oh_my()
        Lions.Tigers.Bears.oh_my_2()
      end
    end 

    js_code = """
    import Bears from 'lions/tigers/bears';
    const __MODULE__ = Erlang.atom('Animals');

    JS.get_property_or_call_function(Bears, 'oh_my');
    JS.get_property_or_call_function(Bears, 'oh_my_2');
     
     export default {};
    """

    assert_translation(ex_ast, js_code)
  end

  should "Pull references from functions" do
    ex_ast = quote do
      defmodule Animals do

        def hello() do
            Lions.Tigers.Bears.oh_my()
        end
      end
    end 

    js_code = """
      import Bears from 'lions/tigers/bears';
      const __MODULE__ = Erlang.atom('Animals');

      let hello = fun([[], function() {
        return JS.get_property_or_call_function(Bears, 'oh_my');
      }]);

      export default {
        hello: hello
      };
    """

    assert_translation(ex_ast, js_code)
  end

  should "ignore aliases already added" do
    ex_ast = quote do
      defmodule Animals do
        alias Lions.Tigers.Bears

        def hello(param) do
            Bears.oh_my()
            Lions.Tigers.Bears.oh_my()
        end
      end
    end 

    js_code = """
      import Bears from 'lions/tigers/bears';
      const __MODULE__ = Erlang.atom('Animals');

      let hello = fun([
        [fun.parameter], 
        function(param) {
          JS.get_property_or_call_function(Bears, 'oh_my');
          return JS.get_property_or_call_function(Bears, 'oh_my');
        }
      ]);

      export default {
        hello: hello
      };
    """

    assert_translation(ex_ast, js_code)
  end
end
