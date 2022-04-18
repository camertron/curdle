require 'spec_helper'

describe Curdle do
  def verify(input, expected)
    expect(described_class.process(input)).to eq(expected)
  end

  it 'removes extend T::Sig' do
    verify('extend T::Sig', '# extend T::Sig')
  end

  it 'removes extend T::Generic' do
    verify('extend T::Generic', '# extend T::Generic')
  end

  it 'removes extend T::Helpers' do
    verify('extend T::Helpers', '# extend T::Helpers')
  end

  it 'removes casts' do
    verify('foo = T.cast(bar, String)', 'foo = bar')
  end

  it 'removes musts' do
    verify('foo = T.must(bar)', 'foo = bar')
  end

  it 'removes unsafes' do
    verify('foo = T.unsafe(bar)', 'foo = bar')
  end

  it 'removes abstract! calls' do
    verify(<<~END1, <<~END2)
      class Foo
        abstract!
      end
    END1
      class Foo
        # abstract!
      end
    END2
  end

  it 'removes single-line sigs' do
    verify(<<~END1, <<~END2)
      class Foo
        sig { returns(String) }
        def foo
        end
      end
    END1
      class Foo
        # sig { returns(String) }
        def foo
        end
      end
    END2
  end

  it 'removes multi-line sigs' do
    verify(<<~END1, <<~END2)
      class Foo
        sig {
          params(bar: String, baz: Integer).returns(String)
        }
        def foo(bar, baz)
        end
      end
    END1
      class Foo
        # sig {
        #   params(bar: String, baz: Integer).returns(String)
        # }
        def foo(bar, baz)
        end
      end
    END2
  end

  it 'removes T.let assigned to an instance variable' do
    verify(<<~END1, <<~END2)
      class Foo
        def initialize
          @version = T.let(@version, T.nilable(String))
        end
      end
    END1
      class Foo
        def initialize
          # @version = T.let(@version, T.nilable(String))
        end
      end
    END2
  end

  it 'removes T.let ivar with an actual value' do
    verify(<<~END1, <<~END2)
      class Foo
        def initialize
          @version = T.let(version, T.nilable(String))
        end
      end
    END1
      class Foo
        def initialize
          @version = version
        end
      end
    END2
  end

  it 'removes T.let assigned to a constant' do
    verify(<<~END1, <<~END2)
      class Foo
        FOO = T.let('foo'.freeze, String)
      end
    END1
      class Foo
        FOO = 'foo'.freeze
      end
    END2
  end

  it 'removes type_members' do
    verify(<<~END1, <<~END2)
      class Foo
        extend T::Generic

        Elem = type_member
      end
    END1
      class Foo
        # extend T::Generic

        # Elem = type_member
      end
    END2
  end

  it 'removes type_aliases' do
    verify(<<~END1, <<~END2)
      class Foo
        AfterCallback = T.type_alias do
          T.proc.params(cmd: T::Array[String], last_status: T.nilable(Process::Status)).void
        end
      end
    END1
      class Foo
        # AfterCallback = T.type_alias do
        #   T.proc.params(cmd: T::Array[String], last_status: T.nilable(Process::Status)).void
        # end
      end
    END2
  end
end