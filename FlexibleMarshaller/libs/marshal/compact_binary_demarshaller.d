module libs.marshal.compact_binary_demarshaller;

import libs.marshal.binary_demarshaller, libs.marshal.demarshaller;
import std.conv, std.string, std.traits;
import std.stdio;

alias Demarshaller!(CompactBinaryDemarshallerStrategy, BinaryDemarshallerStorageStrategy) CompactBinaryDemarshaller;

package class CompactBinaryDemarshallerStrategy(StorageStrategy) : IDemarshalStrategy
{
	mixin DemarshalMixinTemplate!(StorageStrategy);
	
	void BeginArrayDemarshal(T)(string name, ref T val)
	{
		val.length = m_storer.ReadVal!(typeof(val.length))();
	}
	
	void EndArrayDemarshal(T)(string name, ref T val)
	{
	}
	
	void LoopArrayDemarshal(T)(string name, ref T val)
	{
		foreach (ref item; val)
		{
			Demarshal("", item); 
		}
	}
	
	void BeginDocumentDemarshal(string name)
	{
	}
	
	void EndDocumentDemarshal(string name)
	{
	}
	
	void BeginObjectDemarshal(T)(string name, ref T val)
	{
	}
	
	void EndObjectDemarshal(T)(string name, ref T val)
	{
	}
	
	void DemarshalSingleVar(T)(string name, ref T val)
	{
		static if (isSomeString!(T))
		{
			Unqual!(ForeachType!(T))[] str;
			str.length = m_storer.ReadVal!(typeof(val.length))();
			foreach(ref item; str)
			{
				item = m_storer.ReadVal!(typeof(item))();
			}
			val = to!(T)(str);
		}
		else
		{
			val = m_storer.ReadVal!(T)();
		}
	}
	
	void DemarshalEnum(T)(out T val, string name)
	{
		MarshalSingleVar(val, name);
	}
		
	void DemarshalUnion(T)(out T val, string name)
	{
		MarshalSingleVar(val, name);
	}
}

unittest {
	//Integers
	CompactBinaryDemarshaller binary_demarshaller = new CompactBinaryDemarshaller;
	binary_demarshaller.SetBuffer([0, 0, 0, 42]);
	
	int meaning_of_life;
	binary_demarshaller.Demarshal("", meaning_of_life);
	assert(meaning_of_life == 42);

	//Strings
	char[] name;
	binary_demarshaller = new CompactBinaryDemarshaller;
	binary_demarshaller.SetBuffer([0, 0, 0, 8, '1', ' ', 's', 't', 'r', 'i', 'n', 'g']);
	binary_demarshaller.Demarshal("", name);
//	writefln("name = %s", name);
	assert(name == "1 string");
	
	//Enums
	enum MyEnum
	{
		a = 10,
		b,
		c
	}
	MyEnum myenum;
	binary_demarshaller = new CompactBinaryDemarshaller;
	binary_demarshaller.SetBuffer([0, 0, 0, 11]);
	binary_demarshaller.Demarshal("", myenum);
	assert(myenum == MyEnum.b);

	//Arrays
	binary_demarshaller = new CompactBinaryDemarshaller;
	binary_demarshaller.SetBuffer([/*length*/0,0,0,5,
											 			/*ary[0]*/0,0,0,1,
										 				/*ary[1]*/0,0,0,2,
										 				/*ary[2]*/0,0,0,3,
										 				/*ary[3]*/0,0,0,44,
										 				/*ary[4]*/0,0,0,5]);
	 
	int[] ary_expect = [1, 2, 3, 44, 5];
	int[] ary;
	binary_demarshaller.Demarshal("", ary);
	assert(ary == ary_expect);
	
	//Structs
	binary_demarshaller = new CompactBinaryDemarshaller;
	static struct A
	{
		int x;
		float y;
		string z;
	}
	A a_expect;
	A a;
	a_expect.x = 10;
	a_expect.y = 11.2;
	a_expect.z = "abc";
	binary_demarshaller.SetBuffer([/*x*/0, 0, 0, 10, 
								   /*y*/65, 51, 51, 51,
								   /*z*/0, 0, 0, 3, 'a', 'b', 'c']);
	
	binary_demarshaller.Demarshal("", a);
	assert(a == a_expect);

	//Nested Structs
	binary_demarshaller = new CompactBinaryDemarshaller;
	static struct B
	{
		int i1 = 1024;
		float f1 = 22.2;
		A a;
	}
	B b_expect;
	B b;
	b_expect.i1 = 1024;
	b_expect.f1 = 22.2;
	b_expect.a.x = 10;
	b_expect.a.y = 11.2;
	b_expect.a.z = "abc";
	binary_demarshaller.SetBuffer([/*b.i1 */0, 0, 4, 0,
								   /*b.f1 */65, 177, 153, 154,
								   /*b.a.x*/0, 0, 0, 10,
								   /*b.a.y*/65, 51, 51, 51,
								   /*b.a.z*/0, 0, 0, 3, 'a', 'b', 'c']);
	
	binary_demarshaller.Demarshal("", b);
//	writeln(to!string(b));
	assert( b == b_expect );
	
	//Self Defined Marshal Function
	binary_demarshaller = new CompactBinaryDemarshaller;
	static struct C
	{
		int x;
		int y;
		int z;
		void Demarshal(DemarshalStrategy : CompactBinaryDemarshallerStrategy!StorageStrategy, 
					   StorageStrategy : BinaryDemarshallerStorageStrategy)
				   	  (StorageStrategy storer, string name)
		{
			assert(name == "test");
			x = storer.ReadVal!int;
			y = 122;
			z = 333;
		}
	}
	C c_expect;
	C c;
	c_expect.x = 1;
	c_expect.y = 122;
	c_expect.z = 333;
	binary_demarshaller.SetBuffer([0, 0, 0, 1]);
	binary_demarshaller.Demarshal("test", c);
	
	assert(c == c_expect);
	
	//Read in multiple variables
	int v1;
	char[] s1;
	int v2;
	binary_demarshaller = new CompactBinaryDemarshaller;
	binary_demarshaller.SetBuffer([0,0,0,1,0,0,0,3,'a','b','c',0,0,0,5]);
	
	binary_demarshaller.Demarshal("", v1);
	binary_demarshaller.Demarshal("", s1);
	binary_demarshaller.Demarshal("", v2);
	
	assert( v1 == 1 );
	assert( s1 == "abc" );
	assert( v2 == 5 );
}