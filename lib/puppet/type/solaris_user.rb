module Puppet
  newtype(:solaris_user) do
    @doc = "Manage users with RAD"

    ensurable

    newparam(:name)

    newproperty(:uid)

    newproperty(:gid)

    newproperty(:comment)

    newproperty(:groups, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

    newproperty(:home)

    newproperty(:roles, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

    newproperty(:auths, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

    newproperty(:auth_profiles, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

    newproperty(:profiles, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

    newproperty(:default_proj)
    newproperty(:shell)

    newproperty(:limit_priv, :array_matching => :all) do
      def insync?(is)
        if is.is_a?(Array) and @should.is_a?(Array)
          is.sort == @should.sort
        else
          is == @should
        end
      end
    end

  end
end
