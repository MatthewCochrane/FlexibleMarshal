module libs.marshal.compact_binary_marshaller;

import libs.marshal.binary_marshaller, libs.marshal.marshaller;
import std.conv, std.string, std.traits;
import std.stdio;
import std.bitmanip;

alias Marshaller!(CompactBinaryMarshallerStrategy, BinaryMarshallerStorageStrategy) CompactBinaryMarshaller;

package class CompactBinaryMarshallerStrategy(StorageStrategy) : IMarshalStrategy
{
	mixin MarshalMixinTemplate!(StorageStrategy);
	
	void BeginDocumentMarshal(string name)
	{
	}
	
	void EndDocumentMarshal(string name)
	{
	}
	
	void BeginObjectMarshal(T)(T val, string name)
	{
	}
	
	void EndObjectMarshal(T)(T val, string name)
	{
	}
	
	void BeginArrayMarshal(T)(T val, string name)
	{
		MarshalSingleVar(val.length, "");
	}
	
	void EndArrayMarshal(T)(T val, string name)
	{
	}
	
	void MarshalSingleVar(T)(T val, string name)
	{
		static if (isSomeString!(T))
		{
			//Write the length
			MarshalSingleVar(val.length, "");
			//Write the data
			ubyte[] bytes = new ubyte[ForeachType!(T).sizeof*val.length];
			foreach(i, c; val)
			{
				bytes.write!(ForeachType!(T))(c, ForeachType!(T).sizeof * i);
			}
			m_storer.AddBytes(bytes);
		}
		else
		{
			ubyte[] bytes = new ubyte[T.sizeof];
			bytes.write!(T)(val, 0);
			//bytes = cast(byte[])val;
			m_storer.AddBytes(bytes);
		}
	}
		
	void MarshalEnum(T)(T val, string name)
	{
		MarshalSingleVar(val, name);
	}
		
	void MarshalUnion(T)(T val, string name)
	{
		MarshalSingleVar(val, name);
	}
}

unittest {
	//Integers
	CompactBinaryMarshaller binary_marshaller = new CompactBinaryMarshaller;
	binary_marshaller.Marshal(42, "");
	//writeln(to!string(binary_marshaller.GetBuffer()));
	assert(binary_marshaller.GetBuffer() == [0, 0, 0, 42]);
	
	//Strings
	binary_marshaller = new CompactBinaryMarshaller;
	binary_marshaller.Marshal("1 string", "");
	//writeln(to!string(binary_marshaller.GetBuffer()));
	assert(binary_marshaller.GetBuffer() == [0, 0, 0, 8, '1', ' ', 's', 't', 'r', 'i', 'n', 'g']);

	//Enums
	enum MyEnum
	{
		a = 10,
		b,
		c
	}
	MyEnum myenum;
	myenum = MyEnum.b;
	binary_marshaller = new CompactBinaryMarshaller;
	binary_marshaller.Marshal(myenum, "");
	//writeln(to!string(binary_marshaller.GetBuffer()));
	assert(binary_marshaller.GetBuffer() == [0, 0, 0, 11]);
	
	enum MyEnum2 : ubyte
	{
		a = 10,
		b,
		c
	}
	MyEnum2 myenum2;
	myenum2 = MyEnum2.b;
	binary_marshaller = new CompactBinaryMarshaller;
	binary_marshaller.Marshal(myenum2, "");
	//writeln(to!string(binary_marshaller.GetBuffer()));
	assert(binary_marshaller.GetBuffer() == [11]);

	//Arrays
	binary_marshaller = new CompactBinaryMarshaller;
	int[] ary = [1, 2, 3, 44, 5];
	binary_marshaller.Marshal(ary, "");
	//writeln(to!string(binary_marshaller.GetBuffer()));
	assert(binary_marshaller.GetBuffer() == [/*length*/0,0,0,5,
											 /*ary[0]*/0,0,0,1,
											 /*ary[1]*/0,0,0,2,
											 /*ary[2]*/0,0,0,3,
											 /*ary[3]*/0,0,0,44,
											 /*ary[4]*/0,0,0,5]);
	
	//Structs
	binary_marshaller = new CompactBinaryMarshaller;
	static struct A
	{
		int x = 10;
		float y = 11.2;
		string z = "abc";
	}
	A a;
	binary_marshaller.Marshal(a, "");
	//writeln(binary_marshaller.ToString());
	assert(binary_marshaller.GetBuffer() == [/*x*/0, 0, 0, 10, 
											 /*y*/65, 51, 51, 51,
											 /*z*/0, 0, 0, 3, 'a', 'b', 'c']);

	//Nested Structs
	binary_marshaller = new CompactBinaryMarshaller;
	static struct B
	{
		int i1 = 1024;
		float f1 = 22.2;
		A a;
	}
	B b;
	binary_marshaller.Marshal(b, "");
	//writeln(binary_marshaller.ToString());
	assert(binary_marshaller.GetBuffer ==  [/*b.i1 */0, 0, 4, 0,
		 									/*b.f1 */65, 177, 153, 154,
		 									/*b.a.x*/0, 0, 0, 10,
		 									/*b.a.y*/65, 51, 51, 51,
		 									/*b.a.z*/0, 0, 0, 3, 'a', 'b', 'c']);
	
	//Self Defined Marshal Function
	binary_marshaller = new CompactBinaryMarshaller;
	static struct C
	{
		void Marshal(MarshalStrategy : CompactBinaryMarshallerStrategy!StorageStrategy, StorageStrategy : BinaryMarshallerStorageStrategy)(StorageStrategy storer, string name)
		{
			assert(name == "cab");
			storer.AddBytes([1, 2, 3]);
		}
	}
	C c;
	binary_marshaller.Marshal(c, "cab");
	assert(binary_marshaller.GetBuffer() == [1, 2, 3]);
}