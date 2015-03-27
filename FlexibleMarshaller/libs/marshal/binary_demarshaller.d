module libs.marshal.binary_demarshaller;

import std.conv, std.algorithm, std.bitmanip;
import std.stdio;

package interface IBinaryDemarshalerStorageStrategy 
{
package:
	immutable(ubyte[]) GetBuffer();
	void SetBuffer(immutable(ubyte[]) data);

	T ReadVal(T)();
}

public class InvalidFormattingException : Exception
{
	this(string s) { super(s); }
}

package class BinaryDemarshallerStorageStrategy : IBinaryDemarshalerStorageStrategy
{
package:
	this() {}

	this(const(ubyte[]) data)
	{
		SetBuffer(data);
	}
	
	final const(ubyte[]) GetBuffer()
	{
		return m_buffer.idup;
	}
	
	final void SetBuffer(const(ubyte)[] data)
	{
		m_buffer = data.dup;
		m_cursor = 0;
	}
	
	T ReadVal(T)()
	{
		T retval = m_buffer.peek!T(m_cursor);
		m_cursor += T.sizeof;
//		writefln("ReadVal!(%s) = %s", T.stringof, to!string(retval));
		return retval;
	}
	
private:

	ubyte[] m_buffer;
	int m_cursor = 0;
	
	unittest {
		BinaryDemarshallerStorageStrategy tm = new BinaryDemarshallerStorageStrategy;
		tm.SetBuffer([0, 0, 0, 10, 65, 51, 51, 51]);

		auto i = tm.ReadVal!int();
		auto f = tm.ReadVal!float();
		
		assert( i == 10 );
		assert( f == 11.2f );
		
	}
}