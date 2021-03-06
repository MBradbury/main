require File.dirname(__FILE__) + '/../../../spec_helper'
require File.dirname(__FILE__) + '/../fixtures/classes'
require 'socket'

describe "Socket.for_fd given a file descriptor" do
  it "adopts that descriptor into a new Socket object" do
    begin
      server = TCPServer.new("127.0.0.1", SocketSpecs.port)
      client = TCPSocket.open("127.0.0.1", SocketSpecs.port)
      new_sock = Socket.for_fd(client.fileno)

      new_sock.should_not be_nil
      new_sock.class.should == Socket
      new_sock.fileno.should == client.fileno

      new_sock.send("foo", 0)
      client.send("bar", 0)

      # state explicitly that we are done sending
      new_sock.shutdown
      client.shutdown

      host = server.accept
      host.read(3).should == "foo"
      host.read(3).should == "bar"
    ensure
      if (host && !host.closed?)
        host.close
      end
      if (server && !server.closed?)
        server.close
      end
      if (client && !client.closed?)
        client.close
      end
      if (new_sock && !new_sock.closed?)
        begin
          new_sock.close
        rescue Errno::EBADF
        end
      end
    end
  end

  it "raises error for a bad descriptor" do
    lambda { Socket.for_fd(9999999) }.should raise_error
  end
end
