module libs.marshal.xml_text_marshaller;

import libs.marshal.text_marshaller, libs.marshal.marshaller;
import std.conv, std.string, std.traits;
import std.stdio;

alias Marshaller!(XmlMarshallerStrategy, TextMarshallerStorageStrategy) XmlTextMarshaller;

package class XmlMarshallerStrategy(StorageStrategy) : IMarshalStrategy
{
	mixin MarshalMixinTemplate!(StorageStrategy);
	
	void BeginDocumentMarshal(string name)
	{
		//m_storer.AddLine(`<?xml version="1.0" encoding="UTF-8"?>`);
	}
	
	void EndDocumentMarshal(string name)
	{
	}
	
	void BeginObjectMarshal(T)(T val, string name)
	{
		m_storer.AddLine(format("<%s>", name));
		m_storer.IncrementIndentation();
	}
	
	void EndObjectMarshal(T)(T val, string name)
	{
		m_storer.DecrementIndentation();
		m_storer.AddLine(format("</%s>", name));
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
		m_storer.AddLine(format("<%s>%s</%s>", name, val, name));
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
	XmlTextMarshaller xml_marshaller = new XmlTextMarshaller;
	xml_marshaller.Marshal(42, "meaning of life");
	assert(xml_marshaller.ToString() == "<meaning of life>42</meaning of life>\r\n");
	
	//Strings
	xml_marshaller = new XmlTextMarshaller;
	xml_marshaller.Marshal("a string", "name");
	assert(xml_marshaller.ToString() == "<name>a string</name>\r\n");
	
	//Enums
	enum MyEnum
	{
		a = 10,
		b,
		c
	}
	MyEnum myenum;
	xml_marshaller = new XmlTextMarshaller;
	xml_marshaller.Marshal(myenum, "myenum");
	assert(xml_marshaller.ToString() == "<myenum>a</myenum>\r\n");

	//Arrays
	xml_marshaller = new XmlTextMarshaller;
	int[] ary = [1, 2, 3, 44, 5];
	xml_marshaller.Marshal(ary, "ary");
	assert(xml_marshaller.ToString() == "<ary>\r\n" ~ 
										"\t<0>1</0>\r\n" ~
										"\t<1>2</1>\r\n" ~
										"\t<2>3</2>\r\n" ~
										"\t<3>44</3>\r\n" ~
										"\t<4>5</4>\r\n" ~ 
										"</ary>\r\n");
	
	//Structs
	xml_marshaller = new XmlTextMarshaller;
	static struct A
	{
		int x = 10;
		float y = 11.2;
		string z = "test string";
	}
	A a;
	xml_marshaller.Marshal(a, "a");
	//writeln(xml_marshaller.ToString());
	assert(xml_marshaller.ToString() == "<a>\r\n" ~ 
										"\t<x>10</x>\r\n" ~
										"\t<y>11.2</y>\r\n" ~
										"\t<z>test string</z>\r\n" ~
										"</a>\r\n");
	
	//Nested Structs
	xml_marshaller = new XmlTextMarshaller;
	static struct B
	{
		int i1 = 1024;
		float f1 = 22.2;
		A a;
	}
	B b;
	xml_marshaller.Marshal(b, "b");
	//writeln(xml_marshaller.ToString());
	assert(xml_marshaller.ToString() == "<b>\r\n" ~
										"\t<i1>1024</i1>\r\n" ~
										"\t<f1>22.2</f1>\r\n" ~
										"\t<a>\r\n" ~ 
										"\t\t<x>10</x>\r\n" ~
										"\t\t<y>11.2</y>\r\n" ~
										"\t\t<z>test string</z>\r\n" ~
										"\t</a>\r\n" ~
										"</b>\r\n");
	
	//Self Defined Marshal Function
	xml_marshaller = new XmlTextMarshaller;
	static struct C
	{
		void Marshal(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, StorageStrategy : TextMarshallerStorageStrategy)(StorageStrategy storer, string name)
		{
			storer.AddText(format("%s: inner", name));
		}
	}
	C c;
	xml_marshaller.Marshal(c, "cab");
	assert(xml_marshaller.ToString() == "cab: inner");
	
	//Self Defined Begin and End Marshal Functions
	xml_marshaller = new XmlTextMarshaller;
	static struct D
	{
		int x = 1;
		void BeginObjectMarshal(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, StorageStrategy : TextMarshallerStorageStrategy)(StorageStrategy storer, string name)
		{
			storer.AddText(format("%s: start, ", name));
		}
		
		void EndObjectMarshal(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, StorageStrategy : TextMarshallerStorageStrategy)(StorageStrategy storer, string name)
		{
			storer.AddText(format("%s: end", name));
		}
	}
	D d;
	xml_marshaller.Marshal(d, "cab");
//	writeln(xml_marshaller.ToString());
	assert(xml_marshaller.ToString() == "cab: start, <x>1</x>\r\ncab: end");
	
	//Self Defined Begin/End for array... 
	//Doesn't work.  Need Begin and End Array Marshal to be visible to marshaller.d?
	xml_marshaller = new XmlTextMarshaller;
	
	struct E
	{ 
		int x = 2; 
	}
	
	@property void BeginArrayMarshal
		(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, 
		 StorageStrategy : TextMarshallerStorageStrategy)
		(E[] ary, StorageStrategy storer, string name)
	{
		storer.AddText(format("start %s\r\n", name));
	}
	
	@property void EndArrayMarshal 
		(MarshalStrategy : XmlMarshallerStrategy!StorageStrategy, 
		 StorageStrategy : TextMarshallerStorageStrategy)
		(E[] ary, StorageStrategy storer, string name)
	{
		storer.AddText(format("end %s\r\n", name));
	}
	
	E[] e_ary = [E(), E(), E()];
	xml_marshaller.Marshal(e_ary, "e_ary");
	//writeln(xml_marshaller.ToString()); // Doesn't print what we expect..!
	//assert( xml_marshaller.ToString() == "start e_ary\r\n" ~
	//									 "<0>..............\r\n");
}