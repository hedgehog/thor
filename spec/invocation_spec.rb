require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'thor/base'

describe Thor::Invocation do
  describe "#invoke" do
    it "invokes a task inside another task" do
      capture(:stdout){ A.new.invoke(:two) }.must == "2\n3\n"
    end

    it "invokes a task just once" do
      capture(:stdout){ A.new.invoke(:one) }.must == "1\n2\n3\n"
    end

    it "invokes a task just once even if they belongs to different classes" do
      capture(:stdout){ Defined.new.invoke(:one) }.must == "1\n2\n3\n4\n5\n"
    end

    it "invokes a task with arguments" do
      A.new.invoke(:five, [5]).must be_true
      A.new.invoke(:five, [7]).must be_false
    end

    it "invokes the default task of given class passed as default namespace" do
      content = capture(:stdout){ A.new.invoke("b", [1,2,3]) }
      content.must == "\"default 1 2 3\"\n"
    end

    it "invokes default task of class given as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(B, [1,2,3]) }
      content.must == "\"default 1 2 3\"\n"
    end

    it "invokes the default task of given class passed as default namespace" do
      content = capture(:stdout){ A.new.invoke("b", "default", [1,2,3]) }
      content.must == "\"default 1 2 3\"\n"
    end

    it "invokes default task of class given as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(B, [1,2,3]) }
      content.must == "\"default 1 2 3\"\n"
    end

    it "raises error on invoking the default task of namespace with wrong arity" do
      lambda do
        A.new.invoke('b', ['1'])
      end.must raise_error(ArgumentError, /b:default called incorrectly. Were required arguments provided\? b:default  arg1, arg2, arg3/)
     end

    it "raises error on invoking the default task of class with wrong arity" do
      lambda do
        A.new.invoke(B, ['1'])
      end.must raise_error(ArgumentError, /b:default called incorrectly. Were required arguments provided\? b:default  arg1, arg2, arg3/)
     end

    it "invokes the default task with default arguments of given class passed as default namespace" do
      content = capture(:stdout){ A.new.invoke("d") }
      content.must == "\"default a b c\"\n"
    end

    it "invokes default task  with default arguments of class given as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(D) }
      content.must == "\"default a b c\"\n"
    end

    it "invokes the default task  with default arguments of given class passed as default namespace" do
      content = capture(:stdout){ A.new.invoke("d") }
      content.must == "\"default a b c\"\n"
    end

    it "invokes default task  with default arguments of class given as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(D) }
      content.must == "\"default a b c\"\n"
    end

    it "invokes the default task with custom and default arguments of given class passed as default namespace" do
      content = capture(:stdout){ A.new.invoke("d", ['1']) }
      content.must == "\"default 1 b c\"\n"
    end

    it "invokes default task with custom and default arguments of class given as argument without a task to invoke" do
      content = capture(:stdout){ A.new.invoke(D, ['1']) }
      content.must == "\"default 1 b c\"\n"
    end

    it "raises no errors on invoking the default task  with default arguments of namespace with wrong arity" do
      capture(:stdout) do
        lambda do
          A.new.invoke('d', ['1'])
        end.must_not raise_error(ArgumentError)
      end
    end

    it "raises no errors on invoking the default task  with default arguments of class with wrong arity" do
      capture(:stdout) do
         lambda do
           A.new.invoke(D, ['1'])
         end.must_not raise_error(ArgumentError)
      end
    end

    it "raises no errors on invoking the default task  with default arguments of namespace with wrong arity" do
      lambda do
        A.new.invoke('d', ['1','','','',''])
      end.must raise_error(ArgumentError, /d:default called incorrectly. Were required arguments provided\? d:default \[arg1\], \[arg2\], \[arg3\]/)
    end
    it "raises no errors on invoking the default task  with default arguments of namespace with wrong arity" do
      lambda do
        A.new.invoke(D, ['1','','','',''])
      end.must raise_error(ArgumentError, /d:default called incorrectly. Were required arguments provided\? d:default \[arg1\], \[arg2\], \[arg3\]/)
     end

    it "accepts a class as argument with a task to invoke" do
      base = A.new([], :last_name => "Valim")
      base.invoke(B, :one, ["Jose"]).must == "Valim, Jose"
    end

    it "accepts a Thor instance as argument" do
      invoked = B.new([], :last_name => "Valim")
      base = A.new
      base.invoke(invoked, :one, ["Jose"]).must == "Valim, Jose"
      base.invoke(invoked, :one, ["Jose"]).must be_nil
    end

    it "allows customized options to be given" do
      base = A.new([], :last_name => "Wrong")
      base.invoke(B, :one, ["Jose"], :last_name => "Valim").must == "Valim, Jose"
    end

    it "reparses options in the new class" do
      A.start(["invoker", "--last-name", "Valim"]).must == "Valim, Jose"
    end

    it "shares initialize options with invoked class" do
      A.new([], :foo => :bar).invoke("b:two").must == { "foo" => :bar }
    end

    it "dump configuration values to be used in the invoked class" do
      base = A.new
      base.invoke("b:three").shell.must == base.shell
    end

    it "allow extra configuration values to be given" do
      base, shell = A.new, Thor::Base.shell.new
      base.invoke("b:three", [], {}, :shell => shell).shell.must == shell
    end

    it "invokes a Thor::Group and all of its tasks" do
      capture(:stdout){ A.new.invoke(:c) }.must == "1\n2\n3\n"
    end

    it "does not invoke a Thor::Group twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke(:c) }.must be_empty
    end

    it "does not invoke any of Thor::Group tasks twice" do
      base = A.new
      silence(:stdout){ base.invoke(:c) }
      capture(:stdout){ base.invoke("c:one") }.must be_empty
    end

    it "raises Thor::UndefinedTaskError if the task can't be found" do
      lambda do
        A.new.invoke("foo:bar")
      end.must raise_error(Thor::UndefinedTaskError)
    end

    it "raises Thor::UndefinedTaskError if the task can't be found even if all tasks where already executed" do
      base = C.new
      silence(:stdout){ base.invoke }

      lambda do
        base.invoke("foo:bar")
      end.must raise_error(Thor::UndefinedTaskError)
    end

    it "raises an error if a non Thor class is given" do
      lambda do
        A.new.invoke(Object)
      end.must raise_error(RuntimeError, "Expected Thor class, got Object")
    end
  end
end
