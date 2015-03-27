module libs.marshal.xml_text_demarshaller;

import libs.marshal.text_demarshaller, libs.marshal.demarshaller;
import std.conv, std.string, std.traits;
import std.stdio;

alias Demarshaller!(XmlDemarshallerStrategy, TextDemarshallerStorageStrategy) XmlTextDemarshaller;

package class XmlDemarshallerStrategy(StorageStrategy) : IDemarshalStrategy
{
	mixin DemarshalMixinTemplate!(StorageStrategy);
	
	void BeginArrayDemarshal(T)(string name, ref T val)
	{
		m_storer.ChompWhitespace();
		m_storer.Expect(format("<%s>", name));
	}
	
	void EndArrayDemarshal(T)(string name, ref T val)
	{
		m_storer.ChompWhitespace();
		m_storer.Expect(format("</%s>", name));
	}
	
	void BeginDocumentDemarshal(string name)
	{
		//m_storer.AddLine(`<?xml version="1.0" encoding="UTF-8"?>`);
	}
	
	void EndDocumentDemarshal(string name)
	{
	}
	
	void BeginObjectDemarshal(T)(string name, ref T val)
	{
		m_storer.ChompWhitespace();
		m_storer.Expect(format("<%s>", name));
	}
	
	void EndObjectDemarshal(T)(string name, ref T val)
	{
		m_storer.ChompWhitespace();
		m_storer.Expect(format("</%s>", name));
	}
	
	void DemarshalSingleVar(T)(string name, ref T val)
	{
		m_storer.ChompWhitespace();
		m_storer.Expect(format("<%s>", name)); // throws exception..
		m_storer.ReadValAndExpect(val, format("</%s>", name)); // throws exception
		
//		writefln("expect('%s'), ReadValAndExpect('%s', '%s')", format("<%s>", name), val, format("</%s>", name));
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
	XmlTextDemarshaller xml_demarshaller = new XmlTextDemarshaller;
	xml_demarshaller.SetText("<meaning of life>42</meaning of life>\r\n");
	
	int meaning_of_life;
	xml_demarshaller.Demarshal("meaning of life", meaning_of_life);
	assert(meaning_of_life == 42);
	
	//Strings
	char[] name;
	xml_demarshaller = new XmlTextDemarshaller;
	xml_demarshaller.SetText("<name>a string</name>\r\n");
	xml_demarshaller.Demarshal("name", name);
	
	assert(name == "a string");
	
	//Enums
	enum MyEnum
	{
		a = 10,
		b,
		c
	}
	MyEnum myenum;
	xml_demarshaller = new XmlTextDemarshaller;
	xml_demarshaller.SetText("<myenum>b</myenum>\r\n");
	xml_demarshaller.Demarshal("myenum", myenum);
	assert(myenum == MyEnum.b);

	//Arrays
	xml_demarshaller = new XmlTextDemarshaller;
	xml_demarshaller.SetText( "<ary>\r\n" ~ 
								"\t<0>1</0>\r\n" ~
								"\t<1>2</1>\r\n" ~
								"\t<2>3</2>\r\n" ~
								"\t<3>44</3>\r\n" ~
								"\t<4>5</4>\r\n" ~ 
								"</ary>\r\n");
	
	int[] ary_expect = [1, 2, 3, 44, 5];
	int[] ary;
	xml_demarshaller.Demarshal("ary", ary);
	assert(ary == ary_expect);
	
	//Structs
	xml_demarshaller = new XmlTextDemarshaller;
	static struct A
	{
		int x = 10;
		float y = 11.2;
		string z = "test string";
	}
	A a_expect;
	A a;
	a.x = 0;
	a.y = 0;
	a.z = "";
	xml_demarshaller.SetText( "<a>\r\n" ~ 
								"\t<x>10</x>\r\n" ~
								"\t<y>11.2</y>\r\n" ~
								"\t<z>test string</z>\r\n" ~
								"</a>\r\n");
	xml_demarshaller.Demarshal("a", a);
	assert(a == a_expect);

	//Nested Structs
	xml_demarshaller = new XmlTextDemarshaller;
	static struct B
	{
		int i1 = 1024;
		float f1 = 22.2;
		A a;
	}
	B b_expect;
	B b;
	b.i1 = 0;
	b.f1 = 0;
	b.a.x = 0;
	b.a.y = 0;
	b.a.z = "";
	xml_demarshaller.SetText( "<b>\r\n" ~
								"\t<i1>1024</i1>\r\n" ~
								"\t<f1>22.2</f1>\r\n" ~
								"\t<a>\r\n" ~ 
								"\t\t<x>10</x>\r\n" ~
								"\t\t<y>11.2</y>\r\n" ~
								"\t\t<z>test string</z>\r\n" ~
								"\t</a>\r\n" ~
								"</b>\r\n");
	
	xml_demarshaller.Demarshal("b", b);
	assert( b == b_expect );
	
	//Self Defined Marshal Function
	xml_demarshaller = new XmlTextDemarshaller;
	static struct C
	{
		int x;
		int y;
		int z;
		void Demarshal(DemarshalStrategy : XmlDemarshallerStrategy!StorageStrategy, 
					   StorageStrategy : TextDemarshallerStorageStrategy)
				   	  (StorageStrategy storer, string name)
		{
			assert(name == "cabname");
			storer.ChompWhitespace();
			storer.Expect("cab:");
			storer.ChompWhitespace();
			storer.ReadValAndExpect(x, "ab");
			y = 122;
			z = 333;
		}
	}
	C c_expect;
	C c;
	c_expect.x = 123;
	c_expect.y = 122;
	c_expect.z = 333;
	xml_demarshaller.SetText("   \t\rcab: 123ab");
	xml_demarshaller.Demarshal("cabname", c);
	
	assert(c == c_expect);
	
	//Read in multible variables
	int v1;
	char[] s1;
	xml_demarshaller = new XmlTextDemarshaller;
	xml_demarshaller.SetText( "<name>a string</name>\r\n" ~
								"<var>1222</var>\r\n");
	
	xml_demarshaller.Demarshal("name", s1);
	xml_demarshaller.Demarshal("var", v1);
	
	assert( s1 == "a string");
	assert( v1 == 1222);

}