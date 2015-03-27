module libs.marshal.binary_marshaller;

package interface IBinaryMarshalerStorageStrategy 
{
package:
	immutable(ubyte[]) GetBuffer();
    void ClearBuffer();

    void AddBytes(ubyte[] bytes);
}

package class BinaryMarshallerStorageStrategy : IBinaryMarshalerStorageStrategy
{
package:
	final immutable(ubyte[]) GetBuffer()
	{
		return m_buffer.idup;
	} 
	
	final void ClearBuffer()
	{
		m_buffer = [];
	}
	
	final void AddBytes(ubyte[] bytes)
	{
		m_buffer ~= bytes;
	}
	
private:
	ubyte[] m_buffer;
	
	unittest {
		BinaryMarshallerStorageStrategy tm = new BinaryMarshallerStorageStrategy;
		tm.AddBytes(['1', '2', '3']);
		tm.AddBytes(['4', '5']);
		
		assert(tm.GetBuffer() == "12345");
		
		tm.ClearBuffer();
		
		assert(tm.GetBuffer() == "");
	}
}