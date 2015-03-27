module libs.marshal.human_readable_text_marshaller;

import libs.marshal.text_marshaller, libs.marshal.marshaller;
import std.conv, std.string, std.traits;
import std.stdio;

alias Marshaller!(XmlMarshallerStrategy, TextMarshallerStorageStrategy) HumanReadableTextMarshaller;

package class XmlMarshallerStrategy(StorageStrategy) : IMarshalStrategy
{
	mixin MarshalMixinTemplate!(StorageStrategy);
	
	void BeginDocumentMarshal(string name)
	{
		m_storer.SetIndentationString(" ");
	}
	
	void EndDocumentMarshal(string name)
	{
		
	}
	
	void BeginObjectMarshal(T)(T val, string name)
	{
		m_storer.AddLine(format("%s:", name));
		m_storer.IncreaseIndentation(name.length + 2);
	}
	
	void EndObjectMarshal(T)(T val, string name)
	{
		m_storer.UndoLastIndentation();
	}
	
	void BeginArrayMarshal(T)(T val, string name)
	{
		BeginObjectMarshal(val, name);
	}
	
	void EndArrayMarshal(T)(T val, string name)
	{
		EndObjectMarshal(val, name);
	}
	
	void MarshalSingleVar(T)(T val, string name)
	{
		m_storer.AddLine(format("%s: %s", name, val));
	}
		
	void MarshalEnum(T)(T val, string name)
	{
		m_storer.AddLine(format("%s: \"%s\" (%s)", name, to!string(val), to!(OriginalType!T)(val)));
	}
		
	void MarshalUnion(T)(T val, string name)
	{
		MarshalSingleVar(val, name);
	}
}

unittest {
	//Integers
	HumanReadableTextMarshaller human_readable_marshaller = new HumanReadableTextMarshaller;
	human_readable_marshaller.Marshal(42, "meaning of life");
	assert(human_readable_marshaller.ToString() == "meaning of life: 42\r\n");
	
	//Strings
	human_readable_marshaller = new HumanReadableTextMarshaller;
	human_readable_marshaller.Marshal("a string", "name");
	assert(human_readable_marshaller.ToString() == "name: a string\r\n");

	//Enums
	enum MyEnum
	{
		a = 10,
		b,
		c
	}
	MyEnum myenum;
	human_readable_marshaller = new HumanReadableTextMarshaller;
	human_readable_marshaller.Marshal(myenum, "myenum");
	assert(human_readable_marshaller.ToString() == "myenum: \"a\" (10)\r\n");

	//Arrays
	human_readable_marshaller = new HumanReadableTextMarshaller;
	int[] ary = [1, 2, 3, 44, 5];
	human_readable_marshaller.Marshal(ary, "ary");
	//writeln(human_readable_marshaller.ToString());
	assert(human_readable_marshaller.ToString() == "ary:\r\n" ~ 
												   "     0: 1\r\n" ~ 
												   "     1: 2\r\n" ~
												   "     2: 3\r\n" ~
												   "     3: 44\r\n" ~
												   "     4: 5\r\n");
	
	//Structs
	human_readable_marshaller = new HumanReadableTextMarshaller;
	static struct A
	{
		int x = 10;
		float y = 11.2;
		string z = "test string";
	}
	A a;
	human_readable_marshaller.Marshal(a, "a");
	//writeln(human_readable_marshaller.ToString());
	assert(human_readable_marshaller.ToString() == "a:\r\n" ~ 
												   "   x: 10\r\n" ~
												   "   y: 11.2\r\n" ~
												   "   z: test string\r\n");
	
	//Nested Structs
	human_readable_marshaller = new HumanReadableTextMarshaller;
	static struct B
	{
		A a;
		int i1 = 1024;
		float f1 = 22.2;
	}
	B b;
	human_readable_marshaller.Marshal(b, "b");
	//writeln(human_readable_marshaller.ToString());
	assert(human_readable_marshaller.ToString() == "b:\r\n" ~
												   "   a:\r\n" ~
												   "      x: 10\r\n" ~
												   "      y: 11.2\r\n" ~
												   "      z: test string\r\n" ~
												   "   i1: 1024\r\n" ~
												   "   f1: 22.2\r\n");
	
	//Self Defined Marshal Function
	human_readable_marshaller = new HumanReadableTextMarshaller;
	static struct C
	{
		void Marshal(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, StorageStrategy : TextMarshallerStorageStrategy)(StorageStrategy storer, string name)
		{
			storer.AddText(format("%s: inner", name));
		}
	}
	C c;
	human_readable_marshaller.Marshal(c, "cab");
	assert(human_readable_marshaller.ToString() == "cab: inner");
}